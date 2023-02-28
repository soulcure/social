import 'dart:convert';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' hide Text;
import 'package:get/get.dart';
import 'package:im/common/extension/operation_extension.dart';
import 'package:im/core/http_middleware/http.dart';
import 'package:im/icon_font.dart';
import 'package:im/pages/guild_setting/circle/circle_loading_view.dart';
import 'package:im/pages/guild_setting/circle/circle_news_model.dart';
import 'package:im/pages/home/view/text_chat/rich_editor/utils.dart';
import 'package:im/svg_icons.dart';
import 'package:im/themes/const.dart';
import 'package:im/utils/custom_cache_manager.dart';
import 'package:im/utils/orientation_util.dart';
import 'package:im/utils/utils.dart';
import 'package:im/web/widgets/app_bar/web_appbar.dart';
import 'package:im/widgets/app_bar/custom_appbar.dart';
import 'package:im/widgets/avatar.dart';
import 'package:im/widgets/realtime_user_info.dart';
import 'package:im/widgets/round_image.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:tuple/tuple.dart';
import 'package:websafe_svg/websafe_svg.dart';

import 'circle_detail_page/common.dart';
import 'circle_detail_page/show_landscape_circle_reply_popup.dart';

class CircleNewsPage extends StatefulWidget {
  final String circleId;

  const CircleNewsPage(this.circleId);

  @override
  _CircleNewsPageState createState() => _CircleNewsPageState();
}

class _CircleNewsPageState extends State<CircleNewsPage> {
  CircleNewsDataModel _circleNewsDataModel;
  final RefreshController _refreshController = RefreshController();
  RequestType requestType = RequestType.normal;

  // 互动消息布局参数
  final double _trailingSize = 60;
  final double _avatarWidth = 18;
  final double _headSpace = 12;
  final double _trailingSpace = 31;
  final _itemPadding = const EdgeInsets.fromLTRB(12, 12, 12, 10);
  ScrollController _controller;

  @override
  void initState() {
    _controller = ScrollController();
    if (OrientationUtil.landscape) _controller.addListener(_onScroll);
    _circleNewsDataModel = CircleNewsDataModel(widget.circleId);
    requestType = RequestType.normal;
    super.initState();
  }

  // Future _reloadData() async {
  //   await _circleNewsDataModel.initFromNet();
  //   if (_circleNewsDataModel.initFinish &&
  //       _circleNewsDataModel.circleNewsListCount > 0) {
  //     final circleNewsInfoDataModel =
  //         _circleNewsDataModel.circleNewsInfoDataModelAtIndex(0);
  //     await CircleApi.circleUpdateNewsReadState(
  //         circleNewsInfoDataModel.channelId, circleNewsInfoDataModel.reletedId);
  //   }
  //   if (mounted) {
  //     setState(() {});
  //   }
  // }

