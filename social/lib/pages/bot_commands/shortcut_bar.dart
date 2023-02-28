import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:get/get.dart';
import 'package:im/common/permission/permission.dart';
import 'package:im/api/entity/bot_info.dart';
import 'package:im/dlog/dlog_manager.dart';
import 'package:im/icon_font.dart';
import 'package:im/loggers.dart';
import 'package:im/pages/bot_commands/model/displayed_cmds_model.dart';
import 'package:im/pages/bot_market/bot_utils.dart';
import 'package:im/pages/home/model/chat_index_model.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/pages/home/model/live_status_model.dart';
import 'package:im/pages/home/view/bottom_bar/text_chat_bottom_bar.dart';
import 'package:im/services/connectivity_service.dart';
import 'package:im/themes/const.dart';
import 'package:im/utils/universal_platform.dart';
import 'package:im/widgets/avatar.dart';
import 'package:pedantic/pedantic.dart';

import '../../routes.dart';

const double kQuickCommandsHeight = 38;

const Duration _kAnimateDuration = Duration(milliseconds: 100);

class ShortcutBar extends StatefulWidget {
  /// 当前的聊天对象
  final ChatChannel channel;

  final FocusNode focusNode;

  final ValueNotifier<FocusIndex> focusIndex;

  const ShortcutBar(
    this.channel, {
    Key key,
    this.focusNode,
    this.focusIndex,
  }) : super(key: key);

  @override
  _ShortcutBarState createState() => _ShortcutBarState();
}

