import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/api/channel_api.dart';
import 'package:im/common/extension/string_extension.dart';
import 'package:im/common/permission/permission.dart';
import 'package:im/common/permission/permission_mixin.dart';
import 'package:im/common/permission/permission_model.dart';
import 'package:im/common/permission/permission_utils.dart';
import 'package:im/db/db.dart';
import 'package:im/db/guild_table.dart';
import 'package:im/pages/chat_index/components/channel_item_listener_builder.dart';
import 'package:im/pages/chat_index/components/ui_category_item.dart';
import 'package:im/pages/home/model/chat_index_model.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/routes.dart';
import 'package:im/themes/custom_color.dart';
import 'package:im/utils/im_utils/channel_util.dart';
import 'package:im/utils/show_confirm_dialog.dart';
import 'package:im/web/pages/setting/create_channel_cate_page.dart';
import 'package:im/web/utils/show_web_tooltip.dart';
import 'package:im/web/utils/web_util/web_util.dart';
import 'package:im/web/widgets/button/web_hover_button.dart';
import 'package:im/widgets/super_tooltip.dart';
import 'package:pedantic/pedantic.dart';
import 'package:reorderables/reorderables.dart';
import 'package:rxdart/rxdart.dart';

import '../../../../global.dart';
import '../channel_list_listener_builder.dart';
import '../ui_channel_no_permission_alert.dart';
import 'guild_channel_list.dart';

class LandscapeGuildChannelList extends StatefulWidget {
  static bool dragging = false;

  // ignore: close_sinks
  static BehaviorSubject<bool> rebuildStream = BehaviorSubject<bool>();

  @override
  _LandscapeGuildChannelListState createState() =>
      _LandscapeGuildChannelListState();
}

