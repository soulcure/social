import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:convert/convert.dart';
import 'package:cross_file/cross_file.dart';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:fb_utils/fb_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:im/api/entity/cos_auth.dart';
import 'package:im/api/upload_api.dart';
import 'package:im/core/http_middleware/http.dart';
import 'package:im/loggers.dart';
import 'package:im/utils/rsa_util.dart';
import 'package:im/utils/universal_platform.dart';
import 'package:im/ws/ws.dart';
import 'package:path/path.dart' as p;
import 'package:pedantic/pedantic.dart';
import 'package:xml/xml.dart';

import 'cos_file_cache_index.dart';

typedef UploadProgressCallback = void Function(String fileId, double progress);
typedef UploadErrorCallback = void Function(String fileId, Exception error);
typedef UploadFinishCallback = void Function(String fileId, String downloadUrl);
typedef UploadStatusCallback = void Function(
    String fileId, CosUploadStatus status);
const int MAX_UNSLICE_FILE_SIZE = 1024 * 1024 * 5; //5M
const int SIZE_100M = 100 * 1024 * 1024;
const int SIZE_4M = 4 * 1024 * 1024;

class CosUploadException implements Exception {
  final int statusCode;
  final String code;
  final String message;
  CosUploadException(this.code, this.message, {this.statusCode});
  @override
  String toString() => "$code : $message";
}

enum CosUploadFileType {
  unKnow,
  video,
  image,
  audio,
  headImage, //头像
  live,
  pdf,
  txt,
  doc,
  circleIcon, //圈子头像
}

extension CosUploadFileTypeString on CosUploadFileType {
  String nameString() {
    switch (this) {
      case CosUploadFileType.unKnow:
        return 'unKnow';
      case CosUploadFileType.video:
        return 'video';
      case CosUploadFileType.image:
        return 'image';
      case CosUploadFileType.audio:
        return 'audio';
      case CosUploadFileType.headImage:
        return 'headImage';
      case CosUploadFileType.pdf:
        return 'pdf';
      case CosUploadFileType.txt:
        return 'txt';
      case CosUploadFileType.live:
        return "live";
      case CosUploadFileType.doc:
        return "doc";
      case CosUploadFileType.circleIcon:
        return "circleIcon";
      default:
        return "files";
    }
  }

  String contentTypeString({String ext = ''}) {
    switch (this) {
      case CosUploadFileType.video:
        return 'video/mp4';
      case CosUploadFileType.audio:
        return 'audio/mp3';
      case CosUploadFileType.image:
      case CosUploadFileType.headImage:
      case CosUploadFileType.circleIcon:
        if (ext.contains("gif")) return "image/gif";
        if (ext.contains("png")) return "image/png";
        return 'image/jpeg';
      case CosUploadFileType.pdf:
        return 'application/pdf';
      case CosUploadFileType.txt:
        return 'text/plain';
      case CosUploadFileType.doc:
        return 'application/msword';
      default:
        return "application/octet-stream";
    }
  }
}

enum CosUploadMode {
  unKnow,
  single, //文件直接上传  dio
  slice, //文件分片上传 dio
  bytes, //二进制上传，web http
}

enum CosUploadStatus {
  unKnow,
  init,
  wait,
  uploading,
  cancel,
  error,
  sliceMerge,
  finished,
}

Future<String> getBytesHash(Uint8List bytes) async {
  final fileBytes = bytes.buffer.asUint8List();
  final hash = md5.convert(fileBytes.buffer.asUint8List()).toString();
  return hash;
}

Future<String> getWebFileHash(String filePath) async {
  final file = XFile(filePath);
  final fileLength = await file.length();

  if (fileLength < SIZE_100M) {
    final bytes = await file.readAsBytes();
    final fileBytes = bytes.buffer.asUint8List();
    final hash = md5.convert(fileBytes.buffer.asUint8List()).toString();
    return hash;
  }

  final hash = await md5.bind(file.openRead()).first;
  return hash.toString();
}

Future<String> getFileHash(String filePath) async {
  final file = File(filePath);
  final fileLength = file.lengthSync();

  if (fileLength < SIZE_100M) {
    final fileBytes = file.readAsBytesSync().buffer.asUint8List();
    final hash = md5.convert(fileBytes.buffer.asUint8List()).toString();
    return hash;
  }

  final sFile = await file.open();
  try {
    final output = AccumulatorSink<Digest>();
    final input = md5.startChunkedConversion(output);
    int x = 0;
    const chunkSize = SIZE_100M;
    while (x < fileLength) {
      final tmpLen = fileLength - x > chunkSize ? chunkSize : fileLength - x;
      input.add(sFile.readSync(tmpLen));
      x += tmpLen;
    }
    input.close();

    final hash = output.events.single;
    return hash.toString();
  } finally {
    unawaited(sFile.close());
  }
}

class CosPutObject {
  String fileId; //def val: file.path
  CosUploadFileType fileType;
  String fileExt;
  int fileSize;
  String filePath;
  String fileName;
  String hash;
  CancelToken cancelToken;
  String cosUploadId;
  String cosKey;
  String bucket;
  String cdnUrl;
  CosUploadMode mode = CosUploadMode.single;
  int sliceSize; //mode=slice有效， 分片大小
  bool forceAudit = false;

  int reTryCount = 1;
  bool isUploading = false;
  bool isCanceling = false;
  final List<Map> slicePartPutRecord = [];
  Uint8List fileBytes; //mode=bytes有效， 二进制上传
  double sendProgress = 0;
  CosUploadStatus status = CosUploadStatus.unKnow;
  TaskCompleter taskCompleter; //只用于队列await返回结果使用

  static int _getSliceSize(int filesize, int sliceSize) {
    const maxSlice = 10000; //最大10000片
    var uploadSliceLength = max(SIZE_4M, sliceSize);

    while ((filesize / uploadSliceLength).ceil() > maxSlice) {
      uploadSliceLength *= 2;
    }
    logger.info('自动分片大小：$uploadSliceLength');
    return uploadSliceLength;
  }

