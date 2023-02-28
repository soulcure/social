import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' hide Text;
import 'package:get/get.dart';
import 'package:im/api/circle_api.dart';
import 'package:im/api/data_model/user_info.dart';
import 'package:im/api/entity/circle_comment_bean.dart';
import 'package:im/api/entity/circle_detail_list_bean.dart';
import 'package:im/app/modules/mute/controllers/mute_listener_controller.dart';
import 'package:im/common/extension/operation_extension.dart';
import 'package:im/common/extension/string_extension.dart';
import 'package:im/common/permission/permission.dart';
import 'package:im/core/widgets/button/fade_background_button.dart';
import 'package:im/db/db.dart';
import 'package:im/global.dart';
import 'package:im/icon_font.dart';
import 'package:im/pages/guild_setting/circle/circle_detail_page/show_portrait_circle_reply_popup.dart';
import 'package:im/pages/home/json/text_chat_json.dart';
import 'package:im/pages/home/view/text_chat/rich_editor/utils.dart';
import 'package:im/themes/const.dart';
import 'package:im/utils/orientation_util.dart';
import 'package:im/web/utils/confirm_dialog/message_box.dart';
import 'package:im/web/widgets/web_hover_wrapper/web_hover_wrapper.dart';
import 'package:intl/intl.dart';
import 'package:oktoast/oktoast.dart';

import '../../../../routes.dart';
import 'circle_page.dart';
import 'circle_reply_cache.dart';
import 'common.dart';
import 'like_button.dart';
import 'reply_page/reply_page.dart';
import 'show_circle_reply_popup.dart';

class ReplyItem extends StatelessWidget {
  final List<ReplyDetailBean> detailList;
  final int index;
  final CirclePageModel model;

