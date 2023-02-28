import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:im/api/user_api.dart';
import 'package:im/app/modules/circle_detail/circle_detail_router.dart';
import 'package:im/app/modules/circle_detail/controllers/circle_detail_controller.dart';
import 'package:im/app/modules/direct_message/controllers/direct_message_controller.dart';
import 'package:im/app/routes/app_pages.dart' as get_pages show Routes;
import 'package:im/common/extension/string_extension.dart';
import 'package:im/core/config.dart';
import 'package:im/loggers.dart';
import 'package:im/pages/guild_setting/circle/circle_detail_page/circle_page.dart';
import 'package:im/pages/home/json/text_chat_json.dart';
import 'package:im/pages/home/model/chat_index_model.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/pages/home/view/tab_bar.dart';
import 'package:im/routes.dart';
import 'package:im/utils/orientation_util.dart';
import 'package:im/utils/universal_platform.dart';
import 'package:im/web/utils/web_util/web_util.dart';
import 'package:im/widgets/dialog/permission_tip_dialog.dart';
import 'package:jpush_flutter/jpush_flutter.dart';
import 'package:pedantic/pedantic.dart';

class JPushType {
  // 收到消息
  static const int dm = 0;

  // 被添加好友
  static const int relationAdd = 1;

  // 成为好友
  static const int relationFriend = 2;

  // 收到消息
  static const int channel = 3;

  // 圈子回复
  static const int circleComment = 4;

  // 好有取消
  static const int relationCancel = 5;

  // 圈子点赞
  static const int circleLike = 6;
}

class JPushUtil {
  static final pushedNotificationIds = [];
  static int pushedNotificationSeq = 0;
  static const pushMainPlatform = MethodChannel('buff.com/jpush');

