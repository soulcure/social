import 'dart:async';

import 'package:fb_live_flutter/fb_live_flutter.dart';
import 'package:fb_live_flutter/live/bloc/with/live_mix.dart';
import 'package:fb_live_flutter/live/utils/func/utils_class.dart';
import 'package:fb_live_flutter/live/utils/other/float/float_mode.dart';
import 'package:fb_utils/fb_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:im/app/modules/home/controllers/home_scaffold_controller.dart';
import 'package:im/app/modules/home/views/home_scaffold_view.dart';
import 'package:im/app/modules/manage_guild/models/ban_type.dart';
import 'package:im/app/theme/app_theme.dart';
import 'package:im/common/permission/permission.dart' hide PermissionType;
import 'package:im/db/db.dart';
import 'package:im/global.dart';
import 'package:im/live_provider/live_api_provider.dart';
import 'package:im/pages/chat_index/components/channel_list.dart';
import 'package:im/pages/home/home_page.dart';
import 'package:im/pages/home/json/text_chat_json.dart';
import 'package:im/pages/home/model/chat_index_model.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/pages/home/model/text_channel_event.dart';
import 'package:im/pages/home/model/text_channel_util.dart';
import 'package:im/themes/const.dart';
import 'package:im/utils/orientation_util.dart';
import 'package:im/widgets/app_bar/appbar_action_model.dart';
import 'package:im/widgets/app_bar/appbar_builder.dart';
import 'package:im/widgets/channel_icon.dart';
import 'package:im/widgets/realtime_user_info.dart';
import 'package:im/widgets/share_link_popup/share_link_popup.dart';
import 'package:im/widgets/top_status_bar.dart';
import 'package:im/ws/pin_handler.dart';
import 'package:pedantic/pedantic.dart';
import 'package:provider/provider.dart';

import '../../../icon_font.dart';
import '../../../loggers.dart';
import '../../../routes.dart';
import 'record_view/record_sound_state.dart';

class ChatWindowScaffold extends StatefulWidget {
  /// 聊天口聊天内容
  final Widget child;

  /// 当前频道图标（标题栏-标题位置靠左展示）
  final IconData channelIcon;

  /// 当前频道信息
  final ChatChannel channel;

  const ChatWindowScaffold(this.channelIcon, this.child, this.channel,
      {Key key})
      : super(key: key);

  @override
  ChatWindowScaffoldState createState() => _ChatWindowScaffoldState();
}

abstract class ChatWindowScaffoldState<T extends StatefulWidget>
    extends State<T> {
  /// 监听: 是否滑出展示（）
  final ValueNotifier<bool> fullScreen = ValueNotifier(false);

  /// 监听1: 频道模块窗口滑动
  Worker _listener1;

  /// 监听2: 频道模块展示的窗口下标
  Worker _listener2;

  // ====== Override - Method: Parent ====== //

  @override
  void initState() {
    super.initState();

    /// 初始化所有监听
    fullScreen.value = HomeScaffoldController.to.dragging.value ||
        HomeScaffoldController.to.canChatWindowVisible;
    _listener1 = ever(HomeScaffoldController.to.dragging, _onToggleDragging);
    _listener2 =
        ever(HomeScaffoldController.to.windowIndex, _onWindowIndexChange);
  }

  @override
  void dispose() {
    fullScreen.dispose();
    _listener1.dispose();
    _listener2.dispose();
    super.dispose();
  }

  // ====== Method - Private ====== //

  /// 聊天窗口是否展示：
  /// - 如果窗口正在滑动就预先设置为展示
  /// - 如果滑动结束，但是不是聊天窗口（windowIndex ！= 1），就不设置为展示
  void _onToggleDragging(_) =>
      fullScreen.value = HomeScaffoldController.to.dragging.value ||
          (HomeScaffoldController.to.windowIndex.value == 1);

  /// 聊天窗口是否展示，如果是屏幕就是全屏展示
  void _onWindowIndexChange(_) =>
      fullScreen.value = HomeScaffoldController.to.canChatWindowVisible;
}

