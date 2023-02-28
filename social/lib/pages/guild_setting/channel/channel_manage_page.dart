import 'dart:ui';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:im/api/channel_api.dart';
import 'package:im/app/theme/app_theme.dart';
import 'package:im/common/permission/permission.dart';
import 'package:im/common/permission/permission_model.dart';
import 'package:im/common/permission/permission_utils.dart';
import 'package:im/db/db.dart';
import 'package:im/global.dart';
import 'package:im/pages/guild_setting/circle/circle_setting/topic_name_editor_page.dart';
import 'package:im/pages/home/model/chat_index_model.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/quest/fb_quest_config.dart';
import 'package:im/routes.dart';
import 'package:im/themes/custom_color.dart';
import 'package:im/themes/default_theme.dart';
import 'package:im/utils/show_action_sheet.dart';
import 'package:im/utils/show_confirm_dialog.dart';
import 'package:im/utils/utils.dart';
import 'package:im/widgets/app_bar/appbar_button.dart';
import 'package:im/widgets/app_bar/custom_appbar.dart';
import 'package:im/widgets/button/more_icon.dart';
import 'package:im/widgets/channel_icon.dart';
import 'package:im/widgets/realtime_user_info.dart';
import 'package:oktoast/oktoast.dart';
import 'package:pedantic/pedantic.dart';
import 'package:quest_system/quest_system.dart';
import 'package:tuple/tuple.dart';

import '../../../icon_font.dart';

class ChannelManagePage extends StatefulWidget {
  @override
  _ChannelManagePageState createState() => _ChannelManagePageState();
}

