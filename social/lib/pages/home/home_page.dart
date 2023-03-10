import 'dart:async';
import 'dart:ui';

import 'package:fb_live_flutter/fb_live_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bugly/flutter_bugly.dart';
import 'package:flutter_filereader/filereader.dart';
import 'package:get/get.dart';
import 'package:im/api/check_info_api.dart';
import 'package:im/app/controllers/audio_room_controller.dart';
import 'package:im/app/modules/direct_message/controllers/direct_message_controller.dart';
import 'package:im/app/modules/home/controllers/home_scaffold_controller.dart';
import 'package:im/app/modules/home/views/components/empty_chat_content.dart';
import 'package:im/app/modules/home/views/guild_detail_view/guild_detail_view.dart';
import 'package:im/app/modules/home/views/home_scaffold_view.dart';
import 'package:im/app/modules/task/task_util.dart';
import 'package:im/core/config.dart';
import 'package:im/dlog/dlog_manager.dart';
import 'package:im/hybrid/jpush_util.dart';
import 'package:im/icon_font.dart';
import 'package:im/loggers.dart';
import 'package:im/pages/chat_index/chat_index.dart';
import 'package:im/pages/chat_index/chat_target_list.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/pages/home/model/in_memory_db.dart';
import 'package:im/pages/home/view/audio/audio_chat_popup.dart';
import 'package:im/pages/home/view/bottom_bar/im_bottom_bar.dart';
import 'package:im/pages/home/view/chat_window.dart';
import 'package:im/pages/home/view/chat_window_web.dart' as web;
import 'package:im/pages/home/view/dock.dart';
import 'package:im/pages/home/view/tab_bar.dart';
import 'package:im/pages/home/view/text_chat_view.dart';
import 'package:im/pages/home/view/video/video_chat_popup.dart';
import 'package:im/pages/member_list/member_list_window.dart';
import 'package:im/pages/tool/url_handler/invite_link_handler.dart';
import 'package:im/routes.dart';
import 'package:im/services/server_side_configuration.dart';
import 'package:im/services/sp_service.dart';
import 'package:im/themes/custom_color.dart';
import 'package:im/utils/emo_util.dart';
import 'package:im/utils/invite_code/invite_code_util.dart';
import 'package:im/utils/orientation_util.dart';
import 'package:im/utils/preparing_home_page.dart';
import 'package:im/utils/sensitive_sdk_util.dart';
import 'package:im/utils/show_bottom_modal.dart';
import 'package:im/utils/texture_overlap_notifier.dart';
import 'package:im/utils/universal_platform.dart';
import 'package:im/web/utils/show_web_tooltip.dart';
import 'package:im/web/utils/web_util/web_util.dart';
import 'package:im/widgets/dialog/invite_dialog.dart';
import 'package:im/widgets/super_tooltip.dart';
import 'package:im/ws/ws.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:pedantic/pedantic.dart';
import 'package:rxdart/rxdart.dart' hide Notification;

import '../../global.dart';
import 'model/chat_index_model.dart';
import 'model/text_channel_controller.dart';
import 'model/text_channel_util.dart';

class RestoreMediaChannelViewNotification extends Notification {}

class RestoreAudioPlayerViewNotification extends Notification {}

enum InviteURLFrom { openInstall, clipBoard }
enum InvitePageFrom { defaultPage, welcomePage }

class InviteUrlStream {
  final String url;
  final InviteURLFrom from;
  final InvitePageFrom invitePageFrom;

  const InviteUrlStream(this.url, this.from,
      {this.invitePageFrom = InvitePageFrom.defaultPage});
}

class HomePage extends StatefulWidget {
  static Completer _ready = Completer();

  static Future get ready => _ready.future;

  static final _key = GlobalKey<_HomePageState>();

  // ignore: close_sinks
  static final inviteStream = BehaviorSubject<InviteUrlStream>()
    ..bufferCount(1);

