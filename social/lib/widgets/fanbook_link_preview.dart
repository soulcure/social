import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_link_preview/flutter_link_preview.dart';
import 'package:flutter_quill/flutter_quill.dart' hide Text;
import 'package:im/app/modules/circle/models/models.dart';
import 'package:im/common/extension/operation_extension.dart';
import 'package:im/common/extension/string_extension.dart';
import 'package:im/pages/home/view/text_chat/rich_editor/utils.dart';
import 'package:im/pages/tool/url_handler/circle_link_handler.dart';
import 'package:im/utils/utils.dart';

Map<String, WebCircleInfo> webCircleInfoMap = {};

class FanBookLinkPreview {
  static String postId = "postId";
  static String channelId = "channelId";
  static String topicId = "topicId";

  static bool isFanBookLink(String url) {
    if (CircleLinkHandler().match(url) &&
        _getQuestInfo(Uri.parse(url)).isNotEmpty) {
      return true;
    }
    return false;
  }

  static Future<FanBookLinkPreviewModel> getFanbookInfo(String url) async {
    final String postId = _getQuestInfo(Uri.parse(url));
    final dataModel = CirclePostDataModel();
    dataModel.postId = postId;
    try {
      await dataModel.initFromNet();
    } catch (e) {
      final fbModel = FanBookLinkPreviewModel();
      fbModel.info = WebInfo(redirectUrl: url);
      if (webCircleInfoMap.containsKey(url)) {
        webCircleInfoMap[url] = null;
      }
      return fbModel;
    }
    String imageUrl;
    String description = "来自Fanbook";
    List<Map<String, dynamic>> contentJson = [];
    Document document;
    try {
      final content = dataModel.postInfoDataModel?.postContent2() ??
          RichEditorUtils.defaultDoc.encode();
      contentJson = List<Map<String, dynamic>>.from(jsonDecode(content));
      RichEditorUtils.transformAToLink(contentJson);
      document = Document.fromJson(contentJson);
    } catch (e) {
      document = RichEditorUtils.defaultDoc;
      debugPrint('圈子格式错误:$e');
    }

    final list = RichEditorUtils.formatDelta(document.toDelta()).toList();
    final richTextSb = getRichText(list);

    CirclePostInfoDataModel postInfoDataModel;
    postInfoDataModel = dataModel.postInfoDataModel;
    String videoThumbUrl;
    for (final item in postInfoDataModel.mediaList) {
      final fileType = item['_type'] ?? '';
      if (fileType == 'image' && imageUrl == null) {
        imageUrl = item['source'];
        break;
      } else if (fileType == "video") {
        videoThumbUrl = item['thumbUrl'];
      }
    }
    if (imageUrl == null && videoThumbUrl != null) {
      imageUrl = videoThumbUrl;
    }

    var descriptionStr = richTextSb.toString();
    //去掉所有连续的\n和文本最后的\n
    descriptionStr = descriptionStr.compressLineString();
    description = postInfoDataModel.postTypeAvailable
        ? descriptionStr
        : '当前版本暂不支持查看此信息类型';

    final info = WebCircleInfo(
        guildId: dataModel.postInfoDataModel.guildId,
        title: dataModel.postInfoDataModel.title.isNotEmpty
            ? dataModel.postInfoDataModel.title
            : "${dataModel.postInfoDataModel.guildName}的圈子动态",
        icon: "https://fanbook.mobi/favicon.ico",
        description: description,
        mediaUrl: imageUrl,
        redirectUrl: url);
    final fbModel = FanBookLinkPreviewModel();
    fbModel.info = info;
    webCircleInfoMap[url] = info;
    return fbModel;
  }

  static String _getQuestInfo(Uri uri) {
    return uri.pathSegments.last ?? "";
  }
}

/// 圈子链接WebInfo
class WebCircleInfo extends WebInfo {
  String guildId;

  WebCircleInfo({
    this.guildId,
    String title,
    String icon,
    String description,
    String mediaUrl,
    String redirectUrl,
  }) : super(
          title: title,
          icon: icon,
          description: description,
          mediaUrl: mediaUrl,
          redirectUrl: redirectUrl,
        );
}

enum FanBookLinkPreviewModelType { normal, circle }

class FanBookLinkPreviewModel {
  CirclePostDataModel circleModel;
  FanBookLinkPreviewModelType type = FanBookLinkPreviewModelType.normal;
  InfoBase info;
}

class CircleInfoModel {
  String postId;
  String channelId;
  String topicId;
}