  /*
    新建上传对象
    filePath： 文件路径
    fileType： 文件类型
    forceAudit： 是否强制审核
   */
  static Future<CosPutObject> create(
      String filePath, CosUploadFileType fileType,
      {String fileId,
      int sliceSize = SIZE_4M,
      String fileName,
      bool forceAudit = false}) async {
    final fileSize =
        kIsWeb ? (await XFile(filePath).length()) : File(filePath).lengthSync();
    final String extension = p.extension(filePath).toLowerCase();
    fileId ??= filePath;
    final item = CosPutObject()
      ..fileId = fileId
      ..fileType = fileType
      ..fileExt = extension ?? ''
      ..filePath = filePath
      ..fileSize = fileSize
      ..fileName = fileName
      ..forceAudit = forceAudit
      ..cancelToken = CancelToken();
    item.mode = fileSize > MAX_UNSLICE_FILE_SIZE
        ? CosUploadMode.slice
        : CosUploadMode.single;
    if (item.mode == CosUploadMode.slice) {
      item.sliceSize = _getSliceSize(fileSize, sliceSize);
    }
    logger.info("文件大小： ${fileSize / 1024 / 1024}M， 上传方式:${item.mode}");
    return item;
  }

  static Future<CosPutObject> createFromBytes(
      Uint8List bytes, CosUploadFileType fileType,
      {String fileId, String fileName = "", bool forceAudit = false}) async {
    final fileSize = bytes.lengthInBytes;
    final String extension = p.extension(fileName).toLowerCase();
    fileId ??= fileName;

    final item = CosPutObject()
      ..fileBytes = bytes
      ..mode = CosUploadMode.bytes
      ..fileId = fileId
      ..fileType = fileType
      ..fileExt = extension ?? ''
      ..fileSize = fileSize
      ..forceAudit = forceAudit
      ..fileName = fileName;
    return item;
  }
}

class CosFileUploadQueue {
  static CosFileUploadQueue _instance;
  factory CosFileUploadQueue() => _getInstance();
  static CosFileUploadQueue get instance => _getInstance();
  static CosFileUploadQueue _getInstance() {
    return _instance ??= CosFileUploadQueue._internal();
  }

  int maxConcurrentOperationCount = 3;
  CosFileUpload upload;
  int get queueCount => _queue.length;

  List<CosPutObject> _queue;

  CosFileUploadQueue._internal() {
    _queue = [];
    upload = CosFileUpload();
  }

  void registCallback(
      {UploadProgressCallback onSendProgress,
      UploadErrorCallback onError,
      UploadFinishCallback onFinish,
      UploadStatusCallback onStatus}) {
    upload.onSendProgress = onSendProgress;
    upload.onError = onError;
    upload.onFinish = onFinish;
    upload.onStatus = onStatus;
  }

  void disposeCallback() {
    upload.onSendProgress = null;
    upload.onError = null;
    upload.onFinish = null;
    upload.onStatus = null;
  }

  /*
  添加到任务队列，不返回任务执行结果
  结果通过callback返回,方便统一管理。
   */
  Future<void> addQueue(CosPutObject item) async {
    // if(findPutObject(item.fileId) != null) return; //队列存在
    _queue.add(item);
    unawaited(_startConsumeQueue());
  }

  /*
   添加到任务队列，等待返回任务执行结果
   */
  Future<String> executeCompeterTask(CosPutObject item) async {
    // if(findPutObject(item.fileId) != null) return null; //队列存在
    item.taskCompleter = TaskCompleter<String>();
    _queue.add(item);
    unawaited(_startCompeterConsumeQueue());
    return item.taskCompleter.future;
  }

  /*
   发送失败之后，如果重新发送相同文件，需要先在任务删除该任务
   */
  void removeQueueItem(CosPutObject item) {
    _queue.removeWhere((element) => item.fileId == element.fileId);
  }

  /*
  不添加到队列中，直接执行任务
  同： CosFileUploadQueue.instance.upload.cosFileUpload(item)
   */
  Future<String> once(CosPutObject item) async {
    return upload.cosFileUpload(item);
  }

  /*
  不添加到队列中，直接执行任务
  不需要监听CosPutObject实例状态时候使用
  同： CosFileUploadQueue.instance.upload.cosFileUpload(item)
   */
  Future<String> onceForPath(String filePath, CosUploadFileType fileType,
      {String fileId, String fileName = "", bool forceAudit = false}) async {
    final obj = await CosPutObject.create(filePath, fileType,
        fileId: fileId, fileName: fileName, forceAudit: forceAudit);
    return upload.cosFileUpload(obj);
  }

  /*
  不添加到队列中，直接上传二进制，web用
  不需要监听CosPutObject实例状态时候使用
  同： CosFileUploadQueue.instance.upload.cosFileUpload(item)
   */
  Future<String> onceForBytes(Uint8List bytes, CosUploadFileType fileType,
      {String fileId, String fileName = "", bool forceAudit = false}) async {
    final obj = await CosPutObject.createFromBytes(bytes, fileType,
        fileId: fileId, fileName: fileName, forceAudit: forceAudit);
    return upload.cosFileUpload(obj);
  }

  /*
  通过fileId查询队列中的对象，没有找到返回null
   */
  CosPutObject findPutObject(String fileId) {
    return _queue.firstWhere((element) => element.fileId == fileId,
        orElse: () => null);
  }

  int _uploadingCount() {
    int count = 0;
    _queue.forEach((element) {
      if (element.isUploading) count++;
    });
    return count;
  }

  CosPutObject firstInQueue() {
    return _queue.firstWhere((item) => !item.isUploading && !item.isCanceling,
        orElse: () {
      return null;
    });
  }

  Future<void> _startConsumeQueue() async {
    if (_queue.isEmpty) return;
    if (maxConcurrentOperationCount <= _uploadingCount()) return;

    final item = firstInQueue();
    if (item == null) return;
    item.isUploading = true;

    try {
      logger.info("queue开始上传: ${item.filePath}");
      await upload.cosFileUpload(item);
      logger.info("queue结束一个项目: ${item.filePath}");
      _queue.remove(item);
      unawaited(_startConsumeQueue());
    } catch (e) {
      logger.info('startConsumeQueue error: $e');
      final bool isNetworkError = Http.isNetworkError(e);
      logger.info('_startConsumeQueue error isNetworkError: $isNetworkError');

      if (e is DioError && e?.response?.statusCode == 403) {
        logger.info('_startConsumeQueue cos error 403: ${e.response}');
      }

      //报错处理
      item.reTryCount++;
      item.isUploading = false;
    }
  }

