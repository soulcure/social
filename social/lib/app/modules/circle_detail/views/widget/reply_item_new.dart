import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' hide Text;
import 'package:get/get.dart';
import 'package:im/api/circle_api.dart';
import 'package:im/api/data_model/user_info.dart';
import 'package:im/api/entity/circle_detail_list_bean.dart';
import 'package:im/app/modules/circle_detail/controllers/circle_detail_controller.dart';
import 'package:im/app/modules/circle_detail/views/widget/circle_detail_comment_item.dart';
import 'package:im/app/modules/mute/controllers/mute_listener_controller.dart';
import 'package:im/common/permission/permission.dart';
import 'package:im/core/widgets/button/fade_background_button.dart';
import 'package:im/db/db.dart';
import 'package:im/global.dart';
import 'package:im/icon_font.dart';
import 'package:im/pages/guild_setting/circle/circle_detail_page/show_portrait_circle_reply_popup.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/themes/const.dart';
import 'package:im/themes/default_theme.dart';
import 'package:im/utils/orientation_util.dart';
import 'package:im/web/utils/confirm_dialog/message_box.dart';
import 'package:im/web/widgets/web_hover_wrapper/web_hover_wrapper.dart';
import 'package:intl/intl.dart';
import 'package:oktoast/oktoast.dart';

import '../../../../../pages/guild_setting/circle/circle_detail_page/common.dart';
import '../../../../../pages/guild_setting/circle/circle_detail_page/like_button.dart';
import '../../../../../pages/guild_setting/circle/circle_detail_page/show_circle_reply_popup.dart';

class ReplyItem extends StatelessWidget {
  final List<ReplyDetailBean> detailList;
  final int index;
  final CircleDetailController controller;

