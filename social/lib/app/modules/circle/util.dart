import 'dart:convert';

import 'package:flutter_quill/flutter_quill.dart';
import 'package:im/common/extension/operation_extension.dart';
import 'package:im/loggers.dart';
import 'package:im/pages/home/view/text_chat/rich_editor/utils.dart';

import 'models/circle_post_info_data_model.dart';

class CircleUtil {
  ///解析帖子内容
  static String parsePost(CirclePostInfoDataModel postInfoDataModel) {
    Document document;
    try {
      List<Map<String, dynamic>> contentJson = [];
      final content = postInfoDataModel?.postContent2() ??
          RichEditorUtils.defaultDoc.encode();
      contentJson = List<Map<String, dynamic>>.from(jsonDecode(content));
      document = Document.fromJson(contentJson);
    } catch (e) {
      document = RichEditorUtils.defaultDoc;
      logger.severe('圈子格式错误:$e');
    }

    final _operationList =
        RichEditorUtils.formatDelta(document.toDelta()).toList();
    final stringBuffer = StringBuffer();
    for (final e in _operationList) {
      if (e.isMedia) break;
      if (e.key == Operation.insertKey && e.value is Map) {
        final embed = Embeddable.fromJson(e.value);
        if (embed.data is Map && embed.data['value'] is String) {
          stringBuffer.write(embed.data['value']);
        }
      } else if (e.data is String) {
        stringBuffer.write(e.data);
      }
    }
    final tmpString = stringBuffer.toString().trim();
    return tmpString;
  }
}
