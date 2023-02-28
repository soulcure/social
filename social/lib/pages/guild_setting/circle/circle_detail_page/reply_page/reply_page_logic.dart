import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' hide Text;
import 'package:get/get.dart';
import 'package:im/api/circle_api.dart';
import 'package:im/api/entity/circle_comment_bean.dart';
import 'package:im/api/entity/circle_detail_list_bean.dart';
import 'package:im/app/modules/mute/controllers/mute_listener_controller.dart';
import 'package:im/common/extension/operation_extension.dart';
import 'package:im/common/permission/permission.dart';
import 'package:im/core/http_middleware/http.dart';
import 'package:im/core/widgets/button/fade_background_button.dart';
import 'package:im/db/db.dart';
import 'package:im/icon_font.dart';
import 'package:im/pages/guild_setting/circle/circle_detail_page/show_circle_reply_popup.dart';
import 'package:im/pages/guild_setting/circle/circle_detail_page/show_landscape_circle_reply_popup.dart';
import 'package:im/pages/home/json/text_chat_json.dart';
import 'package:im/themes/const.dart';
import 'package:im/utils/universal_platform.dart';
import 'package:im/web/utils/confirm_dialog/message_box.dart';
import 'package:im/web/widgets/web_hover_wrapper/web_hover_wrapper.dart';
import 'package:oktoast/oktoast.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

import '../circle_page.dart';
import '../common.dart';
import '../input_placeholder.dart';
import '../like_button.dart';
import 'reply_page.dart';

class ReplyPageLogic {
  final ReplyPageModel _model;

  ReplyPageLogic(this._model);

  Widget buildLayout() {
    final model = _model;
    final controller = _model.controller;
    final isLoading = model.isLoading;
    final loadingError = model.requestType != RequestType.normal;
    final errorText = model.requestType == RequestType.netError
        ? '网络异常，请检查后重试'.tr
        : '数据异常，请重试'.tr;
    final canShow = !model.initialLoading && !model.initialError;

    return Column(
      children: [
        Expanded(
          child: SmartRefresher(
            enablePullUp: true,
            header: WaterDropHeader(
              complete: Text('刷新完成'.tr),
              failed: Text('加载失败'.tr),
            ),
            onRefresh: () => reloadList(refresh: true),
            footer: CustomFooter(
              height: 108,
              builder: (context, mode) {
                if (isLoading) return sizedBox;
                return footBuilder(context, mode,
                    requestType: model.requestType,
                    onErrorCall: () =>
                        controller.requestLoading(needMove: false),
                    errorWidget: sizedBox,
                    showIdleWidget: !controller.isLoading && model.noMoreData,
                    showDivider: false);
              },
            ),
            controller: controller,
            onLoading: () => reloadList(loadMore: true),
            child: ListView(
              padding: const EdgeInsets.only(bottom: 48),
              controller: model.scrollController,
              children: [
                buildHeader(),
                sizeHeight12,
                const Divider(
                  height: 0.5,
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: replyNumbers(_model.totalReplyNum?.toString() ?? '1'),
                ),
                ...buildReplies(),
                if (isLoading) buildLoadingWidget(model.context),
                if (loadingError)
                  loadingErrorWidget(() {
                    reloadList(loadMore: model.circleDetailBean != null);
                  }, errorText)
              ],
            ),
          ),
        ),
        if (canShow) buildInputLayout()
      ],
    );
  }