  const ReplyItem(this.detailList, this.index, {Key key, this.controller})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bean = detailList[index];
    // print('===hwh index = $index');
    final comment = bean.comment;
    final likeByMyself = comment.liked == '1';
    final child = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (index == 0) sizeHeight20,
        _wrapGesture(
            child: CircleDetailCommentItem(
                bean.user, comment, detailList[index].comment.content,
                likeButton: _likeButton(likeByMyself, comment)),
            context: context),
        if (OrientationUtil.landscape) sizeHeight8,
        if (OrientationUtil.portrait) sizeHeight16,
        _replyContent(context),
        // sizeHeight6,
        Divider(
          indent: (detailList.length - 1 == index) ? 0 : 60,
          height: 1,
        ),
      ],
    );
    final padding = EdgeInsets.only(top: index == 0 ? 0 : 16);
    if (comment.commentId == controller.jumpTargetId) {
      ///跳转到某条回复时，展示动画
      return Obx(
        () => Container(
          padding: padding,
          color: controller.jumpAnimColor.value,
          child: child,
        ),
      );
    } else {
      return Container(
        padding: padding,
        child: child,
      );
    }
  }

  Widget _likeButton(bool likeByMyself, CommentBean comment) {
    return ValidPermission(
        channelId: controller.topicId,
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
                _addTotalLike(comment);
              } else {
                comment.liked = '0';
                _removeTotalLike(comment);
              }
              if (likeId.isNotEmpty) comment.likeId = likeId;
              controller.update();
            },
            requestError: (code) {
              if (code == postNotFound) {
                showToast(postNotFoundToast);
                Future.delayed(
                    const Duration(seconds: 1), () => Get.back(result: true));
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

  void _addTotalLike(CommentBean bean) {
    bean.likeTotal ??= 0;
    bean.likeTotal++;
  }

  void _removeTotalLike(CommentBean bean) {
    bean.likeTotal ??= 1;
    bean.likeTotal--;
  }

  String getTime(String time) {
    return DateFormat("HH:mm").format(
        DateTime.fromMillisecondsSinceEpoch(int.parse(time) * 1000).toLocal());
  }

  /// 显示回复富文本输入
  void _showReplyRichInputDialog(
    BuildContext context,
    CommentBean commentBean,
    UserBean user, {
    List<ReplyDetailBean> replayList,
    bool needInsertReplyUser = true,
    bool preventDuplicates,
  }) {
    final localUser = Db.userInfoBox?.get(user.userId);

    final hintText =
        '回复 ${localUser?.showName(guildId: controller.guildId) ?? user.nickname}';
    showCircleReplyPopup(
      context,
      guildId: controller.guildId,
      channelId: controller.channelId,
      hintText: hintText,
      // onReplySend: (doc) => controller.onCommentReplySend(
      //     commentBean, doc, user, index,
      //     replayList: replayList, needInsertReplyUser: needInsertReplyUser),
      commentId: commentBean?.commentId,
    );
  }

  Widget _wrapGesture({Widget child, BuildContext context}) {
    final cur = detailList[index];
    final user = cur.user;
    final comment = cur.comment;
    final localUser = Db.userInfoBox?.get(user.userId);
    // TODO 代码重复
    final canDelete = user.userId == Global.user?.id ||
        hasCircleManagePermission(guildId: comment.guildId);
    return ValidPermission(
      channelId: controller.topicId,
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
              if (MuteListenerController.to.isMuted &&
                  !GlobalState.isDmChannel) {
                // 是否被禁言
                showToast('你已被禁言，无法操作'.tr);
                return;
              }
              // 点击 话题回复 并且得有回复权限
              if (!hasPermission && !isOwner) {
                showToast('你没有此动态的回复权限'.tr);
                return;
              }

              _showReplyRichInputDialog(context, comment, user,
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
                      // controller.removeTotalReplyNum(
                      //     value: comment.commentTotal ?? 0);
                      comment.decreaseCommentTotal();
                      controller.needRefreshWhenPop = true;
                      controller.update();
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

                  _showReplyRichInputDialog(context, comment, user,
                      needInsertReplyUser: false, preventDuplicates: false);
                }
              },
              onLongPress: OrientationUtil.portrait
                  ? () {
                      final isMyself = user.userId == Global.user.id;
                      final isOwner =
                          hasCircleManagePermission(guildId: comment.guildId);
                      final userName =
                          localUser?.showName(guildId: comment.guildId) ??
                              user?.nickname;
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
                            // controller.removeTotalReplyNum(
                            //     value: comment.commentTotal ?? 0);
                            comment.decreaseCommentTotal();
                            controller.needRefreshWhenPop = true;
                            controller.update();
                          },
                          isReplyDetailPage: true,
                        );
                    }
                  : null,
              tapDownBackgroundColor: tapBgColor,
              backgroundColor: hover ? Get.theme.scaffoldBackgroundColor : null,
              child: Padding(
                padding: OrientationUtil.portrait
                    ? const EdgeInsets.fromLTRB(16, 0, 16, 0)
                    : const EdgeInsets.fromLTRB(16, 8, 8, 8),
                child: child,
              ),
            );
          },
        );
      },
    );
  }

  Widget _replyContent(BuildContext context) {
    final curBean = detailList[index];
    final list = curBean.comment.replayList;
    final size = list?.length ?? 0;
    final totalNum = curBean.comment.commentTotal ?? 0;
    final hasMore = totalNum > 3 || totalNum > size;
    final isEmpty = list?.isEmpty ?? true;
    if (isEmpty && !hasMore) return sizedBox;
    return replyListWidget(context);
  }

  Widget replyListWidget(BuildContext context) {
    final curBean = detailList[index];
    final list = curBean.comment.replayList;
    final size = list.length;
    final totalNum = curBean.comment.commentTotal ?? 0;
    final hasMore = totalNum > 1 && totalNum > size;
    return Padding(
      padding: const EdgeInsets.only(left: 60, right: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...List.generate(
              size, (index) => _replyDetailItemWidget(context, list, index)),
          if (hasMore)
            FadeBackgroundButton(
              onTap: () {
                _checkAllReply(context, curBean);
              },
              tapDownBackgroundColor: tapBgColor,
              child: Container(
                  padding: const EdgeInsets.only(left: 36, bottom: 12),
                  width: double.infinity,
                  child: Text(
                    '展开剩余 %s条回复'.trArgs([(totalNum - size).toString()]),
                    style: TextStyle(color: primaryColor, fontSize: 13),
                  )),
            )
        ],
      ),
    );
  }

  void _checkAllReply(BuildContext context, ReplyDetailBean curBean) {
    // Routes.pushCircleReplyPage(context, curBean).then((value) {
    //   if (changeNum != 0) controller.addTotalReplyNum(value: changeNum);
    //   // model.refresh();
    //   controller.update();
    // });

    // controller.reloadList(
    //     curBean.comment.commentId, curBean.comment.postId, index,
    //     loadMore: true);
  }

  ///单个楼中楼回复
  Widget _replyDetailItemWidget(
      BuildContext context, List<ReplyDetailBean> replayList, int index) {
    final bean = replayList[index];
    final widget =
        UserInfo.consume(bean.user.userId, builder: (context, user, widget) {
      final comment = bean.comment;
      final replyUser = comment.replyUser;
      final replyToSomeone = replyUser?.userId != null;
      String replyUserName = '';
      // debugPrint('getChat comment: ${replyUser.userId} - ${replyUser.nickname} - ${comment.content}');
      if (replyToSomeone && replyUser.nickname != null)
        replyUserName = replyUser.nickname;
      if (replyUserName.isNotEmpty)
        replyUserName = '@%s：'.trArgs([replyUserName]);
      final userName =
          user?.showName(guildId: controller.guildId) ?? user.nickname;
      // debugPrint('getChat comment: $userName, ${comment.content}');

      final content = comment.content;
      final document = Document.fromJson(jsonDecode(content));
      final list = document.toDelta().toList();
      final text = getAllText(list);
      final canDelete = isMyself(user.userId) ||
          hasCircleManagePermission(guildId: comment.guildId);

      final likeByMyself = comment.liked == '1';
      return ValidPermission(
        channelId: controller.topicId,
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
                if (MuteListenerController.to.isMuted &&
                    !GlobalState.isDmChannel) {
                  // 是否被禁言
                  showToast('你已被禁言，无法操作'.tr);
                  return;
                }
                if (!hasPermission && !isOwner) {
                  showToast('你没有此动态的回复权限'.tr);
                  return;
                }
                // 话题回复 点击
                _showReplyRichInputDialog(context, comment, bean.user,
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
                        // controller.removeTotalReplyNum();
                        controller.update();
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
                    _showReplyRichInputDialog(context, comment, bean.user,
                        replayList: replayList);
                  }
                },
                onLongPress: OrientationUtil.portrait
                    ? () {
                        final myself = isMyself(user.userId);
                        final owner =
                            hasCircleManagePermission(guildId: comment.guildId);
                        if (myself || owner)
                          onSettingPressed(
                              context, comment.commentId, comment.postId,
                              level: comment.level?.toString() ?? '2',
                              onDelete: () {
                            detailList[this.index]
                                .comment
                                ?.decreaseCommentTotal();
                            replayList.removeAt(index);
                            // controller.removeTotalReplyNum();
                            controller.update();
                          },
                              isReplyDetailPage: true,
                              hintText: popHintText(userName, text));
                      }
                    : null,
                tapDownBackgroundColor: tapBgColor,
                // backgroundColor: hover
                //     ? const Color(0xFFDEE0E3)
                //     : Theme.of(context).scaffoldBackgroundColor,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: CircleDetailCommentItem(
                    bean.user,
                    comment,
                    content,
                    likeButton: _likeButton(likeByMyself, comment),
                    replyUserName: replyUserName,
                    replayUserId: replyUser?.userId,
                  ),
                ),
              );
            },
          );
        },
      );
    });
    return widget;
  }

// Future<UserInfo> _userInfoWithUserId(String userId) async {
//   if (Config.kIsCicleWeb || Config.kIsCircleDetailH5) {
//     return null;
//   } else {
//     return UserInfo.get(userId);
//   }
// }
}
