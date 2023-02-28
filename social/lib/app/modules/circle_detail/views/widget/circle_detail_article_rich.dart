import 'dart:convert';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' hide Text;
import 'package:get/get.dart';
import 'package:im/app/modules/circle/controllers/circle_controller.dart';
import 'package:im/app/modules/circle_detail/controllers/circle_detail_controller.dart';
import 'package:im/app/modules/circle_video_page/controllers/circle_video_page_controller.dart';
import 'package:im/app/theme/app_theme.dart';
import 'package:im/common/extension/operation_extension.dart';
import 'package:im/common/permission/permission_model.dart';
import 'package:im/db/db.dart';
import 'package:im/pages/guild_setting/guild/container_image.dart';
import 'package:im/pages/home/json/text_chat_json.dart';
import 'package:im/pages/home/model/chat_index_model.dart';
import 'package:im/pages/home/view/gallery/model/gallery_item.dart';
import 'package:im/pages/home/view/gallery/photo_view.dart';
import 'package:im/pages/home/view/text_chat/items/components/parsed_text_extension.dart';
import 'package:im/routes.dart' as old_routes;
import 'package:im/themes/default_theme.dart';
import 'package:im/utils/custom_cache_manager.dart';
import 'package:im/utils/orientation_util.dart';
import 'package:im/web/widgets/web_video_player/web_video_player.dart';
import 'package:im/widgets/dialog/show_web_image_dialog.dart';
import 'package:im/widgets/poly_text/poly_text.dart';
import 'package:im/widgets/user_info/realtime_nick_name.dart';
import 'package:im/widgets/video_play_button.dart';
import 'package:pedantic/pedantic.dart';
import 'package:tuple/tuple.dart';

import '../../../../../global.dart';

/// * 圈子内容
class CircleDetailArticleRich extends StatelessWidget {
  final CircleDetailController controller;
  final String content;
  final CircleVideoPageControllerParam circleVideoControllerParam;
  final double top;
  final double bottom;

  const CircleDetailArticleRich(
    this.controller, {
    Key key,
    this.content,
    this.circleVideoControllerParam,
    this.top = 0,
    this.bottom = 8,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => Padding(
      padding: EdgeInsets.only(
          left: 16, right: 16, top: top ?? 0, bottom: bottom ?? 8),
      child: LayoutBuilder(builder: (context, constraints) {
        return _buildDocument(maxWidth: constraints.maxWidth);
      }));

  Widget _buildDocument({double maxWidth = double.infinity}) =>
      controller.postTypeAvailable
          ? PolyText(
              key: ValueKey(controller.quillController.hashCode),
              document: controller.quillController.document,
              baseStyle: Get.textTheme.bodyText2,
              paragraphHeight: 1.5,
              refererChannelSource: RefererChannelSource.CircleLink,
              embedBuilder: (c, node) => embedBuilder(c, node, maxWidth),
              mentionBuilder: mentionBuilder,
            )
          : Container(
              height: 70,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(4)),
                  color: Color(0xFFF5F5F8)),
              child: Text(
                '当前版本暂不支持查看此信息类型\n请更新至最新版查看'.tr,
                style: Get.textTheme.bodyText1.copyWith(
                    fontSize: 14, height: 1.35, color: const Color(0xFF646A73)),
                textAlign: TextAlign.center,
              ),
            );

  Widget embedBuilder(BuildContext context, Embed node, double maxWidth) {
    final type = node.value.type;
    Widget child;
    switch (type) {
      case 'image':
        child = _buildImage(context, node.value as ImageEmbed, maxWidth);
        break;
      case 'video':
        child = _buildVideo(context, node.value as VideoEmbed, maxWidth);
        break;
      case 'divider':
        child = const Divider(height: 20, thickness: 1);
        break;
      default:
        child = const SizedBox();
    }
    return Align(alignment: Alignment.centerLeft, child: child);
  }