  Widget buildHeader() {
    final context = _model.context;
    final theme = Theme.of(context);
    final color1 = theme.textTheme.bodyText2.color;
    final bean = _model.replyDetailBean;
    return Container(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16),
            child: buildAvatar(context, bean.user, bean.comment,
                showLikeButton: false),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, top: 12),
            child: buildRichText(bean.comment.content, context,
                style: TextStyle(color: color1, fontSize: 16, height: 1.25)),
          ),
        ],
      ),
    );
  }

  List<Widget> buildReplies() {
    final model = _model;
    final theme = Theme.of(model.context);
    final color1 = theme.textTheme.bodyText2.color;
    final color2 = theme.textTheme.bodyText1.color;
    final style =
        TextStyle(color: color1, fontWeight: FontWeight.normal, fontSize: 16);
    final replyStyle = TextStyle(fontSize: 16, color: color2);
    final context = model.context;
    final replyList = model.replyList;

    return List.generate(replyList.length, (index) {
      final reply = replyList[index];
      final user = reply.user;
      final localUser = Db.userInfoBox.get(user.userId);
      final comment = reply.comment;
      final replyUser = comment.replyUser;
      final replyToSomeone = replyUser?.userId != null;
      String replyUserName = '';
      if (replyToSomeone)
        replyUserName = Db.userInfoBox.get(replyUser.userId)?.showName() ??
            replyUser.nickname;
      if (replyUserName.isNotEmpty)
        replyUserName = '回复 %s：'.trArgs([replyUserName]);

      final content = comment.content;
      final canDelete = isMyself(user.userId) || hasCircleManagePermission();
      return ValidPermission(
        channelId: model.topicId,
        permissions: [Permission.CIRCLE_REPLY],
        builder: (hasPermission, isOwner) {
          return WebHoverWrapper(
              emojis: [
                IconFont.buffChatMessage,
                if (canDelete) IconFont.buffChatDelete
              ],
              hoverEmojis: [
                IconFont.buffTopicReply,
                if (canDelete) IconFont.buffChatDelete
              ],
              postion: const EdgeInsets.only(right: 8, top: 8),
              callback: (index) {
                if (index == 0) {
                  if (MuteListenerController.to.isMuted) {
                    // 是否被禁言
                    showToast('你已被禁言，无法操作'.tr);
                    return;
                  }
                  if (!hasPermission && !isOwner) {
                    showToast('你没有此动态的回复权限'.tr);
                    return;
                  }
                  // 话题回复 点击
                  final innerHintText = '回复 %s'.trArgs([localUser.showName()]);
                  showCircleReplyPopup(
                    context,
                    guildId: comment.guildId,
                    channelId: model.channelId,
                    hintText: innerHintText,
                    onReplySend: (doc) async {
                      final comment = reply.comment;
                      await onReplySend(comment, doc, reply.user,
                          quote1: model.commentId, quote2: comment.commentId);
                    },
                    commentId: comment?.commentId,
                  );
                } else if (index == 1) {
                  // 删除
                  showWebMessageBox(
                      title: '提示'.tr,
                      content: '是否删除该回复'.tr,
                      onConfirm: () async {
                        try {
                          await CircleApi.deleteReply(comment.commentId,
                              comment.postId, comment.level?.toString() ?? '1',
                              toast: false);
                          replyList.removeAt(index);
                          model.removeTotalReplyNum();
                          needRefreshWhenPop = true;
                          updateList();
                          model.refresh();
                          Get.back();
                        } catch (e) {
                          showToast('操作失败'.tr);
                        }
                      });
                }
              },
              builder: (context, hover) {
                return FadeBackgroundButton(
                  onTap: () {
                    if (MuteListenerController.to.isMuted) {
                      // 是否被禁言
                      showToast('你已被禁言，无法操作'.tr);
                      return;
                    }

                    if (!hasPermission && !isOwner) {
                      showToast('你没有此动态的回复权限'.tr);
                      return;
                    }
                    final innerHintText =
                        '回复 %s'.trArgs([localUser.showName()]);
                    showCircleReplyPopup(
                      context,
                      guildId: comment.guildId,
                      channelId: model.channelId,
                      hintText: innerHintText,
                      onReplySend: (doc) async {
                        final comment = reply.comment;
                        await onReplySend(comment, doc, reply.user,
                            quote1: model.commentId, quote2: comment.commentId);
                      },
                      commentId: comment?.commentId,
                    );
                  },
                  onLongPress: () {
                    final isOwner = hasCircleManagePermission();
                    final userName = localUser.showName();
                    final content = comment.content;
                    final document = Document.fromJson(jsonDecode(content));
                    final list = document.toDelta().toList();
                    final text = getAllText(list);
                    final myself = isMyself(user.userId);
                    if (isOwner || myself)
                      onSettingPressed(
                          context, comment.commentId, comment.postId,
                          level: comment.level?.toString() ?? '2',
                          onDelete: () {
                        replyList.removeAt(index);
                        model.removeTotalReplyNum();
                        needRefreshWhenPop = true;
                        updateList();
                        // removeParentList(comment.commentId);
                        model.refresh();
                      }, hintText: popHintText(userName, text));
                  },
                  tapDownBackgroundColor: tapBgColor,
                  backgroundColor: hover
                      ? const Color(0xFFDEE0E3)
                      : Theme.of(context).backgroundColor,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16, top: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding:
                                  const EdgeInsets.only(left: 16, right: 16),
                              child: buildAvatar(
                                  context, reply.user, reply.comment,
                                  showLikeButton: false),
                            ),
                            Container(
                              margin: const EdgeInsets.only(
                                  left: 60, right: 20, top: 10),
                              width: double.infinity,
                              child: Text.rich(TextSpan(children: [
                                if (replyUserName.isNotEmpty)
                                  TextSpan(
                                      style: replyStyle, text: replyUserName),
                                WidgetSpan(
                                    child: buildRichText(
                                  content,
                                  context,
                                  padding: EdgeInsets.zero,
                                  style: style.copyWith(
                                      fontWeight: FontWeight.normal),
                                )),
                              ])),

                              // child: Text.rich(
                              //   TextSpan(text: '', children: [
                              //     if (replyUserName.isNotEmpty)
                              //       TextSpan(
                              //           style: replyStyle, text: replyUserName),
                              //     ...buildSpans(text, context, style: style)
                              //   ]),
                              // ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(
                        color: Color(0xffF2F3F5),
                        height: 0.5,
                      ),
                    ],
                  ),
                );
              });
        },
      );
    });
  }

  ///当前页面做删除操作，父页面也删除
  void removeParentList(String commentId) {
    final list = _model.replyDetailBean.comment.replayList;
    if (list == null || list.isEmpty) return;
    int i = 0;
    while (i < list.length) {
      final cur = list[i];
      if (cur.comment.commentId == commentId) {
        list.removeAt(i);
        break;
      }
      i++;
    }
  }

  Widget buildInputLayout() {
    final model = _model;
    final context = model.context;
    final theme = Theme.of(context);
    final dividerColor = theme.dividerColor;
    final comment = model.replyDetailBean.comment;
    final likeByMyself = comment.liked == '1';
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
              channelId: comment.topicId,
              permissions: [Permission.CIRCLE_REPLY],
              builder: (hasPermission, isOwner) {
                return InputPlaceholder(
                  pageContext: _model.context,
                  guildId: comment.guildId,
                  channelId: comment.channelId,
                  hasPermission: hasPermission || isOwner,
                  onReplySend: (doc) async {
                    final user = model.replyDetailBean.user;
                    await onReplySend(comment, doc, user,
                        quote1: model.commentId, needInsertReplyUser: false);
                  },
                  commentId: model.commentId,
                );
              },
            )),
            ValidPermission(
                channelId: comment.topicId,
                permissions: [Permission.CIRCLE_ADD_REACTION],
                builder: (hasPermission, isOwner) {
                  return CircleAniLikeButton(
                    liked: likeByMyself,
                    count: model.totalLikes,
                    hasPermission: hasPermission || isOwner,
                    onLikeChange: (value, likeId) {
                      if (value) {
                        comment.liked = '1';
                        addTotalLike(comment);
                      } else {
                        comment.liked = '0';
                        removeTotalLike(comment);
                      }
                      if (likeId.isNotEmpty) comment.likeId = likeId;
                      model.refresh();
                    },
                    postData: PostData(
                        guildId: comment.guildId,
                        channelId: comment.channelId,
                        topicId: comment.topicId,
                        postId: comment.postId,
                        t: 'comment',
                        likeId: comment.likeId,
                        commentId: comment.commentId),
                    requestError: (code) {
                      if (code == postNotFound) {
                        showToast(postNotFoundToast);
                        needRefreshWhenPop = true;
                        Future.delayed(const Duration(seconds: 1), () {
                          needRefreshWhenPop = true;
                          Navigator.of(context).pop(true);
                          Navigator.of(context).pop(true);
                        });
                      } else if (code == commentNotFound) {
                        showToast(postNotFoundToast);
                        Future.delayed(const Duration(seconds: 1), () {
                          Navigator.of(context).pop(true);
                        });
                      }
                    },
                  );
                })
          ],
        ),
      ),
    );
  }

  void addTotalLike(CommentBean bean) {
    bean.likeTotal ??= 0;
    bean.likeTotal++;
    final localBean = _model.circleDetailBean?.item?.comment;
    localBean?.likeTotal ??= 0;
    localBean?.likeTotal++;
  }

  void removeTotalLike(CommentBean bean) {
    bean.likeTotal ??= 1;
    bean.likeTotal--;
    final localBean = _model.circleDetailBean?.item?.comment;
    localBean?.likeTotal ??= 1;
    localBean?.likeTotal--;
  }

  Future onReplySend(CommentBean comment, Document doc, UserBean user,
      {String quote2 = '',
      String quote1,
      bool needInsertReplyUser = true}) async {
    final model = _model;
    final res = await toComment(comment, doc, quote1: quote1, quote2: quote2);
    final replyList = model.replyList;
    final listLength = replyList.length;
    final hasMore = model.totalReplyNum > listLength;
    if (res == null) return;
    final resultBean = CircleCommentBean.fromMap(res);
    if (needInsertReplyUser) resultBean.replyUser = user;
    if (needInsertReplyUser) resultBean.replyUserId = user.userId;
    final replyDetailBean = CircleCommentBean.toReplyDetailBean(resultBean);
    if (!hasMore) replyList.insert(listLength, replyDetailBean);
    model.addTotalReplyNum();
    needRefreshWhenPop = true;
    if (!hasMore) model.listId = replyList.last.comment.commentId;
    updateList();
    model.refresh();
  }

  void initState() {
    _model.scrollController.addListener(_onScroll);
    reloadList(initial: true);
  }

  void _onScroll() {
    final model = _model;
    final controller = model.scrollController;

    ///这里会导致手机版滑动到底部时，一直重复刷新，需要分别处理
    if (model.curOff == controller.offset) return;
    model.curOff = controller.offset;
    if (UniversalPlatform.isAndroid || UniversalPlatform.isIOS) return;
    if (controller.offset == controller.position.maxScrollExtent &&
        !model.controller.isLoading) {
      model.controller.requestLoading();
    }
  }

  void updateList() {
    final model = _model;
    final list = model.replyDetailBean.comment.replayList;
    final realList = model.circleDetailBean?.replys;
    if (realList != null) {
      list.clear();
      final subLength = realList.length > 3 ? 3 : realList.length;
      final tempList = realList
          .sublist(0, subLength)
          .map((e) => ReplyDetailBean(e.comment, e.user))
          .toList();
      list.addAll(tempList);
    }
  }

  Future getList({
    bool loadMore = false,
    bool initialLoading = false,
  }) async {
    final model = _model;
    final res = await CircleApi.getReplyList(
        model.commentId, model.postId, 10, initialLoading ? '0' : model.listId,
        showToast: false);
    if (res == null) return;
    final bean = CircleDetailBean.fromMap(res);
    if (bean == null) return;

    model.circleDetailBean ??= bean;
    model.circleDetailBean?.item = bean.item;
    if (bean.listId != '0' && bean.listId != null) {
      model.circleDetailBean.listId = bean.listId;
      model.noMoreData = true;
    } else
      model.noMoreData = false;
    model.circleDetailBean.size = bean.size;
    if (initialLoading) {
      model.replyList.clear();
      model.replyList.addAll([...bean.replys ?? []]);
    } else if (loadMore) model.replyList.addAll([...bean.replys ?? []]);
    model.refresh();
  }

  Future reloadList({
    bool loadMore = false,
    bool refresh = false,
    bool initial = false,
  }) async {
    final model = _model;
    model.requestType = RequestType.normal;
    if (model.isLoading) return;
    model.isLoading = true;
    final controller = model.controller;
    controller.resetNoData();
    try {
      await getList(loadMore: loadMore, initialLoading: refresh);
      if (controller.isRefresh) controller.refreshCompleted();
      if (controller.isLoading) controller.loadComplete();
      model.initialError = false;
    } catch (e) {
      if (Http.isNetworkError(e))
        model.requestType = RequestType.netError;
      else
        model.requestType = RequestType.dataError;
      if (initial) model.initialError = true;
      onRequestError(e, model.context);
      if (controller.isRefresh) controller.refreshFailed();
      if (controller.isLoading) controller.loadFailed();
    }
    model.isLoading = false;
    model.initialLoading = false;
    model.refresh();
  }

  // ignore: type_annotate_public_apis
  void onRequestError(e, BuildContext context) {
    if (e is RequestArgumentError && e.code == postNotFound) {
      showToast(postNotFoundToast);
      Future.delayed(const Duration(seconds: 1), () {
        needRefreshWhenPop = true;
        Get.back();
        Get.back();
      });
    }
  }

  Future toComment(CommentBean comment, Document doc,
      {String quote2 = '', String quote1}) async {
    try {
      /// 富文本对象
      final richTextEntity =
          RichTextEntity(document: Document.fromDelta(doc.toDelta()));

      final res = await CircleApi.createComment(
          comment.guildId,
          comment.channelId,
          comment.topicId,
          doc.encode(),
          comment.postId,
          quote1 ?? comment.commentId,
          quote2,
          mentions: richTextEntity?.mentions?.item2);
      return res;
    } catch (e) {
      onRequestError(e, _model.context);
    }
  }
}
