import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:im/core/http_middleware/http.dart';
import 'package:im/loggers.dart';
import 'package:im/utils/universal_platform.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pedantic/pedantic.dart';

import 'cos_file_upload.dart';

typedef DownProgressCallback = void Function(String fileId, double progress);
typedef DownErrorCallback = void Function(String fileId, Exception error);
typedef DownFinishCallback = void Function(String fileId, String downloadUrl);

class CosDownObject {
  String url;
  String fileId; //def md5(url)
  String savePath;
  CancelToken cancelToken;
  int reTryCount = 3;
  String fileName; //def md5(url)

  bool isDowning = false;
  bool isCance = false;
  double downProgress = 0;
  int fileSize;
  final chunkProgress = <int>[];
  final chunkProgressPre = <int>[];

  TaskCompleter taskCompleter; //只用于队列await返回结果使用

  static Future<CosDownObject> create(
    String url, {
    String fileId,
    String saveDir,
    String fileName = '',
  }) async {
    final hash = md5.convert(utf8.encode(url)).toString();
    fileId ??= hash;

    final savePath = await fileSavePath(
      url,
      fileId: fileId,
      saveDir: saveDir,
      fileName: fileName,
    );

    final item = CosDownObject()
      ..url = url
      ..fileId = fileId
      ..savePath = savePath
      ..fileName = fileName
      ..cancelToken = CancelToken();
    return item;
  }

  ///  - 文件本地存储路径
  static Future<String> fileSavePath(
    String url, {
    String fileId,
    String saveDir,
    String fileName = '',
  }) async {
    final hash = md5.convert(utf8.encode(url)).toString();
    fileId ??= hash;

    final tempDir = await fileDirectoryPath();
    saveDir ??= tempDir.path;
    final String extension = p.extension(url).toLowerCase();

    String savePath = "$saveDir/$fileId$extension";
    if (fileName.isNotEmpty) savePath = "$saveDir/$fileName";
    return savePath;
  }

  ///  - 文件本地存储路径
  static Future<String> fileNativePath(String fileName) async {
    final tempDir = await fileDirectoryPath();
    final savePath = "${tempDir.path}/$fileName";
    return savePath;
  }

  ///  - 文件本地存储目录
  static Future<Directory> fileDirectoryPath() async {
    // android 获取外部存储
    final cachePath = UniversalPlatform.isAndroid
        ? await getExternalStorageDirectory()
        : await getTemporaryDirectory();
    final filePath = "${cachePath.path}/files";
    // 文件夹不存在则创建文件夹
    var fileDirectory = Directory(filePath);
    try {
      if (!fileDirectory.existsSync()) {
        await fileDirectory.create();
      }
    } catch (e) {
      fileDirectory = null;
    }

    return fileDirectory ?? cachePath;
  }
}

class CosFileDownload {
  final _dio = Dio();
  final _firstChunkSize = 102; //用来请求HEAD中的content-length

  DownProgressCallback onDownProgress;
  DownErrorCallback onError;
  DownFinishCallback onFinish;
  int maxChunk = 6; //单文件下载最大并行数量

  int callBackInterval = 400; //下载进度回调间隔；单位:毫秒
  DateTime _lastCallbackTime = DateTime.now();

  Future<String> cosFileDownload(CosDownObject obj) async {
    try {
      //判断文件是否已经存在
      if (File(obj.savePath).existsSync()) {
        onDownProgress?.call(obj.fileId, 1);
        onFinish?.call(obj.fileId, obj.savePath);
        return obj.savePath;
      }

      final rangeRep =
          await _downloadChunk(obj, 0, _firstChunkSize, 0, isMerge: false);
      if (rangeRep.statusCode == 206) {
        //support range download
        //解析文件总长度，进而算出剩余长度
        obj.fileSize = int.parse(rangeRep.headers
            .value(HttpHeaders.contentRangeHeader)
            .split("/")
            .last);
        //2M以内，直接下载
        if (obj.fileSize < 2 * 1024 * 1024) return _singleDownload(obj);

        final reserved = obj.fileSize -
            int.parse(rangeRep.headers.value(HttpHeaders.contentLengthHeader));
        //文件的总块数(包括第一块 temp0)
        int chunkCount = (reserved / _firstChunkSize).ceil() + 1;
        if (chunkCount > 1) {
          int chunkSize = _firstChunkSize;
          if (chunkCount > maxChunk + 1) {
            chunkCount = maxChunk + 1;
            chunkSize = (reserved / maxChunk).ceil();
          }
          final futures = <Future>[];
          for (int i = 0; i < maxChunk; ++i) {
            final start = _firstChunkSize + i * chunkSize;
            int end;
            if (i == maxChunk - 1) {
              end = obj.fileSize;
            } else {
              end = start + chunkSize;
            }
            futures.add(_downloadChunk(obj, start, end, i + 1));
          }
          await Future.wait(futures);
        }
        await _mergeTempFiles(obj, chunkCount);
        if (onFinish != null) {
          onFinish(obj.fileId, obj.savePath);
        }
        return obj.savePath;
      } else if (rangeRep.statusCode == 200) {
        return _singleDownload(obj);
      } else {
        throw "The request encountered a problem, please handle it yourself";
      }
    } catch (e) {
      onError?.call(obj.fileId, e);
      return "";
    }
  }

