import 'package:flutter/widgets.dart';
import 'package:im/common/extension/string_extension.dart';
import 'package:im/dlog/dlog_manager.dart';
import 'package:im/global.dart';
import 'package:im/loggers.dart';
import 'package:im/widgets/share_link_popup/share_link_popup.dart';

class ShareLinkReportManager {
  /// 直播分享上报日志行为(正在直播与直播回放)
  ///
  /// 其中参数从[liveLink]中获取到直播相关信息，需要指明[optContent]即分享的目的地，
  /// 目的地值为：
  /// 1.copy_link = 复制链接
  /// 2.fanbook_friend = 分享好友/私信最近(包括机器人)
  /// 3.wechat  = 微信
  /// 4.wechat_moments = 朋友圈
  static void liveBehavior(
      String link, String optContent, ShareLinkType linkType) {
    if (linkType != ShareLinkType.live &&
        linkType != ShareLinkType.livePlayback) return;
    if (!link.hasValue) return;
    Map<String, List<String>> queryParamsMap = {};
    try {
      queryParamsMap = Uri.parse(link).queryParametersAll ?? {};
    } catch (e) {
      debugPrint(e.toString());
      return;
    }
    final roomId = queryParamsMap['roomid']?.first ?? '';
    final guildId = queryParamsMap['guildId']?.first ?? '';
    final channelId = queryParamsMap['channelId']?.first ?? '';
    if (!roomId.hasValue || !guildId.hasValue || !channelId.hasValue) {
      debugPrint('直播分享日志上报时，解析直播相关参数失败');
      return;
    }

    const logType = 'dlog_app_audio_user_behavior_fb';
    final optType = linkType == ShareLinkType.live
        ? 'audio_share_success'
        : 'audio_share_success_playback';
    final Map exJson = {
      "guild_id": guildId,
      "audio_log_type": 3,
      "opt_type": optType,
      "channel_id": channelId,
      "room_id": roomId,
      "opt_content": optContent,
      "user_type": "${Global.user.id.hasValue ? 1 : 0}",
    };
    try {
      DLogManager.getInstance()
          .extensionEvent(logType: logType, extJson: exJson);
    } catch (e) {
      logger.warning(e);
    }
  }
}