  void _onScroll() {
    if (_controller.offset == _controller.position.maxScrollExtent &&
        !_refreshController.isLoading &&
        // todo 临时处理web滚动条件
        _circleNewsDataModel.circleNewsListCount % 10 == 0) {
      _refreshController.requestLoading();
    }
  }

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _circleNewsDataModel.initFinish
        ? _buildMainWidget()
        : CircleLoadingView();
  }

  Widget _buildMainWidget() {
    final _theme = Theme.of(context);
    return Scaffold(
      appBar: OrientationUtil.portrait
          ? CustomAppbar(
              backgroundColor: _theme.scaffoldBackgroundColor,
              title: '圈子消息'.tr,
            )
          : WebAppBar(
              title: '消息'.tr,
              height: 68,
            ),
      body: _circleNewsDataModel.circleNewsListCount > 0
          ? _buildNewsList()
          : _buildNoneDynamicAnnotation(),
    );
  }

  Widget _buildNewsList() {
    return SmartRefresher(
      controller: _refreshController,
      enablePullUp: true,
      header: WaterDropHeader(
        complete: Text('刷新完成'.tr),
        failed: Text('网络异常，请检查后重试'.tr),
      ),
      footer: _circleNewsDataModel.circleNewsListCount > 10
          ? CustomFooter(
              height: 58,
              builder: (context, mode) {
                return footBuilder(context, mode, requestType: requestType);
              },
            )
          : CustomFooter(
              height: 1,
              builder: (context, mode) {
                return const SizedBox();
              }),
      onRefresh: () {
        _circleNewsDataModel
            .initFromNet()
            .then((value) => setState(() {}))
            .whenComplete(_refreshController.refreshCompleted)
            .catchError((error) {
          _refreshController.refreshFailed();
        });
      },
      onLoading: () {
        requestType = RequestType.normal;
        _circleNewsDataModel
            .loadMore()
            .then((value) => setState(() {}))
            .whenComplete(_refreshController.loadComplete)
            .catchError((error) {
          requestType = Http.isNetworkError(error)
              ? RequestType.netError
              : RequestType.dataError;
          _refreshController.loadFailed();
        });
      },
      child: ListView.separated(
          controller: _controller,
          separatorBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Divider(
                color: const Color(0xff919499).withOpacity(0.3),
              ),
            );
          },
          itemCount: _circleNewsDataModel.circleNewsListCount,
          itemBuilder: (context, index) {
            final dataModel =
                _circleNewsDataModel.circleNewsInfoDataModelAtIndex(index);
            switch (dataModel.newsType) {

              /// 动态回复
              case "post_comment":
                return _buildPostCommentItem(dataModel);
                break;

              ///动态点赞
              case "post_like":
                return _buildPostLikeItem(dataModel);
                break;

              /// 回复他人回复
              case "comment_comment":
                return _buildCommentCommentItem(dataModel);
                break;

              /// 点赞回复
              case "comment_like":
                return _buildCommentLikeItem(dataModel);
                break;

              /// 动态at
              case "post_at":
                return _buildPostAtItem(dataModel);
                break;

              /// 动态回复at他人
              case "post_comment_at":
                return _buildPostCommentAtItem(dataModel);
                break;

              /// 回复他人回复中有at
              case "comment_comment_at":
                return _buildCommentCommentAtItem(dataModel);
                break;
              default:
                return const SizedBox();
                break;
            }
          }),
    );
  }

  Widget _buildPostLikeItem(CircleNewsInfoDataModel dataModel) {
    final quotePostDataModel = _circleNewsDataModel
        .circleNewsPostQuoteInfoDataModelWithSrcId(dataModel.postId);
    final quoteText = quotePostDataModel?.toPlainText();
    final firstFrame = quotePostDataModel?.fetchRichFirstFrame();
    final postText = quotePostDataModel?.toPlainText();
    return Container(
      color: Colors.white,
      padding: _itemPadding,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _didSelectNews(dataModel.channelId, dataModel.topicId,
            dataModel.postId, '', dataModel.guildId, dataModel.newsType),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Avatar(
              radius: _avatarWidth,
              url: dataModel.avatar,
            ),
            SizedBox(width: _headSpace),
            Expanded(
                child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildNickName(dataModel.objectId),
                sizeHeight6,
                if (quoteText == null)
                  _buildRichTextWidget('', '内容已被删除'.tr, 'delete')
                else
                  _buildLikeWidget(),
                sizeHeight6,
                _buildCreateTime(dataModel.createdAt),
              ],
            )),
            SizedBox(width: _trailingSpace),
            _buildItemTrailing(postText, firstFrame)
          ],
        ),
      ),
    );
  }

  Widget _buildCommentCommentItem(CircleNewsInfoDataModel dataModel) {
    // 找二级回复是否存在
    final commentDataModel = _circleNewsDataModel
        .circleNewsCommentQuoteInfoDataModelWithSrcId(dataModel.reletedId);
    // 找一级回复是否存在
    final quoteCommentDataModel = _circleNewsDataModel
        .circleNewsCommentQuoteInfoDataModelWithSrcId(dataModel.srcId);
    // 找原动态是否存在
    final quotePostDataModel = _circleNewsDataModel
        .circleNewsPostQuoteInfoDataModelWithSrcId(dataModel.postId);
    // final commentL2Text = commentDataModel?.toPlainText();
    // final commentL1Text = quoteCommentDataModel?.toPlainText();
    final commentL2Text = commentDataModel?.content;
    final commentL1Text = quoteCommentDataModel?.content;
    final postFirstFrame = quotePostDataModel?.fetchRichFirstFrame();
    final postText = quotePostDataModel?.toPlainText();
    return Container(
      color: Colors.white,
      padding: _itemPadding,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _didSelectNews(
            dataModel.channelId,
            dataModel.topicId,
            dataModel.postId,
            commentDataModel?.commentId ?? '',
            dataModel.guildId,
            dataModel.newsType),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Avatar(
              radius: _avatarWidth,
              url: dataModel.avatar,
            ),
            SizedBox(width: _headSpace),
            Expanded(
                child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildNickName(dataModel.objectId),
                sizeHeight6,
                if (quotePostDataModel == null || commentL2Text == null)
                  _buildRichTextWidget('', '回复内容已被删除'.tr, 'delete')
                else
                  _buildRichTextWidget(
                      dataModel.receiveId == 'null'
                          ? '回复了你：'.tr
                          : '回复了你的动态：'.tr,
                      commentL2Text,
                      'quote'),
                sizeHeight6,
                if (quotePostDataModel == null || commentL1Text == null)
                  _buildRichTextWidget('', '回复内容已被删除'.tr, 'delete')
                else
                  _buildRichTextWidget('', commentL1Text, 'origin'),
                sizeHeight6,
                _buildCreateTime(dataModel.createdAt),
              ],
            )),
            SizedBox(width: _trailingSpace),
            _buildItemTrailing(postText, postFirstFrame)
          ],
        ),
      ),
    );
  }

  Widget _buildCommentLikeItem(CircleNewsInfoDataModel dataModel) {
    final quoteCommentDataModel = _circleNewsDataModel
        .circleNewsCommentQuoteInfoDataModelWithSrcId(dataModel.srcId);
    final quotePostDataModel = _circleNewsDataModel
        .circleNewsPostQuoteInfoDataModelWithSrcId(dataModel.postId);
    // final quoteText = quoteCommentDataModel?.toPlainText();
    final quoteText = quoteCommentDataModel?.content;
    final postFirstFrame = quotePostDataModel?.fetchRichFirstFrame();
    final postText = quotePostDataModel?.toPlainText();
    return Container(
      color: Colors.white,
      padding: _itemPadding,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _didSelectNews(
            dataModel.channelId,
            dataModel.topicId,
            dataModel.postId,
            quoteCommentDataModel?.commentId ?? '',
            dataModel.guildId,
            dataModel.newsType),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Avatar(
              radius: _avatarWidth,
              url: dataModel.avatar,
            ),
            SizedBox(width: _headSpace),
            Expanded(
                child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildNickName(dataModel.objectId),
                sizeHeight6,
                if (quotePostDataModel == null || quoteCommentDataModel == null)
                  _buildRichTextWidget('', '回复内容已被删除'.tr, 'delete')
                else
                  _buildLikeWidget(),
                sizeHeight6,
                if (quotePostDataModel == null || quoteText == null)
                  _buildRichTextWidget('', '回复内容已被删除'.tr, 'delete')
                else
                  _buildRichTextWidget('', quoteText, 'origin'),
                sizeHeight6,
                _buildCreateTime(dataModel.createdAt),
              ],
            )),
            SizedBox(width: _trailingSpace),
            _buildItemTrailing(postText, postFirstFrame)
          ],
        ),
      ),
    );
  }

  Widget _buildPostCommentItem(CircleNewsInfoDataModel dataModel) {
    final quotePostDataModel = _circleNewsDataModel
        .circleNewsPostQuoteInfoDataModelWithSrcId(dataModel.postId);
    final quoteCommentDataModel = _circleNewsDataModel
        .circleNewsCommentQuoteInfoDataModelWithSrcId(dataModel.reletedId);
    // final quoteText = quoteCommentDataModel?.toPlainText();
    final quoteText = quoteCommentDataModel?.content;
    final postFirstFrame = quotePostDataModel?.fetchRichFirstFrame();
    final postText = quotePostDataModel?.toPlainText();
    return Container(
      color: Colors.white,
      padding: _itemPadding,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _didSelectNews(
            dataModel.channelId,
            dataModel.topicId,
            dataModel.postId,
            quoteCommentDataModel?.commentId ?? '',
            dataModel.guildId,
            dataModel.newsType),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Avatar(
              radius: _avatarWidth,
              url: dataModel.avatar,
            ),
            SizedBox(width: _headSpace),
            Expanded(
                child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildNickName(dataModel.objectId),
                sizeHeight6,
                if (quotePostDataModel == null || quoteText == null)
                  _buildRichTextWidget('', '回复内容已被删除'.tr, 'delete')
                else
                  _buildRichTextWidget('回复了你的动态：'.tr, quoteText, 'quote'),
                sizeHeight6,
                _buildCreateTime(dataModel.createdAt),
              ],
            )),
            SizedBox(width: _trailingSpace),
            _buildItemTrailing(postText, postFirstFrame)
          ],
        ),
      ),
    );
  }

  Widget _buildPostAtItem(CircleNewsInfoDataModel dataModel) {
    final quotePostDataModel = _circleNewsDataModel
        .circleNewsPostQuoteInfoDataModelWithSrcId(dataModel.postId);
    final quoteCommentDataModel = _circleNewsDataModel
        .circleNewsCommentQuoteInfoDataModelWithSrcId(dataModel.reletedId);
    // final quoteText = quoteCommentDataModel?.toPlainText();
    final quoteText = quotePostDataModel?.content;
    final postFirstFrame = quotePostDataModel?.fetchRichFirstFrame();
    final postText = quotePostDataModel?.toPlainText();
    return Container(
      color: Colors.white,
      padding: _itemPadding,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _didSelectNews(
            dataModel.channelId,
            dataModel.topicId,
            dataModel.postId,
            quoteCommentDataModel?.commentId ?? '',
            dataModel.guildId,
            dataModel.newsType),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Avatar(
              radius: _avatarWidth,
              url: dataModel.avatar,
            ),
            SizedBox(width: _headSpace),
            Expanded(
                child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildNickName(dataModel.objectId),
                sizeHeight6,
                if (quotePostDataModel == null || quoteText == null)
                  _buildRichTextWidget('', '内容已被删除'.tr, 'delete')
                else
                  _buildRichTextWidget('在动态中@你'.tr, quoteText, 'quote',
                      isShowContext: false),
                sizeHeight6,
                _buildCreateTime(dataModel.createdAt),
              ],
            )),
            SizedBox(width: _trailingSpace),
            _buildItemTrailing(postText, postFirstFrame)
          ],
        ),
      ),
    );
  }

  Widget _buildPostCommentAtItem(CircleNewsInfoDataModel dataModel) {
    final quotePostDataModel = _circleNewsDataModel
        .circleNewsPostQuoteInfoDataModelWithSrcId(dataModel.postId);
    final quoteCommentDataModel = _circleNewsDataModel
        .circleNewsCommentQuoteInfoDataModelWithSrcId(dataModel.reletedId);
    // final quoteText = quoteCommentDataModel?.toPlainText();
    final quoteText = quoteCommentDataModel?.content;
    final postFirstFrame = quotePostDataModel?.fetchRichFirstFrame();
    final postText = quotePostDataModel?.toPlainText();
    return Container(
      color: Colors.white,
      padding: _itemPadding,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _didSelectNews(
            dataModel.channelId,
            dataModel.topicId,
            dataModel.postId,
            quoteCommentDataModel?.commentId ?? '',
            dataModel.guildId,
            dataModel.newsType),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Avatar(
              radius: _avatarWidth,
              url: dataModel.avatar,
            ),
            SizedBox(width: _headSpace),
            Expanded(
                child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildNickName(dataModel.objectId),
                sizeHeight6,
                if (quotePostDataModel == null || quoteText == null)
                  _buildRichTextWidget('', '回复内容已被删除'.tr, 'delete')
                else
                  _buildRichTextWidget('在回复中@你：'.tr, quoteText, 'quote'),
                sizeHeight6,
                _buildCreateTime(dataModel.createdAt),
              ],
            )),
            SizedBox(width: _trailingSpace),
            _buildItemTrailing(postText, postFirstFrame)
          ],
        ),
      ),
    );
  }

  Widget _buildCommentCommentAtItem(CircleNewsInfoDataModel dataModel) {
    // 找二级回复是否存在
    final commentDataModel = _circleNewsDataModel
        .circleNewsCommentQuoteInfoDataModelWithSrcId(dataModel.reletedId);
    // 找一级回复是否存在
    final quoteCommentDataModel = _circleNewsDataModel
        .circleNewsCommentQuoteInfoDataModelWithSrcId(dataModel.srcId);
    // 找原动态是否存在
    final quotePostDataModel = _circleNewsDataModel
        .circleNewsPostQuoteInfoDataModelWithSrcId(dataModel.postId);
    final commentL2Text = commentDataModel?.content;
    final commentL1Text = quoteCommentDataModel?.content;
    final postFirstFrame = quotePostDataModel?.fetchRichFirstFrame();
    final postText = quotePostDataModel?.toPlainText();

    return Container(
      color: Colors.white,
      padding: _itemPadding,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _didSelectNews(
            dataModel.channelId,
            dataModel.topicId,
            dataModel.postId,
            commentDataModel?.commentId ?? '',
            dataModel.guildId,
            dataModel.newsType),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Avatar(
              radius: _avatarWidth,
              url: dataModel.avatar,
            ),
            SizedBox(width: _headSpace),
            Expanded(
                child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildNickName(dataModel.objectId),
                sizeHeight6,
                if (quotePostDataModel == null || commentL2Text == null)
                  _buildRichTextWidget('', '回复内容已被删除'.tr, 'delete')
                else
                  _buildRichTextWidget(
                      dataModel.receiveId == 'null'
                          ? '在回复中@你：'.tr
                          : '在动态中@你：'.tr,
                      commentL2Text,
                      'quote'),
                sizeHeight6,
                if (quotePostDataModel == null || commentL1Text == null)
                  _buildRichTextWidget('', '回复内容已被删除'.tr, 'delete')
                else
                  _buildRichTextWidget('', commentL1Text, 'origin'),
                sizeHeight6,
                _buildCreateTime(dataModel.createdAt),
              ],
            )),
            SizedBox(width: _trailingSpace),
            _buildItemTrailing(postText, postFirstFrame)
          ],
        ),
      ),
    );
  }

  Widget _buildCreateTime(String createdAt) {
    final _theme = Theme.of(context);
    return Text(
        formatDate2Str(
            DateTime.fromMillisecondsSinceEpoch(int.tryParse(createdAt) ?? 0)),
        style: _theme.textTheme.bodyText1
            .copyWith(fontSize: 14, color: _theme.disabledColor));
  }

  Widget _buildNickName(String userId) {
    final _theme = Theme.of(context);
    return RealtimeNickname(
      userId: userId,
      style: TextStyle(
          color: _theme.textTheme.bodyText2.color,
          fontSize: 14,
          height: 1.25,
          fontWeight: FontWeight.bold),
      showNameRule: ShowNameRule.remarkAndGuild,
    );
  }

  Widget _buildNoneDynamicAnnotation() {
    final _theme = Theme.of(context);
    return Container(
      alignment: Alignment.center,
      margin: const EdgeInsets.only(bottom: kToolbarHeight),
      color: _theme.scaffoldBackgroundColor,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          WebsafeSvg.asset(SvgIcons.svgCircleNoneDynamic, width: 170),
          const SizedBox(
            height: 40,
          ),
          Text(
            '暂无动态消息'.tr,
            style: TextStyle(
                color: _theme.textTheme.bodyText2.color,
                fontSize: 17,
                fontWeight: FontWeight.bold),
          ),
          sizeHeight12,
          Text(
            '发布动态，评论互动，就有机会收到消息哟~'.tr,
            style: _theme.textTheme.bodyText1.copyWith(fontSize: 14),
          ),
        ],
      ),
    );
  }

  void _didSelectNews(String channelId, String topicId, String postId,
      String commentId, String guildId, String newsType) {
    // ExtraType type = ExtraType.postLike;
    // switch (newsType) {
    //   case "post_like":
    //     type = ExtraType.postLike;
    //     break;
    //   case "post_comment":
    //     type = ExtraType.postComment;
    //     break;
    //   case "comment_comment":
    //     type = ExtraType.commentComment;
    //     break;
    //   case "comment_like":
    //     type = ExtraType.commentLike;
    //     break;
    //   case "post_at":
    //     type = ExtraType.postAt;
    //     break;
    //   case "post_comment_at":
    //     type = ExtraType.postCommentAt;
    //     break;
    //   case "comment_comment_at":
    //     type = ExtraType.commentCommentAt;
    //     break;
    //   default:
    //     return;
    // }
    // Routes.pushCirclePage(context,
    //     extraData: ExtraData(
    //         channelId: channelId,
    //         topicId: topicId,
    //         postId: postId,
    //         commentId: '',
    //         guildId: guildId,
    //         extraType: type));
  }

  Widget _buildLikeWidget() {
    final _theme = Theme.of(context);
    return Icon(IconFont.buffCircleLikeUnselect,
        color: _theme.primaryColor, size: 24);
  }

  Widget _buildItemTrailing(
      String quoteString, Tuple2<Operation, String> firstFrame) {
    final _theme = Theme.of(context);
    if (firstFrame?.item1 != null &&
        (firstFrame.item1?.isMedia ?? false) &&
        firstFrame.item2.startsWith('http')) {
      if (firstFrame.item1.isImage) {
        return ConstrainedBox(
            constraints: BoxConstraints(
                maxHeight: _trailingSize, maxWidth: _trailingSize),
            child: RoundImage(
              url: firstFrame.item2,
              height: _trailingSize,
              width: _trailingSize,
              cacheManager: CircleCachedManager.instance,
            ));
      } else {
        return ConstrainedBox(
            constraints: BoxConstraints(
                maxHeight: _trailingSize, maxWidth: _trailingSize),
            child: Stack(
              children: [
                RoundImage(
                  url: firstFrame.item2,
                  height: _trailingSize,
                  width: _trailingSize,
                  cacheManager: CircleCachedManager.instance,
                ),
                Center(
                  child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        IconFont.buffCirclePlay,
                        color: Colors.white,
                        size: 20,
                      )),
                )
              ],
            ));
      }
    } else {
      double paddingSize = 2;
      TextAlign align = TextAlign.left;
      if (quoteString == null) {
        quoteString = '内容已被删除'.tr;
        paddingSize = max(14.0 - (quoteString.length ~/ 2.5) * 2, 2);
        align = TextAlign.center;
      }
      return Container(
          width: _trailingSize,
          height: _trailingSize,
          padding: EdgeInsets.all(paddingSize.toDouble()),
          decoration: BoxDecoration(
              borderRadius: const BorderRadius.all(Radius.circular(5)),
              color: _theme.scaffoldBackgroundColor),
          child: Center(
            child: Text(
              quoteString,
              textAlign: align,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: _theme.textTheme.bodyText1
                  .copyWith(fontSize: 11, color: _theme.disabledColor),
            ),
          ));
    }
  }

  Widget _buildRichTextWidget(String replyText, String text, String type,
      {bool isShowContext = true}) {
    final _theme = Theme.of(context);
    switch (type) {
      case 'quote':
        final jsonObject = jsonDecode(text);
        if (jsonObject == null) {
          return const SizedBox();
        }

        final document = Document.fromJson(jsonObject);
        final list = RichEditorUtils.formatDelta(document.toDelta()).toList();
        text = getAllText(list);

        return Text.rich(
          TextSpan(style: _theme.textTheme.bodyText1, children: [
            if (replyText.isNotEmpty)
              TextSpan(
                  style: _theme.textTheme.bodyText1
                      .copyWith(fontSize: 16, color: _theme.disabledColor),
                  text: replyText),

            /// TODO 以下按照竖屏逻辑复用代码
            // if (isShowContext)
            // ...buildSpans(text, context,
            //     style: _theme.textTheme.bodyText2.copyWith(fontSize: fontSize),
            //     parse: [
            //       ParsedTextExtension.matchCusEmoText(context, fontSize),
            //       ParsedTextExtension.matchChannelLink(context),
            //       ParsedTextExtension.matchAtText(context,
            //           textStyle:
            //               _theme.textTheme.bodyText2.copyWith(fontSize: 16)),
            //     ])
            // buildRichTextSpan(bean.comment.content, context, style: style),
          ]),
          overflow: TextOverflow.ellipsis,
          maxLines: 5,
        );

        break;
      case 'origin':
        final jsonObject = jsonDecode(text);
        if (jsonObject == null) {
          return const SizedBox();
        }
        final document = Document.fromJson(jsonObject);
        final list = RichEditorUtils.formatDelta(document.toDelta()).toList();
        text = getAllText(list);

        return Stack(
          children: [
            Positioned(
                top: 0,
                bottom: 1,
                left: 2,
                width: 2,
                child: Container(
                  width: 2,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      color: const Color(0xff919499).withOpacity(0.3)),
                )),
            Container(
                padding: const EdgeInsets.fromLTRB(8, 0, 0, 0),
                child: Text.rich(
                  TextSpan(style: _theme.textTheme.bodyText1, children: [
                    if (replyText.isNotEmpty)
                      TextSpan(
                          style: _theme.textTheme.bodyText1.copyWith(
                              fontSize: 16, color: _theme.disabledColor),
                          text: replyText),

                    // ...buildSpans(text, context,
                    //     style:
                    //         _theme.textTheme.bodyText2.copyWith(fontSize: 16),
                    //     parse: [
                    //       ParsedTextExtension.matchCusEmoText(context),
                    //       ParsedTextExtension.matchChannelLink(context),
                    //       ParsedTextExtension.matchAtText(context,
                    //           textStyle: _theme.textTheme.bodyText2
                    //               .copyWith(fontSize: 16)),
                    //     ])
                    // buildRichTextSpan(bean.comment.content, context, style: style),
                  ]),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 5,
                ))
          ],
        );
        break;
      case 'delete':
        return Container(
            padding: const EdgeInsets.all(2),
            color: _theme.scaffoldBackgroundColor,
            child: RichText(
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              text: TextSpan(
                text: '',
                style: _theme.textTheme.bodyText1,
                children: [
                  TextSpan(
                      text: text,
                      style: _theme.textTheme.bodyText1.copyWith(
                          height: 1, fontSize: 14, color: _theme.disabledColor))
                ],
              ),
            ));
        break;
      default:
        return const SizedBox();
        break;
    }
  }
}
