import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/api/data_model/user_info.dart';
import 'package:im/api/entity/user_config.dart';
import 'package:im/api/user_api.dart';
import 'package:im/app/modules/circle_detail/controllers/circle_detail_controller.dart';
import 'package:im/app/modules/direct_message/controllers/direct_message_controller.dart';
import 'package:im/app/modules/friend_apply_page/controllers/friend_apply_page_controller.dart';
import 'package:im/app/modules/friend_list_page/controllers/friend_list_page_controller.dart';
import 'package:im/app/modules/redpack/redpack_item/redpack_util.dart';
import 'package:im/common/extension/string_extension.dart';
import 'package:im/db/db.dart';
import 'package:im/hybrid/jpush_util.dart';
import 'package:im/pages/guild_setting/circle/circle_detail_page/circle_page.dart';
import 'package:im/pages/home/json/text_chat_json.dart';
import 'package:im/pages/home/model/chat_index_model.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/quest/fb_quest_config.dart';
import 'package:im/services/sp_service.dart';
import 'package:pedantic/pedantic.dart';

import '../global.dart';
import '../loggers.dart';

void _onError(e) {
  logger.severe("Preparing home error", e);
}

String initialChannelId;

void checkPushNotificationJump() {
  if (!JPushUtil.hasAppLaunchParameters()) return;
  try {
    /// 离线push
    final extras = JPushUtil.appLaunchParameters;
    debugPrint('getChat 离线 notification - extras:$extras');
    final String type = "${extras["type"]}";
    if (type != null) {
      switch (int.parse(type)) {
        case JPushType.relationAdd:
        case JPushType.relationCancel:
          JPushUtil.gotoRelation();
          break;
        case JPushType.relationFriend:
          final String userId = extras["user_id"];
          if (userId != null) {
            JPushUtil.gotoDmChannel(userId);
          }
          break;
        case JPushType.channel:
        case JPushType.dm:
          if (extras["channel_id"] != null) {
            JPushUtil.gotoChannel(
              "${extras["channel_id"]}",
              "${extras["message_id"]}",
              "${extras["channel_type"] ?? ""}",
              "${extras["user_id"]}",
            );
          }
          break;
        case JPushType.circleComment:
        // ignore: no_duplicate_case_values
        case JPushType.circleLike:
          if (extras['data'] == null) return;
          try {
            final Map<String, dynamic> circleData =
                extras['data'].cast<String, dynamic>();
            final message = MessageEntity.fromJson(circleData);
            final content = message.content as CirclePostNewsEntity;
            final postId = content.postId;
            final commentId = message.quoteL1.hasValue
                ? message.quoteL1
                : content.commentId?.toString();
            final circleNewsChannelId = message.channelId;
            final guildId = extras['guild_id'] ?? message.guildId;
            debugPrint(
                'getChat notification - messageId:${message.messageId}, postId:$postId commentId:$commentId');
            if (postId.noValue) return;

            //圈子动态消息-直接跳转到动态详情页
            final detailData = CircleDetailData(
              null,
              extraData: ExtraData(
                  guildId: guildId,
                  circleNewsChannelId: circleNewsChannelId,
                  circleNewsMessageId: message.messageId,
                  postId: postId,
                  commentId: commentId,
                  lastCircleType: content.circleType,
                  extraType: ExtraType.fromPush),
            );
            JPushUtil.gotoCircle(guildId, content.channelId,
                detailData: detailData);
          } catch (e) {
            debugPrint('getChat notification error: $e');
          }
          break;
        default:
          break;
      }
    }
  } catch (e, detail) {
    logger.severe(
        "Failed to parse JPush Notification extras parameters $e", detail);
  }
}

