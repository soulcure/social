import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/api/data_model/user_info.dart';
import 'package:im/app/modules/circle/controllers/circle_controller.dart';
import 'package:im/app/modules/circle/models/models.dart';
import 'package:im/app/modules/circle/util.dart';
import 'package:im/app/modules/circle/views/portrait/widgets/circle_style_rich_text.dart';
import 'package:im/app/theme/app_theme.dart';
import 'package:im/common/extension/string_extension.dart';
import 'package:im/icon_font.dart';
import 'package:im/pages/guild_setting/circle/circle_detail_page/like_button.dart';
import 'package:im/pages/guild_setting/circle/component/circle_user_avatar.dart';
import 'package:im/pages/guild_setting/guild/container_image.dart';
import 'package:im/svg_icons.dart';
import 'package:im/themes/const.dart';
import 'package:im/utils/custom_cache_manager.dart';
import 'package:im/widgets/user_info/realtime_nick_name.dart';
import 'package:websafe_svg/websafe_svg.dart';

class CircleTopicStaggeredItem extends StatefulWidget {
  final CirclePostDataModel circlePostDataModel;

  ///圈子搜索的关键词
  final String searchKey;

  const CircleTopicStaggeredItem(
    this.circlePostDataModel, {
    Key key,
    this.searchKey,
  }) : super(key: key);

  @override
  _CircleTopicStaggeredItemState createState() =>
      _CircleTopicStaggeredItemState();
}

class _CircleTopicStaggeredItemState extends State<CircleTopicStaggeredItem> {
  CirclePostInfoDataModel _postInfoDataModel;
  CirclePostUserDataModel _userInfoDataModel;
  CirclePostSubInfoDataModel _subInfoDataModel;
  String _content;

  /// @提醒查看好友
  List<String> _atUserIds = [];

  ///是否圈子搜索列表item
  bool get _formSearch =>
      widget.searchKey != null && widget.searchKey.isNotEmpty;

  @override
  void initState() {
    _postInfoDataModel = widget.circlePostDataModel?.postInfoDataModel;
    _userInfoDataModel = widget.circlePostDataModel?.userDataModel;
    _subInfoDataModel = widget.circlePostDataModel?.postSubInfoDataModel;
    _atUserIds = widget.circlePostDataModel?.atUserIdList ?? [];
    _content = CircleUtil.parsePost(_postInfoDataModel);
    super.initState();
  }

