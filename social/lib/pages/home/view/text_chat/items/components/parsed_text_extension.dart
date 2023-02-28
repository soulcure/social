import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_parsed_text/flutter_parsed_text.dart';
import 'package:get/get.dart';
import 'package:im/api/data_model/user_info.dart';
import 'package:im/app/modules/circle/controllers/circle_controller.dart';
import 'package:im/app/modules/document_online/info/controllers/doc_link_preview_controller.dart';
import 'package:im/app/modules/task/introduction_ceremony/open_task_introduction_ceremony.dart';
import 'package:im/app/routes/app_pages.dart' as app_pages;
import 'package:im/common/extension/string_extension.dart';
import 'package:im/common/permission/permission_model.dart';
import 'package:im/common/permission/permission_utils.dart';
import 'package:im/db/db.dart';
import 'package:im/dlog/dlog_manager.dart';
import 'package:im/pages/home/json/text_chat_json.dart';
import 'package:im/pages/home/model/chat_index_model.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/pages/tool/url_handler/link_handler_preset.dart';
import 'package:im/themes/default_theme.dart';
import 'package:im/utils/emo_util.dart';
import 'package:im/widgets/realtime_user_info.dart';
import 'package:pedantic/pedantic.dart';

import '../../../../../../global.dart';
import '../../../../../../routes.dart';

enum RefererChannelSource {
  None,

  /// 聊天公屏页
  ChatMainPage,

  /// 圈子链接
  CircleLink,

  /// 消息搜索
  MessageSearch,
}

extension ParsedTextExtension on ParsedText {
  static MatchText matchCusEmoText(BuildContext context, double fontSize) {
    return MatchText(
        pattern: TextEntity.emoPattern.pattern,
        renderWidget: ({text, pattern}) {
          Widget child = Text('$text ');
          if (text.startsWith('[') && text.endsWith(']') && text.length >= 3) {
            final content =
                text.substring(1, text.length - 1).replaceAll(nullChar, '');

            if (EmoUtil.instance.allEmoMap[content] != null) {
              final emoji =
                  EmoUtil.instance.getEmoIcon(content, size: fontSize);

              child = Padding(
                padding: fontSize == 48
                    ? const EdgeInsets.fromLTRB(2, 4, 2, 4)
                    : const EdgeInsets.fromLTRB(2, 2, 2, 2),
                child: emoji,
              );
            }
          }
          return child;
        });
  }

  static MatchText matchCommandText(
      BuildContext context, void Function(String) onTap) {
    return MatchText(
      pattern: TextEntity.commandPattern.pattern,
      style: const TextStyle(color: Colors.blue),
      renderText: ({str, pattern}) {
        final t = TextEntity.commandPattern.firstMatch(str).group(1);
        return {"display": t, "value": str};
      },
      onTap: onTap,
    );
  }

  static MatchText matchAtText(
    BuildContext context, {
    TextStyle textStyle,
    bool tapToShowUserInfo = true,
    bool fetchFromNetIfNotExistLocally = false,
    ShowNameRule showNameRule = ShowNameRule.remarkAndGuild,
    String guildId,
    bool useDefaultColor = true,
    Map<String, bool> userDisabledMap,
    bool plainTextStyle = false,
    Function(String) onTap,
    String prefix = '@',
  }) {
    return MatchText(
      pattern: TextEntity.atPattern.pattern,
      style: TextStyle(color: Get.theme.primaryColor),
      onTap: onTap,
      renderWidget: ({text, pattern}) {
        final match = TextEntity.atPattern.firstMatch(text);
        final id = match.group(2);

        ///60圈子首页的的富文本要求显示为纯文本样式
        if (plainTextStyle)
          return IgnorePointer(
            ignoring: !tapToShowUserInfo,
            child: RealtimeNickname(
              userId: id,
              prefix: prefix ?? "@",
              textScaleFactor: 1,
              showNameRule: showNameRule,
              style: textStyle,
              guildId: guildId,
              tapToShowUserInfo: true,
            ),
          );

        Color textColor;
        Color bgColor;
        Widget child;
        final isRole = match.group(1) == "&";

        if (!isRole) {
          if (useDefaultColor) {
            if (id == Global.user.id) {
              textColor = primaryColor;
              bgColor = primaryColor.withOpacity(0.15);
            } else {
              textColor = Get.theme.primaryColor;
            }
          }
          if (fetchFromNetIfNotExistLocally &&
              !Db.userInfoBox.containsKey(id)) {
            UserInfo.get(id);
          }
          child = RealtimeNickname(
            userId: id,
            prefix: prefix ?? "@",
            suffix: bgColor == null ? " " : "",
            textScaleFactor: 1,
            showNameRule: showNameRule,
            style: (textStyle ?? const TextStyle())
                .copyWith(color: useDefaultColor ? textColor : null),
            tapToShowUserInfo: tapToShowUserInfo,
            guildId: guildId,
          );
          if (!tapToShowUserInfo) {
            child = IgnorePointer(
              child: child,
            );
          }
        } else {
          try {
            final role = PermissionModel.getPermission(
                    ChatTargetsModel.instance.selectedChatTarget.id)
                .roles
                .firstWhere((element) => element.id == id);

            text = "@${role.name}${bgColor != null ? '' : ' '}";

            if (role.color != 0)
              textColor = Color(role.color);
            else
              textColor = Theme.of(context).textTheme.bodyText2.color;

            if (id == ChatTargetsModel.instance.selectedChatTarget.id ||
                Db.userInfoBox.get(Global.user.id).roles.contains(id)) {
              bgColor = primaryColor.withOpacity(0.2);
              textColor = Get.theme.primaryColor;
            }
          } catch (e) {
            text = "@该角色已删除".tr;
          }
        }

        child ??= Text(
          text,
          textScaleFactor: 1,
          style: textStyle?.copyWith(color: textColor),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        );

        /// @自己 有文字背景
        if (bgColor != null) {
          child = IntrinsicWidth(child: buildPrimaryColorBox(child));
        }

        /// 如果没有 builder，一个文本 @同一个人两次会报错，如果采用代码 listen 一次的方式可能解决这个问题
        return Builder(builder: (context) => child);
      },
    );
  }