  //小文件，直接下载
  Future<String> _singleDownload(CosDownObject obj) async {
    //The protocol does not support resumable downloads
    logger.info("_singleDownload: ${obj.url}");
    final _ =
        await _dio.download(obj.url, obj.savePath, onReceiveProgress: (c, t) {
      if (onDownProgress != null && c > 0) {
        if (DateTime.now().difference(_lastCallbackTime).inMilliseconds >
            callBackInterval) {
          _lastCallbackTime = DateTime.now();
          onDownProgress(obj.fileId, c / t);
        }
      }
    }, cancelToken: obj.cancelToken);
    _delTempFileIfNeed(obj);
    onFinish?.call(obj.fileId, obj.savePath);
    return obj.savePath;
  }

  void _delTempFileIfNeed(CosDownObject obj) {
    //remove temp file
    for (int i = 0; i < obj.chunkProgressPre.length; i++) {
      final file = File('${obj.savePath}temp$i');
      if (file.existsSync()) {
        file.delete();
      }
      final filePre = File('${obj.savePath}temp${i}_pre');
      if (filePre.existsSync()) {
        filePre.delete();
      }
    }
  }

  void cancelDownload(CosDownObject obj) {
    if (obj.cancelToken != null && !obj.cancelToken.isCancelled) {
      obj.cancelToken.cancel();
    }
    _delTempFileIfNeed(obj);
    obj.isCance = true;
    obj.chunkProgressPre.clear();
    obj.chunkProgress.clear();
  }

  Future _mergeTempFiles(CosDownObject obj, int chunkCount) async {
    final f = File("${obj.savePath}temp0");
    final ioSink = f.openWrite(mode: FileMode.writeOnlyAppend);
    for (int i = 1; i < chunkCount; ++i) {
      final path = "${obj.savePath}temp$i";
      final oldPath = "${obj.savePath}temp${i}_pre";
      final oldFile = File(oldPath);
      if (oldFile.existsSync()) {
        await _mergeFiles(oldPath, path, path);
      }
      final _f = File("${obj.savePath}temp$i");
      await ioSink.addStream(_f.openRead());
      await _f.delete();
    }
    await ioSink.close();
    await f.rename(obj.savePath);
  }

  Future _mergeFiles(String preFile, String nextFile, String targetFile) async {
    final f1 = File(preFile);
    final f2 = File(nextFile);
    final ioSink = f1.openWrite(mode: FileMode.writeOnlyAppend);
    await ioSink.addStream(f2.openRead());
    await f2.delete();
    await ioSink.close();
    await f1.rename(targetFile);
  }

  Future<Response> _downloadChunk(
      CosDownObject obj, int start, int end, int chunkIndex,
      {bool isMerge = true}) async {
    int initLength = 0;
    --end; // head range 为闭合区间 []
    final path =
        "${obj.savePath}temp$chunkIndex"; // savePath + "temp$chunkIndex";
    final targetFile = File(path);

    if (targetFile.existsSync() && isMerge) {
      final downLen = await targetFile.length();
      if (start + downLen < end) {
        initLength = downLen;
        start += downLen;
        final preFile = File("${path}_pre");
        if (preFile.existsSync()) {
          final preLen = await preFile.length();
          initLength += preLen;
          start += preLen;
          await _mergeFiles(preFile.path, targetFile.path, preFile.path);
        } else {
          await targetFile.rename(preFile.path);
        }
      } else {
        //说明分段错误，或者chunk和之前的不一致，该段重新下载
        await targetFile.delete();
      }
    }
    //校验
    if (obj.fileSize != null) {
      if (start > end || start > obj.fileSize) {
        logger
            .info("http range error: $start - $end - $chunkIndex\n${obj.url}");
      }
    }

    obj.chunkProgress.add(initLength);
    obj.chunkProgressPre.add(initLength);

    return _dio.download(
      obj.url,
      path,
      deleteOnError: chunkIndex == 0,
      onReceiveProgress: (received, rangeTotal) {
        obj.chunkProgress[chunkIndex] =
            obj.chunkProgressPre[chunkIndex] + received;
        final c = obj.chunkProgress.reduce((a, b) => a + b);
        if (obj.fileSize != null &&
            onDownProgress != null &&
            obj.fileSize != 0) {
          if (DateTime.now().difference(_lastCallbackTime).inMilliseconds >
              callBackInterval) {
            _lastCallbackTime = DateTime.now();
            onDownProgress(obj.fileId, c / obj.fileSize);
          }
        }
      },
      options: Options(headers: {"range": "bytes=$start-$end"}),
      cancelToken: obj.cancelToken,
    );
  }
}

