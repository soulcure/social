import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' hide Text;
import 'package:get/get.dart';
import 'package:im/api/circle_api.dart';
import 'package:im/api/entity/circle_comment_bean.dart';
import 'package:im/api/entity/circle_detail_list_bean.dart';
import 'package:im/app/modules/circle/models/models.dart';
import 'package:im/common/extension/operation_extension.dart';
import 'package:im/common/permission/permission.dart';
import 'package:im/common/permission/permission_model.dart';
import 'package:im/core/http_middleware/http.dart';
import 'package:im/db/db.dart';
import 'package:im/loggers.dart';
import 'package:im/pages/guild_setting/circle/circle_share/circle_share_item.dart';
import 'package:im/pages/guild_setting/circle/circle_share/circle_share_widget.dart';
import 'package:im/pages/guild_setting/circle/component/circle_user_info_row.dart';
import 'package:im/pages/guild_setting/guild/container_image.dart';
import 'package:im/pages/home/json/text_chat_json.dart';
import 'package:im/pages/home/model/chat_index_model.dart';
import 'package:im/pages/home/view/gallery/gallery.dart';
import 'package:im/pages/home/view/gallery/photo_view.dart';
import 'package:im/pages/home/view/text_chat/items/components/parsed_text_extension.dart';
import 'package:im/pages/home/view/text_chat/rich_editor/model/editor_model.dart';
import 'package:im/pages/home/view/text_chat/rich_editor/utils.dart';
import 'package:im/themes/const.dart';
import 'package:im/themes/default_theme.dart';
import 'package:im/utils/custom_cache_manager.dart';
import 'package:im/utils/im_utils/channel_util.dart';
import 'package:im/utils/orientation_util.dart';
import 'package:im/web/widgets/web_video_player/web_video_player.dart';
import 'package:im/widgets/dialog/show_web_image_dialog.dart';
import 'package:im/widgets/list_physics.dart';
import 'package:im/widgets/poly_text/poly_text.dart';
import 'package:im/widgets/topic_tag_text.dart';
import 'package:im/widgets/user_info/realtime_nick_name.dart';
import 'package:im/widgets/video_play_button.dart';
import 'package:oktoast/oktoast.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:tuple/tuple.dart';
import 'package:websafe_svg/websafe_svg.dart';

import '../../../../global.dart';
import '../../../../svg_icons.dart';
import 'circle_page.dart';
import 'common.dart';
import 'input_placeholder.dart';
import 'like_button.dart';
import 'menu_button/landscape_menu_button.dart';
import 'reply_item.dart';
import 'show_landscape_circle_reply_popup.dart';

class CirclePageLogic {
  final CirclePageModel _model;

  CirclePageLogic(this._model);

  Widget buildLayout() {
    final model = _model;
    final isLoading = model.initialLoading && model.extraData != null;
    final postDeleted =
        model.requestCode == postNotFound2 || model.requestCode == postNotFound;
    final initialError = model.initialError;
    if (isLoading) return buildLoadingWidget(model.context);
    if (initialError)
      return postDeleted
          ? buildEmptyLayout(model.context)
          : buildReloadLayout();
    return buildBody();
  }

  Widget buildBody() {
    final model = _model;
    final initialError = model.initialError;
    final initialLoading = model.initialLoading;
    return Column(
      children: [
        Expanded(child: buildContentLayout()),
        if (!initialError && !initialLoading) buildInputLayoutWidget(),
      ],
    );
  }