  static MatchText matchURLText(BuildContext context,
      {TextStyle textStyle,
      RefererChannelSource refererChannelSource = RefererChannelSource.None}) {
    return MatchText(
      pattern: TextEntity.urlPattern.pattern,
      renderWidget: ({text, pattern}) {
        /// TODO(临时方案)：这个flutter web的bug，使用widgetspan进行长文本渲染的时候排版会乱
        final String fileId = DocLinkPreviewController.getFileId(text);
        if (kIsWeb) {
          return GestureDetector(
            onTap: text.isMessageLink
                ? null
                : () {
                    LinkHandlerPreset.common.handle(text);
                  },
            child: GetBuilder<DocLinkPreviewController>(
                init: DocLinkPreviewController(fileId),
                tag: fileId,
                autoRemove: false,
                builder: (c) {
                  return c.buildDocTitle(text);
                }),
          );
        }
        return GestureDetector(
          onTap: text.isMessageLink
              ? null
              : () {
                  LinkHandlerPreset.common
                      .handle(text, refererChannelSource: refererChannelSource);
                },
          child: MouseRegion(
            cursor: !text.isMessageLink
                ? SystemMouseCursors.click
                : SystemMouseCursors.basic,
            child: GetBuilder<DocLinkPreviewController>(
                init: DocLinkPreviewController(fileId),
                tag: fileId,
                autoRemove: false,
                builder: (c) {
                  return c.buildDocTitle(text);
                }),
          ),
        );
      },
    );
  }