  @override
  void didUpdateWidget(covariant CircleTopicStaggeredItem oldWidget) {
    if (_postInfoDataModel != widget.circlePostDataModel?.postInfoDataModel) {
      _postInfoDataModel = widget.circlePostDataModel?.postInfoDataModel;
      _content = CircleUtil.parsePost(_postInfoDataModel);
    }
    _userInfoDataModel = widget.circlePostDataModel?.userDataModel;
    _subInfoDataModel = widget.circlePostDataModel?.postSubInfoDataModel;
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.all(
        Radius.circular(4),
      ),
      child: DecoratedBox(
        decoration: const BoxDecoration(color: Colors.white),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildContent(),
            sizeHeight12,
            _buildTitle(),
            _buildPostInfo(),
            sizeHeight12,
          ],
        ),
      ),
    );
  }

  ///卡片内容区
  Widget _buildContent() {
    if (_postInfoDataModel.postTypeAvailable) {
      return LayoutBuilder(
        builder: (context, constraint) {
          ///这里不直接用AspectRatio的原因是：
          ///AspectRatio 的浮点数计算有极其微小的差异，圈子的瀑布流布局，
          ///一个 Item 放左边还是右边，取决于左右两列哪一列比较小，
          ///这个微小的浮点数差异导致两次 layout 取到了不同的结果，最终会导致两列位置切换。
          return SizedBox(
            width: constraint.maxWidth,
            height: (constraint.maxWidth ~/ _postInfoDataModel.itemAspectRatio)
                .toDouble(),

            ///帖子带有媒体就展示图片，否则展示富文本
            child: _postInfoDataModel.firstMedia.isNotEmpty
                ? _buildImage()
                : Container(
                    color: appThemeData.scaffoldBackgroundColor,
                    alignment: Alignment.center,
                    child: CircleStyleRichText(
                      guildId: _postInfoDataModel.guildId,
                      content: _showTitleOrContent(content: true) ?? '',
                      padding: const EdgeInsets.all(8),
                      searchKey: widget.searchKey,
                      formSearch: _formSearch,
                    ),
                  ),
          );
        },
      );
    } else {
      return _buildIncompatibleWidget();
    }
  }

  Widget _buildImage() {
    final Map<String, dynamic> mediaMap = _postInfoDataModel.firstMedia;
    final fileType = _postInfoDataModel.firstMediaFileType;
    final hasDoc = _postInfoDataModel.fileId.hasValue;
    final thumbUrl =
        fileType == 'video' ? mediaMap['thumbUrl'] : mediaMap['source'];
    return Stack(
      fit: StackFit.expand,
      children: [
        ContainerImage(
          thumbUrl,
          fit: BoxFit.cover,
          cacheManager: CircleCachedManager.instance,
          thumbWidth: CircleController.circleThumbWidth,
        ),
        if (fileType == 'video')
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.all(
                  Radius.circular(12),
                ),
              ),
              width: 24,
              height: 24,
              child: WebsafeSvg.asset(
                SvgIcons.circleVideoPlay,
                width: 11,
                height: 11,
                color: Colors.white,
              ),
            ),
          ),
        if (hasDoc)
          Positioned(
            right: 8,
            bottom: 8,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.all(
                  Radius.circular(2),
                ),
              ),
              width: 42,
              height: 18,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(IconFont.buffDocument,
                      color: Colors.white, size: 12),
                  const SizedBox(width: 2),
                  Text(
                    "文档".tr,
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                  )
                ],
              ),
            ),
          ),
      ],
    );
  }

  ///展示标题或正文，默认优先标题，可选优先正文
  String _showTitleOrContent({bool content = false}) {
    final title = _postInfoDataModel.title;

    if (content) {
      return _content.isNotEmpty ? _content : title;
    } else {
      return title.isNotEmpty ? title : _content;
    }
  }

  ///卡片标题
  Widget _buildTitle() {
    final content = _showTitleOrContent();

    if (content.isNotEmpty && _postInfoDataModel.postTypeAvailable) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
        child: CircleStyleRichText(
          content: content,
          guildId: _postInfoDataModel.guildId,
          maxHeight: 36,
          maxLines: 2,
          searchKey: widget.searchKey,
          formSearch: _formSearch,
        ),
      );
    } else if (_atUserIds.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
        child: UserInfo.getUserIdListWidget(
          _atUserIds,
          guildId: _postInfoDataModel.guildId,
          builder: (context, userInfos, child) {
            String atUserName = "";
            userInfos.forEach((key, userInfo) {
              atUserName +=
                  "@${userInfo.showName(guildId: _postInfoDataModel.guildId)} ";
            });
            return CircleStyleRichText(
              content: atUserName,
              guildId: _postInfoDataModel.guildId,
              maxHeight: 36,
              maxLines: 2,
              searchKey: widget.searchKey,
              formSearch: _formSearch,
            );
          },
        ),
      );
    }
    return const SizedBox();
  }

  ///帖子不兼容展示组件
  Widget _buildIncompatibleWidget() {
    return Container(
      height: 70,
      alignment: Alignment.center,
      color: const Color(0xFFF5F5F8),
      child: Text(
        '当前版本暂不支持查看\n请更新至最新版'.tr,
        style: appThemeData.textTheme.bodyText2.copyWith(
          color: const Color(0xFF646A73),
          fontSize: 14,
          height: 1.25,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  ///帖子信息栏
  Container _buildPostInfo() {
    return Container(
      height: 18,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          CircleUserAvatar(
            _userInfoDataModel?.userId ?? "",
            18,
            avatarUrl: _userInfoDataModel?.avatar ?? "",
            cacheManager: CircleCachedManager.instance,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: RealtimeNickname(
              userId: _userInfoDataModel?.userId,
              style: TextStyle(color: appThemeData.disabledColor, fontSize: 11),
              showNameRule: ShowNameRule.remarkAndGuild,
              guildId: _postInfoDataModel?.guildId,
            ),
          ),
          _buildLikeButton(),
        ],
      ),
    );
  }

  ///点赞按钮
  Widget _buildLikeButton() {
    return CircleAniLikeButton(
      fontSize: 11,
      iconSize: 12,
      fontColor: appThemeData.dividerColor.withOpacity(1),
      padding: const EdgeInsets.only(left: 4),
      liked: _subInfoDataModel.iLiked == '1',
      count: _subInfoDataModel.totalLikeNum,
      likeColor: const Color(0xFFF32F56),
      unLikeColor: appThemeData.dividerColor.withOpacity(1),
      likeIconData: IconFont.buffLikeSel,
      unlikeIconData: IconFont.buffLike,
      postData: PostData(
        guildId: _postInfoDataModel.guildId,
        channelId: _postInfoDataModel.channelId,
        topicId: _postInfoDataModel.topicId,
        postId: _postInfoDataModel.postId,
        t: 'post',
        likeId: _subInfoDataModel.likeId,
        commentId: "",
      ),
      onLikeChange: (t, v) {
        if (t) {
          widget.circlePostDataModel.modifyLikedState('1', v,
              postId: _postInfoDataModel?.postId ?? "");
        } else {
          widget.circlePostDataModel.modifyLikedState('0', v,
              postId: _postInfoDataModel?.postId ?? "");
        }
        setState(() {});
        CircleController.to
          ..updateItem(
            widget.circlePostDataModel.postInfoDataModel.topicId,
            widget.circlePostDataModel,
          )
          ..updateSubscriptionItem(widget.circlePostDataModel);
      },
    );
  }
}
