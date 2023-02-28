import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' hide Text;
import 'package:get/get.dart';
import 'package:im/common/extension/operation_extension.dart';
import 'package:im/core/http_middleware/http.dart';
import 'package:im/core/widgets/loading.dart';
import 'package:im/global.dart';
import 'package:im/loggers.dart';
import 'package:im/pages/home/json/text_chat_json.dart';
import 'package:im/utils/content_checker.dart';
import 'package:im/utils/cos_file_upload.dart';
import 'package:im/utils/utils.dart';
import 'package:oktoast/oktoast.dart';
import 'package:tuple/tuple.dart';

import '../../../../../utils/content_checker.dart';

class RichEditorUtils {
  // 空的NotusDocument
  static Document get defaultDoc =>
      Document.fromJson(jsonDecode(r'[{"insert":"\n"}]'));

// 根据document位置计算delta索引
  static int getOperationIndex(Delta delta, int position) {
    int oIndex = -1;
    int allLen = 0;
    for (var i = 0; i < delta.toList().length; i++) {
      final o = delta.elementAt(i);
      if (position >= allLen && position < allLen + o.length) {
        oIndex = i;
      }
      allLen += o.length;
    }
    return oIndex;
  }

// 根据operation位置计算在document的位置
  static int getLenBeforeOperation(Delta delta, int index) {
    int allLen = 0;
    for (var i = 0; i < index; i++) {
      final o = delta.elementAt(i);
      allLen += o.length;
    }
    return allLen;
  }

// 获取下个不为空的节点（去掉换行符）
  static Operation getNextOperation(Delta delta, int index) {
    if (index > delta.length - 1) return null;
    while (index + 1 <= delta.length - 1 &&
        (delta[index + 1].value is String &&
            (delta[index + 1].value as String).replaceAll('\n', '').isEmpty)) {
      index++;
    }
    return index + 1 <= delta.length - 1 ? delta[index + 1] : null;
  }

// 判断是不是最后一个不为空的节点
  static bool isLastOperation(Delta delta, int index) {
    return getNextOperation(delta, index) == null;
  }

// 判断是否处于嵌入节点的末尾
  static bool isEmbedEnd(Delta delta, int position) {
    if (position > delta.allLen) return false;
    int allLen = 0;
    final DeltaIterator dt = DeltaIterator(delta);
    bool res = false;
    while (allLen < position && dt.hasNext) {
      final o = dt.next();
      if (allLen + o.length == position && o.isEmbed) {
        res = true;
      }
      allLen += o.length;
    }
    return res;
  }

// 合并 @ 和 # 到普通text
  static Delta formatDelta(Delta delta) {
    try {
      final oldList = delta.toList();
      final Delta newDelta = Delta();
      String insert = '';
      for (int i = 0; i < oldList.length; i++) {
        final o = oldList[i];
        if (o.isEmbed) {
          String id = '';
          if (o.isAt) {
            id = getOperationAttribute(o, 'at') as String;
          } else if (o.isChannel) {
            id = getOperationAttribute(o, 'channel') as String;
          } else {
            newDelta.insert(o.value, o.attributes);
            continue;
          }
          insert += id ?? '';
        } else {
          if (insert.isNotEmpty) {
            newDelta.insert(insert);
            insert = '';
          }
          newDelta.insert(o.value, o.attributes);
        }
        if (i == oldList.length - 1 && insert.isNotEmpty) {
          newDelta.insert(insert);
        }
      }
      return newDelta;
    } catch (e) {
      logger.severe('富文本格式出错', e);
      rethrow;
    }
  }

  static dynamic getEmbedAttribute(Operation o, String key) {
    if (o == null || !o.isEmbed) return null;
    if (o.value is BlockEmbed) {
      return (o.value as BlockEmbed).data[key];
    }
    return o.value == null ? null : o.value[key];
  }

  static dynamic getOperationAttribute(Operation o, String key) {
    if (o == null) return null;
    return o.attributes == null ? null : o.attributes[key];
  }