  Future<void> _startCompeterConsumeQueue() async {
    if (_queue.isEmpty) return;
    if (maxConcurrentOperationCount <= _uploadingCount()) return;

    final item = firstInQueue();
    if (item == null) return;
    item.isUploading = true;

    final ret = await upload.cosFileUpload(item);
    _queue.remove(item);

    item.taskCompleter.reply(ret);
    unawaited(_startCompeterConsumeQueue());
  }

  Future<void> cancelFirst() async {
    final toCancelFile = firstInQueue();
    if (toCancelFile == null) return;
    try {
      toCancelFile.isCanceling = true;
      await upload.abortMultippartUpload(toCancelFile);
    } catch (e) {
      logger.info('cancel error; $e');
    } finally {
      _queue.remove(toCancelFile);
    }
  }

  /*
  取消队列中的某一项
   */
  Future<bool> cancel(String fileId) async {
    final toCancelFile =
        _queue.firstWhere((e) => e.fileId == fileId, orElse: () => null);
    if (toCancelFile == null) return true;

    try {
      toCancelFile.isCanceling = true;
      await upload.abortMultippartUpload(toCancelFile);
      _queue.remove(toCancelFile);
      return true;
    } catch (e) {
      logger.info('cancel error; $e');
      return false;
    }
  }

  Future<bool> cancelAll() async {
    _queue.forEach((element) {
      element.isCanceling = true;
    });
    for (final item in _queue) {
      unawaited(upload.abortMultippartUpload(item));
    }
    _queue.clear();
    return true;
  }
}

class CosFileUpload {
  // 使用分块上传，每块的大小限制在5GB以内，分块数量需要小于10000，
  // 即最大上传对象约为48.82TB，更多限制说明，请参见 规格与限制。
  //大于20M的文件需要进行分片传输
  final _myDio = Dio();
  CosAuth _cosAuth;
  DateTime _cosAuthExpired;

  UploadProgressCallback onSendProgress;
  UploadErrorCallback onError;
  UploadFinishCallback onFinish;
  UploadStatusCallback onStatus;

  int concurrenCount = 2; //单段并发
  int callBackInterval = 400; //上传进度回调间隔；单位:毫秒
  DateTime _lastCallbackTime = DateTime.now();

  String _signSecretKey(CosUploadFileType fileType, bool forceAudit) {
    return (fileType == CosUploadFileType.video) || forceAudit
        ? _cosAuth.decodeAuditSecretKey
        : _cosAuth.decodeSecretKey;
  }

  String _signSecretId(CosUploadFileType fileType, bool forceAudit) {
    return (fileType == CosUploadFileType.video) || forceAudit
        ? _cosAuth.auditsecretId
        : _cosAuth.secretId;
  }

  String _signToken(CosUploadFileType fileType, bool forceAudit) {
    return (fileType == CosUploadFileType.video) || forceAudit
        ? _cosAuth.auditToken
        : _cosAuth.token;
  }

  String _keyPrefix(CosUploadFileType fileType) {
    return fileType == CosUploadFileType.headImage
        ? _cosAuth.uploadPathService
        : _cosAuth.uploadPath;
  }

  String _upBucket(CosUploadFileType fileType, bool forceAudit) {
    return (fileType == CosUploadFileType.video) || forceAudit
        ? _cosAuth.auditBucket
        : _cosAuth.bucket;
  }

  String _genLocalCosKey(CosPutObject file) {
    /*
    cosKey = [prefix]/[fileType]/[hash]/[ext]
    prefix: "fanbook/app/files/service/"  用户headImage API返回
    prefix: "fanbook/app/files/chatroom/" 其他文件
    fileType: 文件类型 image|video|pdf|txt
    hash: 文件hash
    ext: 文件后缀，可为空字符串
     */
    return "${_keyPrefix(file.fileType)}${file.fileType.nameString()}/${file.hash}${file.fileExt}";
  }

  //上传URL HOST
  String _getHost(CosUploadFileType type, bool forceAudit) {
    return (type == CosUploadFileType.video) || forceAudit
        ? _cosAuth.auditHost
        : _cosAuth.host;
  }

  //下载URL HOST
  String _getCdnUrl(CosUploadFileType type, bool forceAudit) {
    return (type == CosUploadFileType.video) || forceAudit
        ? _cosAuth.auditUrl
        : _cosAuth.cdnUrl;
  }

  //优先取服务器时间
  DateTime get _nowDateTime {
    return Ws.nowDateTime;
  }