class _ChatWindowScaffoldState
    extends ChatWindowScaffoldState<ChatWindowScaffold> {
  /// 监听：Pin消息处理
  StreamSubscription _pinMessageSS;

  // ====== Override - Method: Parent ====== //
  @override
  void initState() {
    _pinMessageSS = TextChannelUtil.instance.stream.listen(_handlePinMessage);
    super.initState();
  }

  @override
  void dispose() {
    _pinMessageSS.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    /// 通过监听是否满屏展示，进而修改背景色以及边框央视
    return ValueListenableBuilder(
      valueListenable: fullScreen,
      builder: (context, fullScreen, child) {
        final color = fullScreen
            ? Theme.of(context).backgroundColor
            : HomeScaffoldView.backgroundColor;
        final boxShadow = fullScreen
            ? [
                const BoxShadow(
                  blurRadius: 12,
                  spreadRadius: -3,
                  color: Colors.black26,
                ),
              ]
            : null;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: color,
            boxShadow: boxShadow,
            border: Border.symmetric(
                vertical: BorderSide(color: color, width: 0.5)),
          ),

          /// 复用
          child: child,
        );
      },
      child: _assembleContentView(),
    );
  }

  // ====== Method - Private：Assemble View ====== //

  /// 组装视图：聊天视图
  Widget _assembleContentView() => ValueListenableBuilder(
      valueListenable: TopStatusController.to().showStatusUI,
      builder: (context, errorVisible, _) {
        final target =
            ChatTargetsModel.instance.selectedChatTarget as GuildTarget;

        return ValueListenableBuilder(
          valueListenable: fullScreen,
          builder: (context, fullScreen, child) {
            return AnimatedOpacity(
              duration: kThemeAnimationDuration,
              opacity: (fullScreen || OrientationUtil.landscape) ? 1 : 0.6,
              child: child,
            );
          },
          child: ChangeNotifierProvider.value(
            value: RecordSoundState.instance,
            child: AnimatedContainer(
                duration: kThemeAnimationDuration,
                margin: EdgeInsets.only(
                  top: (errorVisible
                          ? TopStatusBar.height.toDouble()
                          : HomeScaffoldController.to.windowPadding) +
                      context.mediaQueryPadding.top,
                ),
                decoration: HomePage.getWindowDecorator(context),
                child: Builder(builder: (context) {
                  final child = Column(
                    children: <Widget>[
                      _assembleAppBar(),
                      Expanded(child: widget.child),
                    ],
                  );
                  if (target == null) return child;
                  return ObxValue<Rx<BanType>>((banType) {
                    if (banType.value != BanType.normal)
                      return const SizedBox();
                    return child;
                  }, target.bannedLevel);
                })),
          ),
        );
      });

  /// 组装视图：聊天视图 - 展示标题
  Widget _assembleTitleView() {
    // - 没有选择频道就展示 提示 标题
    if (GlobalState.selectedChannel.value == null) {
      return Text(
        "提示".tr,
        style: Theme.of(context)
            .textTheme
            .headline5
            .copyWith(fontWeight: FontWeight.normal),
      );
    }
    // - 选择频道后要展示频道标题以及频道相关信息
    //  -- 匿名函数：选择展示标题的内容
    Widget selectTitleName() {
      TextStyle style = Get.theme.textTheme.headline5.copyWith(height: 1.25);
      if (kIsWeb) {
        style = style.copyWith(height: 2);
      }
      return GlobalState.selectedChannel.value?.type == ChatChannelType.dm
          ? RealtimeNickname(
              userId: GlobalState.selectedChannel.value?.guildId,
              showNameRule: ShowNameRule.remarkAndGuild,
              style: style,
            )
          : RealtimeChannelName(
              GlobalState.selectedChannel.value?.id,
              style: style,
            );
    }

    return Row(
      children: <Widget>[
        Icon(
          ChannelIcon.getChannelTypeIcon(widget.channel.type,
              isPrivate: widget.channel.isPrivate),
          size: 18,
          color: appThemeData.dividerColor.withOpacity(1),
        ),
        sizeWidth8,
        Expanded(child: selectTitleName())
      ],
    );
  }

  // ====== Method - Private：Logic Handle ====== //

  /// 是否没有在录音
  bool _isNotRecording() => RecordSoundState.instance.second == 0;

  /// 处理Pin消息
  void _handlePinMessage(e) {
    /// 匿名函数：判断是否要移除消息
    void removeChatMessage(String channelId, String messageId) {
      if (!Db.pinMessageUnreadBox.containsKey(channelId)) return;

      /// 发现了 Hive 返回 Fixed-Length List 的情况，因此使用新的数组
      /// https://github.com/hivedb/hive/issues/602
      final pinUnreadList = [...Db.pinMessageUnreadBox.get(channelId)];
      pinUnreadList.remove(messageId);
      Db.pinMessageUnreadBox.put(channelId, pinUnreadList);
    }

    /// 希望大佬来补充！
    if (e is RecallMessageEvent) {
      removeChatMessage(e.channelId, e.id);
    } else if (e is PinEvent) {
      final MessageEntity<MessageContentEntity> message = e.message;
      final PinEntity entity = message.content as PinEntity;
      if (entity.action == 'unpin') {
        removeChatMessage(message.channelId, entity.id);
      } else {
        if (message.userId == Global.user.id) return;
        final List<String> pinUnreadList =
            Db.pinMessageUnreadBox.containsKey(message.channelId)
                ? [...Db.pinMessageUnreadBox.get(message.channelId)]
                : [];
        pinUnreadList.add(entity.id);
        Db.pinMessageUnreadBox.put(message.channelId, pinUnreadList);
      }
    }
  }

  /// 组装标题栏
  /// - 如果是直播就不需要标题了
  Widget _assembleAppBar() => widget.channel?.type == ChatChannelType.guildLive
      ? const SizedBox()
      : GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            if (_isNotRecording()) {
              FocusScope.of(context).unfocus();
            }
          },

          // MediaQuery 用于去掉 AppBar 内部的顶部边距
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(padding: EdgeInsets.zero),
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(8)),
              child: FbAppBar.diyTitleView(
                //  - 横屏不展示返回按钮
                hideLeading: !OrientationUtil.portrait,
                leadingIcon: IconFont.buffNavBarBackChannelItem,
                leadingBlock: () {
                  if (_isNotRecording()) {
                    HomeScaffoldController.to.gotoWindow(0);
                  }
                  FbUtils.hideKeyboard();
                  return true;
                },
                leadingShowMsgNum: GlobalState.totalRedDotNum,
                titleBuilder: (context, style) => _assembleTitleView(),
                actions: _assembleAppBarActions(),
              ),
            ),
          ),
        );

  /// 组装标题栏
  /// - 如果是直播就不需要标题了
  /// - 没有选中频道就不展示右侧按钮
  List<AppBarActionModelInterface> _assembleAppBarActions() {
    /// 频道选择：
    final ChatChannel currentChannel = GlobalState.selectedChannel.value;
    if (currentChannel == null) return [];

    /// 创建右侧按钮容器：
    final List<AppBarActionModelInterface> actionModels = [];

    /// -设置右侧按钮颜色
    final Color iconColor = Get.theme.textTheme.bodyText2.color;
    // - 1.1、非私信横屏模式下:
    if (currentChannel.type != ChatChannelType.dm &&
        OrientationUtil.landscape) {
      // 权限：是否有邀请权限，如果有就添加邀请按钮
      ValidPermission(
          channelId: GlobalState.selectedChannel.value?.id,
          permissions: [Permission.CREATE_INSTANT_INVITE],
          builder: (value, isOwner) {
            if (value) {
              actionModels.add(AppBarIconActionModel(
                IconFont.buffModuleMenuOpen,
                showColor: iconColor,
                actionBlock: () => showShareLinkPopUp(context,
                    channel: GlobalState.selectedChannel.value),
              ));
            }
            return const SizedBox();
          });
      // 权限：是否有邀请权限，管理角色，管理频道等多种种权限，如果是就展示更多
      ValidPermission(
          channelId: GlobalState.selectedChannel.value?.id,
          permissions: [
            Permission.CREATE_INSTANT_INVITE,
            Permission.MANAGE_ROLES,
            Permission.MANAGE_CHANNELS,
          ],
          builder: (value, isOwner) {
            if (value) {
              actionModels.add(AppBarIconActionModel(
                IconFont.buffMoreHorizontal,
                showColor: iconColor,
                actionBlock: () => popChannelActions(
                    context, GlobalState.selectedChannel.value),
              ));
            }
            return const SizedBox();
          });
    }

    // 当前是否为直播频道
    final bool isLiveChannel = currentChannel.type == ChatChannelType.guildLive;
    if (!kIsWeb && isLiveChannel) {
      // 直播频道
      if (FBLiveApiProvider.instance.canStartLive()) {
        // 如果用户有开播权限，添加创建直播间按钮
        actionModels.add(
            AppBarTextPrimaryActionModel("开播", actionBlock: _createLiveAction));
      }
    } else {
      actionModels.add(AppBarIconActionModel(
        IconFont.buffChatPin,
        showColor: iconColor,
        unreadMsgNumListenable: Db.pinMessageUnreadBox
            .listenable(keys: [GlobalState.selectedChannel.value?.id]),
        selector: (box) {
          final String channelId = GlobalState.selectedChannel.value?.id;
          List<String> unread;
          if (kIsWeb) {
            // web 首次取出数据是会抛出异常
            try {
              unread = box.get(channelId) ?? [];
            } catch (e) {
              box.put(channelId, []);
            }
          } else {
            unread = box.get(channelId) ?? [];
          }
          return unread.length;
        },
        actionBlock: () =>
            Routes.pushPinListPage(context, channel: widget.channel),
      ));
    }
    if (OrientationUtil.portrait && !isLiveChannel) {
      // 如果是竖屏且不在直播频道，添加展示更多按钮
      actionModels.add(AppBarIconActionModel(
        IconFont.buffFriendList,
        showColor: iconColor,
        actionBlock: () {
          if (_isNotRecording()) {
            HomeScaffoldController.to.gotoWindow(2);
          }
        },
      ));
    }
    return actionModels;
  }

  /// 行为：开播
  Future<void> _createLiveAction({bool isToPage = true}) async {
    final LiveValueModel liveValueModel = LiveValueModel();

    /// 检查当前用户是否存在直播中的房间
    final Map dataMap = await Api.checkRoom();
    // 如果不存在就创建
    if (dataMap["status"] != 200) {
      logger.info("ChatWindow - createLiveAction: isToPage::$isToPage");
      if (!isToPage) {
        return;
      }

      final int isToPreview = await FloatUtil.pushToPreView(liveValueModel);

      /// 已跳到预览，不需要执行后面的了
      if (isToPreview == 1) {
        return;
      }

      if (kIsWeb) {
        await RouteUtil.push(context,
            CreateRoomWeb(nickName: Global.user.nickname), "createRoomWeb");
        return;
      }

      /// 关闭小窗
      await floatWindow.close();
      unawaited(RouteUtil.push(
          context,
          CreateRoom(nickName: Global.user.nickname),
          RoutePath.liveCreateRoom));
      return;
    }

    /// 如果存在就开始直播
    /// - 1、获取开播信息
    final String roomId = dataMap["data"]["roomId"];
    final String roomLogo = dataMap["data"]["roomLogo"];
    final String serverId = dataMap["data"]["serverId"];
    final int liveType = dataMap["data"]["liveType"];
    final String channelId = dataMap["data"]["channelId"];

    if (strNoEmpty(roomLogo)) {
      liveValueModel.roomInfoObject.roomLogo = roomLogo;
    }
    liveValueModel.roomInfoObject.roomId = roomId;

    /// 无法恢复直播就弹出弹窗提示，如果返回true就不再执行了
    final bool cantRestoreHandle = await DialogUtil.cantRestoreHandle(
        context, channelId, serverId, roomId, liveType,
        isShowDialog: isToPage);
    if (cantRestoreHandle) {
      return;
    }

    /// 获取状态码，如果状态码为2就继续恢复直播
    if (dataMap["data"]["status"] == 2 && OverlayView.overlayEntry != null) {
      Loading.cleanContext();
      if (isToPage) {
        floatWindow.pushToLive(FBLiveEvent.fullscreen);
      }
      return;
    }

    /// 直播恢复提示
    await ThemeDialog.themeDialogDoubleItem(
      context,
      title: '恢复直播提示',
      okText: "恢复直播",
      text: '直播意外中断了，是否继续恢复直播？',
      onPressed: () {
        if (GlobalState.selectedChannel?.value?.guildId == serverId) {
          // if (FBAPI.getCurrentChannel()?.guildId == serverId) {
          _againLiveAction(
              context, roomId, roomLogo, dataMap["data"]["liveType"] == 3);
          return;
        }
        _closeLiveAction(roomId);
      },
    );
  }

  /// 关闭直播
  Future _closeLiveAction(String roomId) async {
    final Map status = await Api.mandatoryClose(roomId);
    if (status["code"] == 200) {
      myToast("暂无直播权限");
    }
  }

  /// 重新加入直播
  Future _againLiveAction(
      BuildContext context, String roomId, String roomLogo, bool isObs) async {
    final LiveValueModel liveValueModel = LiveValueModel();

    /// 浏览器操作
    if (kIsWeb) {
      liveValueModel.roomInfoObject.roomLogo = roomLogo;
      liveValueModel.roomInfoObject.roomId = roomId;
      liveValueModel.isAnchor = true;
      liveValueModel.setObs(isObs);

      await RouteUtil.push(
          context,
          RoomMiddlePage(liveValueModel: liveValueModel),
          "liveRoomWebContainer");
      return;
    }

    /// 客户端设备操作
    if (!await PermissionManager.requestPermission(
        type: PermissionType.createRoom)) {
      // "获取权限失败";
      myFailToast('开启直播需要相机/录音权限，当前权限被禁用');
      return;
    }
    // 判断是否为obs
    // print(" 持久化存储SPManager?.sp是否为空：：${SPManager?.sp == null}");
    // final isObsLiveAndAnchor = SPManager.sp.getBool(SpKey.isObsLiveAndAnchor);
    // print("恢复直播中取到持久化存储数据为::$isObsLiveAndAnchor");
    // final String isObsLiveAndAnchor =
    //     FBAPI.getSharePref(SpKey.isObsLiveAndAnchor);
    /// 设置logo
    liveValueModel.roomInfoObject.roomLogo = roomLogo;
    liveValueModel.roomInfoObject.roomId = roomId;

    liveValueModel.setObs(isObs);
    liveValueModel.isAnchor = true;

    await RouteUtil.push(
      context,
      RoomMiddlePage(liveValueModel: liveValueModel),
      "/liveRoom",
    );
  }
}
