import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:get/get.dart';
import 'package:im/app/modules/home/controllers/home_scaffold_controller.dart';
import 'package:im/pages/home/home_page.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/pages/home/model/text_channel_controller.dart';
import 'package:im/pages/home/view/audio/audio_bar.dart';
import 'package:im/pages/video/model/video_room_controller.dart';
import 'package:im/pages/video/view/video_room_float_bar.dart';
import 'package:im/widgets/audio_player_manager.dart';
import 'package:im/widgets/network_audio_bar.dart';

import '../../../loggers.dart';

class Dock extends StatefulWidget {
  static GlobalKey<_DockState> instanceKey = GlobalKey();

  ///不调用updateDock方法: 默认为false
  static bool noUpdateDock = false;

  /// 由于此类的初始化退出登录再登录会导致初始化两次
  /// 导致系统出错,其他功能异常(比如私聊 / 频道表态不能表态)
  /// 如果初始化后,不在进行初始化
  /// 临时解决方案,后期在处理
  static bool isInit = false;

  const Dock({Key key}) : super(key: key);

  @override
  _DockState createState() => _DockState();

  static void init(BuildContext context) {
    bool _onNotification(Notification notification) {
      if (notification is RestoreMediaChannelViewNotification) {
        final mediaChannel = GlobalState.mediaChannel.value;
        if (mediaChannel != null) {
          if (mediaChannel.item2?.type == ChatChannelType.guildVoice) {
            ///点击悬浮窗：为了防止调用updateDock重复显示悬浮窗，noUpdateDock先改为true，语音频道弹窗关闭时，再改为false
            Dock.noUpdateDock = true;
            HomePage.showAudioRoom(mediaChannel.item2.id);
          } else {
            Dock.noUpdateDock = true;
            mediaChannel.item1
                .setSelectedChannel(mediaChannel.item2, notify: true);
          }

          Dock.hide();
        }
      } else if (notification is RestoreAudioPlayerViewNotification) {
        Dock.hide();
      }
      return true;
    }

    if (!isInit) {
      Future.delayed(const Duration(milliseconds: 500)).then((value) {
        Overlay.of(context, rootOverlay: true).insert(OverlayEntry(
            builder: (_) => NotificationListener(
                onNotification: _onNotification,
                child: Dock(key: Dock.instanceKey))));
      });
      Dock.isInit = true;
    }
  }

  static void updateDock() {
    if (Dock.noUpdateDock) return;
    // if (GlobalState.selectedChannel.value == null) return;

    final currentCategory = GlobalState.isDmChannel
        ? ChatChannelType.dm
        : GlobalState.selectedChannel.value?.type;
    final currentChannelId = TextChannelController.dmChannel?.id ??
        GlobalState.selectedChannel.value?.id ??
        '';
    final playerIsPlaying = AudioPlayerManager.isInPlaying;
    final playerChannelId = AudioPlayerManager.currentChannelId;
    // 没有在媒体房间内 并且 没有播放音频，不需要显示停靠栏
    if (GlobalState.mediaChannel.value == null && !playerIsPlaying) {
      Dock.hide();
      return;
    }

    // 虽然在媒体房间内，但是当前已经显示媒体房间页面，也不需要显示停靠栏
    final isInMediaRoom =
        (HomeScaffoldController.to.canChatWindowVisible || kIsWeb) &&
            (currentCategory == ChatChannelType.guildVideo ||
                currentCategory == ChatChannelType.guildVoice);
    final isInPlayerRoom =
        (HomeScaffoldController.to.canChatWindowVisible || kIsWeb) &&
            (playerIsPlaying && playerChannelId == currentChannelId);
    if (isInMediaRoom || isInPlayerRoom) {
      Dock.hide();
      return;
    }

    final mediaRoomCategory = GlobalState.mediaChannel.value?.item2?.type;
    if (mediaRoomCategory == ChatChannelType.guildVoice)
      Dock.show(AudioBar(GlobalState.mediaChannel.value?.item2?.id));
    else if (mediaRoomCategory == ChatChannelType.guildVideo) {
      VideoRoomController c;
      final roomId = GlobalState.mediaChannel.value?.item2?.id;
      try {
        c = Get.find<VideoRoomController>(tag: roomId);
      } catch (e, s) {
        logger.severe("video room controller find tag $roomId error", e, s);
      }
      if (c != null) Dock.show(VideoRoomFloatBar(roomId));
      // Dock.show(VideoBar(VideoRoomModel.instance));
    } else if (playerIsPlaying &&
        (HomeScaffoldController.to.windowIndex.value != 1 &&
            !GlobalState.isDmChannel)) Dock.show(PlayerBar());
  }