  /*
   httpMethod 转换为小写，例如 get 或 put。
   uriPathname 为请求路径，例如/或/exampleobject。
   reqParam  HTTP 请求参数
   fileType 文件类型
   reqHeader HTTP 请求头, option
   */
  String _cosSliceSign(String uriPathname, String httpMethod, String reqParam,
      CosUploadFileType fileType, bool forceAudit,
      [Map reqHeader]) {
    //doc: https://cos5.cloud.tencent.com/static/cos-sign/
    //步骤1：生成 KeyTime
    final nowTs = _nowDateTime.millisecondsSinceEpoch ~/ 1000;
    final keyTime = '$nowTs;${nowTs + 30 * 60}';

    // 步骤2：生成 SignKey
    // tmp_secretKey
    final hmacSha1SecretKey = Hmac(
        sha1, utf8.encode(_signSecretKey(fileType, forceAudit))); // HMAC-SHA1
    final signKey = hmacSha1SecretKey.convert(utf8.encode(keyTime)).toString();

    // 步骤3：生成 UrlParamList 和 HttpParameters
    final pDic = {};
    for (final String item in reqParam.split("&")) {
      final arr = item.split("=");
      final String key = Uri.encodeComponent(arr[0]).toLowerCase();
      final String value = Uri.encodeComponent(arr.length > 1 ? arr[1] : '');
      pDic[key] = value;
    }
    final allKeys = pDic.keys.toList(growable: false);
    allKeys.sort();
    String httpParameters = '';
    String urlParamList = '';
    allKeys.forEach((element) {
      urlParamList += "$element;";
      httpParameters += "$element=${pDic[element]}&";
    });
    if (urlParamList.endsWith(";")) {
      urlParamList = urlParamList.substring(0, urlParamList.length - 1);
    }
    if (httpParameters.endsWith("&")) {
      httpParameters = httpParameters.substring(0, httpParameters.length - 1);
    }

    // 步骤4：生成 HeaderList 和 HttpHeaders
    String httpHeaders = '';
    String headerList = '';
    if (reqHeader != null && reqHeader.keys.isNotEmpty) {
      final headedAllKeys = reqHeader.keys.toList(growable: false);
      headedAllKeys.sort();

      headedAllKeys.forEach((element) {
        headerList += "${Uri.encodeComponent(element)};".toLowerCase();
        httpHeaders +=
            "${element.toString().toLowerCase()}=${Uri.encodeComponent(reqHeader[element].toString())}&";
      });
      if (headerList.endsWith(";")) {
        headerList = headerList.substring(0, headerList.length - 1);
      }
      if (httpHeaders.endsWith("&")) {
        httpHeaders = httpHeaders.substring(0, httpHeaders.length - 1);
      }
    }

    // 步骤5：生成 HttpString
    //HttpMethod\nUriPathname\nHttpParameters\nHttpHeaders\n。
    final httpString =
        '$httpMethod\n$uriPathname\n$httpParameters\n$httpHeaders\n';

    // 步骤6：生成 StringToSign
    // sha1\nKeyTime\nSHA1(HttpString)\n
    final httpStringSha1 = sha1.convert(utf8.encode(httpString)).toString();
    final stringToSign = 'sha1\n$keyTime\n$httpStringSha1\n';

    // 步骤7：生成 Signature
    final hmacSha1SignKey = Hmac(sha1, utf8.encode(signKey)); // HMAC-SHA1
    final signature = hmacSha1SignKey.convert(utf8.encode(stringToSign));
    //logger.info('Signature: $signature');

    // 步骤8：生成签名 tmp_secretId
    return 'q-sign-algorithm=sha1&q-ak=${_signSecretId(fileType, forceAudit)}&q-sign-time=$keyTime&q-key-time=$keyTime&q-header-list=$headerList&q-url-param-list=$urlParamList&q-signature=$signature';
  }

  /*
  单个文件签名计算
  fileType 文件类型
   */
  Map _cosSingleSign(CosUploadFileType fileType, bool forceAudit) {
    //doc:https://cloud.tencent.com/document/product/436/14690
    //生成 KeyTime
    final nowTs = _nowDateTime.millisecondsSinceEpoch ~/ 1000;
    final keyTime = '$nowTs;${nowTs + 30 * 60}';

    //构造“策略”（Policy）
    final now = _nowDateTime;
    final dayAfter = DateTime.utc(now.year, now.month, now.day, now.hour + 12);
    //logger.info("dayAfter ${dayAfter.toIso8601String()}");
    final policyMap = {
      "expiration": dayAfter.toIso8601String(),
      "conditions": [
        {"acl": "default"},
        {"q-sign-algorithm": "sha1"},
        {"q-ak": _signSecretId(fileType, forceAudit)},
        {"q-sign-time": keyTime},
      ]
    };
    final policyString = json.encode(policyMap);
    final policyStringBase64 = base64Encode(utf8.encode(policyString));

    //生成 SignKey
    final hmacSha1SecretKey = Hmac(
        sha1, utf8.encode(_signSecretKey(fileType, forceAudit))); // HMAC-SHA1
    final signKey = hmacSha1SecretKey.convert(utf8.encode(keyTime)).toString();

    //生成 StringToSign
    final stringToSign = sha1.convert(utf8.encode(policyString)).toString();

    //生成 Signature
    final hmacSha1SignKey = Hmac(sha1, utf8.encode(signKey)); // HMAC-SHA1
    final signature = hmacSha1SignKey.convert(utf8.encode(stringToSign));
    return {
      'keyTime': keyTime,
      'signature': signature.toString(),
      "policy": policyStringBase64,
    };
  }

  Future<bool> _checkFileHashIsExist(String url) async {
    try {
      // 如果 CDN 上已经有这个资源，不用再上传
      final result = await _myDio.head(url).timeout(const Duration(seconds: 5));
      if (result.statusCode == 200) return true;
    } catch (e) {
      return false;
    }
    return false;
  }

  Future<void> _obtainSliceCosAuthFromServer() async {
    //临时密钥为空，或临时密钥到期前1.5小时重新获取
    if (_cosAuth != null &&
        _cosAuthExpired != null &&
        _cosAuthExpired.difference(_nowDateTime).inSeconds > 90 * 60) return;
    final res = await UploadApi.cosTmpKey();
    _cosAuth = CosAuth.fromJson(res);
    final now = _nowDateTime;
    final diff = now.millisecondsSinceEpoch ~/ 1000 - _cosAuth.startTs;
    // 时间误差1h
    //手机时间和服务器返回的开始时间粗略校验。手机时间不对，可能导致签名失败
    if (diff.abs() > 3600) {
      throw CosUploadException('3', "系统时间不准确");
    }
    _cosAuth.decodeSecretKey = decodeString(_cosAuth.secretKey);
    _cosAuth.decodeAuditSecretKey = decodeString(_cosAuth.auditSecretKey);
    _cosAuthExpired =
        DateTime.fromMillisecondsSinceEpoch((_cosAuth.expiredTs) * 1000);
  }

  Future<String> _fileHash(CosPutObject file) async {
    if (file.mode == CosUploadMode.bytes)
      return compute(getBytesHash, file.fileBytes);

    if (UniversalPlatform.isIOS || UniversalPlatform.isAndroid) {
      if (!File(file.filePath).existsSync()) {
        throw CosUploadException('5', '本地文件不存在');
      }
      return FbUtils.getMD5WithPath(file.filePath);
    }
    if (UniversalPlatform.isWeb) return compute(getWebFileHash, file.filePath);

    return compute(getFileHash, file.filePath);
  }

