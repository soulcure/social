import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/common/extension/string_extension.dart';
import 'package:im/common/permission/permission_model.dart';
import 'package:im/common/permission/permission_utils.dart';
import 'package:im/dlog/dlog_manager.dart';
import 'package:im/icon_font.dart';
import 'package:im/pages/home/model/chat_index_model.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/svg_icons.dart';
import 'package:im/themes/custom_color.dart';
import 'package:im/utils/image_operator_collection/image_collection.dart';
import 'package:im/widgets/channel_icon.dart';
import 'package:websafe_svg/websafe_svg.dart';

import 'orientation_util.dart';

class WelcomeContentItem {
  final IconData iconData;
  final String title;
  final String text;
  final String guildId;
  final String channelId;

  WelcomeContentItem(
    this.iconData,
    this.title,
    this.text, {
    this.channelId,
    this.guildId,
  });
}

enum WelcomeStyle {
  Default,

  /// 入门仪式任务样式
  Task,
}

///[showArrow]显示Item右上小箭头
///[showFireworks]显示头像烟花
class WelcomeContent extends StatefulWidget {
  const WelcomeContent({
    Key key,
    @required this.imageUrl,
    this.showFireworks,
    this.showArrow = false,
    this.title,
    this.tips,
    this.bottomTips,
    this.items,
    this.buttonText,
    this.buttonPress,
    this.welcomeStyle = WelcomeStyle.Default,
    this.guildId = '',
  })  : assert(imageUrl != null, "需要图片Url"),
        super(key: key);
  final String imageUrl;
  final bool showFireworks;
  final bool showArrow;
  final List<WelcomeContentItem> items;
  final String title;
  final String tips;
  final String bottomTips;
  final VoidCallback buttonPress;
  final String buttonText;
  final WelcomeStyle welcomeStyle;
  final String guildId;

  @override
  _WelcomeContentState createState() => _WelcomeContentState();
}

class _WelcomeContentState extends State<WelcomeContent> {
  List<WelcomeContentItem> list;
  final bool landscape = OrientationUtil.landscape;

  StreamSubscription _permissionChangeStreamSubscription;

  @override
  void initState() {
    list = widget.items;
    if (widget.welcomeStyle == WelcomeStyle.Task) {
      ChatTargetsModel.instance.selectedChatTarget
          .addListener(onChannelChanged);
      _permissionChangeStreamSubscription =
          PermissionModel.allChangeStream.listen((value) {
        // 自己权限变化导致的UI更新已经处理。这里需要处理因比较权限导致的UI更新。
        onChannelChanged();
      });
    }
    super.initState();
  }

  @override
  void dispose() {
    if (widget.welcomeStyle == WelcomeStyle.Task) {
      _permissionChangeStreamSubscription?.cancel();
      ChatTargetsModel.instance.selectedChatTarget
          .removeListener(onChannelChanged);
    }
    super.dispose();
  }