  // 上传富文本里的图片和视频，会修改document里面的部分字段
  static Future<void> uploadFileInDoc(Document doc,
      {CheckType checkType = CheckType.defaultType, String title = ''}) async {
    final deltaList = doc.toDelta().toList();
    // 上传图片视频
    final List<Tuple2<String, String>> imageAssets = [];
    final List<String> videoAssets = [];
    String textAssets = '';
    int imageCount = 0;
    int videoCount = 0;
    // 保存图片和视频
    for (int i = 0; i < deltaList.length; i++) {
      final d = deltaList[i];
      if (d.key != Operation.insertKey) continue;
      if (d.isImage) {
        final embed = Embeddable.fromJson(d.value) as ImageEmbed;

        final imagePath = embed.source;
        final imageCheckPath = embed.checkPath ?? imagePath;
        if (!_isNetworkAsset(imagePath)) {
          imageAssets.add(Tuple2(imagePath, imageCheckPath));
          d.value['index'] = imageCount;
          imageCount++;
        }
      }

      if (d.isVideo) {
        // final embed = VideoEmbed.fromJson(d.value);
        final embed = Embeddable.fromJson(d.value) as VideoEmbed;
        final videoUrl = embed.source;
        if (!_isNetworkAsset(videoUrl)) {
          videoAssets
            ..add(videoUrl)
            ..add(embed.thumbUrl);
          d.value['index'] = videoCount;
          videoCount++;
        }
      }
      if (!d.isVideo && !d.isImage)
        textAssets += d?.value?.toString()?.trim() ?? '';
    }

    List<String> imageRes;
    List<String> videoRes;
    try {
      // 审核文字
      if (textAssets.isNotEmpty) {
        final textChannel = checkType == CheckType.circle
            ? TextChannelType.FB_CIRCLE_POST_TEXT
            : TextChannelType.GROUP_MESSAGE;
        final textRes = await CheckUtil.startCheck(
            TextCheckItem(title + textAssets, textChannel,
                checkType: checkType),
            toastError: false);
        if (!textRes) {
          // if (checkType == CheckType.circle)
          showToast(defaultErrorMessage);
          Loading.hide();
          throw CheckTypeException(defaultErrorMessage);
        }
      }
      // 审核图片
      imageRes = await Future.wait(imageAssets.map((e) async {
        final imageName = e.item1;
        final imageCheckName = e.item2;
        String path = '${Global.deviceInfo.thumbDir}$imageCheckName';
        Uint8List checkBytes;
        if (!File(path).existsSync()) {
          path = '${Global.deviceInfo.thumbDir}$imageName';
        }
        checkBytes = await File(path).readAsBytes();
        final imageChannel = checkType == CheckType.circle
            ? ImageChannelType.FB_CIRCLE_POST_PIC
            : ImageChannelType.groupMessage;
        final passed = await CheckUtil.startCheck(
            ImageCheckItem.fromBytes(
              [U8ListWithPath(checkBytes, path)],
              imageChannel,
              checkType: checkType,
            ),
            toastError: false);
        if (!passed) {
          throw CheckTypeException(defaultErrorMessage);
        } else {
          // final bytes = await File('${Global.deviceInfo.thumbDir}$imageName')
          //     .readAsBytes();
          // return uploadFileIfNotExist(
          //     bytes: bytes, filename: imageName, fileType: 'image');
          return CosFileUploadQueue.instance.onceForPath(
              '${Global.deviceInfo.thumbDir}$imageName',
              CosUploadFileType.image);
        }
      }));
      // 审核视频
      videoRes = await Future.wait(videoAssets.map((e) async {
        final index = videoAssets.indexOf(e);
        final isVideo = (index % 2).isEven;
        final path = '${Global.deviceInfo.thumbDir}$e';
        final bytes = await File(path).readAsBytes();
        if (!isVideo) {
          final checkRes = await CheckUtil.startCheck(
              ImageCheckItem.fromBytes([U8ListWithPath(bytes, path)],
                  ImageChannelType.FB_CIRCLE_POST_PIC),
              toastError: false);
          if (!checkRes) {
            throw CheckTypeException(defaultErrorMessage);
          }
        }
        // return uploadFileIfNotExist(
        //         bytes: bytes,
        //         filename: e,
        //         fileType: isVideo ? 'video' : 'image')
        //     .catchError((e) {
        //   throw e;
        // });
        return CosFileUploadQueue.instance
            .onceForPath(path,
                isVideo ? CosUploadFileType.video : CosUploadFileType.image)
            .catchError((e) {
          throw e;
        });
      }));
      for (final d in deltaList) {
        if (d.key != Operation.insertKey) continue;
        if (d.isImage) {
          Map embedValue;
          if (d.value['image'] is Map) {
            embedValue = d.value['image'];
          } else {
            embedValue = d.value;
          }
          if (!_isNetworkAsset(embedValue['source'])) {
            final int index = d.value['index'];
            embedValue['source'] = imageRes[index];
            embedValue.remove('checkPath');
            d.value.remove('index');
          }
        }
        if (d.isVideo) {
          Map embedValue;
          if (d.value['video'] is Map) {
            embedValue = d.value['video'];
          } else {
            embedValue = d.value;
          }
          if (!_isNetworkAsset(embedValue['source'])) {
            final int index = d.value['index'];
            embedValue['source'] = videoRes[index * 2];
            embedValue['thumbUrl'] = videoRes[index * 2 + 1];
            d.value.remove('index');
          }
        }
      }
    } on CheckTypeException {
      // if (checkType == CheckType.circle)
      showToast(defaultErrorMessage);
      Loading.hide();
      rethrow;
    } catch (e, s) {
      logger.severe('图片或视频上传失败', e, s);
      final bool isNetworkError = Http.isNetworkError(e);
      if (e is! CheckTypeException)
        // if (checkType == CheckType.circle)
        showToast(isNetworkError ? networkErrorText : '图片或视频上传失败'.tr);
      // 上传失败需要还原doc
      for (final d in deltaList) {
        if (d.isEmbed) d.value.remove('index');
      }
      rethrow;
    }
  }