  Widget buildReloadLayout() {
    final model = _model;
    final text = model.requestType == RequestType.netError
        ? '网络异常，请检查后重试'.tr
        : '数据异常，请重试'.tr;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error,
            size: 30,
            color: Colors.red,
          ),
          TextButton(
            onPressed: () async {
              final hasExtra = _model.extraData != null;
              await loadList(
                  hasExtra: hasExtra,
                  initialLoading:
                      (_model.listId?.isEmpty ?? true) || _model.listId == '0');
              // _model.refresh();
            },
            child: Text(text),
          ),
        ],
      ),
    );
  }

  Widget buildContentLayout() {
    final model = _model;
    final rController = model.refreshController;
    final controller = model.controller;
    final loadingError = model.requestType != RequestType.normal;
    final errorText = model.requestType == RequestType.netError
        ? '网络异常，请检查后重试'.tr
        : '数据异常，请重试'.tr;
    return SmartRefresher(
      physics: const SlowClampingListPhysics(),
      controller: rController,
      enablePullUp: !rController.isLoading || !model.isFloorsEmpty,
      enablePullDown: !rController.isRefresh || !model.isFloorsEmpty,
      header: WaterDropHeader(
        complete: Text('刷新完成'.tr),
        failed: Text('加载失败'.tr),
      ),
      onRefresh: loadList,
      footer: CustomFooter(
        height: 108,
        builder: (ctx, mode) => model.isFloorsEmpty
            ? sizedBox
            : footBuilder(ctx, mode,
                requestType: model.requestType,
                onErrorCall: rController.requestLoading,
                showIdleWidget: !rController.isLoading && model.noMoreData,
                showDivider: false),
      ),
      onLoading: () => loadList(loadMore: true, initialLoading: false),
      child: CustomScrollView(
        controller: controller,
        slivers: [
          SliverPadding(
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                buildAvatar(),
                buildHeadFloor(),
                buildBeforeFloors(),
                loadRestWidget(),
                if (loadingError && model.replyList.isEmpty)
                  loadingErrorWidget(() {
                    loadList(
                        hasExtra: model.extraData != null,
                        initialLoading: (_model.listId?.isEmpty ?? true) ||
                            _model.listId == '0');
                  }, errorText)
              ]),
            ),
            padding: EdgeInsets.zero,
          ),
          buildFloorLayout(),
        ],
      ),
    );
  }

  Widget buildInputLayoutWidget() {
    final model = _model;
    final context = model.context;
    final theme = Theme.of(context);
    final dividerColor = theme.dividerColor;
    final likeTotal = model.totalLikeNum;
    final likeByMyself = model.likeByMyself;
    final data = model.data.postSubInfoDataModel;
    final subData = model.circleDetailBean?.post?.subInfo;
    // final replyUserInfo = Db.userInfoBox.get(_model.replyUserId);
    return SafeArea(
      child: Container(
        width: double.infinity,
        height: 48,
        decoration: BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: dividerColor, width: 0.5))),
        child: Row(
          children: [
            Expanded(
              child: ValidPermission(
                channelId: model.topicId,
                permissions: [Permission.CIRCLE_REPLY],
                builder: (hasPermission, isOwner) {
                  return InputPlaceholder(
                    pageContext: _model.context,
                    guildId: _model.guildId,
                    channelId: _model.channelId,
                    hasPermission: hasPermission || isOwner,
                    onReplySend: (doc) async {
                      final model = _model;
                      final res = await toComment(doc);
                      if (res == null) return;
                      final resultBean = CircleCommentBean.fromMap(res);
                      final userData = model.data.userDataModel;
                      final replyUser = UserBean(
                          avatar: userData.avatar,
                          userId: userData.userId,
                          username: userData.userName,
                          nickname: userData.nickName);
                      resultBean.replyUser = replyUser;
                      resultBean.replyUserId = replyUser.userId;
                      final replyDetailBean =
                          CircleCommentBean.toReplyDetailBean(resultBean);
                      loadRestList();
                      model.replyList.insert(0, replyDetailBean);
                      model.addTotalReplyNum();
                      model.listId =
                          model.replyList.last.comment?.commentId ?? '0';
                      needRefreshWhenPop = true;
                      model.refresh();
                    },
                    commentId: model.postId,
                  );
                },
              ),
            ),
            ValidPermission(
              channelId: model.topicId,
              permissions: [Permission.CIRCLE_ADD_REACTION],
              builder: (hasPermission, isOwner) {
                return CircleAniLikeButton(
                  liked: likeByMyself,
                  count: likeTotal,
                  hasPermission: hasPermission || isOwner,
                  padding: const EdgeInsets.only(left: 20, right: 8),
                  onLikeChange: (value, likeId) {
                    if (value) {
                      data.iLiked = '1';
                      subData?.liked = 1;
                      model.addTotalLike();
                    } else {
                      data.iLiked = '0';
                      subData?.liked = 0;
                      model.removeTotalLike();
                    }
                    if (likeId.isNotEmpty) {
                      data.likeId = likeId;
                      model.circleDetailBean?.post?.subInfo?.likeId = likeId;
                    }
                    needRefreshWhenPop = true;
                    model.refresh();
                  },
                  requestError: (code) {
                    if (code == postNotFound) {
                      showToast(postNotFoundToast);
                      // Future.delayed(const Duration(seconds: 1),
                      //     () => Navigator.of(context).pop(true));
                    }
                  },
                  postData: PostData(
                      guildId: model.guildId,
                      channelId: model.channelId,
                      topicId: model.topicId,
                      postId: model.postId,
                      t: 'post',
                      likeId: model.likeId),
                );
              },
            ),
            ShareButton(
              data: model.data,
              alignment: Alignment.center,
              isLandFromCircleDetail: true,
              isFromList: false,
            ),
            sizeWidth8,
          ],
        ),
      ),
    );
  }

  Widget buildAvatar() {
    // final theme = Theme.of(_model.context);
    // final color1 = theme.textTheme.bodyText2.color;
    // final color2 = theme.textTheme.bodyText1.color;
    final userInfo = _model.headUser;
    // final time = getTime(int.parse(_model.headFloorTime));
    final updatedAt =
        _model.updatedAt.isEmpty ? _model.createdAt : _model.updatedAt;
    final child = Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
      child: CircleUserInfoRow(
        userId: userInfo.userId,
        createdAt: int.parse(_model?.createdAt ?? "0"),
        updatedAt: int.parse(updatedAt),
        avatarUrl: userInfo.avatar,
        nickName: userInfo.nickName,
      ),
    );

    if (OrientationUtil.portrait)
      return child;
    else
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: child,
          ),
          Builder(builder: (context) {
            return MenuButton(
              postData: _model.data,
              iconAlign: Alignment.center,
              onRequestSuccess: (type, {param}) {
                Navigator.of(context).pop(true);
              },
              size: 24,
              padding: const EdgeInsets.only(right: 16),
            );
          })
        ],
      );
  }

  Widget buildHeadFloor() {
    final model = _model;
    final theme = Theme.of(model.context);
    final color1 = theme.dividerColor;
    final hasData = model.contentList?.isNotEmpty ?? false;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (OrientationUtil.landscape) ...[
          buildTopic(),
          sizeHeight8,
          buildTitle(),
          const SizedBox(height: 4)
        ] else ...[
          buildTitle(),
          buildTopic(),
          sizeHeight12,
        ],
        Padding(
          padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
          child: hasData
              ? LayoutBuilder(builder: (context, constraints) {
                  return _buildDocument(maxWidth: constraints.maxWidth);
                })
              : sizedBox,
        ),
        Divider(
          height: 0.5,
          color: color1,
        )
      ],
    );
  }

  Widget buildTitle() {
    final model = _model;
    final title = model.title;
    if (title.isEmpty) return sizedBox;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
      child: Text(
        title,
        style: TextStyle(
            fontSize: OrientationUtil.portrait ? 20 : 14,
            color: const Color(0xff1F2125),
            fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget buildTopic() {
    final model = _model;
    final topic = model.topicName;
    if (topic.isEmpty) return sizedBox;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: TopicTagText([topic]),
    );
  }

  Widget buildFloorLayout() {
    final model = _model;
    final isFloorsEmpty = model.isFloorsEmpty;
    final initialLoading =
        model.initialLoading || (model.isLoading && isFloorsEmpty);
    final loadingError = model.requestType != RequestType.normal;

    Widget keepHeight(Widget child) => SliverToBoxAdapter(
          child: SizedBox(
            height: 237,
            child: child,
          ),
        );
    if (initialLoading) return keepHeight(buildLoadingWidget(model.context));

    if (isFloorsEmpty && !loadingError) return keepHeight(buildEmptyFloor());

    return buildFloors();
  }

  Widget buildEmptyFloor() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 40, top: 48),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          WebsafeSvg.asset(SvgIcons.svgCircleNoneReply, height: 100),
          sizeHeight24,
          Text(
            '快来进行回复吧'.tr,
            style: const TextStyle(color: Color(0xff8F959E), fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget buildFloors() {
    return SliverPadding(
      sliver: SliverList(
        delegate: SliverChildListDelegate(
          buildReplyItems(),
        ),
      ),
      padding: EdgeInsets.zero,
    );
  }

  Widget buildBeforeFloors() {
    final isFloorsEmpty = _model.isFloorsEmpty;
    if (isFloorsEmpty) return sizedBox;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: replyNumbers(_model.totalReplyNum),
    );
  }

  Widget loadRestWidget() {
    final model = _model;
    if (!model.needLoadHeadRest) return sizedBox;
    return TextButton(
        onPressed: () {
          loadRestList();
          model.refresh();
        },
        child: Text('点击加载之前楼层'.tr));
  }

  void loadRestList() {
    final model = _model;
    if (!model.needLoadHeadRest ||
        model.tempList == null ||
        model.tempList.isEmpty) return;
    model.circleDetailBean.replys.insertAll(0, model.tempList);
    model.needLoadHeadRest = false;
  }

  List<Widget> buildReplyItems() {
    final list = _model.replyList;
    return List.generate(
        list.length,
        (index) => Padding(
              padding: EdgeInsets.only(top: index == 0 ? 0 : 16),
              child: ReplyItem(
                list,
                index,
                model: _model,
              ),
            ));
  }

  Future initState() async {
    final model = _model;
    // tempPostInfo.clearData();
    final hasExtra = model.extraData != null;
    final content = _model?.data?.postInfoDataModel?.postContent() ??
        RichEditorUtils.defaultDoc.encode();
    initContent(content);
    await loadList(
        hasExtra: hasExtra,
        onError: (e) {
          model.initialError = true;
          if (e is RequestArgumentError &&
              (e.code == postNotFound2 || e.code == postNotFound)) {
            final postInfo = postInfoMap[model.postId];
            postInfo?.setData(deleted: true);
            model.requestCode = e.code;
          }
        });
    model.initialLoading = false;
    final scrollController = model.controller;
    if (scrollController.hasClients)
      scrollController.addListener(scrollerListener);
    model.refresh();
  }

  void initContent(String content) {
    try {
      final model = _model;
      if (content == null) return;
      final contentJson = List<Map<String, dynamic>>.from(jsonDecode(content));
      RichEditorUtils.transformAToLink(contentJson);
      final document = Document.fromJson(contentJson);
      final list = RichEditorUtils.formatDelta(document.toDelta()).toList();
      model.contentList = list;
      model.imageList.clear();
      for (final o in list) {
        final isImage = o.isImage;
        final isVideo = o.isVideo;
        if (!(isImage || isVideo)) continue;
        final url = RichEditorUtils.getEmbedAttribute(o, 'source');
        model.imageList
            .add(IndexMedia(model.imageList.length, url, isImage: isImage));
      }
      model.refresh();
    } catch (e) {
      logger.shout('文本解析错误');
    }
  }

  Future refreshContent() async {
    final model = _model;
    final res =
        await getModelFromNet(model.topicId, model.channelId, model.postId);
    _model.data?.updateByAnother(res);
    final content = res?.postInfoDataModel?.postContent() ??
        RichEditorUtils.defaultDoc.encode();
    model.quillController = QuillController(
        document: Document.fromJson(jsonDecode(content)),
        selection: const TextSelection.collapsed(offset: 0));
    initContent(content);
  }

  void dispose() {
    final model = _model;
    model.controller.removeListener(scrollerListener);
    if (OrientationUtil.landscape) clearVideoCache();
    final likeTotal = model.totalLikeNum.toString();
    final liked = model.likeByMyself;
    final commentTotal = model.totalReplyNum;
    final title = model.title;
    final content = model.postContent ?? RichEditorUtils.defaultDoc.encode();
    // if(liked) likeTotal++;
    final postInfo = postInfoMap[model.postId];
    try {
      final richEditorModel = Get.find<RichEditorModel>();
      richEditorModel.closeEditor?.call(false);
      richEditorModel.dispose();
      Get.delete<RichEditorModel>();
    } catch (e, s) {
      logger.severe(e, s);
    }
    if (postInfo == null)
      postInfoMap[model.postId] = PostInfo(
          ValueNotifier(commentTotal),
          ValueNotifier(likeTotal),
          ValueNotifier(title),
          ValueNotifier(content),
          ValueNotifier(liked),
          ValueNotifier(false),
          model.postId);
    else
      Future.delayed(
          const Duration(milliseconds: 200),
          () => postInfo.setData(
              commentTotal: commentTotal, liked: liked, likeTotal: likeTotal));
  }

  void scrollerListener() {
    final model = _model;
    model.curOff = model.controller.offset;
  }

  Future toDelete(CirclePostInfoDataModel data) async {
    try {
      final res = await CircleApi.circlePostDelete(
          data.postId, data.channelId, data.topicId,
          showToast: false);
      return res;
    } catch (e) {
      onRequestError(e, _model.context);
    }
  }

  Future toComment(Document doc) async {
    final model = _model;
    try {
      /// 富文本对象
      final richTextEntity =
          RichTextEntity(document: Document.fromDelta(doc.toDelta()));

      ///保存最近艾特过的用户
      if (richTextEntity.mentions?.item2 != null) {
        ChannelUtil.instance
            .addGuildAtUserId(model.guildId, richTextEntity.mentions.item2);
      }

      final res = await CircleApi.createComment(model.guildId, model.channelId,
          model.topicId, doc.encode(), model.postId, model.quoteId, '',
          mentions: richTextEntity?.mentions?.item2);
      return res;
    } catch (e, s) {
      logger.severe('动态详情评论错误', e, s);
      onRequestError(e, model.context);
    }
  }

  Future loadList(
      {bool hasExtra = false,
      bool loadMore = false,
      bool initialLoading = true,
      Function onError,
      VoidCallback onComplete}) async {
    final model = _model;
    if (model.isLoading) return;
    model.isLoading = true;
    model.refresh();
    model.requestType = RequestType.normal;
    final controller = model.refreshController;
    controller.resetNoData();
    try {
      if (!loadMore) await refreshContent();
      if (hasExtra)
        await getAllList();
      else
        await getList(loadMore: loadMore, initialLoading: initialLoading);

      ///没有评论时进行延时操作，解决滑动回弹的问题
      if (model.replyList.isEmpty)
        await Future.delayed(const Duration(milliseconds: 500), () => {});
      onComplete?.call();
      if (controller.isLoading) controller.footerMode?.value = LoadStatus.idle;
      if (controller.isRefresh)
        controller.headerMode?.value = RefreshStatus.completed;
    } catch (e) {
      logger.severe('动态列表请求错误:$e');
      onError?.call(e);
      if (controller.isLoading) controller.loadFailed();
      if (controller.isRefresh) controller.refreshFailed();
      if (Http.isNetworkError(e))
        model.requestType = RequestType.netError;
      else
        model.requestType = RequestType.dataError;
      if (e is Exception) onRequestError(e, model.context);
    }
    model.isLoading = false;
    model.refresh();
  }

  Future getList({bool loadMore = false, bool initialLoading = false}) async {
    // final model = _model;
    // final res = await CircleApi.getCommentList(model.channelId, model.topicId,
    //     model.postId, 10, initialLoading ? '0' : model.listId,
    //     showToast: false);
    // if (res == null) return;
    // final bean = CircleDetailBean.fromMap(res);
    // if (bean == null) return;
    // model.circleDetailBean ??= bean;
    // model.circleDetailBean?.post = bean.post;
    // if (bean.listId != '0' && bean.listId != null) {
    //   model.circleDetailBean.listId = bean.listId;
    //   model.noMoreData = false;
    // } else
    //   model.noMoreData = true;
    // model.circleDetailBean.size = bean.size;
    // if (initialLoading && !model.initialError) {
    //   final tempList = [...bean.replys];
    //   model.replyList?.clear();
    //   model.replyList.addAll(tempList ?? []);
    // } else if (loadMore && !model.initialError)
    //   model.replyList.addAll(bean.replys ?? []);
    //
    // model.isLoading = false;
    // model.initialError = false;
  }

  Future getAllList() async {
    // final model = _model;
    // final extra = model.extraData;
    // final postInfoDataModel = CirclePostDataModel.fromNet(
    //     extra.topicId, extra.channelId, extra.postId);
    // await postInfoDataModel.initFromNet();
    // model.data = postInfoDataModel;
    // final content = postInfoDataModel?.postInfoDataModel?.postContent() ??
    //     RichEditorUtils.defaultDoc.encode();
    // if (model.contentList == null || model.contentList.isEmpty)
    //   initContent(content);
    // final res = await CircleApi.getCommentList(
    //     extra.channelId, extra.topicId, extra.postId, 50, model.listId,
    //     showToast: false);
    // if (res == null) return;
    // final bean = CircleDetailBean.fromDataWithMap(res, model.commentMap);
    // if (bean == null) return;
    // model.circleDetailBean ??= bean;
    // model.circleDetailBean?.post = bean.post;
    // if (bean.next != '0' && bean.listId != '0') {
    //   model.circleDetailBean.listId = bean.listId;
    //   model.noMoreData = false;
    // } else
    //   model.noMoreData = true;
    // model.circleDetailBean.size = bean.size;
    //
    // final initialIndex = model.commentMap[extra.commentId];
    // final List<ReplyDetailBean> tempList = [];
    // if (initialIndex != null && initialIndex > 1) {
    //   tempList.addAll(bean.replys.sublist(0, initialIndex - 1));
    //   bean.replys = bean.replys.sublist(initialIndex, bean.replys.length);
    // }
    // if (tempList.isNotEmpty) {
    //   model.needLoadHeadRest = true;
    //   model.tempList = tempList;
    // }
    // if (content != null)
    //   model.quillController = QuillController(
    //       document: Document.fromJson(jsonDecode(content)),
    //       selection: const TextSelection.collapsed(offset: 0));
    // model.refresh();
  }

  Widget _buildDocument({double maxWidth = double.infinity}) {
    return _model.postTypeAvailable
        ? PolyText(
            key: ValueKey(_model.quillController.hashCode),
            document: _model.quillController.document,
            baseStyle: Get.textTheme.bodyText2,
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
        textColor = const Color(0xff3451b1);
        bgColor = primaryColor.withOpacity(0.2);
      } else {
        textColor = primaryColor[600];
      }

      child = RealtimeNickname(
        userId: id,
        prefix: "@",
        suffix: bgColor == null ? " " : "",
        textScaleFactor: 1,
        style: TextStyle(color: textColor),
        tapToShowUserInfo: true,
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
          textColor = Theme.of(Get.context).textTheme.bodyText2.color;

        if (id == ChatTargetsModel.instance.selectedChatTarget.id ||
            Db.userInfoBox.get(Global.user.id).roles.contains(id)) {
          // bgColor = primaryColor.withOpacity(0.2);
          textColor = primaryColor[600];
        }
      } catch (e) {
        text = "@该角色已删除".tr;
      }
    }

    return WidgetSpan(
        baseline: TextBaseline.alphabetic,
        alignment: PlaceholderAlignment.baseline,
        child: Builder(builder: (context) => child));
  }

  TextSpan _buildChannel(MentionEmbed embed) {
    final match = TextEntity.channelLinkPattern.firstMatch(embed.id);
    final id = match.group(1);
    final channel = Db.channelBox.get(id);
    return TextSpan(
      text: " #${channel?.name ?? "尚未加入该频道".tr} ",
      style: TextStyle(color: primaryColor),
      recognizer: TapGestureRecognizer()
        ..onTap = () => ParsedTextExtension.onChannelTap(id),
    );
  }

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
    return Align(
      alignment: Alignment.centerLeft,
      child: child,
    );
  }