class _ChannelManagePageState extends State<ChannelManagePage>
    with SingleTickerProviderStateMixin {
  // null: 非编辑状态(普通状态)  0: 编辑分类 1: 编辑频道
  int _editType;
  AnimationController _animationController;
  ThemeData _theme;
  List<String> _originChannelOrder;
  List<String> _newChannelOrder;
  List<ChatChannel> _originSortedChannels = [];
  List<ChatChannel> _newSortedChannels = [];
  List<ChatChannel> _categoryChannels = [];
  bool _loading = false;
  bool _orderChanged = false;
  GuildTarget _currentSelectedGuild;

  @override
  void initState() {
    _animationController = AnimationController(
        value: 1, duration: const Duration(milliseconds: 300), vsync: this);

    _currentSelectedGuild =
        ChatTargetsModel.instance.selectedChatTarget as GuildTarget;
    _currentSelectedGuild.addListener(reset);
    reset();
    super.initState();
  }

  void reset() {
    // 判断ui刷新条件，不处于编辑状态可以刷新
    if (_editType != null) {
      final Function eq = const ListEquality().equals;
      final List<String> oldIds =
          _currentSelectedGuild.channels.map((e) => e.id).toList();
      final List<String> newIds =
          _originSortedChannels.map((e) => e.id).toList();

      if (!eq(oldIds, newIds) ||
          !eq(_currentSelectedGuild.channelOrder, _newChannelOrder)) {
        // 顺序改变需要回到非编辑状态
        _editType = null;
        _orderChanged = false;
        _animationController.forward();
      }
    }

    setState(() {
      _originSortedChannels = [..._currentSelectedGuild.channels];
      _newSortedChannels = _originSortedChannels.map((e) => e.clone()).toList();
      _categoryChannels = _newSortedChannels
          .where((element) => element.type == ChatChannelType.guildCategory)
          .toList();
      _originChannelOrder = _currentSelectedGuild.channelOrder;
      _newChannelOrder = List.from(_originChannelOrder);
    });
  }

  @override
  void dispose() {
    _currentSelectedGuild.removeListener(reset);
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      /// 触发任务检查
      CustomTrigger.instance.dispatch(
        QuestTriggerData(
          condition: QuestCondition([
            QIDSegQuest.understandChannelManage,
            ChatTargetsModel.instance.selectedChatTarget.id,
          ]),
        ),
      );
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _theme = Theme.of(context);
    final tempChannels =
        _editType != null ? _newSortedChannels : _originSortedChannels;
    final List<Widget> rows = tempChannels.map((e) {
      if (_editType == 0) {
        if (e.type == ChatChannelType.guildCategory) {
          return ReorderableDelayedDragStartListener(
              key: Key(e.id),
              index: tempChannels.indexOf(e),
              child: _buildItem(e, tempChannels));
        }
        return SizedBox(key: Key(e.id));
      } else if (_editType == 1) {
        if (e.type != ChatChannelType.guildCategory) {
          return ReorderableDelayedDragStartListener(
              key: Key(e.id),
              index: tempChannels.indexOf(e),
              child: _buildItem(e, tempChannels));
        }
        return SizedBox(key: Key(e.id), child: _buildItem(e, tempChannels));
      } else {
        return SizedBox(key: Key(e.id), child: _buildItem(e, tempChannels));
      }
    }).toList();

    String title = '管理频道'.tr;
    if (_editType == 0) {
      title = '频道分类排序'.tr;
    } else if (_editType == 1) {
      title = '频道排序'.tr;
    }
    return Scaffold(
        appBar: CustomAppbar(
          title: title,
          leadingBuilder: (icon) {
            return AppbarCustomButton(
              child: _editType == null
                  ? AppbarIconButton(
                      icon: IconFont.buffNavBarBackItem,
                      onTap: () {
                        Get.back();
                      },
                    )
                  : AppbarCancelButton(onTap: () {
                      setState(() {
                        _newSortedChannels = _originSortedChannels
                            .map((e) => e.clone())
                            .toList();
                        _categoryChannels = _newSortedChannels
                            .where((element) =>
                                element.type == ChatChannelType.guildCategory)
                            .toList();
                        _newChannelOrder = List.from(_originChannelOrder);
                        _editType = null;
                      });
                      unawaited(_animationController.forward());
                    }),
            );
          },
          actions: [
            if (_editType == null) ...[
              AppbarIconButton(
                icon: IconFont.buffChannelSort,
                onTap: _toggleEdit,
              ),
              AppbarIconButton(
                icon: IconFont.buffAdd,
                onTap: _createChannelOrCategory,
              )
            ] else
              AppbarTextButton(
                loading: _loading,
                onTap: _toggleEdit,
                text: '完成'.tr,
              ),
          ],
        ),
        body: ReorderableList(
          padding:
              EdgeInsets.only(top: 16, bottom: Get.mediaQuery.padding.bottom),
          proxyDecorator: _proxyDecorator,
          onReorder: _onReorder,
          itemCount: rows.length,
          itemBuilder: (c, index) {
            return rows[index];
          },
        ));
  }

  Widget _proxyDecorator(Widget child, int index, Animation<double> animation) {
    final channels = _newSortedChannels;
    bool isFirst = false;
    bool isLast = false;
    if (_editType == 0) {
      isFirst = _categoryChannels.first?.id == channels[index].id;
      isLast = _categoryChannels.last?.id == channels[index].id;
    } else {
      isFirst = index == 0 ||
          channels[index - 1].type == ChatChannelType.guildCategory;
      isLast = index == channels.length - 1 ||
          channels[index + 1].type == ChatChannelType.guildCategory;
    }
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final double animValue = Curves.easeInOut.transform(animation.value);
        final double radius = lerpDouble(0, 2, animValue);
        return Material(
          color: Colors.transparent,
          child: Stack(
            children: [
              Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(isFirst ? 8 : 0),
                        bottom: Radius.circular(isLast ? 8 : 0),
                      ),
                      boxShadow: [
                        BoxShadow(
                            color: Theme.of(context).dividerColor,
                            blurRadius: radius,
                            spreadRadius: radius)
                      ])),
              child,
            ],
          ),
        );
      },
      child: child,
    );
  }

  /// 创建分类 / 创建频道
  Future<void> _createChannelOrCategory() async {
    final res = await showCustomActionSheet([
      Text(
        '创建频道分类'.tr,
        style: TextStyle(color: _theme.textTheme.bodyText2.color),
      ),
      Text(
        '创建频道'.tr,
        style: TextStyle(color: _theme.textTheme.bodyText2.color),
      )
    ]);

    if (res == null || res == -1) return;
    if (res == 0) {
      await Routes.pushUpdateChannelCatePage(context, _currentSelectedGuild.id);
    } else if (res == 1) {
      final Tuple2 rtn =
          await Routes.pushChannelCreation(context, _currentSelectedGuild.id);
      final c = rtn?.item1;
      if (c != null) {
        final index = _currentSelectedGuild.channels.lastIndexWhere((e) =>
                isNotNullAndEmpty(e.parentId) &&
                e.type != ChatChannelType.guildCategory) +
            1;
        _currentSelectedGuild.channelOrder.insert(index, c.id);
        _currentSelectedGuild.addChannel(c,
            notify: true,
            initPermissions: rtn?.item2 as List<PermissionOverwrite>);
        unawaited(Db.channelBox.put(c.id, c));
      }
    }
  }

  Future<void> _toggleEdit() async {
    if (_editType == null) {
      final res = await showCustomActionSheet([
        Text(
          '频道分类排序'.tr,
          style: TextStyle(color: _theme.textTheme.bodyText2.color),
        ),
        Text(
          '频道排序'.tr,
          style: TextStyle(color: _theme.textTheme.bodyText2.color),
        )
      ]);
      if (res == null || res == -1) return;

      if (res == 0) {
        final bool isHaveCategory = _originSortedChannels
            .any((element) => element.type == ChatChannelType.guildCategory);
        if (!isHaveCategory) {
          showToast('暂无频道分类'.tr);
          return;
        }
      } else {
        final isHaveChannel = _originSortedChannels
            .any((element) => element.type != ChatChannelType.guildCategory);
        if (!isHaveChannel) {
          showToast('暂无频道'.tr);
          return;
        }
      }
      setState(() {
        _editType = res;
        if (res == 0) {
          _animationController.reverse();
        } else {
          _animationController.forward();
        }
      });
    } else {
      if (!_orderChanged) {
        setState(() {
          _editType = null;
        });
        unawaited(_animationController.forward());
        return;
      }
      try {
        _toggleLoading(true);
        final Map<String, String> groupChangedChannel = {};
        for (var i = 0; i < _newSortedChannels.length; i++) {
          final channel = _newSortedChannels[i];
          if (channel.type != ChatChannelType.guildCategory) {
            final category = _newSortedChannels.getRange(0, i).lastWhere(
                (element) => element.type == ChatChannelType.guildCategory,
                orElse: () => null);
            if (category == null) {
              if (channel.parentId != '') {
                groupChangedChannel[channel.id] = '';
              }
              channel.parentId = '';
            } else {
              if (channel.parentId != category.id) {
                groupChangedChannel[channel.id] = category.id;
              }
              channel.parentId = category.id;
            }
          }
        }
        await ChannelApi.orderChannel(_currentSelectedGuild.id, Global.user.id,
            groupChangedChannel, _newChannelOrder);
        ChatTargetsModel.instance.updateChannelsPosition(
            _currentSelectedGuild, _newChannelOrder,
            channels: _newSortedChannels);

        _originSortedChannels =
            _newSortedChannels.map((e) => e.clone()).toList();
        _originChannelOrder = List.from(_newChannelOrder);

        _editType = null;
        _toggleLoading(false);
        unawaited(_animationController.forward());
        _orderChanged = false;
      } catch (e) {
        _toggleLoading(false);
      }
    }
  }

  void _toggleLoading(bool value) {
    setState(() {
      _loading = value;
    });
  }

  Future<void> _createChannel(ChatChannel channel) async {
    final Tuple2 rtn = await Routes.pushChannelCreation(
        context, _currentSelectedGuild.id,
        cateId: channel.id);
    final c = rtn?.item1;
    if (c != null) {
      final index = _currentSelectedGuild.channels.lastIndexWhere((e) =>
              isNotNullAndEmpty(e.parentId) &&
              e.type != ChatChannelType.guildCategory) +
          1;
      _currentSelectedGuild.channelOrder.insert(index, c.id);
      _currentSelectedGuild.addChannel(c,
          notify: true,
          initPermissions: rtn?.item2 as List<PermissionOverwrite>);
      unawaited(Db.channelBox.put(c.id, c));
    }
  }

  Future<void> _deleteChannel(ChatChannel channel) async {
    // if (_deleteLoading) return;
    final res = await showConfirmDialog(
        title: '删除频道分类'.tr,
        content: '确定将 %s 删除？一旦删除不可撤销。'.trArgs([channel.name]));
    if (res != true) return;
    // _deleteLoading = true;
    // 删除频道分类需要把分类下的频道移除到无分类的频道的最后面
    final GuildTarget gt =
        ChatTargetsModel.instance.selectedChatTarget as GuildTarget;
    final newChannels = [...gt.channels];
    final changedChannels =
        newChannels.where((element) => element.parentId == channel.id).toList();

    newChannels.removeWhere((element) =>
        changedChannels.contains(element) || element.id == channel.id);
    // 寻找最后一个无分类频道的index
    final index = gt.channels.lastIndexWhere((element) =>
        (element.parentId == '' || element.parentId == null) &&
        element.type != ChatChannelType.guildCategory);
    changedChannels.forEach((element) {
      element.parentId = '';
    });
    newChannels.insertAll(index == -1 ? 0 : (index + 1), changedChannels);
    final channelOrder = newChannels.map((e) => e.id).toList();
    try {
      await ChannelApi.removeChannel(
          channel.guildId, Global.user.id, channel.id, channelOrder);
      gt.channels
        ..clear()
        ..addAll(newChannels);
      gt.channelOrder = channelOrder;
      // ignore: invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member
      gt.notifyListeners();
      // _deleteLoading = false;
      unawaited(Db.channelBox.delete(channel.id));
    } catch (e) {
      // _deleteLoading = false;
    }
  }

  Widget _buildCategory(ChatChannel channel, List<ChatChannel> channels) {
    final isFirstChannel = channel.id == channels.first?.id;
    if (_editType == 0) {
      final isFirstItem = channels
              .firstWhere(
                  (element) => element.type == ChatChannelType.guildCategory)
              ?.id ==
          channel.id;
      final isLastItem = channels
              .lastWhere(
                  (element) => element.type == ChatChannelType.guildCategory)
              ?.id ==
          channel.id;
      return Column(
        children: [
          Container(
              decoration: BoxDecoration(
                  color: _theme.backgroundColor,
                  borderRadius: BorderRadius.vertical(
                      top: Radius.circular(isFirstItem ? 8 : 0),
                      bottom: Radius.circular(isLastItem ? 8 : 0))),
              height: 43,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Expanded(
                    child: RealtimeChannelName(
                      channel.id,
                      style: _theme.textTheme.bodyText2,
                    ),
                  ),
                  Listener(
                    onPointerDown: (e) {
                      HapticFeedback.heavyImpact();
                    },
                    child: ReorderableDragStartListener(
                      index: channels.indexOf(channel),
                      child: Container(
                        alignment: Alignment.centerRight,
                        color: Colors.transparent,
                        width: 60,
                        child: Icon(
                          IconFont.buffChannelMoveEditLarge,
                          color: const Color(0xFF747F8D).withOpacity(0.5),
                          size: 22,
                        ),
                      ),
                    ),
                  )
                ],
              )),
          Container(
            color: _theme.backgroundColor,
            child: Divider(
              indent: isLastItem ? 0 : 16,
              height: 0.5,
              color: const Color(0xFFF2F3F5),
            ),
          ),
        ],
      );
    } else if (_editType == 1) {
      return Padding(
        padding: EdgeInsets.only(
            left: 32, right: 32, bottom: 6, top: isFirstChannel ? 0 : 20),
        child: RealtimeChannelName(
          channel.id,
          style: _theme.textTheme.bodyText1
              .copyWith(fontSize: 14, color: const Color(0xFF5C6273)),
        ),
      );
    }
    return Container(
        color: _theme.scaffoldBackgroundColor,
        height: 26,
        margin: EdgeInsets.only(
            left: 32, right: 32, bottom: 6, top: isFirstChannel ? 0 : 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Expanded(
              child: RealtimeChannelName(
                channel.id,
                style: _theme.textTheme.bodyText1
                    .copyWith(fontSize: 14, color: const Color(0xFF5C6273)),
              ),
            ),
            SizedBox(
                height: 16,
                width: 16,
                child: IconButton(
                    padding: EdgeInsets.zero,
                    onPressed: () async {
                      final index = await showCustomActionSheet([
                        Text(
                          '新建频道'.tr,
                          style: appThemeData.textTheme.bodyText2,
                        ),
                        Text(
                          '编辑分类名称'.tr,
                          style: appThemeData.textTheme.bodyText2,
                        ),
                        Text(
                          '删除分类'.tr,
                          style: appThemeData.textTheme.bodyText2
                              .copyWith(color: const Color(0xFFF24848)),
                        ),
                      ]);
                      switch (index) {
                        case 0:
                          unawaited(_createChannel(channel));
                          break;
                        case 1:
                          unawaited(Routes.pushUpdateChannelCatePage(
                            context,
                            _currentSelectedGuild.id,
                            channelCate: channel,
                          ));
                          break;
                        case 2: //删除分类
                          unawaited(_deleteChannel(channel));
                          break;
                      }
                    },
                    iconSize: 16,
                    icon: const Icon(IconFont.buffMoreHorizontal)))
          ],
        ));
  }

  Widget _buildChannel(ChatChannel channel, List<ChatChannel> channels) {
    final gp = PermissionModel.getPermission(_currentSelectedGuild.id);
    final isVisible = PermissionUtils.isChannelVisible(gp, channel.id);
    final isPrivate = PermissionUtils.isPrivateChannel(gp, channel.id);

    final index = channels.indexWhere((element) => element.id == channel.id);

    bool isLastItem = false;
    bool isFirstItem = false;
    if (index < channels.length - 1) {
      final nextChannel = channels[index + 1];
      isLastItem = nextChannel.type == ChatChannelType.guildCategory;
    } else {
      isLastItem = channels.last.id == channel.id;
    }

    isFirstItem = index == 0 ||
        (index > 0 &&
            channels[index - 1].type == ChatChannelType.guildCategory);

    return SizeTransition(
      sizeFactor: _animationController,
      child: FadeTransition(
          opacity: _animationController,
          child: Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.vertical(
                  top: Radius.circular(isFirstItem ? 6 : 0),
                  bottom: Radius.circular(isLastItem ? 6 : 0)),
              color: _theme.backgroundColor,
            ),
            child: Column(
              children: <Widget>[
                SizedBox(
                  height: 52 - 0.5,
                  child: ListTile(
                    leading: Container(
                      color: _theme.backgroundColor,
                      width: 20,
                      height: 24,
                      child: ChannelIcon(
                        channel.type,
                        private: isPrivate,
                        color: _theme.textTheme.bodyText1.color,
                        size: 20,
                      ),
                    ),
                    horizontalTitleGap: -8,
                    // minVerticalPadding: 10,
                    // subtitle: SizedBox(height: 15),
                    // tileColor: _theme.backgroundColor,
                    title: Row(
                      children: [
                        Flexible(
                          child: RealtimeChannelName(
                            channel.id,
                            style: _theme.textTheme.bodyText2,
                          ),
                        ),
                        if (channel.pendingUserAccess) ...[
                          const SizedBox(width: 6),
                          Container(
                              alignment: Alignment.center,
                              width: 48,
                              height: 16,
                              decoration: BoxDecoration(
                                  color: primaryColor.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(1)),
                              child: Center(
                                child: Text(
                                  '游客可见'.tr,
                                  strutStyle: const StrutStyle(
                                      forceStrutHeight: true, height: 1),
                                  style: TextStyle(
                                      color: primaryColor, fontSize: 10),
                                ),
                              )),
                        ]
                      ],
                    ),
                    selectedTileColor: CustomColor(context).disableColor,
                    trailing: _editType == 1
                        ? Listener(
                            onPointerDown: (e) {
                              HapticFeedback.heavyImpact();
                            },
                            child: ReorderableDragStartListener(
                              index: channels.indexOf(channel),
                              child: Container(
                                alignment: Alignment.centerRight,
                                color: Colors.transparent,
                                width: 60,
                                child: Icon(
                                  IconFont.buffChannelMoveEditLarge,
                                  color:
                                      const Color(0xFF747F8D).withOpacity(0.5),
                                  size: 22,
                                ),
                              ),
                            ),
                          )
                        : isVisible
                            ? const MoreIcon()
                            : Icon(
                                IconFont.buffChannelLock,
                                color: const Color(0xFF747F8D).withOpacity(0.5),
                                size: 22,
                              ),

                    onTap: isVisible
                        ? () {
                            if (_editType != null) return;
                            if (channel.type ==
                                ChatChannelType.guildCircleTopic)
                              jumpToCircleSettingPage(
                                  context, channel.guildId, channel.id);
                            else
                              Routes.pushModifyChannelPage(context, channel);
                          }
                        : null,
                  ),
                ),
                if (!isLastItem)
                  Container(
                    color: _theme.backgroundColor,
                    child: const Divider(
                      indent: 50,
                      height: 0.5,
                      color: Color(0xFFF2F3F5),
                    ),
                  ),
              ],
            ),
          )),
    );
  }

  Widget _buildItem(ChatChannel channel, List<ChatChannel> channels) {
    if (channel.type == ChatChannelType.guildCategory) {
      return _buildCategory(channel, channels);
    } else {
      return _buildChannel(channel, channels);
    }
  }

  void _onReorder(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    if (_editType == 0) {
      final cates = _newSortedChannels
          .where((element) => element.type == ChatChannelType.guildCategory)
          .toList();
      final List<int> cateIdxs = cates
          .map((e) => _newChannelOrder.indexWhere((element) => element == e.id))
          .toList();
      final List<Iterable<ChatChannel>> channelsList = [];
      for (var i = 0; i < cateIdxs.length; i++) {
        if (i == 0) {
          channelsList.add(_newSortedChannels.getRange(0, cateIdxs[0]));
        } else if (i != cateIdxs.length - 1) {
          channelsList.add(
              _newSortedChannels.getRange(cateIdxs[i - 1] + 1, cateIdxs[i]));
        } else {
          channelsList.add(
              _newSortedChannels.getRange(cateIdxs[i - 1] + 1, cateIdxs[i]));
          channelsList.add(_newSortedChannels.getRange(
              cateIdxs[i] + 1, _newSortedChannels.length));
        }
      }
      final ele = cates.removeAt(cateIdxs.indexOf(oldIndex));
      // 找不到索引其中一种情况是移动分类又复原，这个时候也会触发reorder，原来的oldIndex发生变化，不需刷新页面
      if (!cateIdxs.contains(newIndex)) return;
      cates.insert(cateIdxs.indexOf(newIndex), ele);
      final tempChannels =
          channelsList.removeAt(cateIdxs.indexOf(oldIndex) + 1);
      channelsList.insert(cateIdxs.indexOf(newIndex) + 1, tempChannels);
      final List<ChatChannel> newChannels = [];
      newChannels.addAll(channelsList[0]);
      for (var i = 0; i < cates.length; i++) {
        newChannels.add(cates[i]);
        newChannels.addAll(channelsList[i + 1]);
      }
      setState(() {
        _newSortedChannels = newChannels;
        _categoryChannels = _newSortedChannels
            .where((element) => element.type == ChatChannelType.guildCategory)
            .toList();
        _newChannelOrder = newChannels.map((e) => e.id).toList();
      });
    } else if (_editType == 1) {
      setState(() {
        final ele = _newSortedChannels.removeAt(oldIndex);
        _newSortedChannels.insert(newIndex, ele);
        _newChannelOrder = _newSortedChannels.map((e) => e.id).toList();
        _categoryChannels = _newSortedChannels
            .where((element) => element.type == ChatChannelType.guildCategory)
            .toList();
      });
    }
    _orderChanged = true;
  }
}