  static bool _isNetworkAsset(String url) {
    return isNotNullAndEmpty(url) && url.startsWith('http');
  }

  // 老版本富文本消息兼容方法
  static String toCompatibleJson(String json) {
    if (!json.contains('embed')) {
      return json;
    }
    final jsonList = jsonDecode(json);
    final List<Map<String, dynamic>> newJsonList = [];
    Map<String, dynamic> tempJson = {};
    for (final i in jsonList) {
      if (i['attributes'] == null) {
        tempJson = i;
      } else {
        final embed = i['attributes']['embed'];
        // 视频或图片
        if (embed != null) {
          if (embed['type'] == 'image') {
            tempJson = {
              "insert": {
                "source": embed['source'],
                "width": embed['width'],
                "height": embed['height'],
                "_type": "image",
                "_inline": false
              }
            };
          } else if (embed['type'] == 'video') {
            tempJson = {
              "insert": {
                "source": embed['source'],
                "width": embed['width'],
                "height": embed['height'],
                "fileType": embed['fileType'],
                "duration": embed['duration'],
                "thumbUrl": embed['thumbUrl'],
                "_type": "video",
                "_inline": false
              }
            };
          }
        } else {
          // @ #
          tempJson = i;
        }
      }
      newJsonList.add(tempJson);
    }
    return jsonEncode(newJsonList);
  }

  // 临时修复新版本富文本编辑器链接属性a改成link导致的json解析错误，新版本编辑器上线后可去掉
  static void transformAToLink(List<Map<String, dynamic>> json) {
    json.forEach((element) {
      if (element['attributes'] != null && element['attributes']['a'] != null) {
        element['attributes']['link'] = element['attributes']['a'];
        (element['attributes'] as Map<String, dynamic>).remove('a');
      }
    });
  }

  static DefaultStyles defaultDocumentStyle(BuildContext context) {
    final bodyText2 = Get.textTheme.bodyText2;
    return DefaultStyles(
      paragraph: DefaultTextBlockStyle(
          bodyText2.copyWith(
            height: 1.5,
          ),
          const Tuple2(0, 0),
          const Tuple2(0, 0),
          null),
      h1: DefaultTextBlockStyle(
          bodyText2.copyWith(
            fontSize: 22,
            fontWeight: FontWeight.w500,
            height: 1.5,
          ),
          const Tuple2(0, 0),
          const Tuple2(0, 0),
          null),
      h2: DefaultTextBlockStyle(
          bodyText2.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w500,
            height: 1.5,
          ),
          const Tuple2(0, 0),
          const Tuple2(0, 0),
          null),
      h3: DefaultTextBlockStyle(
          bodyText2.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            height: 1.5,
          ),
          const Tuple2(0, 0),
          const Tuple2(0, 0),
          null),
      leading: DefaultTextBlockStyle(
          bodyText2.copyWith(fontSize: 16, height: 1.5), null, null, null),
      quote: DefaultTextBlockStyle(
        const TextStyle(fontSize: 16, color: Color(0xFF646A73), height: 1.5),
        const Tuple2(8, 8),
        const Tuple2(0, 0),
        BoxDecoration(
          border: Border(
            left: BorderSide(width: 2, color: Theme.of(context).primaryColor),
          ),
        ),
      ),
      code: DefaultTextBlockStyle(
        const TextStyle(
          fontSize: 14,
          color: Color(0xFF646A73),
          height: 1.5,
        ),
        const Tuple2(8, 8),
        const Tuple2(0, 0),
        BoxDecoration(
          // color: Colors.grey.shade50,
          color: Colors.white,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      lists: DefaultListBlockStyle(
        bodyText2.copyWith(
          fontSize: 16,
          height: 1.5,
        ),
        const Tuple2(0, 0),
        const Tuple2(0, 0),
        null,
        null,
      ),
    );
  }

  static List<Map<String, dynamic>> content2Document(String content) {
    content = content.trim();
    final List<Operation> _operations = [];
    final match = TextEntity.atPattern.allMatches(content);
    if (match.isEmpty) {
      _operations.add(Operation.insert(content));
    } else {
      for (int i = 0; i < match.length; i++) {
        final element = match.elementAt(i);
        // 添加左边字符
        final leftStr = content.substring(
            i == 0 ? 0 : match.elementAt(i - 1).end, element.start);
        if (leftStr.isNotEmpty) _operations.add(Operation.insert(leftStr));
        // 添加at
        _operations
            .add(Operation.insert('', AtAttribute(element.group(0)).toJson()));
        // 添加右边字符
        if (i == match.length - 1) {
          final rightStr = content.substring(element.end, content.length);
          if (rightStr.isNotEmpty) _operations.add(Operation.insert(rightStr));
        }
      }
    }
    // 换行结尾
    if (!(_operations.last.value is String &&
        (_operations.last.value as String).endsWith('\n'))) {
      _operations.add(Operation.insert('\n'));
    }
    return _operations.map((e) => e.toJson()).toList();
  }
}
