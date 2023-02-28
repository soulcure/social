import 'package:fb_live_flutter/live/api/fblive_provider.dart';
import 'package:fb_live_flutter/live/utils/func/utils_class.dart';

class PlaybackLogUp {
  // dlog_app_audio_user_join_fb
  // "根据指标需求，需上报音视频直播用户参与日志，上报行为场景如下：
  // 1. 用户进入观看直播间回放时上报一条日志：
  // ①进入直播间时opt_type上报joined_playback，同时要带上用户进入直播间的入口，当用户通过直播链接(卡片)进入时join_entrance上报1，当用户通过直播列表页进入时join_entrance上报2
  // 2. 用户退出观看直播间回放时上报一条日志：
  // ①退出直播间时opt_type上报left_palyback【left_playback】，同时上报用户从进入到退出的时间间隔（单位: 秒），即参与时长join_duration
  // 3. 需要区分用户id(user_id) 是否是游客，当用户是游客时user_type上报0，当用户是fanbook app用户时user_type上报1
  // 注：每条行为日志audio_log_type都上报3，为直播日志"

  /*
  * 进入直播间回放日志上报
  * */
  static void playBackEnter(
      bool isFromList, String? roomId, String? serverId, String? channelId) {
    // 1=来自直播列表；2=直播链接（直播卡片）
    final int fromType = isFromList ? 2 : 1;

    fbApi.setSharePref("join_entrance", "$fromType");
    fbApi.setSharePref(
        "join_duration", "${DateTime.now().millisecondsSinceEpoch}");

    // 用户观看直播行为【事件埋点】-进入直播间【参与直播】
    fbApi.extensionEvent(
      extJson: {
        "guild_id": serverId,
        "audio_log_type": 3,
        "opt_type": "joined_playback",
        "channel_id": channelId,
        "room_id": roomId,
        "join_entrance": fromType,
        "user_type": "${strNoEmpty(fbApi.getUserId()) ? 1 : 0}",
      },
      logType: 'dlog_app_audio_user_join_fb',
    );
  }

  /*
  * 退出直播回放日志上报
  * */
  static void liveLeave(String? roomId, String? serverId, String? channelId) {
    final String? fromTypeStr = fbApi.getSharePref("join_entrance");
    int? fromType;
    if (strNoEmpty(fromTypeStr)) {
      fromType = int.parse(fromTypeStr!);
    }

    final String? joinDurationStr = fbApi.getSharePref("join_duration");
    int? joinDuration;
    if (strNoEmpty(joinDurationStr)) {
      final int mel = int.parse(joinDurationStr!);
      final int nowMel = DateTime.now().millisecondsSinceEpoch;
      joinDuration = (nowMel - mel) ~/ 1000;
    }

    fbApi.extensionEvent(
      extJson: {
        "guild_id": serverId,
        "audio_log_type": 3,
        "opt_type": "left_playback",
        "channel_id": channelId,
        "room_id": roomId,
        "join_duration": joinDuration,
        "join_entrance": fromType,
        "user_type": "${strNoEmpty(fbApi.getUserId()) ? 1 : 0}",
      },
      logType: 'dlog_app_audio_user_join_fb',
    );
  }
}