  static Future<void> init() async {
    if (!UniversalPlatform.isMobileDevice) return;

    try {
      JPush()
        ..setup(
          appKey: "df59cd0f418a857fe19363a1",
          channel: "Develop",
          debug: Config.env == Env.dev,
          production: Config.env != Env.dev,
        )
        // ..applyPushAuthority()
        ..addEventHandler(onOpenNotification: (e) async {
          try {
            /// 在线push
            ///但是魅族手机的离线推送，会走这里
            final extras = UniversalPlatform.isIOS
                ? e["extras"]
                : jsonDecode(e["extras"]["cn.jpush.android.EXTRA"]);

            logger.info("onOpenNotification extras:$extras");
            // debugPrint('getChat notification: $extras');

            final String type = "${extras["type"]}";
            if (type != null) {
              switch (int.parse(type)) {
                case JPushType.relationAdd:
                case JPushType.relationCancel:
                  gotoRelation();
                  break;
                case JPushType.relationFriend:
                  final String userId = extras["user_id"];
                  if (userId != null) {
                    gotoDmChannel(userId);
                  }
                  break;
                case JPushType.channel:
                  if (extras["channel_id"] != null) {
                    await gotoChannel(
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
                  var data = extras['data'];
                  if (data == null && extras['circleData'] != null) {
                    data = jsonDecode(extras['circleData']);
                  }
                  if (data == null) return;

                  try {
                    final Map<String, dynamic> circleData =
                        data.cast<String, dynamic>();
                    final message = MessageEntity.fromJson(circleData);
                    final content = message.content as CirclePostNewsEntity;
                    final postId = content.postId;
                    final commentId = message.quoteL1.hasValue
                        ? message.quoteL1
                        : content.commentId?.toString();
                    final guildId = extras['guild_id'] ?? message.guildId;

                    final circleNewsChannelId = message.channelId;
                    debugPrint(
                        'getChat notification: guildId: $guildId, postId: $postId - $commentId - $circleNewsChannelId');
                    if (postId.noValue) return;

                    //圈子动态消息-直接跳转到详情页
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
                    JPushUtil.gotoCircle(guildId, null, detailData: detailData);
                  } catch (e) {
                    debugPrint('getChat notification error -- $e');
                  }
                  break;
                default:
                  break;
              }
            }
          } catch (e, detail) {
            logger.severe(
                "Failed to parse JPush Notification extras parameters $e",
                detail);
          }
        });
    } on PlatformException catch (e) {
      print("JPush PlatformException. $e");
    }

    if (UniversalPlatform.isIOS) {
      appLaunchParameters = await JPush().getLaunchAppNotification();
      appLaunchParameters = appLaunchParameters["extras"];
    } else if (UniversalPlatform.isAndroid) {
      final paramString = await pushMainPlatform
          .invokeMethod('getLaunchParam')
          .timeout(const Duration(seconds: 1));
      if (paramString != null) {
        final json = jsonDecode(paramString);
        appLaunchParameters = json['n_extras'];
      } else {
        appLaunchParameters = null;
      }
    }
    logger.info(
        'appLaunchParameters $appLaunchParameters', appLaunchParameters);
  }

  /// 权限提示单独拿出来，在进入home页面后再弹出
  /// 延迟的主要原因，每次重新安装应用后需要弹极光权限窗，虽在home页面init中调用，但每次都在
  /// 登录页面就弹窗，有偶尔卡住进入不了主界面的情况。延迟2秒是为了保证在服务器列表比较多时大部
  /// 分列表图标能加载显示完成，权限弹窗会卡住home ui的显示，如列表图标。
  static Future<void> applyPushAuthority() async {
    Future.delayed(const Duration(seconds: 2), () {
      JPush().applyPushAuthority();
    });
  }

  static Map<dynamic, dynamic> appLaunchParameters;

  static bool hasAppLaunchParameters() {
    return appLaunchParameters != null && appLaunchParameters.isNotEmpty;
  }

  static Future<void> gotoChannel(String channelId, String messageId,
      String channelType, String dmRecipient) async {
    var chatTargetAndChannel =
        ChatTargetsModel.instance.getChatTargetAndChannelByChannelId(channelId);

    ///如果客户端关闭了私信或群聊,或者频道被删除，导致找不到
    ///等待5秒(等待客户端接收离线消息)，再查找
    if (chatTargetAndChannel == null) {
      await Future.delayed(const Duration(seconds: 5));
      chatTargetAndChannel = ChatTargetsModel.instance
          .getChatTargetAndChannelByChannelId(channelId);
    }

    if (chatTargetAndChannel != null) {
      /// 如果是跳转的是服务台，那就需要返回到首页
      if (chatTargetAndChannel.item1 != null) {
        Routes.backHome();
        HomeTabBar.gotoIndex(0);
      }
      await ChatTargetsModel.instance.selectChatTarget(
          chatTargetAndChannel.item1,
          channel: chatTargetAndChannel.item2,
          gotoChatView: true);
      //messageId: messageId); // notify 不跳转到指定的消息，还原为跳转到频道底部
    }

    ///找不到频道，不用跳转空白消息页或者默认频道
  }

  static void gotoCircle(
    String guildId,
    String channelId, {
    bool autoPushCircleMessage = false,
    CircleDetailData detailData,
  }) {
    // Routes.backHome();
    // HomeTabBar.gotoIndex(0);
    // final chatTarget = ChatTargetsModel.instance.getChatTarget(guildId);
    // if (chatTarget != null) {
    //   ChatTargetsModel.instance.selectChatTarget(chatTarget);
    // } else {
    //   ChatTargetsModel.instance.selectDefaultChatTarget();
    //   // showToast('消息推送中所在的服务器不存在'.tr);
    // }
    CircleDetailRouter.push(detailData);
  }

  static Future pushNotification(
      {String title,
      String content,
      Map<String, String> extra,
      DateTime fireTime,
      bool addBadge = true,
      String sound,
      String subtitle}) async {
    if (kIsWeb) {
      if (WebConfig.isWindowHidden) {
        webUtil.pushLocalNotification(title, content, extra);
      }
      return;
    }
    unawaited(JPush().sendLocalNotification(LocalNotification(
        id: ++pushedNotificationSeq,
        title: title ?? "",
        buildId: DateTime.now().millisecondsSinceEpoch,
        content: content ?? "",
        badge: UniversalPlatform.isIOS
            ? await JPush().getBadge() + (addBadge ? 1 : 0)
            : 2,
        fireTime:
            fireTime ?? DateTime.now().add(const Duration(milliseconds: 100)),
        soundName: sound ?? "",
        extra: extra ?? const {})));
    pushedNotificationIds.add(pushedNotificationSeq);
  }

  static void clearAllNotification() {
    if (UniversalPlatform.isIOS) {
      JPush().clearAllNotifications();
      pushedNotificationIds.clear();
    } else {
      JPush().clearAllNotifications();
      for (final item in pushedNotificationIds) {
        JPush().clearNotification(notificationId: item);
      }
      pushedNotificationIds.clear();
      pushMainPlatform
          .invokeMethod('clearAllNotification')
          .timeout(const Duration(seconds: 1));
    }
    pushedNotificationSeq = 0;
  }

  static void gotoRelation() {
    Routes.backHome();
    HomeTabBar.gotoIndex(1);
    Get.toNamed(get_pages.Routes.FRIEND_APPLY_PAGE);
  }

  static void gotoDmChannel(String userId) {
    if (OrientationUtil.portrait) {
      DirectMessageController.to
          .createChannel(userId)
          .then(Routes.pushDirectChatPage);
    } else {
      /// TODO: 还没想好
      ChatTargetsModel.instance.selectChatTarget(null,
          channel: ChatChannel.directMessage(userId), gotoChatView: true);
    }
  }

  static void setAlias(String string) {
    JPush()
        .setAlias(string)
        .timeout(const Duration(seconds: 20))
        .catchError((error) {
      try {
        /// TODO 改成一个 try-catch 使用 on error 分支判断
        if (error is TimeoutException) {
          throw error;
        }

        final code = error.code;
        if (code.contains("6027")) {
          UserApi.delJPushAlias().then((value) => Future.delayed(
              const Duration(seconds: 5), () => setAlias(string)));
        } else if (code.contains("6021") ||
            code.contains("6022") ||
            code.contains("6011")) {
          Future.delayed(const Duration(seconds: 21), () => setAlias(string));
        } else {
          throw code;
        }
      } catch (e) {
        Future.delayed(const Duration(seconds: 5), () => setAlias(string));
        logger.warning(
            "Failed to call JPush.setAlias, retry in 5 seconds. ${error.toString()} ${e.toString()}");
      }
    }).then((value) {
      logger.info("JPush.setAlias success. alias: $value");
    });
  }

  static Future<bool> callOppoPermission() async {
    try {
      final bool result = await pushMainPlatform
          .invokeMethod('callOppoNotificationPermission')
          .timeout(const Duration(seconds: 1));
      return result;
    } catch (e) {
      return false;
    }
  }

  //检查Android的通知权限是否打开，没有则提示
  static Future checkAndroidNotificationPermission(BuildContext context) async {
    final enabled = await JPush().isNotificationEnabled();
    logger.info("checkNotification enabled：$enabled");
    if (!enabled) {
      await Future.delayed(const Duration(seconds: 2));
      logger.info("checkNotification delayed 2");
      final bool oppoNotificationResult = await callOppoPermission();
      if (oppoNotificationResult) {
        logger.info("checkNotification -- oppo has call");
        return;
      }
      await showDialog(
          context: context,
          builder: (ctx) {
            return PermissionTipDialog(
              title: '“Fanbook”想给你发送通知'.tr,
              content: '请打开APP通知权限，否则您将不能及时收到我们的通知消息'.tr,
              confirmText: '允许'.tr,
              cancelText: '不允许'.tr,
              onConfirm: () {
                JPush().openSettingsForNotification();
              },
            );
          });
    }
    return enabled;
  }
}