  Future<String> cosFileUpload(CosPutObject file) async {
    try {
      //获取临时密钥
      await _obtainSliceCosAuthFromServer();

      //数据准备 计算hash
      file.slicePartPutRecord.clear();
      final stopwatch2 = Stopwatch()..start();
      logger.info('开始计算hash');
      file.hash = await _fileHash(file);
      logger.info('hash executed in ${stopwatch2.elapsed}, hash: ${file.hash}');
      final key = _genLocalCosKey(file);
      file.cosKey = key;
      file.bucket = _upBucket(file.fileType, file.forceAudit);
      file.cdnUrl = "${_getCdnUrl(file.fileType, file.forceAudit)}/$key";
      file.status = CosUploadStatus.wait;
      onStatus?.call(file.fileId, file.status);

      //检查文件是否已经上传
      final isUploaded = await _checkFileHashIsExist(
          "${_getHost(file.fileType, file.forceAudit)}/${file.cosKey}");

      //cache path -- cdnurl
      if (file.fileType == CosUploadFileType.video ||
          file.fileType == CosUploadFileType.image)
        unawaited(CosUploadFileIndexCache.cache(file.cdnUrl, file.filePath));

      if (isUploaded) {
        logger.info('秒传：${file.cdnUrl}');
        file.status = CosUploadStatus.finished;
        onStatus?.call(file.fileId, file.status);
        onSendProgress?.call(file.fileId, 1);
        onFinish?.call(file.fileId, file.cdnUrl);
        return file.cdnUrl;
      }
      //分片上传
      if (file.mode == CosUploadMode.slice)
        return await _cosInitiatePartUpload(file);
      //二进制上传
      if (file.mode == CosUploadMode.bytes) return await _bytesFileUpload(file);
      //直接上传
      return await _singleFileUpload(file);
    } catch (e) {
      file.status = CosUploadStatus.error;
      file.isUploading = false;
      if (e is DioError &&
          e?.response?.statusCode == 403 &&
          file.reTryCount > 0) {
        logger.info('cos error 403: ${e.response}');
        _cosAuth = null;
        file.reTryCount--;
        await _obtainSliceCosAuthFromServer();
        return cosFileUpload(file);
      }

      if (onError != null && e is Exception) onError(file.fileId, e);
      logger.info("cosFileUpload error: $e");
      file.taskCompleter?.error("");
      // final bool isNetworkError = e is DioError &&
      //     [
      //       DioErrorType.connectTimeout,
      //       DioErrorType.sendTimeout,
      //       DioErrorType.receiveTimeout,
      //       DioErrorType.other,
      //     ].contains(e.type);
      // final bool isUserCancel = e is DioError &&
      //     [
      //       DioErrorType.cancel,
      //     ].contains(e.type);
      rethrow;
    }
  }

  Future<String> _bytesFileUpload(CosPutObject file) async {
    file.status = CosUploadStatus.uploading;
    onStatus?.call(file.fileId, file.status);
    final mySignDic = _cosSingleSign(file.fileType, file.forceAudit);
    final request = http.MultipartRequest(
        'POST', Uri.parse(_getHost(file.fileType, file.forceAudit)));
    request.fields['key'] = file.cosKey;
    request.fields['policy'] = mySignDic['policy'];
    request.fields['x-cos-security-token'] =
        _signToken(file.fileType, file.forceAudit);
    request.fields['q-sign-algorithm'] = "sha1";
    request.fields['q-ak'] = _signSecretId(file.fileType, file.forceAudit);
    request.fields['q-key-time'] = mySignDic['keyTime'];
    request.fields['q-signature'] = mySignDic['signature'];
    request.fields['acl'] = "default";
    request.fields['success_action_status'] = '200';
    request.files
        .add(http.MultipartFile.fromBytes('file', file.fileBytes.toList()));
    request.headers['Content-Type'] =
        file.fileType.contentTypeString(ext: file.fileExt);
    final res = await request.send();
    if (res.statusCode == 200) {
      logger.info('二进制文件上传ok');
      file.cancelToken = null;
      file.status = CosUploadStatus.finished;
      file.sendProgress = 1;
      onStatus?.call(file.fileId, file.status);
      onSendProgress?.call(file.fileId, 1);
      onFinish?.call(file.fileId, file.cdnUrl);
      return file.cdnUrl;
    } else {
      file.status = CosUploadStatus.error;
      onStatus?.call(file.fileId, file.status);
      logger.info("bytes上传文件失败${res.statusCode} ${res.reasonPhrase}");
    }
    return null;
  }

  Future<String> _singleFileUpload(CosPutObject file) async {
    file.status = CosUploadStatus.uploading;
    onStatus?.call(file.fileId, file.status);
    final mySignDic = _cosSingleSign(file.fileType, file.forceAudit);
    final bytes = UniversalPlatform.isWeb
        ? (await XFile(file.filePath).readAsBytes()).buffer.asUint8List()
        : File(file.filePath).readAsBytesSync().buffer.asUint8List();

    final stopwatch1 = Stopwatch()..start();
    final uploadForm = FormData.fromMap({
      "key": file.cosKey,
      "policy": mySignDic['policy'],
      "x-cos-security-token": _signToken(file.fileType, file.forceAudit),
      'q-sign-algorithm': 'sha1',
      "q-ak": _signSecretId(file.fileType, file.forceAudit),
      "q-key-time": mySignDic['keyTime'],
      "q-signature": mySignDic['signature'],
      "acl": "default",
      "file": MultipartFile.fromBytes(bytes, filename: ""),
    });
    final headers = {
      "Content-Type": file.fileType.contentTypeString(ext: file.fileExt),
      Headers.contentLengthHeader: bytes.length
    };
    final res = await _myDio.post(_getHost(file.fileType, file.forceAudit),
        options: Options(sendTimeout: 30000, headers: headers),
        data: uploadForm, onSendProgress: (c, t) {
      if (onSendProgress != null && t != 0 && t != -1) {
        if (DateTime.now().difference(_lastCallbackTime).inMilliseconds >
            callBackInterval) {
          _lastCallbackTime = DateTime.now();
          file.sendProgress = c / t;
          onSendProgress(file.fileId, c / t);
        }
      }
    });
    logger.info('单文件上传Ok:${res.headers}');
    logger.info("上传时间${stopwatch1.elapsed}");
    file.cancelToken = null;
    file.sendProgress = 1;
    file.status = CosUploadStatus.finished;
    onStatus?.call(file.fileId, file.status);
    onFinish?.call(file.fileId, file.cdnUrl);
    return file.cdnUrl;
  }