class _LandscapeGuildChannelListState extends State<LandscapeGuildChannelList>
    with GuildPermissionListener
    implements GuildChannelListContent {
//  分类拖拽视图滚动控制器
  ScrollController _scrollerController1;

  // 频道拖拽视图滚动控制器
  ScrollController _scrollerController2;
  ScrollController _scrollerController3;
  ScrollController _scrollerController4;
  StreamSubscription _subscription;
  bool hasManagePermission = false;
  ValueNotifier<bool> channelCategorySelected = ValueNotifier(false);

  // 记录之前是否选中频道分类
  bool preChannelCategorySelected;

  // 记录之前的ChatTarget，切换target必须滚动到最上方
  String preChatTargetId;

  bool targetChanged = false;

  @override
  void initState() {
    _subscription = LandscapeGuildChannelList.rebuildStream
        .debounceTime(const Duration(milliseconds: 200))
        .listen((val) {
      if (hasManagePermission) channelCategorySelected.value = val;
    });
    _scrollerController1 = ScrollController();
    _scrollerController2 = ScrollController();
    _scrollerController3 = ScrollController();
    _scrollerController4 = ScrollController();

    addPermissionListener();
    // target变化，更新权限监听
    ChatTargetsModel.instance.addListener(addPermissionListener);

    super.initState();
  }

  @override
  void dispose() {
    _scrollerController1?.dispose();
    _scrollerController2?.dispose();
    _scrollerController3?.dispose();
    _scrollerController4?.dispose();
    _subscription?.cancel();
    disposePermissionListener();
    super.dispose();
  }

  @override
  String get guildPermissionMixinId =>
      ChatTargetsModel.instance.selectedChatTarget?.id;

  @override
  Future<void> onPermissionChange() async {
    // 如果选中的频道变成了没权限查看，则选择到默认频道
    final guildId = ChatTargetsModel.instance.selectedChatTarget?.id;
    final selectedChannel = GlobalState.selectedChannel.value;
    if (selectedChannel != null &&
        selectedChannel.id != null &&
        selectedChannel.guildId == guildId) {
      final gp = PermissionModel.getPermission(guildId);
      final isVisible =
          PermissionUtils.isChannelVisible(gp, selectedChannel.id);
      if (!isVisible) {
        unawaited(
            UIChannelNoPermissionAlert.showNoPermissionAlert(onConfirm: () {
          // 从showNoPermissionAlert移植到此处
          Routes.backHome();
        }));
      }
    }
    // 权限变化，此页面要刷新
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return ChannelListListenerBuilder(
        contentBuilder: (context, gt, hasPermission) {
      hasManagePermission = hasPermission;
      return _buildReorderableChannel(gt);
    });
  }

  Widget _buildReorderableChannel(GuildTarget gt) {
    bool _noParentId(String id) {
      return id == '0' || id == '';
    }

    // 频道排序
    final List<Widget> reorderRows = [];
    final List<Widget> subItems = [];
    final List<Widget> fixedChannels = [];
    for (int i = 0; i < gt.channels.length; i++) {
      final c = gt.channels[i];
      if (_noParentId(c.parentId) && c.type != ChatChannelType.guildCategory) {
        //无分类的频道
        fixedChannels
            .add(buildChannelItem(gt, c, context, hasManagePermission));
      } else if (c.type == ChatChannelType.guildCategory) {
        // 频道分类
        if (subItems.isNotEmpty) {
          reorderRows.add(ReorderableWidget(
            key: ValueKey(c.id),
            reorderable: hasManagePermission,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [...subItems],
            ),
          ));
          subItems.clear();
        }
        subItems.add(buildCategoryItem(gt, c));
      } else if (c.type != ChatChannelType.guildCategory) {
        // 有分类的频道
        subItems.add(buildChannelItem(gt, c, context, hasManagePermission));
      }
      if (c == gt.channels.last && subItems.isNotEmpty) {
        reorderRows.add(ReorderableWidget(
          key: ValueKey(c.id),
          reorderable: hasManagePermission,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [...subItems],
          ),
        ));
      }
    }

    // 频道分类拖拽视图
    final child1 = CustomScrollView(
      controller: _scrollerController3,
      slivers: [
        ...fixedChannels.map((e) => SliverToBoxAdapter(child: e)),
        SliverToBoxAdapter(
          child: ReorderableColumn(
            scrollController: _scrollerController1,
            buildDraggableFeedback: (context, constraints, child) {
              return Card(
                elevation: 4,
                child: ConstrainedBox(constraints: constraints, child: child),
              );
            },
            // 由于web鼠标右键点击会触发拖拽，所以改成长按触发拖拽
            // needsLongPressDraggable: true,
            onReorder: (oldIndex, newIndex) =>
                _onCategoryReorder(oldIndex, newIndex, gt),
            children: reorderRows,
          ),
        ),
      ],
    );
    // 频道拖拽视图
    final child2 = SingleChildScrollView(
      controller: _scrollerController4,
      child: ReorderableColumn(
        scrollController: _scrollerController2,
        buildDraggableFeedback: (context, constraints, child) {
          return Card(
            elevation: 4,
            child: ConstrainedBox(constraints: constraints, child: child),
          );
        },
        // 由于web鼠标右键点击会触发拖拽，所以改成长按触发拖拽
        // needsLongPressDraggable: true,
        onReorder: (oldIndex, newIndex) =>
            _onChannelReorder(oldIndex, newIndex, gt),
        children: [
          ...gt.channels
              .map(
                (e) => ReorderableWidget(
                    reorderable: hasManagePermission,
                    key: Key(e.id),
                    child:
                        buildChannelItem(gt, e, context, hasManagePermission)),
              )
              .toList(),
        ],
      ),
    );
    return ValueListenableBuilder(
        valueListenable: channelCategorySelected,
        builder: (context, value, _) {
          targetChanged = preChatTargetId != gt.id;
          preChatTargetId = gt.id;
          if (targetChanged) {
            if (_scrollerController1.hasClients) {
              _scrollerController1.jumpTo(0);
              _scrollerController2.jumpTo(0);
            }
          } else {
            if (_scrollerController1.hasClients) {
              final double scrollHeight = preChannelCategorySelected
                  ? _scrollerController1.offset
                  : _scrollerController2.offset;
              if (value) {
                _scrollerController1.jumpTo(scrollHeight);
              } else {
                _scrollerController2.jumpTo(scrollHeight);
              }
            }
          }

          preChannelCategorySelected = value;
          return IndexedStack(
            index: value ? 0 : 1,
            children: [
              child1,
              child2,
            ],
          );
        });
  }

  /// 构建某个分类的频道
  @override
  Widget buildChannelItem(
    GuildTarget model,
    ChatChannel channel,
    BuildContext context,
    bool hasManagePermission,
  ) {
    final gp = PermissionModel.getPermission(channel.guildId);

    /// 游客是否可以访问
    final bool pendingUserAccess = channel.pendingUserAccess ?? false;
    if (model.userPending && !pendingUserAccess) return const SizedBox();

    if (channel.type == ChatChannelType.guildCategory) {
      final bool isEmptyCategory = model.channels.where((element) {
        //子节点
        return element.parentId == channel.id;
      }).where((element) {
        // 可见的
        return PermissionUtils.isChannelVisible(gp, element.id);
      }).isEmpty;
      if (isEmptyCategory && !hasManagePermission)
        return SizedBox(
          key: ValueKey(channel.id),
        );
      return buildCategoryItem(model, channel);
    }

    // 分类下的，没有可读消息，未被选中的，即折叠状态，不绘制
    if (channel.parentId.hasValue) {
      try {
        final category = model.channels
            .firstWhere((element) => element.id == channel.parentId);
        if (!category.expanded &&
            ChannelUtil.instance.getUnread(channel.id) == 0 &&
            GlobalState.selectedChannel.value != channel)
          return SizedBox(key: ValueKey(channel.id));
        // ignore: empty_catches
      } catch (e) {}
    }

    // 没有权限的，不绘制
    if (!PermissionUtils.isChannelVisible(gp, channel.id)) {
      return SizedBox(key: ValueKey(channel.id));
    }
    return ChannelItemListenerBuilder(channel, model);
  }

  @override
  Widget buildCategoryItem(GuildTarget gt, ChatChannel channel) {
    final gp = PermissionModel.getPermission(channel.guildId);
    final bool managePermission = PermissionUtils.oneOf(
        gp, [Permission.MANAGE_CHANNELS, Permission.MANAGE_ROLES],
        channelId: channel.id);
    final bool isEmptyCategory = gt.channels.where((element) {
      //子节点
      return element.parentId == channel.id;
    }).where((element) {
      // 可见的
      return PermissionUtils.isChannelVisible(gp, element.id);
    }).isEmpty;
    if (isEmptyCategory && !hasManagePermission) return const SizedBox();
    return Builder(builder: (context) {
      return Listener(
        onPointerDown: managePermission
            ? (e) => _onCategoryContextMenu(gt, channel, e, context)
            : null,
        onPointerMove: (e) {
          LandscapeGuildChannelList.dragging = true;
        },
        onPointerUp: (e) {
          LandscapeGuildChannelList.dragging = false;
        },
        child: MouseRegion(
          onEnter: (e) async {
            if (mounted && !LandscapeGuildChannelList.dragging)
              LandscapeGuildChannelList.rebuildStream.add(true);
          },
          child: UICategoryItem(
            channel: channel,
            model: gt,
            hasManagePermission: managePermission,
          ),
        ),
      );
    });
  }

  Future<void> _onChannelReorder(
      int oldIndex, int newIndex, GuildTarget gt) async {
    // 防止渲染出错，做容错处理
    if (channelCategorySelected.value) return;
    final newChannels = [...gt.channels];
    final remove = newChannels.removeAt(oldIndex);
    newChannels.insert(newIndex, remove);
    final newParent = newChannels.sublist(0, newIndex).lastWhere(
        (element) => element.type == ChatChannelType.guildCategory,
        orElse: () => null);
    final newOrders = newChannels.map((e) => e.id).toList();
    final parentId = newParent?.id ?? '';
    await ChannelApi.orderChannel(
        gt.id, Global.user.id, {remove.id: parentId}, newOrders);
    remove.parentId = parentId;
    gt
      ..channelOrder = newOrders
      ..sortChannels()
      // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
      ..notifyListeners();
    GuildTable.add(gt);
  }

  Future<void> _onCategoryReorder(
      int oldIndex, int newIndex, GuildTarget gt) async {
    // 防止渲染出错，做容错处理
    if (!channelCategorySelected.value) return;
    final newChannels = [...gt.channels];
    final List<ChatChannel> categories = newChannels
        .where((element) => element.type == ChatChannelType.guildCategory)
        .toList();
    final removeCateIdx = newChannels
        .indexWhere((element) => element.id == categories[oldIndex].id);
    final removeItems = [
      categories[oldIndex],
      ...newChannels.where((element) =>
          element.parentId == categories[oldIndex].id &&
          element.type != ChatChannelType.guildCategory),
    ];
    newChannels
        .replaceRange(removeCateIdx, removeCateIdx + removeItems.length, []);
    int insertIdx;
    if (oldIndex < newIndex) {
      // 往下移动
      final cateStart = newChannels.indexWhere((element) =>
          element.id == categories[newIndex].id &&
          element.type == ChatChannelType.guildCategory);
      final cateLen = newChannels
          .where((element) =>
              element.parentId == categories[newIndex].id &&
              element.type != ChatChannelType.guildCategory)
          .length;
      insertIdx = cateStart + cateLen + 1;
    } else {
      // 往上移动
      final cateStart = newChannels.indexWhere((element) =>
          element.id == categories[newIndex == 0 ? 0 : newIndex - 1].id &&
          element.type == ChatChannelType.guildCategory);
      final cateLen = newIndex == 0
          ? 0
          : newChannels
              .where((element) =>
                  element.parentId == categories[newIndex - 1].id &&
                  element.type != ChatChannelType.guildCategory)
              .length;
      insertIdx = cateStart + cateLen;
    }
    newChannels.replaceRange(insertIdx, insertIdx, removeItems);
    final newOrders = newChannels.map((e) => e.id).toList();
    await ChannelApi.orderChannel(gt.id, Global.user.id, {}, newOrders);
    gt
      ..channelOrder = newOrders
      ..sortChannels()
      // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
      ..notifyListeners();
    GuildTable.add(gt);
  }

  Future<void> _onCategoryContextMenu(GuildTarget gt, ChatChannel channel,
      PointerDownEvent e, BuildContext context) async {
    if (e.kind == PointerDeviceKind.mouse && e.buttons == 2) {
      Widget buildItem(String title, int index, Function(int) done,
          {Color color}) {
        return WebHoverButton(
            align: Alignment.centerLeft,
            hoverColor: Theme.of(context).disabledColor.withOpacity(0.1),
            onTap: () {
              done(index);
            },
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            child: Text(title ?? '',
                style: TextStyle(
                    color: color, fontSize: 14, fontWeight: FontWeight.w400)));
      }

      WebConfig.disableContextMenu();
      final res = await showWebTooltip<int>(context,
          globalPoint: e.position,
          maxWidth: 150,
          popupDirection: TooltipDirection.followMouse,
          builder: (context, done) {
        return IntrinsicWidth(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              buildItem('编辑分类名称'.tr, 0, done),
              Divider(
                indent: 12,
                endIndent: 12,
                color: CustomColor(context).disableColor.withOpacity(0.2),
              ),
              buildItem('删除频道分类'.tr, 1, done,
                  color: Theme.of(context).errorColor),
            ],
          ),
        );
      });
      switch (res) {
        case 0:
          unawaited(showDialog(
              context: context,
              builder: (_) =>
                  CreateChannelCatePage(guildId: gt.id, channelCate: channel)));
          break;
        case 1:
          final res = await showConfirmDialog(
              title: '删除频道分类'.tr,
              content: '确定将 %s 删除？一旦删除不可撤销。'.trArgs([channel.name]));
          if (res != true) return;
          // 删除频道分类需要把分类下的频道移除到无分类的频道的最后面
          final GuildTarget gt =
              ChatTargetsModel.instance.selectedChatTarget as GuildTarget;
          final newChannels = [...gt.channels];
          final changedChannels = newChannels
              .where((element) => element.parentId == channel.id)
              .toList();

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
          await ChannelApi.removeChannel(
              channel.guildId, Global.user.id, channel.id, channelOrder);
          gt.channels
            ..clear()
            ..addAll(newChannels);
          gt.channelOrder = channelOrder;
          // ignore: invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member
          gt.notifyListeners();
          GuildTable.add(gt);
          unawaited(Db.channelBox.delete(channel.id));
          break;
        default:
      }
    }
  }
}