  InlineSpan mentionBuilder(Embed embed) {
    // final channel = Db.channelBox.get(value);
    // if(node.value is )
    if (embed.value is MentionEmbed) {
      final value = embed.value as MentionEmbed;
      if (TextEntity.atPattern.hasMatch(value.id)) {
        return _buildAt(value);
      } else if (TextEntity.channelLinkPattern.hasMatch(value.id)) {
        return _buildChannel(value);
      } else {
        return TextSpan(text: embed.value.toString());
      }
    } else {
      return TextSpan(text: embed.value.toString());
    }
  }

  // 富文本图片渲染器
  Widget _buildImage(BuildContext context, ImageEmbed embed, double maxWidth) {
    final doc = Document.fromJson(jsonDecode(content));
    final medias = doc.imageAndVideoEmbeds;
    medias.removeWhere((element) => element is! ImageEmbed);
    final index = medias.indexWhere((element) {
      return element is ImageEmbed && element.source == embed.source;
    });
    final imageSize = _getEmbedSize(_getSizeByDefault(embed.width, 350),
        _getSizeByDefault(embed.height, 200),
        maxWidth: maxWidth);
    final screenSize = MediaQuery.of(context).size;
    return GestureDetector(
      onTap: () {
        if (OrientationUtil.portrait) {
          showImageDialog(
            context,
            items: medias.map((e) {
              if (e is ImageEmbed) {
                final url = e.source;
                return GalleryItem(
                  url: url,
                  id: 'tag: $e',
                  holderUrl: ContainerImage.getThumbUrl(url,
                      thumbWidth: screenSize.width.toInt() * 2),
                );
              }
            }).toList(),
            index: max(index, 0),
            showIndicator: true,
          );
        } else
          showWebImageDialog(
            context,
            url: embed.source,
            width: embed.width.toDouble(),
            height: embed.height.toDouble(),
          );
      },
      child: Container(
          width: imageSize.item1,
          height: imageSize.item2,
          margin: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: appThemeData.dividerColor.withOpacity(0.15),
              width: 0.5,
            ),
          ),
          child: ContainerImage(
            embed.source,
            radius: 4,
            thumbWidth: CircleController.circleThumbWidth,
            fit: BoxFit.cover,
            cacheManager: CircleCachedManager.instance,
          )),
    );
  }

  InlineSpan _buildAt(MentionEmbed embed) {
    Color textColor;
    Color bgColor;
    Widget child;
    String text = embed.id;
    final match = TextEntity.atPattern.firstMatch(text);
    final id = match.group(2);
    final isRole = match.group(1) == "&";
    if (!isRole) {
      if (id == Global.user.id) {
        textColor = primaryColor;
        bgColor = primaryColor.withOpacity(0.2);
      } else {
        textColor = primaryColor;
      }

      child = RealtimeNickname(
        userId: id,
        prefix: "@",
        textScaleFactor: 1,
        style: TextStyle(color: textColor),
        tapToShowUserInfo: true,
        guildId: controller.data?.postInfoDataModel?.guildId,
        showNameRule: ShowNameRule.remarkAndGuild,
      );
    } else {
      try {
        final role = PermissionModel.getPermission(
                ChatTargetsModel.instance.selectedChatTarget.id)
            .roles
            .firstWhere((element) => element.id == id);

        text = "@${role.name}";

        if (role.color != 0)
          textColor = Color(role.color);
        else
          textColor = Get.textTheme.bodyText2.color;

        if (id == ChatTargetsModel.instance.selectedChatTarget.id ||
            Db.userInfoBox.get(Global.user.id).roles.contains(id)) {
          bgColor = primaryColor.withOpacity(0.2);
          textColor = primaryColor;
        }
      } catch (e) {
        text = "@该角色已删除".tr;
      }
    }

    child ??= Text(
      text,
      textScaleFactor: 1,
      style: TextStyle(color: textColor),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );

    /// @自己 有文字背景
    if (bgColor != null) {
      child = IntrinsicWidth(
        child: Container(
          alignment: Alignment.center,
          margin: const EdgeInsets.fromLTRB(4, 0.5, 4, 0.5),
          padding: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(3),
            color: primaryColor.withOpacity(0.15),
          ),
          child: child,
        ),
      );
    }

    /// 如果没有 builder，一个文本 @同一个人两次会报错，如果采用代码 listen 一次的方式可能解决这个问题
    return WidgetSpan(
      alignment: PlaceholderAlignment.middle,
      child: Builder(builder: (context) => child),
    );
  }

  TextSpan _buildChannel(MentionEmbed embed) {
    final match = TextEntity.channelLinkPattern.firstMatch(embed.id);
    final id = match.group(1);
    final channel = Db.channelBox.get(id);
    return TextSpan(
      text: " #${channel?.name ?? "尚未加入该频道".tr} ",
      style: TextStyle(color: primaryColor),
      recognizer: TapGestureRecognizer()
        ..onTap = () async {
          Get.back();
          await Future.delayed(const Duration(milliseconds: 300));
          unawaited(ParsedTextExtension.onChannelTap(id,
              refererChannelSource: RefererChannelSource.CircleLink));
        },
    );
  }

  Widget _buildVideo(BuildContext context, VideoEmbed embed, double maxWidth) {
    final doc = Document.fromJson(jsonDecode(content));
    final medias = doc.imageAndVideoEmbeds;
    medias.removeWhere((element) => element is! VideoEmbed);
    final index = medias.indexWhere((element) {
      return element is VideoEmbed && element.source == embed.source;
    });
    final size = _getEmbedSize(
      _getSizeByDefault(embed.width, 350),
      _getSizeByDefault(embed.height, 200),
      maxWidth: maxWidth,
    );
    final thumbUrl = embed.thumbUrl;
    final duration = embed.duration;
    final url = embed.source;
    if (kIsWeb) {
      return Container(
          width: max(size.item1.toDouble(), 210),
          height: size.item2,
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: WebVideoPlayer(
            videoUrl: url,
            thumbUrl: thumbUrl,
            duration: duration,
            padding: size.item1 < 210 ? (210 - size.item1.toDouble()) / 2 : 0,
          ));
    }
    return GestureDetector(
      onTap: () {
        final data = controller.circleDetailData;
        old_routes.Routes.pushCircleVideo(
          Get.context,
          CircleVideoPageControllerParam(
            model: controller.data,
            offset: max(index, 0),
            circlePostDateModels: data?.circlePostDataModels,
            topicId: data?.circleListTopicId,
          ),
        );
      },
      child: Container(
        width: size.item1.toDouble(),
        height: size.item2.toDouble(),
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: appThemeData.dividerColor.withOpacity(0.15),
            width: 0.5,
          ),
        ),
        child: VideoWidget(
          borderRadius: 4,
          url: url,
          backgroundColor: const Color.fromARGB(255, 0xf0, 0xf1, 0xf2),
          duration: duration ?? 0,
          child: ContainerImage(
            thumbUrl,
            radius: 4,
            thumbWidth: CircleController.circleThumbWidth,
            fit: BoxFit.cover,
            cacheManager: CircleCachedManager.instance,
          ),
        ),
      ),
    );
  }

  ///value为空或0时，返回defaultValue
  num _getSizeByDefault(num value, num defaultValue) {
    return value != null && value > 0 ? value : defaultValue;
  }

  Tuple2<double, double> _getEmbedSize(num width, num height,
      {double maxWidth = double.infinity}) {
    double w;
    double h;
    try {
      w = min(width, maxWidth).toDouble();
      h = (height * w / width).toDouble();
    } catch (e) {
      w = h = 100.0;
    }
    return Tuple2(w, h);
  }
}