  static void show(Widget child, {bool customControl = false}) {
    Dock.noUpdateDock = customControl;
    instanceKey.currentState.show(child);
  }

  static void hide() {
    if (instanceKey.currentState != null) {
      instanceKey.currentState.hide();
    }
  }
}

class _DockState extends State<Dock> with SingleTickerProviderStateMixin {
  AnimationController _controller;
  Animation<Offset> _animation;

  Widget _child = const SizedBox();
  double _opacity = 0;

  Size _windowSize;
  Offset pos;

  /// Calculates and runs a [SpringSimulation].
  void _runAnimation(Offset pixelsPerSecond) {
    final width = context?.size?.width ?? 90;
    final height = context?.size?.height ?? 138;
    final endX = pos.dx + width / 2 < _windowSize.width / 2
        ? 0.0
        : _windowSize.width - width;
    final endY = max(0, min(pos.dy, _windowSize.height - height));
    _animation = _controller.drive(
      Tween<Offset>(
        begin: pos,
        end: Offset(endX, endY),
      ),
    );
    // Calculate the velocity relative to the unit interval, [0,1],
    // used by the animation controller.
    final unitsPerSecondX = pixelsPerSecond.dx / _windowSize.width;
    final unitsPerSecondY = pixelsPerSecond.dy / _windowSize.height;
    final unitsPerSecond = Offset(unitsPerSecondX, unitsPerSecondY);
    final unitVelocity = unitsPerSecond.distance;

    const spring = SpringDescription(
      mass: 40,
      stiffness: 1,
      damping: 1,
    );

    final simulation = SpringSimulation(spring, 0, 1, -unitVelocity);

    _controller.animateWith(simulation);
  }

  @override
  void didChangeDependencies() {
    if (_windowSize == null || pos == null) {
      _windowSize = MediaQuery.of(context).size;
      pos = Offset(
        _windowSize.width - 90,
        _windowSize.height - 138 - 150,
      );
    }

    super.didChangeDependencies();
  }

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(vsync: this);

    _controller.addListener(() {
      setState(() {
        pos = _animation.value;
      });
    });
  }

  void show(Widget child) {
    _child = child;

    Future.delayed(kThemeAnimationDuration, () {
      setState(() {
        // 这里设置透明度时，Texture渲染视频时会卡顿
        // see: https://github.com/flutter/flutter/issues/83887
        _opacity = 1.0;
      });
    });
  }

  void hide() {
    setState(() {
      Future.delayed(kThemeAnimationDuration, () {
        _child = const SizedBox();
      });
      _opacity = 0;
    });
  }

  @override
  void dispose() {
    Dock.isInit = false;
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // final statusBarHeight = MediaQueryData.fromWindow(window).viewInsets.top;
    return Positioned(
      top: pos.dy,
      left: pos.dx,
      child: SafeArea(
          child: Material(
        color: Colors.transparent,
        child: AnimatedOpacity(
          duration: kThemeAnimationDuration,
          opacity: _opacity,
          curve: Curves.easeOut,
          child: GestureDetector(
            onPanDown: (details) {
              _controller.stop();
            },
            onPanUpdate: (details) {
              setState(() {
                final offset =
                    pos.translate(details.delta.dx, details.delta.dy);
                pos = Offset(max(8, offset.dx), max(8, offset.dy));
              });
            },
            onPanEnd: (details) {
              _runAnimation(details.velocity.pixelsPerSecond);
            },
            child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Theme.of(context).backgroundColor,
                  boxShadow: const [
                    BoxShadow(
                      blurRadius: 20,
                      offset: Offset(0, 1),
                      color: Color(0x406A7480),
                    )
                  ],
                ),
                child: _child),
          ),
        ),
      )),
    );
  }
}
