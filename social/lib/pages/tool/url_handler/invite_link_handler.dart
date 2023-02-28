import 'dart:async';

import 'package:get/get.dart';
import 'package:im/api/invite_api.dart';
import 'package:im/app/modules/home/controllers/home_scaffold_controller.dart';
import 'package:im/common/extension/future_extension.dart';
import 'package:im/common/extension/string_extension.dart';
import 'package:im/core/config.dart';
import 'package:im/dlog/dlog_manager.dart';
import 'package:im/pages/guild_setting/guild/quit_guild.dart';
import 'package:im/pages/home/model/chat_index_model.dart';
import 'package:im/pages/home/view/text_chat/items/components/parsed_text_extension.dart';
import 'package:im/pages/tool/url_handler/link_handler.dart';
import 'package:im/routes.dart';
import 'package:im/utils/invite_code/invite_code_util.dart';
import 'package:oktoast/oktoast.dart';

enum JoinedBehavior {
  jump,
  doNothing,
}

class InviteLinkHandler extends LinkHandler {
  final Map inviteInfo;
  final JoinedBehavior joinedBehavior;
  final bool showErrorToast;

  const InviteLinkHandler(
      {this.inviteInfo,
      this.joinedBehavior = JoinedBehavior.jump,
      this.showErrorToast = true});

  @override
  bool match(String url) {
    try {
      final uri = Uri.parse(url);
      if (uri.pathSegments.length != 1) return false;
      if (uri.host == Uri.parse(Config.webLinkPrefix).host) {
        return RegExp(r"\w{8,}").hasMatch(uri.pathSegments[0]);
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  @override
  Future handle(String url, {RefererChannelSource refererChannelSource}) async {
    final code = _getCode(url);
    if (code == null) {
      showToast('无效的邀请链接'.tr);
      return;
    }
    final postId = _getCirclePostId(url);
    await handleWithCode(code,
        postId: postId, refererChannelSource: refererChannelSource);
  }

  Future handleWithCode(String code,
      {String postId, RefererChannelSource refererChannelSource}) async {
    /// TODO(jp@jin.dev): 2022/6/1 处理邀请码异常的问题，应该从源头判断是否符合规范
    final Map info = inviteInfo ??
        await InviteApi.getCodeInfo(
          code,
          showDefaultErrorToast: showErrorToast,
        );
    info.addIf(postId != null, 'post_id', postId);

    /// 检查失效
    if (info == null || info.keys.toList().isEmpty) {
      if (showErrorToast) showToast('邀请链接已失效'.tr);
      return;
    }

    final joined = _hasJoined(info['guild_id']);
    final isExpire = _isExpired(info);

    // 检查过期
    if (isExpire) {
      if (showErrorToast) showToast('请使用正确的邀请码'.tr);
      return;
    }

    if (joined) {
      switch (joinedBehavior) {

        /// 与产品确认合并已加入业务逻辑，统一跳转并土司弹窗提醒
        case JoinedBehavior.jump:
          if (postId != null) {
            ///修复：从外部跳转至圈子某个圈子频道时页面灰屏
            Routes.backHome();
            await HomeScaffoldController.to.gotoWindow(0);
            final chatTarget = ChatTargetsModel.instance
                .getChatTarget(info['guild_id'] as String);
            if (chatTarget != null) {
              //选中服务器并选中默认频道
              await ChatTargetsModel.instance.selectChatTarget(chatTarget,
                  channel: chatTarget.defaultChannel);
            }
            await Future.delayed(200.milliseconds);
          }
          gotoJoinedGuild(
                  guildId: info['guild_id'], channelId: info['channel_id'])
              .unawaited;
          showToast('已加入服务器'.tr);
          channelDataReport(info['guild_id'], info['channel_id'],
              refererChannelSource: refererChannelSource);
          break;
        case JoinedBehavior.doNothing:
          break;
      }
    } else {
      handleNotJoin(inviteInfo: info, code: code, isExpire: isExpire);
    }
  }

  /// 进入频道相关数据上报
  void channelDataReport(String guildId, String channelId,
      {RefererChannelSource refererChannelSource = RefererChannelSource.None}) {
    if (guildId.noValue ||
        channelId.noValue ||
        channelId == '0' ||
        refererChannelSource == RefererChannelSource.None) return;

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

    if (actionEventSubParam.hasValue)
      DLogManager.getInstance().customEvent(
          actionEventId: 'click_enter_chatid',
          actionEventSubId: channelId ?? '',
          actionEventSubParam: actionEventSubParam,
          pageId: 'page_chitchat_chat',
          extJson: {"guild_id": guildId ?? ''});
  }

  String _getCode(String url) {
    final index = url.lastIndexOf('/') + 1;
    final qIndex = url.lastIndexOf('?');
    if (index > 0 && index <= url.length) {
      final lastIndex =
          qIndex > index && qIndex < url.length ? qIndex : url.length;
      return url.substring(index, lastIndex);
    }
    return null;
  }

  // 获取来源圈子id
  String _getCirclePostId(String url) {
    return Uri.parse(url).queryParameters['postId'];
  }

  bool _hasJoined(String guildId) {
    return ChatTargetsModel.instance.chatTargets.any((e) => e.id == guildId);
  }

  bool _isExpired(Map inviteInfo) {
    if (inviteInfo['number'] == '-1') {
      return inviteInfo['expire_time'] == '0';
    } else {
      return inviteInfo['expire_time'] == '0' ||
          inviteInfo['number'] == '0' ||
          inviteInfo['is_used'] == '1';
    }
  }

  void handleNotJoin({Map inviteInfo, String code, bool isExpire}) {
    InviteCodeUtil.setInviteCode2(code);
    Routes.pushAcceptInvitePage(
      inviteInfo['guild_id'],
      inviteInfo['inviter_id'],
      code,
      channelId: inviteInfo['channel_id'],
      postId: inviteInfo['post_id'],
      isExpire: isExpire,
    ).unawaited;
  }
}