  static ValueNotifier<double> chatWindowXWithTextAlpha = ValueNotifier(0);

  /// ??????????????????????????????
  static ValueNotifier<bool> dragging = ValueNotifier(false);

  HomePage() : super(key: _key);

  @override
  _HomePageState createState() => _HomePageState();

  static void showAudioRoom(String roomId) {
    HomeTabBar.gotoIndex(0);
    HomeScaffoldController.to.gotoWindow(0).then((value) {
      _key.currentState.showAudioRoom(roomId);
    });
  }

  static void showVideoRoom(String roomId) {
    HomeTabBar.gotoIndex(0);
    HomeScaffoldController.to.gotoWindow(0).then((value) {
      _key.currentState.showVideoRoom(roomId);
    });
  }

  static Decoration getWindowDecorator(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.portrait
        ? ShapeDecoration(
            color: CustomColor(context).backgroundColor2,
            shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(8))))
        : BoxDecoration(
            color: CustomColor(context).backgroundColor2,
          );
  }
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  /// ??????????????? chat ????????????????????????????????????
  final double peekChatWindowWidth = 0.1;

  /// ????????????
  final double spaceBetweenWindow = 8;

  ValueNotifier<bool> hideChatIndexWindow = ValueNotifier(false);
  ValueNotifier<bool> hideMemberListWindow = ValueNotifier(true);
  ValueNotifier<double> chatWindowX;

  StreamSubscription _wsSubscription;

  StreamSubscription<InviteUrlStream> _inviteStreamSubscription;

  Worker _onWindowChangeListener;

  Future<void> init() async {
    logger.info("User ID: ${Global.user.id}");

    /// ???????????????
    if (UniversalPlatform.isMobileDevice) {
      /// TODO ??????????????????????????? HomePage ???????????????????????????????????????????????????
      unawaited(JPushUtil.init().then((value) {
        checkPushNotificationJump();
        JPushUtil.setAlias(Global.user.id.toString());
        JPushUtil.applyPushAuthority();
      }));

      /// ??????????????????
      await checkClipboardInvite(context);
    }

    if (kIsWeb) webUtil.initNotification();

    /// ????????????
    unawaited(CheckInfoApi.postCheckUpdate(context,
        toast: false, showUpdateDialog: true));
    unawaited(CheckInfoApi.postCheckInfo(context));

    ///??????Android?????????????????????????????????????????????(???????????????)
    if (UniversalPlatform.isAndroid) {
      final checked =
          SpService.to.getBool(SP.checkNotificationPermission) ?? false;
      if (!checked) {
        unawaited(JPushUtil.checkAndroidNotificationPermission(context));
        await SpService.to.setBool(SP.checkNotificationPermission, true);
      }
    }

    //?????????bugly?????????appid????????????
    logger.info("flutter-bugly ---> channel: ${Global.deviceInfo.channel}");
    if (UniversalPlatform.isAndroid || UniversalPlatform.isIOS) {
      final packageInfo = await PackageInfo.fromPlatform();
      final appVersion = '${packageInfo.version}.${packageInfo.buildNumber}';
      await FlutterBugly.init(
          androidAppId: "58f80b9ee9",
          iOSAppId: "617a8513ab",
          channel: Global.deviceInfo.channel,
          appVersion: appVersion);
      //bugly????????????ID?????????,??????
      await FlutterBugly.setUserId(Global.user.username);
      await FlutterBugly.putUserData(
          key: 'nickname', value: Global.user.nickname);
      await FlutterBugly.putUserData(key: 'env', value: '${Config.env}');
    }

    // ????????????????????????android.app.ActivityManager:getRunningAppProcesses(3967)???
    // ?????????????????????x5??????????????????
    FileReader.instance.initX5();
  }

  @override
  void initState() {
    HomeTabBar.index.value = 0;

    Get.put(HomeScaffoldController());
    Get.put(DirectMessageController(), permanent: true);
    DirectMessageController.to.init();
    DirectMessageController.to.loadLocalData();

    if (initialChannelId == null) {
      ChatTargetsModel.instance.selectDefaultChatTarget();
    }

    /// ????????????????????????
    final afterFirstTimeLoadGuilds = Completer<bool>();
    afterFirstTimeLoadGuilds.future.then((isNew) {
      if (!ChatTargetsModel.instance.hasJoinAnyGuild()) {
        /// ??????????????????????????????????????????
        Routes.pushWelcomePage();
      }

      _inviteStreamSubscription = HomePage.inviteStream
          // ?????????????????????????????????????????????
          .throttleTime(const Duration(milliseconds: 2000))
          .listen((value) {
        /// ????????????openInstall????????????jump
        InviteLinkHandler(
                joinedBehavior: value.from == InviteURLFrom.openInstall
                    ? JoinedBehavior.jump
                    : JoinedBehavior.doNothing,
                showErrorToast: value.from == InviteURLFrom.openInstall)
            .handleIfMatch(value.url);
        // ????????? listen ???????????? onData
        HomePage.inviteStream.addError(Error());
      }, onError: (_) {});
    });

    bool isReported = false;
    _wsSubscription = Ws.instance.on().listen((event) async {
      if (event is Connected) {
        //  ?????? WS ?????????????????????????????????
        await ChatTargetsModel.instance.loadRemoteData();
        if (!afterFirstTimeLoadGuilds.isCompleted) {
          /// ????????????????????????????????????????????????????????????????????????
          afterFirstTimeLoadGuilds.complete();
        }
        await TextChannelUtil.instance.initChannelViewPermission();

        ///??????????????????????????????????????????ws??????
        await TextChannelUtil.instance.fetchData();
        DirectMessageController.to.updateUnread();

        if (initialChannelId != null) {
          final chatTargetAndChannel = ChatTargetsModel.instance
              .getChatTargetAndChannelByChannelId(initialChannelId);
          if (chatTargetAndChannel != null) {
            initialChannelId = null;
            unawaited(ChatTargetsModel.instance.selectChatTarget(
              chatTargetAndChannel.item1,
              channel: chatTargetAndChannel.item2,
            ));
          } else {
            ChatTargetsModel.instance.selectDefaultChatTarget();
          }
        }

        /// ????????????????????????????????????????????????app,?????????????????????id????????????
        /// ???????????????????????????id????????????????????????
        if (!isReported) {
          isReported = true;
          DLogManager.getInstance().customEvent(
              actionEventId: 'enter_home_page',
              actionEventSubId:
                  ChatTargetsModel.instance?.selectedChatTarget?.id ?? '',
              pageId: 'page_home',
              extJson: {"invite_code": InviteCodeUtil.inviteCode});
        }
      } else if (event is Disconnected) {
        InMemoryDb.resetAllMessageList();
        ServerSideConfiguration.to.aliPayUid = null;
      }
    });
    Ws.instance.connect();

    _onWindowChangeListener =
        ever(HomeScaffoldController.to.windowIndex, (_) => Dock.updateDock());

    EmoUtil.instance.doInitial();

    unawaited(init());
    // widget.initialCallback?.call();
    HomePage._ready.complete();

    super.initState();
    Dock.init(context);

    /// ???????????????????????????????????????????????????????????????????????????????????????????????????check???????????????
    /// ??????????????????????????????
    final cacheAgreedStatus = SpService.to.getBool(SP.agreedProtocals) ?? false;
    if (!cacheAgreedStatus) {
      SpService.to.setBool(SP.agreedProtocals, true);
      SensitiveSDKUtil.handleEvents();
    }

    TextureOverlapNotifier.instance.listen((event) {
      if (event.overlap) {
        Dock.hide();
      } else {
        Dock.updateDock();
      }
    });
  }

  @override
  void dispose() {
    HomePage._ready = Completer();
    _inviteStreamSubscription?.cancel();
    _wsSubscription.cancel();
    _onWindowChangeListener?.dispose();
    Get.delete<HomeScaffoldController>();
    super.dispose();
  }

  Future showVideoRoom(String roomId) async {
    //Dock.hide(); //??????????????????????????????????????????
    if (OrientationUtil.portrait) {
      await HomeScaffoldController.to.gotoIndex(0);
      await showBottomModal(context,
          backgroundColor: const Color(0xFFF5F5F8),
          routeSettings: const RouteSettings(name: audioRoomPopRoute),
          showTopCache: false,
          cornerRadius: 10,
          margin: const EdgeInsets.all(0),
          // scrollSpec: const ScrollSpec(physics: AlwaysScrollableScrollPhysics()),
          builder: (c, s) => VideoChatPopup(roomId));
    } else {
      await showWebTooltip(ChatIndex.context,
          popupDirection: TooltipDirection.right,
          containsBackgroundOverlay: false,
          offsetX: 8, builder: (ctx, done) {
        return Container(
          width: 374,
          height: 452,
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                    color: const Color(0xFF717D8D).withOpacity(0.1),
                    blurRadius: 16,
                    offset: const Offset(0, 2))
              ],
              color: Theme.of(context).scaffoldBackgroundColor),
          child: VideoChatPopup(roomId, callback: (value) async {
            if (value == 1) {
              done.call(null);
            }
          }),
        );
      });
    }
    // Dock.noUpdateDock = false;
    // try {
    //   // ?????????????????????????????????????????????controller
    //   final c = Get.find<AudioRoomController>(tag: roomId);
    //
    //   ///?????????'?????????'???'?????????'???????????????closeAndDispose???????????????????????????????????????
    //   if (c.joined.value != JoinStatus.joined &&
    //       c.joined.value != JoinStatus.unJoined) {
    //     unawaited(c.closeAndDispose());
    //   }
    // } catch (_) {}
    //
    // if (OrientationUtil.portrait) {
    //   Dock.updateDock();
    // } else {
    //   Dock.hide(); //web????????????Dock????????????????????????
    // }
  }

  Future showAudioRoom(String roomId) async {
    Dock.hide(); //??????????????????????????????????????????
    if (OrientationUtil.portrait) {
      await HomeScaffoldController.to.gotoIndex(0);
      await showBottomModal(context,
          backgroundColor: const Color(0xFFF5F5F8),
          routeSettings: const RouteSettings(name: audioRoomRoute),
          showTopCache: false,
          cornerRadius: 10,
          margin: const EdgeInsets.all(0),
          // scrollSpec: const ScrollSpec(physics: AlwaysScrollableScrollPhysics()),
          builder: (c, s) => AudioChatPopup(roomId));
    } else {
      await showWebTooltip(ChatIndex.context,
          popupDirection: TooltipDirection.right,
          containsBackgroundOverlay: false,
          offsetX: 8, builder: (ctx, done) {
        return Container(
          width: 374,
          height: 452,
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                    color: const Color(0xFF717D8D).withOpacity(0.1),
                    blurRadius: 16,
                    offset: const Offset(0, 2))
              ],
              color: Theme.of(context).scaffoldBackgroundColor),
          child: AudioChatPopup(roomId, callback: (value) async {
            if (value == 1) {
              done.call(null);
            }
          }),
        );
      });
    }
    Dock.noUpdateDock = false;
    try {
      // ?????????????????????????????????????????????controller
      final c = Get.find<AudioRoomController>(tag: roomId);

      ///?????????'?????????'???'?????????'???????????????closeAndDispose???????????????????????????????????????
      if (c.joined.value != JoinStatus.joined &&
          c.joined.value != JoinStatus.unJoined) {
        unawaited(c.closeAndDispose());
      }
    } catch (_) {}

    if (OrientationUtil.portrait) {
      Dock.updateDock();
    } else {
      Dock.hide(); //web????????????Dock????????????????????????
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: HomeScaffoldView(
        buildChatTargetList: () => ChatTargetList(),
        buildSecondWindow: _buildChatWindow,
        buildThirdWindow: () => const MemberListWindow(),
        buildGuildView: (t) => GuildDetailView(
          target: t,
          key: ObjectKey(t),
        ),
      ),
    );
  }

  static const kEmptyView = SizedBox();
  final List<Widget> _chatWindows = [kEmptyView, kEmptyView];

  Widget _buildChatWindow(ChatChannel channel) {
    int index;
    Widget chatWindow;
    if (channel == null) {
      chatWindow = const ChatWindowScaffold(null, EmptyChatContent(), null);
      index = 0;
      _chatWindows[0] = chatWindow;
    } else {
      switch (channel.type) {
        case ChatChannelType.guildText:
        case ChatChannelType.dm:
        case ChatChannelType.group_dm:
          final Widget bottomBar = ImBottomBar(channel);

          if (OrientationUtil.portrait)
            chatWindow = ChatWindowScaffold(
              channel.type == ChatChannelType.dm ? IconFont.buffTabAt : null,
              ObxValue<RxBool>((rxIsShow) {
                return TextChatView(
                  model: TextChannelController.to(channelId: channel.id),
                  bottomBar: bottomBar,
                  key: ValueKey('${channel.id}-$rxIsShow'),
                );
              }, TaskUtil.instance.isNewGuy),
              channel,
              key: ValueKey(channel.id),
            );
          else
            chatWindow = web.ChatWindowScaffold(
              channel.type == ChatChannelType.dm
                  ? IconFont.buffTabAt
                  : IconFont.webChannelWord,
              TextChatView(
                model: TextChannelController.to(channelId: channel.id),
                bottomBar: bottomBar,
              ),
              key: ValueKey(channel.id),
            );
          index = 0;
          _chatWindows[0] = chatWindow;
          break;

        case ChatChannelType.guildVoice:
          //TODO: ??????????????????????????????????????????,????????????????????????????????????????????????????????????
          // AudioRoomController.to(channel.id);

          index = 0;
          _chatWindows[0] = kEmptyView;

          // chatWindow = ChatWindowScaffold(
          //   null,
          //   AudioChatView(channel),
          // );
          // index = 1;
          // _chatWindows[1] = chatWindow;
          break;

        case ChatChannelType.guildVideo:
          // chatWindow = VideoChatWindowScaffold(
          //     // child: VideoRoomHomePage(channel.id, channel.name));
          // index = 1;
          // _chatWindows[1] = chatWindow;
          index = 0;
          _chatWindows[0] = kEmptyView;

          break;
        case ChatChannelType.guildLink:
          chatWindow = ChatWindowScaffold(
            IconFont.buffChannelLink,
            Center(child: Text('????????????'.tr)),
            channel,
            key: ValueKey(channel.id),
          );
          index = 0;
          _chatWindows[0] = chatWindow;
          break;
        case ChatChannelType.guildLive:
          if (OrientationUtil.portrait)
            chatWindow = ChatWindowScaffold(
              null,
              RoomList(
                  backAction: () => HomeScaffoldController.to.gotoWindow(0)),
              channel,
              key: ValueKey(channel.id),
            );
          else
            chatWindow = web.ChatWindowScaffold(
              null,
              RoomList(
                  backAction: () => HomeScaffoldController.to.gotoWindow(0)),
              key: ValueKey(channel.id),
              showMemberlist: false,
            );
          index = 0;
          _chatWindows[0] = chatWindow;
          break;
        // ignore: no_default_cases
        default:
          assert(false, "Unsupported channel type");
          break;
      }
    }

    if (GlobalState.mediaChannel.value == null) {
      _chatWindows[1] = kEmptyView;
    }

    return IndexedStack(
      index: index,
      children: _chatWindows,
    );
  }
}
