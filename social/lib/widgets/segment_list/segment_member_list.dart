import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_state_manager/src/simple/get_state.dart';
import 'package:im/api/data_model/user_info.dart';
import 'package:im/common/permission/permission_utils.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/pages/member_list/item_renderer/text_chat_member_item_renderer.dart';
import 'package:im/utils/orientation_util.dart';
import 'package:im/widgets/list_physics.dart';
import 'package:im/widgets/segment_list/segment_member_list_service.dart';
import 'package:im/widgets/segment_list/segment_member_list_view_model.dart';

// ignore: must_be_immutable
class SegmentMemberList extends StatefulWidget {
  ///
  String guildId;

  /// 频道id
  String channelId;

  /// 频道类型
  ChatChannelType channelType;

  /// 构造函数
  SegmentMemberList(this.guildId, this.channelId, this.channelType)
      : super(key: Key("$guildId-$channelId"));

  @override
  _SegmentMemberListState createState() => _SegmentMemberListState();
}

class _SegmentMemberListState extends State<SegmentMemberList> {
  /// 唯一标识
  String tag;

  /// ViewModel -
  SegmentMemberListViewModel viewModel;

  @override
  void initState() {
    tag = "${widget.guildId}-${widget.channelId}";
    viewModel = SegmentMemberListViewModel(
        widget.guildId, widget.channelId, widget.channelType);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<SegmentMemberListViewModel>(
      key: Key(tag),
      init: viewModel,
      tag: tag,
      builder: (c) {
        return Scrollbar(
            child: NotificationListener<ScrollNotification>(
                onNotification: c.onScrollNotification,
                child: CustomScrollView(
                    controller: c.scrollController,
                    physics: const SlowListPhysics(),
                    slivers: [
                      SliverList(
                          delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final item = c.itemOfIndex(index);
                          if (item != null) {
                            if (item is UserInfo) {
                              /// todo 性能优化
                              final color =
                                  PermissionUtils.getRoleColor(item.roles);

                              //成员
                              return SizedBox(
                                  key: Key(item.userId),
                                  height: SegmentMemberListService.listHeight,
                                  child: TextChatMemberItemRenderer(
                                    item,
                                    color: color,
                                    channelId: widget.channelId,
                                    guildId: widget.guildId,
                                  ));
                            } else if (item is UserGroup) {
                              return _memberGroupItemRenderer(context, item,
                                  height: SegmentMemberListService.listHeight);
                            } else {
                              return _defaultItemWidget(context);
                            }
                          } else {
                            return _defaultItemWidget(context);
                          }
                        },
                        childCount: c.itemCount(),
                      ))
                    ])));
      },
    );
  }

  Widget _memberGroupItemRenderer(BuildContext context, UserGroup group,
      {double height}) {
    return Container(
        height: height,
        alignment: Alignment.centerLeft,
        padding:
            EdgeInsets.symmetric(horizontal: OrientationUtil.portrait ? 16 : 8),
        child: Text(
          "${group.name}-${group.count}",
          style: Theme.of(context).textTheme.bodyText1.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
        ));
  }

  Widget _defaultItemWidget(BuildContext context) {
    final color = Theme.of(context).dividerTheme.color;
    return SizedBox(
      height: SegmentMemberListService.listHeight,
      child: Padding(
        padding:
            EdgeInsets.symmetric(horizontal: OrientationUtil.portrait ? 16 : 8),
        child: Container(
            height: OrientationUtil.portrait ? 52 : 42,
            padding: EdgeInsets.symmetric(
                horizontal: OrientationUtil.portrait ? 0 : 8),
            decoration: BoxDecoration(color: Theme.of(context).backgroundColor),
            child: Row(
              children: <Widget>[
                Container(
                  width: 32,
                  height: 32,
                  decoration:
                      BoxDecoration(shape: BoxShape.circle, color: color),
                ),
                const SizedBox(width: 10),
                Flexible(
                    child: FractionallySizedBox(
                  widthFactor: Random().nextDouble() * (0.666 - 0.333) + 0.333,
                  child: Container(
                    decoration: BoxDecoration(
                        color: color, borderRadius: BorderRadius.circular(6)),
                    height: 18,
                  ),
                )),
              ],
            )),
      ),
    );
  }
}
