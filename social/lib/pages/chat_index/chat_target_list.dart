import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:im/api/user_api.dart';
import 'package:im/app/controllers/verified_controller.dart';
import 'package:im/app/modules/direct_message/controllers/direct_message_controller.dart';
import 'package:im/app/modules/home/views/components/create_guild_icon.dart';
import 'package:im/app/modules/home/views/home_scaffold_view.dart';
import 'package:im/app/modules/manage_guild/models/ban_type.dart';
import 'package:im/app/theme/app_theme.dart';
import 'package:im/dlog/dlog_manager.dart';
import 'package:im/icon_font.dart';
import 'package:im/pages/chat_index/chat_dock_view.dart';
import 'package:im/pages/chat_index/components/land_create_or_join_server_pop.dart';
import 'package:im/pages/guild_setting/guild/container_image.dart';
import 'package:im/pages/home/components/red_dot.dart';
import 'package:im/pages/home/model/chat_index_model.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/routes.dart';
import 'package:im/themes/const.dart';
import 'package:im/themes/custom_color.dart';
import 'package:im/themes/default_theme.dart';
import 'package:im/utils/custom_cache_manager.dart';
import 'package:im/utils/orientation_util.dart';
import 'package:im/utils/universal_platform.dart';
import 'package:im/utils/utils.dart';
import 'package:im/widgets/list_view/clamp_sliver_reorder.dart';
import 'package:provider/provider.dart';

class ChatTargetList extends StatefulWidget {
  static BoxShadow get iconShadow {
    return BoxShadow(
      color: const Color(0xFF646A73).withOpacity(1),
      offset: const Offset(0, 2),
      blurRadius: 8,
      spreadRadius: -10,
    );
  }

  @override
  _ChatTargetListState createState() => _ChatTargetListState();
}

class _ChatTargetListState extends State<ChatTargetList> {
  Future<bool> _future;