  static MatchText matchChannelLink(
    BuildContext context, {
    TextStyle textStyle,
    bool tapToJumpChannel = true,
    bool hasBgColor = true,
    bool fromCircleJump = false,
    RefererChannelSource refererChannelSource = RefererChannelSource.None,
  }) {
    return MatchText(
      pattern: TextEntity.channelLinkPattern.pattern,
      renderWidget: ({text, pattern}) {
        text = text.substring(3, text.length - 1);
        final theme = Theme.of(Global.navigatorKey.currentContext);

        /// TODO: 这个flutter web的bug，使用widgetspan进行长文本渲染的时候排版会乱
        if (kIsWeb) {
          final channel = Db.channelBox.get(text);
          return GestureDetector(
            onTap: () =>
                onChannelTap(text, refererChannelSource: refererChannelSource),
            child: Text(" #${channel?.name ?? "尚未加入该频道".tr} ",
                style: TextStyle(
                  color: channel == null
                      ? theme.textTheme.bodyText1.color
                      : primaryColor,
                )),
          );
        }
        final widget = RealtimeChannelInfo(text, builder: (_, channel) {
          return IntrinsicWidth(
            child: buildPrimaryColorBox(
              Text(
                "#${channel?.name?.breakWord ?? "尚未加入该频道".tr}",
                textScaleFactor: 1,
                style: textStyle ??
                    TextStyle(
                        // 设置fontSize会导致app上横向对齐出现问题（老版本富文本），暂时注释
                        // fontSize: style.fontSize,
                        color: channel == null
                            ? theme.textTheme.bodyText1.color
                            : primaryColor,
                        height: 1.25),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              hasBgColor: hasBgColor,
            ),
          );
        });
        if (tapToJumpChannel)
          return GestureDetector(
            onTap: () async {
              if (fromCircleJump) {
                Get.back();
                await Future.delayed(const Duration(milliseconds: 300));
              }
              unawaited(onChannelTap(text,
                  refererChannelSource: refererChannelSource));
            },
            child: widget,
          );
        return widget;
      },
    );
  }

  static MatchText matchSearchKey(
      BuildContext context, String pattern, TextStyle textStyle) {
    return MatchText(
      pattern: pattern,
      style: textStyle,
      renderText: ({str, pattern}) => {"display": str},
    );
  }

  static Future<void> onChannelTap(String value,
      {RefererChannelSource refererChannelSource =
          RefererChannelSource.None}) async {
    final channel = Db.channelBox.get(value);
    if (channel == null) return;

    /// 如果在圈子内跳转到圈子 topic，没必要重新初始化圈子，直接更新 UI
    if (channel.type == ChatChannelType.guildCircleTopic &&
        Get.isRegistered<CircleController>()) {
      Get.until((route) => route.settings.name == app_pages.Routes.CIRCLE);
      CircleController.to.updateTabIndex(channel.id);
      return;
    }

    final GuildTarget dbTarget = ChatTargetsModel.instance.chatTargets
        .firstWhere((e) => e.id == channel.guildId, orElse: () => null);

    final gt = ChatTargetsModel.instance.selectedChatTarget as GuildTarget;

    /// 这里是处理私信点击对应服务器频道逻辑
    if (gt.id == dbTarget.id) {
      ///是否需要参加入门仪式
      if (OpenTaskIntroductionCeremony.openTaskInterface()) return;
    } else {
      if (dbTarget.userPending && channel.pendingUserAccess == false) {
        // 跳入没有权限的频道，先弹流程,不做跳转动作
        await Routes.pushInsertFlowPage(Get.context,
            tipText: "你没有权限访问此频道，请联系管理员".tr);
        return;
      }
    }
    // 如果没有该频道的权限，先插入流程，再跳转
    final gp = PermissionModel.getPermission(channel.guildId);
    final isVisible = PermissionUtils.isChannelVisible(gp, channel.id);
    if (!isVisible && channel.id != null && channel.id.isNotEmpty) {
      // 跳入没有权限的频道，先弹流程,不做跳转动作
      await Routes.pushInsertFlowPage(Get.context,
          tipText: "你没有权限访问此频道，请联系管理员".tr);
    } else {
      // !!! backHome 必须在前面，否则如果跳链接频道会导致被 pop
      Routes.backHome();
      await ChatTargetsModel.instance.selectChatTargetById(channel.guildId,
          channelId: channel.id, gotoChatView: true);
      channelDataReport(refererChannelSource, channel);
    }
  }

  /// 进入频道相关数据上报
  static void channelDataReport(
      RefererChannelSource refererChannelSource, ChatChannel channel) {
    if (refererChannelSource == RefererChannelSource.None) return;

    String actionEventSubParam;
    switch (refererChannelSource) {
      case RefererChannelSource.None:
        break;
      case RefererChannelSource.ChatMainPage:
        actionEventSubParam = '3';
        break;
      case RefererChannelSource.CircleLink:
        actionEventSubParam = '4';
        break;
      case RefererChannelSource.MessageSearch:
        actionEventSubParam = '5';
        break;
    }

    /// 通过消息中#频道进入频道
    if (actionEventSubParam.hasValue)
      DLogManager.getInstance().customEvent(
          actionEventId: 'click_enter_chatid',
          actionEventSubId: channel.id ?? '',
          actionEventSubParam: actionEventSubParam,
          pageId: 'page_chitchat_chat',
          extJson: {"guild_id": channel.guildId});
  }

  static Widget buildPrimaryColorBox(Widget child, {bool hasBgColor = true}) {
    if (!hasBgColor) {
      return Container(
        alignment: Alignment.center,
        // height: 23,
        margin: const EdgeInsets.fromLTRB(4, 0.5, 4, 0.5),
        padding: const EdgeInsets.symmetric(horizontal: 2),
        // TODO 把圆角改成自动计算 h / 8
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(3),
        ),
        child: child,
      );
    }
    return Container(
      alignment: Alignment.center,
      // height: 23,
      margin: const EdgeInsets.fromLTRB(4, 0.5, 4, 0.5),
      padding: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(3),
        color: primaryColor.withOpacity(0.15),
      ),
      child: child,
    );
  }
}