// 富文本图片渲染器
  Widget _buildImage(BuildContext context, ImageEmbed embed, double maxWidth) {
    final content = _model?.data?.postInfoDataModel?.postContent() ??
        RichEditorUtils.defaultDoc.encode();
    final doc = Document.fromJson(jsonDecode(content));
    final medias = doc.imageAndVideoEmbeds;
    final imageSize = _getEmbedSize(_getSizeByDefault(embed.width, 350),
        _getSizeByDefault(embed.height, 200),
        maxWidth: maxWidth);
    final screenSize = MediaQuery.of(context).size;
    return GestureDetector(
      onTap: () {
        if (OrientationUtil.portrait) {
          final index = medias.indexWhere((element) {
            return element is ImageEmbed && element.source == embed.source;
          });
          showImageDialog(context,
              items: medias.map((e) {
                bool isImage;
                String url;

                if (e is ImageEmbed) {
                  isImage = true;
                  url = e.source;
                } else if (e is VideoEmbed) {
                  isImage = false;
                  url = e.source;
                }
                return GalleryItem(
                  url: url,
                  id: 'tag: $e',
                  isImage: isImage,
                  holderUrl: url,
                );
              }).toList(),
              index: max(index, 0));
        } else
          showWebImageDialog(
            context,
            url: embed.source,
            width: embed.width,
            height: embed.height,
          );
      },
      child: Container(
          width: imageSize.item1,
          height: imageSize.item2,
          margin: const EdgeInsets.symmetric(vertical: 4),
          color: Theme.of(context).scaffoldBackgroundColor,
          child: ContainerImage(
            embed.source,
            radius: 4,
            width: screenSize.width,
            thumbWidth: screenSize.width.toInt() * 2,
            fit: BoxFit.cover,
            cacheManager: CircleCachedManager.instance,
          )),
    );
  }

  Widget _buildVideo(BuildContext context, VideoEmbed embed, double maxWidth) {
    final content = _model?.data?.postInfoDataModel?.postContent() ??
        RichEditorUtils.defaultDoc.encode();
    final doc = Document.fromJson(jsonDecode(content));
    final medias = doc.imageAndVideoEmbeds;
    final thumbUrl = embed.thumbUrl;
    final duration = embed.duration;
    final url = embed.source;
    final videoSize = _getEmbedSize(
      _getSizeByDefault(embed.width, 350),
      _getSizeByDefault(embed.height, 200),
      maxWidth: maxWidth,
    );
    final screenSize = MediaQuery.of(context).size;
    if (kIsWeb) {
      return Container(
          width: max(videoSize.item1.toDouble(), 210),
          height: videoSize.item2,
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: WebVideoPlayer(
            videoUrl: url,
            thumbUrl: thumbUrl,
            duration: duration,
            padding: videoSize.item1 < 210
                ? (210 - videoSize.item1.toDouble()) / 2
                : 0,
          ));
    }

    return GestureDetector(
      onTap: () {
        final index = medias.indexWhere((element) {
          return element is VideoEmbed && element.source == embed.source;
        });
        showImageDialog(context,
            items: medias.map((e) {
              bool isImage;
              String url;

              if (e is ImageEmbed) {
                isImage = true;
                url = e.source;
              } else if (e is VideoEmbed) {
                isImage = false;
                url = e.source;
              }
              return GalleryItem(
                url: url,
                id: 'tag: $e',
                isImage: isImage,
                holderUrl: thumbUrl,
              );
            }).toList(),
            index: max(index, 0));
      },
      child: Container(
          width: videoSize.item1.toDouble(),
          height: videoSize.item2.toDouble(),
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: VideoWidget(
            borderRadius: 4,
            url: url,
            backgroundColor: const Color.fromARGB(255, 0xf0, 0xf1, 0xf2),
            duration: duration,
            child: ContainerImage(
              thumbUrl,
              radius: 4,
              width: screenSize.width,
              thumbWidth: screenSize.width.toInt() * 2,
              fit: BoxFit.cover,
              cacheManager: CircleCachedManager.instance,
            ),
          )),
    );
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

  ///value为空或0时，返回defaultValue
  num _getSizeByDefault(num value, num defaultValue) {
    return value != null && value > 0 ? value : defaultValue;
  }
}