  @override
  void initState() {
    super.initState();
    _future = () async {
      return UserApi.getAllowRoster('guild');
    }();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        if (Theme.of(context).platform == TargetPlatform.macOS)
          const SizedBox(height: 25),
        Expanded(
          child: Consumer<ChatTargetsModel>(
            builder: (context, model, _) {
              final chatTargets = model.chatTargets;
              return _buildChatTargetsDock(chatTargets);
            },
          ),
        ),
      ],
    );
  }

  /// ??????dock
  ///
  ///???TODO ?????????????????????????????????????????????????????????????????????????????????
  ///
  /// [ChatTargetsModel.instance]??????[chatTargets]??????????????????????????????????????????????????????.
  /// [DockView]??????itemCount???????????????????????????????????????itemCount?????????
  /// ???????????????guildStartIndex????????????[chatTargets]??????guildStartIndex???????????????
  /// header???????????????????????????????????????????????????????????????????????????
  ///
  Widget _buildChatTargetsDock(List<BaseChatTarget> chatTargets) {
    return NotificationListener<ClampReorderableNotification>(
      onNotification: (notification) {
        //????????????????????????????????????????????????(web?????????????????????????????????)
        if (notification.event == ClampReorderEvent.startDrag) {
          HapticFeedback.heavyImpact();
        } else if (notification.event == ClampReorderEvent.endDrag) {
          HapticFeedback.heavyImpact();
          delay(HapticFeedback.heavyImpact, 150);
        } else if (notification.event == ClampReorderEvent.updateItem) {
          HapticFeedback.lightImpact();
        }
        return true;
      },
      child: DockView.builder(
        header: OrientationUtil.landscape
            ? const _Item(null, key: ValueKey('dmListTarget.id'))
            : null,
        footer: CreateGuildButton(onPressed: () => showGuildActions(context)),
        itemBuilder: (context, index) {
          // ?????????index????????????????????????guildTargets?????????
          final guildIndex = index + ChatTargetsModel.instance.guildStartIndex;
          final BaseChatTarget target = chatTargets[guildIndex];
          return _Item(target, key: ValueKey(target?.id ?? 'direct_chat'));
        },
        itemCount:
            chatTargets.length - ChatTargetsModel.instance.guildStartIndex,
        onReorder: (oldIndex, newIndex) {
          // ?????????index???ClampReorderableListView???item???index,
          // ???????????????chatTargets????????????????????????????????????????????????
          oldIndex += ChatTargetsModel.instance.guildStartIndex;
          newIndex += ChatTargetsModel.instance.guildStartIndex;
          if (oldIndex < newIndex) newIndex -= 1;
          ChatTargetsModel.instance.swapChatTarget(oldIndex, newIndex);
        },
      ),
    );
  }

  // ???????????????
  Future<void> showGuildActions(BuildContext context) async {
    Widget _buildGuildAction({
      IconData icon,
      Color iconColor,
      String title = '',
      String subtitle = '',
      Function onTap,
      Color titleColor = const Color(0xFF333333),
      Color subtitleColor = const Color(0xFF6D6F73),
      Color backgroundColor = Colors.white,
      EdgeInsetsGeometry padding,
      BorderRadius borderRadius,
    }) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          padding: padding,
          decoration:
              BoxDecoration(color: backgroundColor, borderRadius: borderRadius),
          child: Row(
            children: <Widget>[
              SizedBox(
                width: 28,
                height: 28,
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 28,
                ),
              ),
              sizeWidth24,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: TextStyle(
                          color: titleColor,
                          fontSize: 16,
                          height: 1.25,
                          fontWeight: FontWeight.bold),
                    ),
                    sizeHeight6,
                    Text(
                      subtitle,
                      style: TextStyle(
                          color: subtitleColor, fontSize: 14, height: 1.25),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      );
    }

    Widget _buildCreateServerUi({Function onTap}) => _buildGuildAction(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
          icon: IconFont.buffCreateGuild,
          iconColor: appThemeData.textTheme.bodyText1.color,
          title: '???????????????'.tr,
          subtitle: '??????????????????????????????????????????'.tr,
          onTap: onTap,
        );

    if (OrientationUtil.landscape) {
      await Get.dialog(
        GetBuilder<VerifiedController>(
          init: VerifiedController(),
          builder: (controller) => LandCreateOrJoinServerPop(
            future: _future,
            onCreatePress: (_) {
              Get.back();
              controller.onTap();
            },
            onJoinPress: () {
              Get.back();
              Routes.pushJoinGuildPage(context);
            },
          ),
        ),
      );
    } else {
      await showModalBottomSheet(
        backgroundColor: Colors.transparent,
        context: context,
        builder: (context) {
          return Container(
            margin: const EdgeInsets.fromLTRB(24, 0, 24, 58),
            child: ClipRRect(
              borderRadius: const BorderRadius.all(Radius.circular(8)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  GetBuilder<VerifiedController>(
                    init: VerifiedController(),
                    builder: (controller) => _buildCreateServerUi(onTap: () {
                      Get.back();
                      controller.onTap();
                      DLogManager.getInstance().customEvent(
                        actionEventId: "guild_apply_create",
                        actionEventSubId: "click_create",
                        actionEventSubParam: "home_page",
                      );
                    }),
                  ),
                  const Divider(),
                  _buildGuildAction(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                      icon: IconFont.buffJoinGuild,
                      iconColor: appThemeData.textTheme.bodyText1.color,
                      title: '???????????????'.tr,
                      subtitle: '?????????????????????????????????????????????'.tr,
                      // borderRadius: const BorderRadius.vertical(
                      //   bottom: Radius.circular(8),
                      // ),
                      onTap: () {
                        Get.back();
                        Routes.pushJoinGuildPage(context);
                      }),
                ],
              ),
            ),
          );
        },
      );
    }
  }
}

class _Item extends StatefulWidget {
  final BaseChatTarget chatTarget;

  const _Item(this.chatTarget, {Key key}) : super(key: key);

  @override
  _ItemState createState() => _ItemState();
}

class _ItemState extends State<_Item> with SingleTickerProviderStateMixin {
  ColorTween _colorTween;
  ColorTween _borderColorTween;

  static const _iconSize = 48.0;
  AnimationController _animationController;

  bool get _isSelected =>
      widget.chatTarget?.id == ChatTargetsModel.instance.selectedChatTarget?.id;

  @override
  void initState() {
    _animationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _borderColorTween =
        ColorTween(begin: primaryColor.withOpacity(0), end: primaryColor);
    if (_isSelected) {
      _animationController.forward();
    }
    ChatTargetsModel.instance.addListener(_doSelectionAnim);

    super.initState();
  }

  @override
  void dispose() {
    ChatTargetsModel.instance.removeListener(_doSelectionAnim);
    _animationController.dispose();
    super.dispose();
  }