class CosFileDownloadQueue {
  static CosFileDownloadQueue _instance;

  factory CosFileDownloadQueue() => _getInstance();

  static CosFileDownloadQueue get instance => _getInstance();

  static CosFileDownloadQueue _getInstance() {
    return _instance ??= CosFileDownloadQueue._internal();
  }

  /// - 最大并发数量
  int maxConcurrentOperationCount = 4;
  CosFileDownload download;

  int get queueCount => _queue.length;

  /// 任务队列
  List<CosDownObject> _queue;

  CosFileDownloadQueue._internal() {
    _queue = [];
    download = CosFileDownload();
  }

  void registerCallback(
      {DownProgressCallback onDownProgress,
      DownErrorCallback onError,
      DownFinishCallback onFinish}) {
    download.onDownProgress = onDownProgress;
    download.onError = onError;
    download.onFinish = onFinish;
  }

  void disposeCallback() {
    download.onDownProgress = null;
    download.onError = null;
    download.onFinish = null;
  }

  /*
  添加到任务队列，不返回任务执行结果
  结果通过callback返回,方便统一管理。
   */
  Future<void> addQueue(CosDownObject item) async {
    _queue.add(item);
    unawaited(_startConsumeQueue());
  }

  /*
   添加到任务队列，等待返回任务执行结果
   */
  Future<String> executeCompeterTask(CosDownObject item) async {
    item.taskCompleter = TaskCompleter<String>();
    _queue.add(item);
    unawaited(_startCompeterConsumeQueue());
    return item.taskCompleter.future;
  }

  /*
  不添加到队列中，直接执行任务
  同： CosFileUploadQueue.instance.upload.cosFileUpload(item)
   */
  Future<String> once(CosDownObject item) async {
    return download.cosFileDownload(item);
  }

  /*
  不添加到队列中，直接执行任务
  不需要监听CosPutObject实例状态时候使用
  同： CosFileUploadQueue.instance.upload.cosFileUpload(item)
   */
  Future<String> onceForPath(
    String fileUrl,
    CosDownObject fileType,
  ) async {
    final obj = await CosDownObject.create(fileUrl, fileId: fileUrl);
    return download.cosFileDownload(obj);
  }

  int _downloadingCount() {
    int count = 0;
    _queue.forEach((element) {
      if (element.isDowning) count++;
    });
    return count;
  }

  CosDownObject firstInQueue() {
    return _queue.firstWhere((item) => !item.isDowning && !item.isCance,
        orElse: () {
      return null;
    });
  }

  Future<void> _startConsumeQueue() async {
    if (_queue.isEmpty) return;
    if (maxConcurrentOperationCount <= _downloadingCount()) return;

    final item = firstInQueue();
    if (item == null) return;
    item.isDowning = true;

    try {
      logger.info("queue开始下载: ${item.url}");
      await download.cosFileDownload(item);
      logger.info("queue结束一个下载项目: ${item.url}");
      _queue.remove(item);
      unawaited(_startConsumeQueue());
    } catch (e) {
      logger.info('startConsumeQueue error: $e');
      final bool isNetworkError = Http.isNetworkError(e);
      logger.info('_startConsumeQueue error isNetworkError: $isNetworkError');

      if (e is DioError && e?.response?.statusCode == 403) {
        logger.info('_startConsumeQueue cos error 403: ${e.response}');
      }

      //TODO 报错处理
      item.reTryCount++;
      item.isDowning = false;
    }
  }

  Future<void> _startCompeterConsumeQueue() async {
    if (_queue.isEmpty) return;
    if (maxConcurrentOperationCount <= _downloadingCount()) {
      return;
    }

    final item = firstInQueue();
    if (item == null) return;
    item.isDowning = true;

    final ret = await download.cosFileDownload(item);
    _queue.remove(item);

    item.taskCompleter.reply(ret);
    unawaited(_startCompeterConsumeQueue());
  }

  Future<void> cancelFirst() async {
    final toCancelFile = firstInQueue();
    if (toCancelFile == null) return;
    try {
      toCancelFile.isCance = true;
      download.cancelDownload(toCancelFile);
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
    CosDownObject toCancelFile;
    for (final item in _queue) {
      if (item.fileId == fileId) {
        toCancelFile = item;
        break;
      }
    }
    if (toCancelFile == null) return true;

    try {
      toCancelFile.isCance = true;
      download.cancelDownload(toCancelFile);
      _queue.remove(toCancelFile);
      return true;
    } catch (e) {
      logger.info('cancel error; $e');
      return false;
    }
  }

  bool cancelAll() {
    _queue.forEach((element) {
      element.isCance = true;
    });
    _queue.forEach((element) => download.cancelDownload(element));
    _queue.clear();
    return true;
  }
}