class _ShortcutBarState extends State<ShortcutBar>
    with SingleTickerProviderStateMixin {
  Animation<double> _animation;

  AnimationController _animationController;

  int _livingCount = 0;

  ValueNotifier<GuildLivingStatus> liveNotifier;

  StreamSubscription _keyboardStreamSubscription;

  List<BotCommandItem> _cmds = [];

  DisplayedCmdsController _cmdsController;

  StreamSubscription _networkSubscription;

  @override
  void initState() {
    // 动画控制器，默认是展开状态
    _animationController =
        AnimationController(value: 1, duration: _kAnimateDuration, vsync: this);
    _animation = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.ease));

    widget.focusIndex.addListener(_onFocusIndexChange);
    widget.focusNode.addListener(_onFocusChange);

    // 安卓手机可以收起键盘但是焦点还存在，这种情况需要监听键盘变化
    if (UniversalPlatform.isAndroid) {
      _keyboardStreamSubscription =
          KeyboardVisibilityController().onChange.listen(_onKeyboardChange);
    }

    _initLiveCount();

    _initChannelCmds();

    _networkSubscription =
        ConnectivityService.to.onConnectivityChanged.listen((event) {
      if (event != ConnectivityResult.none) {
        _initChannelCmds();
      }
    });

    // 监听来自控制器的刷新
    if (Get.isRegistered<DisplayedCmdsController>(tag: widget.channel.id)) {
      _cmdsController =
          Get.find<DisplayedCmdsController>(tag: widget.channel.id)
            ..addListener(_onControllerNotify);
    }

    super.initState();
  }

  void _onControllerNotify() {
    setState(() {
      _cmds = _cmdsController.btnCtlCmds ?? [];
    });
  }

  void _onFocusIndexChange() {
    if (widget.focusIndex.value == FocusIndex.none) {
      if (!widget.focusNode.hasFocus) _forward();
    } else {
      _reverse();
    }
  }

  void _onKeyboardChange(visible) {
    if (!visible && widget.focusNode.hasFocus) {
      _forward();
    }
    if (visible && widget.focusNode.hasFocus) {
      _reverse();
    }
  }

  void _onFocusChange() {
    if (widget.focusNode.hasFocus) {
      _reverse();
    } else {
      if (widget.focusIndex.value == FocusIndex.none) {
        _forward();
      }
    }
  }

  // 获取频道快捷指令
  Future _initChannelCmds() async {
    try {
      if (widget.channel == null) {
        return;
      }
      DisplayedCmdsController model;
      if (Get.isRegistered<DisplayedCmdsController>(tag: widget.channel.id)) {
        model = Get.find<DisplayedCmdsController>(tag: widget.channel.id);
      }
      if (model == null) return;

      /// 在频道聊天窗口中
      if (widget.channel.type == ChatChannelType.guildText) {
        final channelCmds = await model.getChannelCmds(
            widget.channel.id, widget.channel.guildId);
        _cmds = channelCmds;
        if (mounted) setState(() {});
      }
    } catch (e, s) {
      logger.severe("_initChannelCmds error", e, s);
    }
  }

  // 初始化直播状态和监听直播状态变化
  void _initLiveCount() {
    // 只有文字频道需要显示频道内直播状态UI
    final GuildTarget target =
        ChatTargetsModel.instance.getChatTarget(widget.channel?.guildId);
    // 显示频道内直播场数的条件：
    // 1.服务器内有直播频道
    // 2.文字频道
    // 3.未点击过此UI组件且直播场数大于0
    liveNotifier = LiveStatusManager.instance.getNotifier(target?.id);
    final showLiveHint = (target?.hasLiveChannel ?? false) &&
        liveNotifier != null &&
        (widget.channel?.type == ChatChannelType.guildText);

    if (showLiveHint) {
      _onLiveNotify();
      liveNotifier.addListener(_onLiveNotify);
    }
  }

  void _onLiveNotify() {
    setState(() {
      final livingChannels = liveNotifier.value.livingChannels ?? [];
      final ChannelLivingStatus cls = livingChannels.firstWhere(
        (element) => element.channelId == widget.channel.id,
        orElse: () => null,
      );
      _livingCount = cls?.livingCount ?? 0;
    });
  }

  // 高度变大
  void _forward() {
    if (_animationController.isAnimating) return;
    _animationController.forward();
  }

  // 高度变小
  void _reverse() {
    if (_animationController.isAnimating) return;
    _animationController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    if (_livingCount == 0 && (_cmds?.isEmpty ?? true)) {
      return const SizedBox();
    }
    final itemCount = _cmds.length + (_livingCount > 0 ? 1 : 0);

    return ValidPermission(
      channelId: widget.channel.id,
      permissions: [
        Permission.SEND_MESSAGES,
      ],
      builder: (isAllowed, isOwner) {
        if (isAllowed) return _getCommandWidget(itemCount);
        return const SizedBox();
      },
    );
  }

  Widget _getCommandWidget(int itemCount) {
    return SizeTransition(
      sizeFactor: _animation,
      axisAlignment: -1,
      child: FadeTransition(
        opacity: _animation,
        child: Container(
          height: kQuickCommandsHeight,
          alignment: Alignment.bottomLeft,
          child: SizedBox(
            height: 30,
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              separatorBuilder: (c, i) => sizeWidth8,
              itemBuilder: (c, i) {
                if (i == 0 && _livingCount > 0) {
                  return _LiveHintUI(
                    channel: widget.channel,
                    count: _livingCount,
                  );
                } else {
                  return _CommandItem(
                    channelId: widget.channel.id,
                    command: _cmds[_livingCount > 0 ? i - 1 : i],
                  );
                }
              },
              itemCount: itemCount,
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocusChange);
    widget.focusIndex.removeListener(_onFocusIndexChange);
    _cmdsController.removeListener(_onControllerNotify);
    liveNotifier?.removeListener(_onLiveNotify);
    _keyboardStreamSubscription?.cancel();
    _animationController.dispose();
    _networkSubscription.cancel();
    super.dispose();
  }
}

class _LiveHintUI extends StatelessWidget {
  final int count;
  final ChatChannel channel;

  const _LiveHintUI({Key key, @required this.count, @required this.channel})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        unawaited(Routes.pushChannelLivePage(context));
        DLogManager.getInstance().customEvent(
          actionEventId: 'live_list_entrance_click',
          actionEventSubId: 'click_live_guide_sign',
          extJson: {'guild_id': channel.guildId},
        );
      },
      child: _wrapper(
          padding: const EdgeInsets.fromLTRB(10, 6, 12, 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(
                IconFont.buffChatLive,
                color: Color(0xFFFF6040),
                size: 12,
              ),
              const SizedBox(width: 6),
              Text(
                '频道内有 $count场直播'.tr,
                style: Get.textTheme.bodyText2.copyWith(
                  fontSize: 14,
                  height: 18 / 14,
                ),
              ),
              sizeWidth4,
              SizedBox(
                width: 12,
                height: 12,
                child: Icon(
                  IconFont.buffXiayibu,
                  color: Get.textTheme.bodyText2.color,
                  size: 12,
                ),
              ),
            ],
          )),
    );
  }
}

class _CommandItem extends StatelessWidget {
  final BotCommandItem command;
  final String channelId;

  const _CommandItem(
      {Key key, @required this.command, @required this.channelId})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => BotUtils.sendCommand(
        context: context,
        channelId: channelId,
        cmd: command,
      ),
      child: _wrapper(
        child: Row(
          children: [
            Avatar(
              url: command.botAvatar,
              size: 16,
            ),
            sizeWidth4,
            Text(
              command.command ?? '',
              style: Get.theme.textTheme.bodyText2.copyWith(
                fontSize: 14,
                height: 18 / 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _wrapper(
    {Widget child,
    EdgeInsets padding = const EdgeInsets.fromLTRB(8, 6, 12, 6)}) {
  return Container(
    padding: padding,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      color: Get.theme.backgroundColor,
    ),
    child: child,
  );
}