  //分片上传
  Future<String> _cosInitiatePartUpload(CosPutObject file) async {
    file.status = CosUploadStatus.init;
    onStatus?.call(file.fileId, file.status);

    final uploadUrl =
        "${_getHost(file.fileType, file.forceAudit)}/${file.cosKey}?uploads";
    final mySign = _cosSliceSign(
        '/${file.cosKey}', "post", "uploads", file.fileType, file.forceAudit);
    //logger.info('slice init upload url: $uploadUrl');
    final headers = {
      "success_action_status": 200,
      "x-cos-security-token": _signToken(file.fileType, file.forceAudit),
      "Authorization": mySign
    };
    headers['Content-Type'] =
        file.fileType.contentTypeString(ext: file.fileExt);
    final res = await _myDio.post(uploadUrl,
        options: Options(sendTimeout: 30000, headers: headers),
        cancelToken: file.cancelToken);
    final document = XmlDocument.parse(res.data);
    final cosUploadId = document
        .getElement("InitiateMultipartUploadResult")
        .getElement("UploadId")
        .text;
    //final cosUploadKey =  document.getElement("InitiateMultipartUploadResult").getElement("Key").text;
    //final cosBucket =  document.getElement("InitiateMultipartUploadResult").getElement("Bucket").text;
    //开始上传
    logger.info('分片初始化成功：$cosUploadId');
    file.cosUploadId = cosUploadId;

    final ret = concurrenCount == 1
        ? await _doCosPartUpload(file)
        : await _doCosPartUploadConcurren(file);
    return ret;
  }

  Future<String> _doCosPartUpload(CosPutObject file) async {
    final stopwatch1 = Stopwatch()..start();

    file.status = CosUploadStatus.uploading;
    onStatus?.call(file.fileId, file.status);

    final util = _CosFileReadUtils.path(file.filePath);

    final fileLength = file.fileSize; // 获取文件长度
    final chunkSize = file.sliceSize; // 分片大小
    int x = 0; // 已经上传的长度
    int chunkIndex = 1; // 传到第几片了

    while (x < fileLength) {
      final tmpLen = min(fileLength - x, chunkSize);
      //final postData = util.getRangeSync(x, x + tmpLen);
      final postData = kIsWeb
          ? await util.getRange(x, x + tmpLen)
          : util.getRangeSync(x, x + tmpLen);

      final reqP = 'partNumber=$chunkIndex&uploadId=${file.cosUploadId}';
      final uploadUrl =
          '${_getHost(file.fileType, file.forceAudit)}/${file.cosKey}?$reqP';
      final mySign = _cosSliceSign(
          '/${file.cosKey}', 'put', reqP, file.fileType, file.forceAudit);
      final headers = {
        'chunkIndex': chunkIndex,
        'Content-Length': postData.length,
        "x-cos-security-token": _signToken(file.fileType, file.forceAudit),
        "Authorization": mySign
      };

      if (file.cancelToken.isCancelled) return "";

      final dioRep = await _myDio.put(uploadUrl,
          data: Stream.fromIterable([postData]),
          options: Options(
              sendTimeout: 30000,
              headers: headers,
              contentType: 'application/octet-stream'), onSendProgress: (c, t) {
        final current = x + c; // x是已经上传成功的长度
        final total = fileLength;
        final p = current / total;
        file.sendProgress = p;
        if (onSendProgress != null) {
          if (DateTime.now().difference(_lastCallbackTime).inMilliseconds >
              callBackInterval) {
            _lastCallbackTime = DateTime.now();
            onSendProgress(file.fileId, p);
          }
        }
      }, cancelToken: file.cancelToken);

      // final reqH = (dioRep as Response).requestOptions.headers;
      // final chunkIndex = reqH['chunkIndex'];
      final etag = dioRep.headers.value("etag");
      file.slicePartPutRecord.add({'ETag': etag, 'PartNumber': chunkIndex});

      postData.clear();
      chunkIndex++;
      x += tmpLen;
    }
    logger.info('分片1并发执行时间 executed in ${stopwatch1.elapsed}');
    return _completeMultipartUpload(file);
  }