  void _doSelectionAnim() {
    if (_isSelected) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final _iconRenderSize = MediaQuery.of(context).devicePixelRatio * _iconSize;
    _colorTween = ColorTween(begin: const Color(0xFFf0f1f2), end: primaryColor);
    final chatTarget = widget.chatTarget;
    return ChangeNotifierProvider.value(
      value: chatTarget,
      builder: (_, __) => GestureDetector(
        onTap: () {
          if (UniversalPlatform.isMobileDevice) HapticFeedback.lightImpact();
          ChatTargetsModel.instance.selectChatTarget(chatTarget,
              channel: chatTarget?.defaultChannel);
        },
        child: Selector<ChatTargetsModel, BaseChatTarget>(
          selector: (_, model) => model.selectedChatTarget,
          builder: (context, selectedChatTarget, child) {
            final bool isSelected = selectedChatTarget == chatTarget;

            Widget child;
            final target = chatTarget as GuildTarget;

            if (target == null) {
              child = _itemWrapper(
                context,
                child: Icon(
                  IconFont.buffChannelMessage,
                  color: isSelected
                      ? Colors.white
                      : OrientationUtil.landscape
                          ? Theme.of(context).textTheme.bodyText2.color
                          : Theme.of(context).disabledColor,
                ),
              );
            } else if (isNotNullAndEmpty(target.icon)) {
              child = ValueListenableBuilder(
                  valueListenable: target.iconNotifier,
                  builder: (context, value, child) {
                    final imageUrl = value ?? target.icon ?? '';
                    return _itemWrapper(context,
                        target: target,
                        image: imageUrl,
                        renderSize: _iconRenderSize);
                  });
            } else {
              child = _itemWrapper(
                context,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(target.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .bodyText2
                          .copyWith(fontSize: 12)),
                ),
              );
            }

            return ValueListenableBuilder(
              valueListenable: target == null
                  ? DirectMessageController.numUnreadMute
                  : chatTarget.numUnread,
              builder: (context, value, child) {
                int redCount = 0;
                if (value is Unread) {
                  redCount = value.normalUnread + value.muteUnread;
                } else if (value is int) {
                  redCount = value;
                }

                return SizedBox(
                  // ???????????????54??????2????????????Dock???????????????????????????padding
                  // ?????????????????????????????????2.
                  height: 58,
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: <Widget>[
                      AnimatedBuilder(
                        animation: _animationController,
                        builder: (context, _) {
                          const double size = 54;
                          return Container(
                            decoration: BoxDecoration(
                                boxShadow: [ChatTargetList.iconShadow],
                                //???????????????????????????icon??????????????????
                                color: isSelected
                                    ? CustomColor(context).backgroundColor1
                                    : Colors.transparent,
                                border: Border.all(
                                    color: _borderColorTween
                                        .transform(_animationController.value),
                                    width: 2),
                                borderRadius: BorderRadius.circular(size / 5)),
                            alignment: Alignment.center,
                            height: size,
                            width: size,
                            child: child,
                          );
                        },
                      ),
                      // ???????????????
                      Visibility(
                        visible: widget.chatTarget != null && redCount > 0,
                        // TODO ?????????????????? RedDot ???????
                        child: Align(
                          alignment: Alignment.topRight,
                          child: Container(
                            width: 14,
                            height: 14,
                            margin: const EdgeInsets.only(right: 7),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: HomeScaffoldView.backgroundColor,
                            ),
                            alignment: Alignment.center,
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: DefaultTheme.dangerColor,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Visibility(
                        visible: widget.chatTarget == null && redCount > 0,
                        child: Positioned(
                            top: 0,
                            right: 8,
                            child: RedDot(
                              redCount,
                              borderColor:
                                  CustomColor(context).backgroundColor1,
                            )),
                      ),
                    ],
                  ),
                );
              },
              child: child,
            );
          },
        ),
      ),
    );
  }

  Widget _itemWrapper(BuildContext context,
      {GuildTarget target,
      String image,
      double renderSize = _iconSize,
      Widget child}) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(_iconSize / 6),
          child: Container(
            width: _iconSize,
            height: _iconSize,
            decoration: BoxDecoration(
              color: _colorTween.transform(_animationController.value),
            ),
            child: child ??
                (image == null
                    ? const SizedBox()
                    : _buildGuildIcon(target, image, _iconSize, renderSize)),
          ),
        );
      },
      child: child,
    );
  }

  ///???????????????
  Widget _buildGuildIcon(
      GuildTarget target, String image, double size, double renderSize) {
    return ObxValue<Rx<BanType>>((_) {
      if (target.isBan) {
        return Container(
          alignment: Alignment.center,
          color: Colors.red,
          child: const Icon(IconFont.buffRoundExclamations,
              size: 24, color: Colors.white),
        );
      } else {
        return ContainerImage(
          image,
          cacheManager: CustomCacheManager.instance,
          width: size,
          height: size,
          thumbWidth: renderSize.toInt(),
          fit: BoxFit.cover,
        );
      }
    }, target.bannedLevel);
  }
}