Future<void> _initUserSetting() async {
  unawaited(
    UserApi.getUserInfo([Global.user.id]).then((users) {
      final user = users.single;
      Global.user.update(
        id: user.userId,
        avatar: user.avatar,
        gender: user.gender,
        mobile: user.phoneNumber,
        nickname: user.nickname,
        username: user.username,
        avatarNft: user.avatarNft,
        avatarNftId: user.avatarNftId,
      );
      UserInfo.set(UserInfo(
        userId: Global.user.id,
        avatar: user.avatar,
        nickname: Global.user.nickname,
        username: Global.user.username,
        gender: user.gender,
        phoneNumber: Global.user.mobile,
        avatarNft: Global.user.avatarNft,
        avatarNftId: Global.user.avatarNftId,
      ));
    }),
  );
  final res = await UserApi.getSetting();
  final mutedChannels = _parseMutedChannel(res);
  unawaited(
    UserConfig.update(
      defaultGuildsRestricted: res[UserConfig.defaultGuildsRestricted] ?? true,
      restrictedGuilds:
          ((res[UserConfig.restrictedGuilds] ?? []) as List).cast<String>(),
      friendSourceFlags: res[UserConfig.friendSourceFlags],
      mutedChannels: mutedChannels,
    ),
  );
}

List<String> _parseMutedChannel(res) {
  if (res[UserConfig.mute] != null &&
      res[UserConfig.mute][UserConfig.channel] != null) {
    final List<dynamic> rawChannels = res[UserConfig.mute][UserConfig.channel];
    return rawChannels.cast<String>();
  }
  return null;
}

///检查: 当前时间 - pullTime > 7天，是则清理本地所有消息相关数据
Future<void> checkPullTime() async {
  final int pullTime = SpService.to.getInt2("${Global.user.id}_pullTime");
  if (pullTime != null) {
    final DateTime lastTime =
        DateTime.fromMillisecondsSinceEpoch(pullTime * 1000);
    //测试代码，间隔1分钟触发
    // final inSeconds = DateTime.now().difference(lastTime).inSeconds;
    // debugPrint('getChat -- checkPullTime inSeconds: $inSeconds');
    // if (inSeconds >= 60){
    //   await Db.clearLocalChatData();
    // }
    final inDays = DateTime.now().difference(lastTime).inDays;
    debugPrint('getChat -- checkPullTime inDays:$inDays');
    if (inDays >= 7) {
      await Db.cleanUserChatData(type: CleanLastIdType.excludeDm);
    }
  }

  ///兼容旧版本：客户端本地有lastId，但pullTime为空，也执行清理操作
  if (pullTime == null && Db.lastMessageIdBox.isNotEmpty) {
    debugPrint('getChat -- checkPullTime pullTime is null');
    await Db.cleanUserChatData(type: CleanLastIdType.excludeDm);
  }
}

///启动时判断app版本号有没有变化：有就删除myGuild2和dmList2接口的缓存参数
Future<void> checkAppVersion() async {
  final preVersion = SpService.to.getString(SP.appVersion);
  final curAppVersion =
      '${Global.packageInfo.version}.${Global.packageInfo.buildNumber}';
  if (preVersion == null || preVersion != curAppVersion) {
    await Db.userConfigBox.delete(UserConfig.myGuild2Hash);
    await Db.userConfigBox.delete(UserConfig.dmList2Time);
    await Db.userConfigBox.delete(UserConfig.dmList2ChannelIds);
    logger.info('checkAppVersion: $preVersion -> $curAppVersion');
  }
  unawaited(SpService.to.setString(SP.appVersion, curAppVersion));
}

Future preparingHomePage() async {
  await Db.open(Global.user.id);
  if (!kIsWeb) await checkPullTime();

  await RedPackUtil().initBox(); //红包状态管理，需要在UI前，打开hive后初始化
  await checkAppVersion();
  Get.put(FriendApplyPageController(), permanent: true);
  Get.put(DirectMessageController(), permanent: true);
  Get.put(FriendListPageController(), permanent: true);

  await ChatTargetsModel.instance.loadLocalData().catchError(_onError);
  await GlobalState.init().catchError(_onError);
  unawaited(_initUserSetting());
  initFbQuestConfig();
}
