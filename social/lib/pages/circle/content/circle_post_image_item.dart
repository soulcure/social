import 'dart:io';
import 'dart:typed_data';

import 'package:im/global.dart';
import 'package:im/utils/content_checker.dart';
import 'package:im/utils/cos_file_upload.dart';
import 'package:im/utils/random_string.dart';
import 'package:multi_image_picker/multi_image_picker.dart';

class CirclePostImageItem {
  String itemKey;
  String requestId;
  String name;
  String thumbName;
  Uint8List thumbData;
  String checkPath;
  String identifier;
  double duration;
  double width;
  double height;
  String url;
  String thumbUrl;
  String type;

  //视频Item用户自定义过封面
  bool customCover;

  //添加图片item
  bool isAdd;

  CirclePostImageItem({
    this.requestId,
    this.name,
    this.thumbName,
    this.thumbData,
    this.checkPath = '',
    this.identifier = '',
    this.url,
    this.thumbUrl,
    this.type,
    this.width = 0,
    this.height = 0,
    this.duration = 0,
    this.customCover = false,
    this.isAdd = false,
  }) : itemKey = RandomString.length(12);

  CirclePostImageItem.fromJson(Map<String, dynamic> json)
      : itemKey = RandomString.length(12) {
    name = json['name'] ?? '';
    thumbName = json['thumbName'] ?? '';
    url = json['source'] ?? '';
    thumbUrl = json['thumbUrl'] ?? '';
    type = json['_type'] ?? '';
    width = ((json['width'] ?? 0) as num).toDouble();
    height = ((json['height'] ?? 0) as num).toDouble();
    duration = ((json['duration'] ?? 0) as num).toDouble();
    checkPath = json['checkPath'] ?? '';
    identifier = json['identifier'] ?? '';
    requestId = json['request_id'] ?? '';
    customCover = json['custom_cover'] ?? false;
    isAdd = false;
  }

  CirclePostImageItem.fromAsset(Asset asset)
      : itemKey = RandomString.length(12) {
    name = asset.filePath ?? asset.name;
    thumbName = asset.thumbName;
    checkPath = asset.checkPath ?? '';
    identifier = asset.identifier ?? '';
    url = asset.filePath;
    thumbUrl = asset.thumbFilePath;
    type = (asset.fileType.contains('video')) ? 'video' : 'image';
    width = asset.originalWidth;
    height = asset.originalHeight;
    duration = asset?.duration ?? 0;
    requestId = asset.requestId ?? '';
    isAdd = false;
  }

  Future<void> upload({int queueIndex = 0}) async {
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      if (type == 'video') {
        thumbUrl = await uploadImage(thumbName ?? '');
        url = await uploadVideo(queueIndex: 1);
      } else {
        url = await uploadImage(name ?? '', queueIndex: queueIndex);
      }
    }
  }

  Future<void> getMediaThumb() async {
    if (type == 'video') {
      final List<Asset> assets = await MultiImagePicker.fetchMediaInfo(-1, -1,
          selectedAssets: [identifier.toString()]);
      double videoDuration = 0;
      if (assets.isNotEmpty) {
        final Asset asset = assets.first;
        videoDuration = asset.duration;
      }
      duration = videoDuration;
    }

    thumbData =
        await MultiImagePicker.fetchMediaThumbData(identifier.toString());
  }

  Future<String> uploadImage(String name, {int queueIndex = 0}) async {
    final imageName = name;
    final imageCheckName = checkPath;

    String path = '${Global.deviceInfo.mediaDir}$imageCheckName';
    Uint8List checkBytes;
    if (!File(path).existsSync()) {
      path = '${Global.deviceInfo.mediaDir}$imageName';
    }
    checkBytes = await File(path).readAsBytes();
    final passed = await CheckUtil.startCheck(
      ImageCheckItem.fromBytes(
        [U8ListWithPath(checkBytes, path)],
        ImageChannelType.FB_CIRCLE_POST_PIC,
        checkType: CheckType.circle,
      ),
    );
    if (!passed) {
      throw CheckTypeException(defaultErrorMessage);
    } else {
      final obj = await CosPutObject.create(
          '${Global.deviceInfo.mediaDir}$imageName', CosUploadFileType.image,
          fileName: '', fileId: queueIndex.toString());
      return CosFileUploadQueue.instance.once(obj);
    }
  }

  Future<String> uploadVideo({String name, int queueIndex = 0}) async {
    final videoName =
        name ?? await MediaPicker.generateVideo(requestId: requestId);

    final obj = await CosPutObject.create(
        '${Global.deviceInfo.mediaDir}$videoName', CosUploadFileType.video,
        fileName: '', fileId: queueIndex.toString(), forceAudit: true);
    return CosFileUploadQueue.instance.once(obj);
  }

  Map toJson() {
    Map map = {};
    if (type == 'video') {
      map = {
        'name': name ?? '',
        'source': url ?? '',
        'width': width ?? 0,
        'height': height ?? 0,
        'fileType': 'video',
        'duration': duration ?? 0,
        'thumbName': thumbName ?? '',
        'thumbUrl': thumbUrl ?? '',
        'identifier': identifier ?? '',
        '_type': 'video',
        'request_id': requestId ?? '',
        '_inline': false,
        'custom_cover': customCover ?? false,
      };
    } else {
      map = {
        'name': name ?? '',
        'source': url ?? '',
        'width': width ?? 0,
        'height': height ?? 0,
        'checkPath': checkPath.substring(checkPath.lastIndexOf('/') + 1) ?? '',
        'identifier': identifier ?? '',
        '_type': 'image',
        'request_id': requestId ?? '',
        '_inline': false,
      };
    }

    return map;
  }
}
