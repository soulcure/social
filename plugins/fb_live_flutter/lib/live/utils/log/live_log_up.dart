import 'package:fb_live_flutter/live/api/fblive_provider.dart';
import 'package:fb_live_flutter/live/model/room_infon_model.dart';
import 'package:fb_live_flutter/live/utils/func/utils_class.dart';

class LiveLogUp {
  /*
  * 进入直播间日志上报
  * */
  static void liveEnter(
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
        "opt_type": "joined",
        "channel_id": channelId,
        "room_id": roomId,
        "join_entrance": fromType,
        "user_type": "${strNoEmpty(fbApi.getUserId()) ? 1 : 0}",
      },
      logType: 'dlog_app_audio_user_join_fb',
    );
  }

  /*
  * 退出直播日志上报
  * */
  static void liveLeave(String? roomId, RoomInfon roomInfoObject) {
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
        "guild_id": roomInfoObject.serverId,
        "audio_log_type": 3,
        "opt_type": "left",
        "channel_id": roomInfoObject.channelId,
        "room_id": roomId,
        "join_duration": joinDuration,
        "join_entrance": fromType,
        "user_type": "${strNoEmpty(fbApi.getUserId()) ? 1 : 0}",
      },
      logType: 'dlog_app_audio_user_join_fb',
    );
  }

  /*
  * 用户行为日志上报
  * */
  static void userBehavior(String optType,
      {String? optContent, required RoomInfon roomInfoObject}) {
    fbApi.extensionEvent(
      extJson: {
        "guild_id": roomInfoObject.serverId,
        "audio_log_type": 3,
        "opt_type": optType,
        "channel_id": roomInfoObject.channelId,
        "room_id": roomInfoObject.roomId,
        "opt_content": optContent,
        "user_type": "${strNoEmpty(fbApi.getUserId()) ? 1 : 0}",
      },
      logType: 'dlog_app_audio_user_behavior_fb',
    );
  }

/*
* 用户行为事件埋点发送【发送弹幕消息】
* */
  static void send(String msg, RoomInfon roomInfoObject) =>
      userBehavior("send", roomInfoObject: roomInfoObject); // optContent: msg

/*
* 用户行为事件埋点发送【点击货架】
* */
  static void clickShoppingCart(RoomInfon roomInfoObject) =>
      userBehavior("click_shopping_cart", roomInfoObject: roomInfoObject);

/*
* 用户行为事件埋点发送【分享直播】
* */
  static void audioShare(RoomInfon roomInfoObject) =>
      userBehavior("audio_share", roomInfoObject: roomInfoObject);

/*
* 用户行为事件埋点发送【送礼】
* */
  static void giveGifts(
          {String? optContent, required RoomInfon roomInfoObject}) =>
      userBehavior("give_gifs",
          optContent: optContent, roomInfoObject: roomInfoObject);

/*
* 用户行为事件埋点发送【点赞】
* */
  static void audioLike(RoomInfon roomInfoObject) =>
      userBehavior("audio_like", roomInfoObject: roomInfoObject);
}
