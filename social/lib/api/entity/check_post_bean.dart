import 'dart:convert';
import 'dart:io';

import 'package:filesize/filesize.dart';
import 'package:multi_image_picker/multi_image_picker.dart';

import '../../loggers.dart';
import '../../utils/content_checker.dart';

/// accessKey : "qpf2AMCycOarMkHEurSf"
/// type : "SOCIAL"
/// data : {"text":"胡锦涛","tokenId":"117950755050098688"}

class TextBean {
  String accessKey;
  String type;
  String appId;
  TextDataBean data;

  TextBean(this.accessKey, this.type, this.data, this.appId);

  Map toJson() => {
        "accessKey": accessKey,
        "type": type,
        "appId": appId,
        "data": data.toJson(),
      };
}

class TextDataBean {
  String text;
  String tokenId;
  String channel;

  TextDataBean(this.text, this.tokenId, this.channel);

  Map toJson() => {
        "text": text,
        "tokenId": tokenId,
        "channel": channel,
      };
}

/// accessKey : "qpf2AMCycOarMkHEurSf"
/// data : {"imgs":[{"img":"data:image/jpg;base64,...","btId":"123123123"}],"tokenId":"117950755050098688"}

class ImageBean {
  String accessKey;
  String appId;
  ImageDataBean data;

  ImageBean(this.accessKey, this.data, this.appId);

  Map toJson() => {
        "accessKey": accessKey,
        "appId": appId,
        "data": data.toJson(),
      };
}

class ImageDataBean {
  List<ImgData> imgs;
  String tokenId;
  String channel;

  ImageDataBean(this.imgs, this.tokenId, this.channel);

  Map toJson() => {
        "imgs": imgs.map((e) => e.toJson()).toList(),
        "tokenId": tokenId,
        "channel": channel,
      };
}

class ImgData {
  String img;
  String btId;
  String fileSize;

  ImgData(this.img, this.btId, {this.fileSize = ''});

  Map toJson() => {
        "img": img,
        "btId": btId,
      };

  static Future<List<ImgData>> fromAssets(List<Asset> assets,
      {bool needCompress = false}) async {
    List<Asset> tempAssets = assets;
    final List<ImgData> result = [];
    if (needCompress) {
      try {
        tempAssets = await MultiImagePicker.requestCompressMedia(
          true,
          fileType: 'image',
          fileList: assets.map((e) => e.filePath).toList(),
        );
      } catch (e) {
        logger.finer('审核图片压缩错误:$e');
      }
    }

    for (final asset in tempAssets) {
      final bytes = File(asset.filePath).readAsBytesSync();
      String base64 = base64Encode(bytes);
      if (base64.startsWith('data:image/jpg;base64,'))
        base64 = base64.replaceAll('data:image/jpg;base64,', '');
      result.add(ImgData(
        base64,
        asset.identifier,
        fileSize: getFileSize(asset.filePath),
      ));
    }
    return result;
  }

  static Future<List<ImgData>> fromFiles(List<File> files,
      {bool needCompress = false}) async {
    List<File> tempFiles = files;
    if (needCompress) {
      try {
        final assList = await MultiImagePicker.requestCompressMedia(
          true,
          fileType: 'image',
          fileList: files.map((e) => e.path).toList(),
        );

        tempFiles = assList.map((e) => File(e.filePath)).toList();
      } catch (e) {
        logger.finer('审核图片压缩错误:$e');
      }
    }
    final List<ImgData> result = [];
    for (var i = 0; i < tempFiles.length; ++i) {
      final file = tempFiles[i];
      if (file == null || !file.existsSync()) {
        logger.finer('文件:$file  不存在');
        continue;
      }
      final bytes = file.readAsBytesSync();
      String base64 = base64Encode(bytes);
      if (base64.startsWith('data:image/jpg;base64,'))
        base64 = base64.replaceAll('data:image/jpg;base64,', '');
      result.add(ImgData(
        base64,
        '${file.hashCode}$i',
        fileSize: getFileSize(file.path),
      ));
    }
    return result;
  }

  static Future<List<ImgData>> fromBytes(List<U8ListWithPath> bytesList,
      {bool needCompress = false}) async {
    List<U8ListWithPath> tempBytesList = bytesList;
    final List<ImgData> result = [];
    if (needCompress) {
      try {
        final assList = await MultiImagePicker.requestCompressMedia(
          true,
          fileType: 'image',
          fileList: bytesList.map((e) => e.path).toList(),
        );

        tempBytesList = assList
            .map((e) =>
                U8ListWithPath(File(e.filePath).readAsBytesSync(), e.filePath))
            .toList();
      } catch (e) {
        logger.finer('审核图片压缩错误:$e');
      }
    }

    for (var i = 0; i < tempBytesList.length; ++i) {
      final bytes = tempBytesList[i].uint8list;
      String base64 = base64Encode(bytes);
      if (base64.startsWith('data:image/jpg;base64,'))
        base64 = base64.replaceAll('data:image/jpg;base64,', '');
      result.add(ImgData(
        base64,
        '${bytes.hashCode}$i',
        fileSize: getFileSize(bytesList[i].path, size: bytes.length),
      ));
    }
    return result;
  }

  static String getFileSize(String path, {int size}) {
    if (size != null) return filesize(size);
    final file = File(path);
    String fileSize = '';
    if (file.existsSync()) fileSize = filesize(file.lengthSync());
    return fileSize;
  }
}