  const ReplyItem(this.detailList, this.index, {Key key, this.model})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bean = detailList[index];
    final comment = bean.comment;
    final likeByMyself = comment.liked == '1';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (index == 0) sizeHeight16,
        _wrapGesture(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                buildAvatar(context, bean.user, comment,
                    likeButton: likeButton(context, likeByMyself, comment)),
                _buildContent(context),
              ],
            ),
            context: context),
        if (OrientationUtil.landscape) sizeHeight8,
        replyContent(context),
        sizeHeight6,
        const Divider(
          height: 0.5,
          color: Color(0xffF2F3F5),
        )
      ],
    );
  }

  Widget likeButton(
      BuildContext context, bool likeByMyself, CommentBean comment) {
    return ValidPermission(
        channelId: model.topicId,
        permissions: [Permission.CIRCLE_ADD_REACTION],
        builder: (hasPermission, isOwner) {
          return CircleAniLikeButton(
            userReplyButton: true,
            padding: const EdgeInsets.fromLTRB(3, 3, 13, 3),
            liked: likeByMyself,
            count: comment.likeTotal,
            iconSize: 18,
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
            requestError: (code) {
              if (code == postNotFound) {
                showToast(postNotFoundToast);
                Future.delayed(const Duration(seconds: 1),
                    () => Navigator.of(context).pop(true));
              } else if (code == commentNotFound) showToast(postNotFoundToast);
            },
            postData: PostData(
                guildId: comment.guildId,
                channelId: comment.channelId,
                topicId: comment.topicId,
                postId: comment.postId,
                t: 'comment',
                likeId: comment.likeId,
                commentId: comment.commentId),
          );
        });
  }

  void addTotalLike(CommentBean bean) {
    bean.likeTotal ??= 0;
    bean.likeTotal++;
  }

  void removeTotalLike(CommentBean bean) {
    bean.likeTotal ??= 1;
    bean.likeTotal--;
  }

  String getTime(String time) {
    return DateFormat("HH:mm").format(
        DateTime.fromMillisecondsSinceEpoch(int.parse(time) * 1000).toLocal());
  }

  /// 显示回复富文本输入
  void showReplyRichInputDialog(
      BuildContext context, CommentBean commentBean, UserBean user,
      {List<ReplyDetailBean> replayList, bool needInsertReplyUser = true}) {
    final localUser = Db.userInfoBox?.get(user.userId);

    final hintText = '回复 ${localUser?.showName() ?? user.nickname}';
    showCircleReplyPopup(
      context,
      guildId: model.guildId,
      channelId: model.channelId,
      hintText: hintText,
      onReplySend: (doc) => onReplySend(commentBean, doc, user,
          replayList: replayList, needInsertReplyUser: needInsertReplyUser),
      commentId: commentBean?.commentId,
    );
  }

  Widget _buildContent(BuildContext context) {
    final cur = detailList[index];
    final comment = cur.comment;
    return Container(
      margin: const EdgeInsets.only(top: 4, bottom: 10, left: 44, right: 20),
      width: double.infinity,
      child: buildRichText(comment.content, context,
          padding: const EdgeInsets.fromLTRB(0, 5, 0, 5),
          style: Theme.of(context).textTheme.bodyText2.copyWith(
                height: 1.25,
                fontSize: 17,
              )),
    );
  }

  Widget _wrapGesture({Widget child, BuildContext context}) {
    final cur = detailList[index];
    final user = cur.user;
    final comment = cur.comment;
    final localUser = Db.userInfoBox?.get(user.userId);
    final totalNum = comment.commentTotal ?? 0;
    final canDelete =
        user.userId == Global.user?.id || hasCircleManagePermission();
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
          callback: (i) {
            if (i == 0) {
              if (MuteListenerController.to.isMuted) {
                // 是否被禁言
                showToast('你已被禁言，无法操作'.tr);
                return;
              }
              // 点击 话题回复 并且得有回复权限
              if (!hasPermission && !isOwner) {
                showToast('你没有此动态的回复权限'.tr);
                return;
              }

              showReplyRichInputDialog(context, comment, user,
                  needInsertReplyUser: false);
            } else if (i == 1) {
              // 删除
              showWebMessageBox(
                  title: '提示'.tr,
                  content: '是否删除该回复'.tr,
                  onConfirm: () async {
                    try {
                      await CircleApi.deleteReply(comment.commentId,
                          comment.postId, comment.level?.toString() ?? '1',
                          toast: false);
                      detailList.removeAt(index);
                      comment.decreaseCommentTotal();
                      model.removeTotalReplyNum(value: totalNum);
                      needRefreshWhenPop = true;
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
                if (OrientationUtil.portrait) {
                  if (MuteListenerController.to.isMuted) {
                    // 是否被禁言
                    showToast('你已被禁言，无法操作'.tr);
                    return;
                  }

                  if (!hasPermission && !isOwner) {
                    showToast('你没有此动态的回复权限'.tr);
                    return;
                  }

                  showReplyRichInputDialog(context, comment, user,
                      needInsertReplyUser: false);
                }
              },
              onLongPress: OrientationUtil.portrait
                  ? () {
                      final isMyself = user.userId == Global.user.id;
                      final isOwner = hasCircleManagePermission();
                      final userName = localUser?.showName() ?? user?.nickname;
                      final content = comment.content;
                      final document = Document.fromJson(jsonDecode(content));
                      final list = document.toDelta().toList();
                      final text = getAllText(list);
                      if (isMyself || isOwner)
                        onSettingPressed(
                          context,
                          comment.commentId,
                          comment.postId,
                          hintText: popHintText(userName, text),
                          level: comment.level?.toString() ?? '1',
                          onDelete: () {
                            detailList.removeAt(index);
                            comment.decreaseCommentTotal();
                            model.removeTotalReplyNum(value: totalNum);
                            needRefreshWhenPop = true;
                            model.refresh();
                          },
                          isReplyDetailPage: true,
                        );
                    }
                  : null,
              tapDownBackgroundColor: tapBgColor,
              backgroundColor: hover
                  ? Theme.of(context).scaffoldBackgroundColor
                  : Theme.of(context).backgroundColor,
              child: Padding(
                padding: OrientationUtil.portrait
                    ? const EdgeInsets.fromLTRB(16, 0, 0, 0)
                    : const EdgeInsets.fromLTRB(16, 8, 8, 8),
                child: child,
              ),
            );
          },
        );
      },
    );
  }

  Widget replyContent(BuildContext context) {
    final theme = Theme.of(context);
    final color1 = theme.scaffoldBackgroundColor;
    final curBean = detailList[index];
    final list = curBean.comment.replayList;
    final size = list?.length ?? 0;
    final totalNum = curBean.comment.commentTotal ?? 0;
    final hasMore = totalNum > 3 || totalNum > size;
    final isEmpty = list?.isEmpty ?? true;
    if (isEmpty && !hasMore) return sizedBox;
    return Padding(
      padding: const EdgeInsets.fromLTRB(60, 0, 16, 10),
      child: CustomPaint(
        painter: CusShape(color: color1),
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 6.75, 10, 6.75),
          width: double.infinity,
          child: replyListWidget(context),
        ),
      ),
    );
  }

  Widget replyListWidget(BuildContext context) {
    final curBean = detailList[index];
    final list = curBean.comment.replayList;
    final size = list.length;
    final totalNum = curBean.comment.commentTotal ?? 0;
    final hasMore = totalNum > 1 && totalNum > size;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...List.generate(
            size, (index) => replyDetailItem(context, list, index)),
        if (hasMore)
          FadeBackgroundButton(
            onTap: () => _checkAllReply(context, curBean),
            tapDownBackgroundColor: tapBgColor,
            child: Container(
                padding: const EdgeInsets.only(top: 6.5),
                width: double.infinity,
                child: Text(
                  '查看全部%s条回复'.trArgs([totalNum.toString()]),
                  style:
                      const TextStyle(color: Color(0xff576B95), fontSize: 14),
                )),
          )
      ],
    );
  }

  void _checkAllReply(BuildContext context, ReplyDetailBean curBean) {
    Routes.pushCircleReplyPage(context, curBean).then((value) {
      if (changeNum != 0) model.addTotalReplyNum(value: changeNum);
      model.refresh();
    });
  }

  Widget replyDetailItem(
      BuildContext context, List<ReplyDetailBean> replayList, int index) {
    return FutureBuilder(
      builder: (ctx, snapShot) {
        if (snapShot.hasData) return snapShot.data;
        return sizedBox;
      },
      future: replyDetailItemWidget(context, replayList, index),
    );
  }

  Future<Widget> replyDetailItemWidget(
      BuildContext context, List<ReplyDetailBean> replayList, int index) async {
    final theme = Theme.of(context);
    final color1 = theme.textTheme.bodyText2.color;
    final color2 = theme.textTheme.bodyText1.color;
    final bean = replayList[index];
    final user = bean.user;
    final localUser = await UserInfo.get(user.userId);
    final comment = bean.comment;
    final replyUser = comment.replyUser;
    final replyToSomeone = replyUser?.userId != null;
    String replyUserName = '';
    if (replyToSomeone)
      replyUserName = (await UserInfo.get(replyUser?.userId))?.showName() ??
          replyUser.nickname;
    if (replyUserName.isNotEmpty)
      replyUserName = '回复 %s：'.trArgs([replyUserName]);
    final style = TextStyle(color: color2, fontSize: 14);
    final userName = localUser?.showName() ?? user.nickname;

    final content = comment.content;
    final document = Document.fromJson(jsonDecode(content));
    final list = RichEditorUtils.formatDelta(document.toDelta()).toList();
    final text = getAllText(list);
    final showName =
        '${localUser?.showName() ?? user.nickname}${replyUserName.isNotEmpty ? ' ' : '：'.tr}';
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
          postion: EdgeInsets.zero,
          callback: (_index) {
            if (_index == 0) {
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
              showReplyRichInputDialog(context, comment, user,
                  replayList: replayList);
            } else if (_index == 1) {
              // 删除
              showWebMessageBox(
                  title: '提示'.tr,
                  content: '是否删除该回复'.tr,
                  onConfirm: () async {
                    try {
                      await CircleApi.deleteReply(comment.commentId,
                          comment.postId, comment.level?.toString() ?? '1',
                          toast: false);
                      detailList[this.index].comment?.decreaseCommentTotal();
                      replayList.removeAt(index);
                      model.removeTotalReplyNum();
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
                if (OrientationUtil.portrait) {
                  if (MuteListenerController.to.isMuted) {
                    // 是否被禁言
                    showToast('你已被禁言，无法操作'.tr);
                    return;
                  }

                  if (!hasPermission && !isOwner) {
                    showToast('你没有此动态的回复权限'.tr);
                    return;
                  }
                  showReplyRichInputDialog(context, comment, user,
                      replayList: replayList);
                }
              },
              onLongPress: OrientationUtil.portrait
                  ? () {
                      final myself = isMyself(user.userId);
                      final owner = hasCircleManagePermission();
                      if (myself || owner)
                        onSettingPressed(
                            context, comment.commentId, comment.postId,
                            level: comment.level?.toString() ?? '2',
                            onDelete: () {
                          detailList[this.index]
                              .comment
                              ?.decreaseCommentTotal();
                          replayList.removeAt(index);
                          model.removeTotalReplyNum();
                          final curReplyBean = detailList[this.index];
                          curReplyBean.comment.commentTotal--;
                          model.refresh();
                        },
                            isReplyDetailPage: true,
                            hintText: popHintText(userName, text));
                    }
                  : null,
              tapDownBackgroundColor: tapBgColor,
              backgroundColor: hover
                  ? const Color(0xFFDEE0E3)
                  : Theme.of(context).scaffoldBackgroundColor,
              child: Container(
                padding: OrientationUtil.portrait
                    ? const EdgeInsets.only(top: 2, bottom: 2)
                    : const EdgeInsets.only(top: 8, bottom: 8),
                alignment: Alignment.centerLeft,
                child: Text.rich(TextSpan(children: [
                  TextSpan(
                    text: '$showName$nullChar',
                    style: TextStyle(color: color1, fontSize: 14),
                  ),
                  if (replyUserName.isNotEmpty)
                    TextSpan(style: style, text: replyUserName),
                  WidgetSpan(
                      child: buildRichText(
                    content,
                    context,
                    padding: EdgeInsets.zero,
                    style: style.copyWith(fontWeight: FontWeight.normal),
                  )),
                ])),

                // child: Text.rich(
                //   TextSpan(
                //       text: '$showName$nullChar',
                //       style: TextStyle(color: color1, fontSize: 14),
                //       children: [
                //         if (replyUserName.isNotEmpty)
                //           TextSpan(style: style, text: replyUserName),
                //
                //         ...buildSpans('$text$nullChar', context,
                //             style: style.copyWith(fontWeight: FontWeight.normal))
                //         // buildRichTextSpan(bean.comment.content, context, style: style),
                //       ]),
                // ),
              ),
            );
          },
        );
      },
    );
  }

  Future onReplySend(CommentBean comment, Document doc, UserBean user,
      {List<ReplyDetailBean> replayList,
      bool needInsertReplyUser = true}) async {
    final hasReply = replayList != null;
    final res = await toComment(comment, doc, hasReply);
    CircleReplyCache().removeCache(comment?.commentId);
    if (res == null) return;
    final resultBean = CircleCommentBean.fromMap(res);
    if (needInsertReplyUser) resultBean.replyUser = user;
    if (needInsertReplyUser) resultBean.replyUserId = user.userId;
    final replyDetailBean =
        CircleCommentBean.toCommentReplyDetailBean(resultBean);
    comment.replayList ??= [];
    final list = replayList ?? comment.replayList;
    list.insert(list.length, replyDetailBean);
    detailList[index].comment.increaseCommentTotal();
    model.addTotalReplyNum();
    needRefreshWhenPop = true;
    model.refresh();
  }

  Future toComment(CommentBean comment, Document doc, bool hasReply) async {
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
          hasReply ? detailList[index].comment.commentId : comment.commentId,
          hasReply ? comment.commentId : '',
          mentions: richTextEntity?.mentions?.item2);
      return res;
    } catch (e) {
      onRequestError(e, model.context);
    }
  }
}

class CusShape extends CustomPainter {
  final double borderRadius;
  final Color color;

  CusShape({
    this.borderRadius = 4,
    this.color = Colors.grey,
  });

  @override
  void paint(Canvas canvas, Size size) {
    ///左上角圆角
    final Rect rect1 = Rect.fromLTRB(0, size.height, size.width, 0);
    final RRect r1 =
        RRect.fromRectAndRadius(rect1, Radius.circular(borderRadius));

    final Paint paint = Paint();
    paint.color = color;
    paint.strokeWidth = 0;

    final Path path = Path();
    path.moveTo(0, 0);
    path.addRRect(r1);
    path.lineTo(12, 0);
    path.lineTo(18, -6);
    path.lineTo(24, 0);
    path.lineTo(size.width - borderRadius, 0);
    path.addRRect(r1);
    path.lineTo(size.width, size.height - borderRadius);
    path.addRRect(r1);
    path.lineTo(borderRadius, size.height);
    path.addRRect(r1);
    path.close();
    if (size.width == 0 || size.height == 0) {
      canvas.drawPath(Path(), paint);
    } else
      canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
