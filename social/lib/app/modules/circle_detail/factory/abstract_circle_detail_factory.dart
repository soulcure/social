import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:im/app/modules/circle/models/circle_post_data_model.dart';
import 'package:im/app/modules/circle_detail/controllers/circle_detail_controller.dart';
import 'package:im/app/modules/circle_detail/factory/landscape_circle_detail_factory.dart';
import 'package:im/app/modules/circle_detail/factory/portrait_circle_detail_factory.dart';
import 'package:im/app/modules/circle_detail/views/widget/circle_detail_article_rich.dart';
import 'package:im/app/modules/circle_detail/views/widget/circle_detail_article_title.dart';
import 'package:im/app/modules/circle_detail/views/widget/circle_detail_article_topic.dart';
import 'package:im/app/modules/circle_detail/views/widget/circle_detail_doc.dart';
import 'package:im/app/modules/circle_detail/views/widget/circle_detail_input.dart';
import 'package:im/app/modules/circle_detail/views/widget/circle_detail_widgets.dart';
import 'package:im/app/modules/circle_detail/views/widget/circle_like_view.dart';
import 'package:im/app/modules/circle_detail/views/widget/image_video_view.dart';
import 'package:im/app/modules/document_online/entity/doc_item.dart';
import 'package:im/pages/guild_setting/circle/circle_detail_page/like_button.dart';
import 'package:im/pages/guild_setting/circle/circle_detail_page/show_circle_reply_popup.dart';
import 'package:im/pages/home/view/text_chat/text_chat_ui_creator.dart';
import 'package:im/themes/const.dart';
import 'package:im/utils/orientation_util.dart';

abstract class AbstractCircleDetailFactory {
  static AbstractCircleDetailFactory _instance;

  static AbstractCircleDetailFactory get instance => OrientationUtil.landscape
      ? _instance ??= LandscapeCircleDetailFactory()
      : _instance ??= PortraitCircleDetailFactory();

  static void destroy() => _instance = null;

  Widget showAppBar(CircleDetailController controller, {BuildContext context});

  /// * 标题
  CircleDetailArticleTitle createArticleTitle(String title,
          {double top, double bottom}) =>
      CircleDetailArticleTitle(
        title,
        top: top,
        bottom: bottom,
      );

  CircleDetailArticleTopic createArticleTopic(String topicName,
      {double top, double bottom, Color textColor, Color bgColor});

  /// * 正文内容
  CircleDetailArticleRich createArticleRich(CircleDetailController controller,
          {String content,
          CirclePostDataModel data,
          double top,
          double bottom}) =>
      CircleDetailArticleRich(
        controller,
        content: content,
        top: top,
        bottom: bottom,
      );

  /// * 底部输入框 - 50版本
  CircleDetailInput createArticleInput({
    String topicId,
    String guildId,
    String channelId,
    String postId,
    String likeId,
    CirclePostDataModel data,
    OnReplySend onReplySend,
    CircleDetailData circleDetailData,
    OnLikeChange<bool, String> onLikeChange,
    Alignment alignment,
  }) =>
      CircleDetailInput(
        topicId: topicId,
        guildId: guildId,
        channelId: channelId,
        postId: postId,
        likeId: likeId,
        data: data,
        onReplySend: onReplySend,
        onLikeChange: onLikeChange,
        circleDetailData: circleDetailData,
        alignment: alignment,
      );

  /// * 列表单个回复
  Widget createCommentItem(
      CircleDetailController controller, int index, BuildContext context) {
    return TextChatUICreator.createItem(
      context,
      index,
      controller.replyList,
      guidId: controller.guildId,
      shouldShowUserInfo: true,
      padding: const EdgeInsets.only(top: 12, bottom: 12),
      onTap: () {
        FocusScope.of(context).unfocus();
      },
    );
  }

  /// * 列表上方的进度条
  Widget buildListTopLoading(CircleDetailController controller) {
    if (controller.reachStart) return sizedBox;
    return const Padding(
      padding: EdgeInsets.all(8),
      child: CupertinoActivityIndicator.partiallyRevealed(),
    );
  }

  /// * 图片视频轮播
  Widget createImageVideoSwipe(CircleDetailController controller,
          {OnLongPressImage onLongPressImage,
          OnTapVideo onTapVideo,
          double top,
          double bottom}) =>
      ImageVideoSwipeView(
        onTapVideo: onTapVideo,
        onLongPressImage: onLongPressImage,
        top: top,
        bottom: bottom,
        detailController: controller,
      );

  /// * 艾特的用户
  Widget createAtUsers(
    CirclePostDataModel data, {
    EdgeInsetsGeometry padding,
    TextStyle textStyle,
  }) =>
      AtUserListView(
        data?.atUserIdList,
        guildId: data?.postInfoDataModel?.guildId,
        padding: padding,
        textStyle: textStyle,
        isCircleDetail: true,
      );

  /// * 发布更新时间
  Widget createTimeView(CirclePostDataModel data,
          {EdgeInsetsGeometry padding, TextStyle textStyle}) =>
      CircleDetailTime(
        createdAt: int.tryParse(data?.postInfoDataModel?.createdAt ?? "0"),
        updatedAt: int.tryParse(data?.postInfoDataModel?.updatedAt ??
            data?.postInfoDataModel?.createdAt ??
            '0'),
        padding: padding,
        textStyle: textStyle,
      );

  /// * 喜欢图标和列表
  Widget createLikeView(String postId) => CircleLikeView(postId);

  /// * 腾讯文档
  Widget createCircleDetailDocView(DocItem docItem, VoidCallback onTap) =>
      CircleDetailDocView(docItem: docItem, onTap: onTap);
}