  //单文件并发上传
  Future<String> _doCosPartUploadConcurren(CosPutObject file) {
    //logger.info("并发V2 : $concurrenCount");
    final stopwatch1 = Stopwatch()..start();
    final ret = TaskCompleter<String>();

    file.status = CosUploadStatus.uploading;
    onStatus?.call(file.fileId, file.status);

    final fileLength = file.fileSize; // 获取文件长度
    final initChunkSize = file.sliceSize; // 初始分片大小
    final upList = <_ChunkItem>[];
    int upIndex = 0; //上传最大索引
    int upingCount = 0; //正在上传数量
    int offx = 0; //偏移量
    //final chunkProgessList = <int>[]; //进度
    int chunkSendCount = 0;
    final util = _CosFileReadUtils.path(file.filePath);

    int _calcNextChunkSize(int end) {
      //https://idreamsky.feishu.cn/docs/doccnv2cLoUueREnw3FwwY4yKug#4ykYX3
      final f = upList[end];
      if (f == null) return SIZE_4M;
      var rate = f.ts / 15000;
      rate = max(0.5, min(2, rate));
      final chunk = ((f.end - f.start) / rate).floor();
      // logger.info(
      //     "切片${f.index}的大小${f.chunkSize/1024/1024}M, 速率是${(f.end - f.start) / f.ts}b/ms,修正大小为${chunk / 1048576}M");
      return max(2 * 1024 * 1024, min(24 * 1024 * 1024, chunk));
    }

    Future<void> _upChunk(_ChunkItem chunk) async {
      try {
        final start = DateTime.now();
        // chunkProgessList.add(0);
        // final postData = kIsWeb
        //     ? await util.getRange(chunk.start, chunk.end)
        //     : util.getRangeSync(chunk.start, chunk.end);
        final postData = util.getRangeSync(chunk.start, chunk.end);
        final reqP =
            'partNumber=${chunk.index + 1}&uploadId=${file.cosUploadId}';
        final uploadUrl =
            '${_getHost(file.fileType, file.forceAudit)}/${file.cosKey}?$reqP';
        final mySign = _cosSliceSign(
            '/${file.cosKey}', 'put', reqP, file.fileType, file.forceAudit);
        final headers = {
          'chunkIndex': chunk.index + 1,
          'Content-Length': postData.length,
          "x-cos-security-token": _signToken(file.fileType, file.forceAudit),
          "Authorization": mySign
        };
        final dioRep = await _myDio.put(uploadUrl,
            data: Stream.fromIterable([postData]),
            options: Options(
                sendTimeout: 30000,
                receiveTimeout: 30000,
                headers: headers,
                contentType: 'application/octet-stream'),
            onSendProgress: (c, t) {
          // chunkProgessList[chunk.index] = c; // c是当前请求已经上传的长度
          // final sum = chunkProgessList.reduce((curr, next) => curr + next);
          chunkSendCount += c;
          // final current = sum;
          // final total = fileLength;
          final p = chunkSendCount / fileLength;
          file.sendProgress = p;
          if (onSendProgress != null) {
            if (DateTime.now().difference(_lastCallbackTime).inMilliseconds >
                callBackInterval) {
              _lastCallbackTime = DateTime.now();
              onSendProgress(file.fileId, p);
            }
          }
        }, cancelToken: file.cancelToken);
        final end = DateTime.now();
        chunk.ts = end.difference(start).inMilliseconds;
        postData.clear();
        // final reqH = dioRep.requestOptions.headers;
        // final chunkIndex = reqH['chunkIndex'];
        final etag = dioRep.headers.value("etag");
        file.slicePartPutRecord
            .add({'ETag': etag, 'PartNumber': chunk.index + 1});

        return chunk;
      } catch (e) {
        if (e is OutOfMemoryError) {
          logger.info('没有内存了');
          concurrenCount = max(1, concurrenCount--);
        }
        if (e is DioError &&
            e?.response?.statusCode == 403 &&
            chunk.retryCount > 0) {
          //一般是签名错误，没有权限
          logger.info('cos error 403: ${e.response}');
          _cosAuth = null;
          chunk.retryCount--;
          await _obtainSliceCosAuthFromServer();
          return _upChunk(chunk);
        }
        //其他错误不重试
        file.status = CosUploadStatus.error;
        file.isUploading = false;
        file.taskCompleter?.error("");
        onError?.call(file.fileId, e);
        // if (e is CosUploadException) ret.error(e.message);
        // if (e is DioError) ret.error(e.response?.data ?? '');
      }
    }

    void _genChunkItem({dynaChunkSize}) {
      final size = dynaChunkSize ?? initChunkSize;
      final start = offx;
      final end = min(fileLength, start + size);
      if (end > start) {
        offx = end;
        final cItem = _ChunkItem(start: start, end: end, index: upList.length);
        upList.add(cItem);
      }
    }

    Future<String> _consumeUpList() async {
      if (upingCount == 0 &&
          upIndex == upList.length &&
          offx >= file.fileSize) {
        logger.info('文件分片上传完成，执行时间： ${stopwatch1.elapsed}');
        //clear
        upList.clear();
        util.dispose();

        final url = await _completeMultipartUpload(file);
        ret.reply(url);
      }

      if (upIndex >= upList.length) return ret.future;

      final item = upList[upIndex];
      item.isUploading = true;
      upingCount++;
      upIndex++;
      await _upChunk(item);
      item.isUploading = false;
      item.isFinish = true;
      upingCount--;
      //构造下一个chunkItem
      if (file.cancelToken?.isCancelled ?? false) return "";
      _genChunkItem(dynaChunkSize: _calcNextChunkSize(item.index));
      unawaited(_consumeUpList());
      return ret.future;
    }

    for (var i = 0; i < concurrenCount; i++) {
      _genChunkItem();
      unawaited(_consumeUpList());
    }
    return ret.future;
  }

  //Complete Multipart Upload 完成分块上传
  void _buildPart(XmlBuilder builder, num part, String eTag) {
    builder.element('Part', nest: () {
      builder.element('PartNumber', nest: part);
      builder.element('ETag', nest: eTag);
    });
  }

  Future<String> _completeMultipartUpload(CosPutObject file) async {
    //sort
    file.slicePartPutRecord
        .sort((a, b) => a['PartNumber'].compareTo(b['PartNumber']));
    //check part number is continuous
    bool isContinuous = true;
    for (int i = 0; i < file.slicePartPutRecord.length - 1; i++) {
      if (file.slicePartPutRecord[i]['PartNumber'] + 1 !=
          file.slicePartPutRecord[i + 1]['PartNumber']) {
        logger.info(
            "file.slicePartPutRecord: ${file.slicePartPutRecord[i]['PartNumber']}-${file.slicePartPutRecord[i + 1]['PartNumber']}");
        isContinuous = false;
        break;
      }
    }
    if (isContinuous == false) {
      logger.info("file.slicePartPutRecord: ${file.slicePartPutRecord}");
      throw CosUploadException("2", 'check part number is not continuous',
          statusCode: 2);
    }

    file.status = CosUploadStatus.sliceMerge;
    onStatus?.call(file.fileId, file.status);

    final builder = XmlBuilder();
    builder.element('CompleteMultipartUpload', nest: () {
      file.slicePartPutRecord.forEach((element) {
        _buildPart(builder, element['PartNumber'], element['ETag']);
      });
    });
    final reqBodyXml = builder.buildDocument();
    final reqP = 'uploadId=${file.cosUploadId}';
    final uploadUrl =
        '${_getHost(file.fileType, file.forceAudit)}/${file.cosKey}?$reqP';
    final mySign = _cosSliceSign(
        '/${file.cosKey}', 'post', reqP, file.fileType, file.forceAudit);
    final headers = {
      "x-cos-security-token":
          _signToken(file.fileType, file.forceAudit), //  slice_token,
      "Authorization": mySign
    };
    final res = await _myDio.post(uploadUrl,
        data: reqBodyXml.toString(),
        options: Options(sendTimeout: 30000, headers: headers));
    final document = XmlDocument.parse(res.data);
    final fileLocation = document
        .getElement("CompleteMultipartUploadResult")
        .getElement("Location")
        .text;
    final fileBucket = document
        .getElement("CompleteMultipartUploadResult")
        .getElement("Bucket")
        .text;
    final fileKey = document
        .getElement("CompleteMultipartUploadResult")
        .getElement("Key")
        .text;
    logger.info("文件上传完成：$fileLocation\n$fileBucket\n$fileKey");

    //清除部分临时数据
    file.slicePartPutRecord.clear();
    file.cancelToken = null;

    file.status = CosUploadStatus.finished;
    onStatus?.call(file.fileId, file.status);
    onFinish?.call(file.fileId, file.cdnUrl);

    return file.cdnUrl;
  }