  void onChannelChanged() {
    final guildInfo = ChatTargetsModel.instance?.getGuild(widget.guildId);
    final List<WelcomeContentItem> items = [];
    final gp = PermissionModel.getPermission(widget.guildId);

    for (final c in guildInfo.channels) {
      final isPrivate = PermissionUtils.isPrivateChannel(gp, c.id);
      if (isPrivate) {
        continue;
      }
      for (final element in guildInfo.welcome) {
        if (c.id == element) {
          final item = WelcomeContentItem(
              ChannelIcon.getChannelTypeIcon(c.type), c.name, c.topic,
              guildId: widget.guildId, channelId: c.id);
          items.add(item);
        }
      }
    }

    list = items;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Wrap(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).backgroundColor,
              borderRadius: _borderRadiusAdapt(),
            ),
            child: Stack(
              children: [
                _buildFireworks(),
                SafeArea(
                  child: Column(
                    children: [
                      _buildDropTag(context),
                      _buildImage(),
                      _buildTitle(),
                      _topDivider(),
                      _buildTips(),
                      _buildItemList(),
                      _bottomDivider(),
                      _buildBottomTips(),
                      const SizedBox(height: 16),
                      _buildTextButton(context),
                    ],
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  BorderRadius _borderRadiusAdapt() {
    if (landscape) {
      if (widget.welcomeStyle == WelcomeStyle.Task)
        return const BorderRadius.all(Radius.circular(12));
      else
        return const BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        );
    } else {
      return const BorderRadius.only(
        topRight: Radius.circular(12),
        topLeft: Radius.circular(12),
      );
    }
  }

  Widget _buildFireworks() {
    if (widget.showFireworks == true) {
      if (landscape && widget.welcomeStyle != WelcomeStyle.Task)
        return Padding(
          padding: const EdgeInsets.only(top: 44, left: 70, right: 70),
          child: WebsafeSvg.asset(SvgIcons.fireworks),
        );
      else
        return Padding(
          padding: const EdgeInsets.only(top: 60, left: 30, right: 30),
          child: WebsafeSvg.asset(SvgIcons.fireworks),
        );
    } else {
      return const SizedBox();
    }
  }

  Widget _buildDropTag(BuildContext context) {
    if (landscape)
      return const SizedBox();
    else
      return Center(
        child: Container(
          margin: const EdgeInsets.only(top: 8),
          width: 36,
          height: 4,
          decoration: BoxDecoration(
              color:
                  Theme.of(context).textTheme.bodyText1.color.withOpacity(0.2),
              borderRadius: const BorderRadius.all(Radius.circular(4))),
        ),
      );
  }

  Widget _buildImage() {
    return Padding(
      padding: EdgeInsets.only(
          top:
              (landscape && widget.welcomeStyle != WelcomeStyle.Task) ? 16 : 32,
          bottom: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: ImageWidget.fromNetWork(
          NetworkImageBuilder(
            widget.imageUrl,
            fit: BoxFit.cover,
            height: 80,
            width: 80,
            cacheHeight: (80 * Get.mediaQuery.devicePixelRatio).toInt(),
            cacheWidth: (80 * Get.mediaQuery.devicePixelRatio).toInt(),
          ),
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: SizedBox(
        width: 280,
        child: Center(
          child: Text(
            widget.title ?? "",
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _topDivider() {
    if (landscape)
      return const Padding(
        padding: EdgeInsets.only(bottom: 24, left: 24, right: 24),
        child: Divider(
          height: 1,
          color: Color.fromRGBO(145, 148, 153, .3),
        ),
      );
    else
      return const SizedBox();
  }

  Widget _buildTips() {
    if (widget.items?.isNotEmpty == true)
      return Padding(
        padding: const EdgeInsets.fromLTRB(30, 0, 30, 4),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            widget.tips ?? "",
            style: const TextStyle(
              color: Color.fromRGBO(101, 106, 115, 1),
            ),
          ),
        ),
      );
    else
      return const SizedBox();
  }

  Widget _buildItemList() {
    final List<bool> onTap = List.generate(list?.length ?? 0, (index) => false);
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: Get.size.height * .44),
      child: ClipRect(
        child: ListView.builder(
          shrinkWrap: true,
          padding: const EdgeInsets.only(left: 30, right: 30),
          itemCount: list?.length ?? 0,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(top: 12),
              child: IgnorePointer(
                ignoring: !widget.showArrow,
                child: GestureDetector(
                  onTap: () {
                    Get.back();
                    final channelId = list[index]?.channelId ?? '';
                    final guildId = widget.guildId ?? '';

                    final selectGuild = ChatTargetsModel
                        .instance.selectedChatTarget as GuildTarget;

                    ///如果是当前选中服务器就使用,非夸服务器选中频道
                    if (selectGuild?.id == guildId) {
                      for (final channel in selectGuild.channels) {
                        if (channel?.id == channelId) {
                          ChatTargetsModel.instance.selectedChatTarget
                              .setSelectedChannel(channel);
                          break;
                        }
                      }
                    } else {
                      /// 如果当前服务器不是欢迎界面对应的服务器,那么使用夸服务器选中频道
                      ChatTargetsModel.instance.selectChatTargetById(guildId,
                          channelId: channelId,
                          gotoChatView: channelId?.isNotEmpty ?? false);
                    }

                    /// 选择频道埋点
                    DLogManager.getInstance().customEvent(
                        actionEventId: 'click_enter_chatid',
                        actionEventSubId: channelId ?? '',
                        actionEventSubParam: '2',
                        pageId: 'page_chitchat_chat',
                        extJson: {"guild_id": guildId});
                  },
                  child: Listener(
                    onPointerDown: (details) {
                      onTap[index] = !onTap[index];
                      (context as Element).markNeedsBuild();
                    },
                    onPointerUp: (event) {
                      onTap[index] = !onTap[index];
                      (context as Element).markNeedsBuild();
                    },
                    child: Container(
                      color: onTap[index]
                          ? CustomColor(context)
                              .backgroundColor4
                              .withOpacity(0.5)
                          : Theme.of(context).backgroundColor,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(list[index].iconData, size: 16),
                              const SizedBox(width: 9),
                              Expanded(
                                child: Text(
                                  list[index]?.title ?? "",
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.headline5,
                                ),
                              ),
                              // const Spacer(),
                              if (widget.showArrow == true)
                                const Icon(
                                  IconFont.buffPayArrowNext,
                                  color: Color.fromRGBO(54, 57, 64, .65),
                                  size: 16,
                                ),
                            ],
                          ),
                          if (list != null && list[index].text.hasValue)
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Text(
                                list[index].text,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color.fromRGBO(100, 106, 115, 1),
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 4,
                              ),
                            ),
                          const SizedBox(height: 12),
                          if (index + 1 != list.length)
                            const Divider(
                              height: 0.5,
                              color: Color.fromRGBO(143, 149, 158, .2),
                            )
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _bottomDivider() {
    if (landscape)
      return const SizedBox();
    else
      return const Divider(
        height: 0.5,
        color: Color.fromRGBO(145, 148, 153, .3),
      );
  }

  Widget _buildBottomTips() {
    if (widget.bottomTips?.isNotEmpty == true)
      return SizedBox(
        height: 50,
        child: Column(
          children: [
            const SizedBox(height: 16),
            SizedBox(
              width: 200,
              child: Text(
                widget.bottomTips,
                style: const TextStyle(
                  color: Color.fromRGBO(54, 57, 64, 1),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    else
      return const SizedBox();
  }

  Widget _buildTextButton(BuildContext context) {
    return Align(
      alignment: landscape ? Alignment.centerRight : Alignment.center,
      child: Padding(
        padding: landscape
            ? const EdgeInsets.only(right: 24, bottom: 16, top: 24)
            : const EdgeInsets.only(bottom: 16),
        child: TextButton(
          style: TextButton.styleFrom(
            alignment: Alignment.center,
            minimumSize: landscape ? null : const Size(200, 40),
            backgroundColor: Theme.of(context).primaryColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(landscape ? 4 : 20),
            ),
          ),
          onPressed: widget.buttonPress,
          child: Padding(
            padding:
                landscape ? const EdgeInsets.all(10) : const EdgeInsets.all(0),
            child: Text(
              widget.buttonText ?? "",
              style: TextStyle(
                color: const Color.fromRGBO(255, 255, 255, 1),
                fontSize: landscape ? 14 : 16,
                fontWeight: landscape ? FontWeight.w400 : null,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