  CosUploadException parseCosError(String xmlString, int statusCode) {
    final document = XmlDocument.parse(xmlString);
    final error = document.getElement("Error");
    final errorCode = error.getElement("Code").text;
    final errorMessage = error.getElement("Message").text;
    final errorResource = error.getElement("Resource").text;
    final errorTraceId = error.getElement("TraceId").text;
    return CosUploadException(errorCode,
        "errorMessage: $errorMessage; errorResource:$errorResource; errorTraceId:$errorTraceId",
        statusCode: statusCode);
  }

  /*
  用来实现舍弃一个分块上传并删除已上传的块。
  当您调用 Abort Multipart Upload 时，如果有正在使用这个 Upload Parts 上传块的请求，
  则 Upload Parts 会返回失败
   */
  Future<bool> abortMultippartUpload(CosPutObject file) async {
    try {
      file.status = CosUploadStatus.cancel;
      onStatus?.call(file.fileId, file.status);

      if (file.cancelToken != null) file.cancelToken.cancel();

      if (file.status == CosUploadStatus.finished) return true;
      if (file.cosUploadId == null || file.cosUploadId.isEmpty) return true;

      final reqP = 'uploadId=${file.cosUploadId}';
      final uploadUrl =
          '${_getHost(file.fileType, file.forceAudit)}/${file.cosKey}?$reqP';
      final mySign = _cosSliceSign(
          '/${file.cosKey}', 'delete', reqP, file.fileType, file.forceAudit);
      final headers = {
        "x-cos-security-token":
            _signToken(file.fileType, file.forceAudit), //  slice_token,
        'Authorization': mySign
      };
      final res = await _myDio.delete(uploadUrl,
          options: Options(sendTimeout: 30000, headers: headers));
      logger.info('abortMultippartUpload ok: $res');
      return true;
    } catch (e) {
      logger.info('abordt error: $e');
    }
    return true;
  }

  /*
  通过uploadId 获取已上传的分片
   */
  Future<List> fetchUploadIdFinishedParts(String uploadId, String cosKey,
      CosUploadFileType fileType, bool forceAudit) async {
    try {
      final reqQ = 'uploadId=$uploadId';
      final uploadUrl = '${_getHost(fileType, forceAudit)}/$cosKey?$reqQ';
      final mySign =
          _cosSliceSign('/$cosKey', 'get', reqQ, fileType, forceAudit);
      final headers = {
        "x-cos-security-token":
            _signToken(fileType, forceAudit), //  slice_token,
        'Authorization': mySign
      };
      final res = await _myDio.get(uploadUrl,
          options: Options(sendTimeout: 30000, headers: headers));
      logger.info("list finish part ok: $res");

      final document = XmlDocument.parse(res.data);
      final finishList = [];
      final parts =
          document.getElement("ListPartsResult").findAllElements("Part");
      parts.forEach((element) {
        final partNumber = element.getElement("PartNumber").text;
        final lastModified = element.getElement("LastModified").text;
        final eTag = element.getElement("ETag").text;
        final size = element.getElement("Size").text;

        finishList.add({
          "PartNumber": partNumber,
          "LastModified": lastModified,
          "ETag": eTag,
          "Size": size
        });
      });
      return finishList;
    } catch (e) {
      logger.info("list finish part error: $e");
      return null;
    }
  }
}

class _CosFileReadUtils {
  File _file;
  XFile _xFile;

  _CosFileReadUtils.path(String filePath) {
    kIsWeb ? _xFile = XFile(filePath) : _file = File(filePath);
  }

  // 同步读取文件的某个范围返回, 不支持web
  List<int> getRangeSync(int start, int end) {
    // if(UniversalPlatform.isWeb){
    //   throw CosUploadException('4', '不支持');
    // }
    final accessFile = _file.openSync();
    try {
      accessFile.setPositionSync(start);
      return accessFile.readSync(end - start).toList();
    } finally {
      accessFile.closeSync();
    }
  }

  // 异步读取文件的某个范围返回
  Future<List<int>> getRange(int start, int end) async {
    if (_file != null && !_file.existsSync()) {
      throw CosUploadException('5', '本地文件不存在');
    }

    final c = TaskCompleter<List<int>>();
    List<int> result;
    result = [];
    if (UniversalPlatform.isWeb) {
      _xFile.openRead(start, end).listen((data) {
        result.addAll(data);
      }).onDone(() {
        c.reply(result);
      });
    } else {
      _file.openRead(start, end).listen((data) {
        result.addAll(data);
      }).onDone(() {
        c.reply(result);
      });
    }

    return c.future;
  }

  void dispose() {
    _file = null;
    _xFile = null;
  }
}

class TaskCompleter<T> {
  Completer<T> completer = Completer();
  TaskCompleter();

  Future<T> get future => completer.future;

  void reply(T result) {
    if (!completer.isCompleted) {
      completer.complete(result);
    }
  }

  void error(T result) {
    if (!completer.isCompleted) {
      completer.completeError(result);
    }
  }
}

class _ChunkItem {
  final int start;
  final int end;
  final int index;
  num ts; //chunk上传时间，用来动态修正下次chunk size
  bool isUploading = false;
  bool isFinish = false;
  int retryCount = 1;
  int get chunkSize => end - start;

  _ChunkItem({this.start, this.end, this.index});
}
