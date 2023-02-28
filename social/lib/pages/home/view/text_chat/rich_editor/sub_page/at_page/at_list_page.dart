import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/api/data_model/user_info.dart';
import 'package:im/app/theme/app_theme.dart';
import 'package:im/core/widgets/button/fade_button.dart';
import 'package:im/loggers.dart';
import 'package:im/pages/guild_setting/role/role.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/pages/home/view/text_chat/rich_editor/sub_page/at_page/at_controller.dart';
import 'package:im/pages/search/widgets/member_nickname.dart';
import 'package:im/pages/search/widgets/search_input_box.dart';
import 'package:im/themes/const.dart';
import 'package:im/themes/custom_color.dart';
import 'package:im/themes/default_theme.dart';
import 'package:im/utils/orientation_util.dart';
import 'package:im/utils/utils.dart';
import 'package:im/widgets/app_bar/appbar_button.dart';
import 'package:im/widgets/app_bar/custom_appbar.dart';
import 'package:im/widgets/load_more.dart';
import 'package:im/widgets/realtime_user_info.dart';
import 'package:im/widgets/search_widget/ordered_member_search_controller.dart';

import '../../../../../../../icon_font.dart';

///富文本编辑：艾特列表
class AtListPage extends StatelessWidget {
  final String guildId;
  final ChatChannel channel;
  final void Function(List) onSelect;
  final VoidCallback onClose;

  const AtListPage(
      {@required this.guildId,
      this.channel,
      this.onSelect,
      this.onClose,
      Key key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget appBar;
    if (OrientationUtil.portrait) {
      appBar = CustomAppbar(
        title: '选择成员'.tr,
        leadingIcon: IconFont.buffNavBarCloseItem,
        leadingCallback: () => onClose?.call(),
      );
    } else {
      appBar = CustomAppbar(
        title: '选择成员',
        leadingBuilder: (icon) => const SizedBox(),
        actions: [
          AppbarIconButton(
              onTap: () {
                onClose?.call();
              },
              icon: IconFont.buffChatTextShrink,
              size: 18,
              color: CustomColor(context).disableColor)
        ],
      );
    }

    if (kIsWeb) {
      try {
        ///web版本：在富文本编辑页多次点击艾特，打开的是同一个atListPage，需要刷新下
        final atController = Get.find<AtController>();
        atController.loadAtUsers();
        atController.searchInputModel.onInput('');
      } catch (_) {}
    }

    // 初始化 Controller ，不会多次 build
    return GetBuilder<AtController>(
      init: AtController(channel),
      builder: (c) {
        return Scaffold(
          backgroundColor: Theme.of(context).backgroundColor,
          appBar: appBar,
          body: Column(
            children: [
              Container(
                height: 36,
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: SearchInputBox(
                  searchInputModel: c.searchInputModel,
                  autoFocus: false,
                  height: 36,
                  borderRadius: 4,
                ),
              ),
              Expanded(
                child: LoadMore(
                  autoStart: true,
                  fetchNextPage: () async {
                    bool ret = false;
                    try {
                      ret = await Get.find<OrderedMemberSearchController>()
                          .fetchNextPage();
                    } catch (e) {
                      logger.info(
                          '@list fetchNextPage error, because can not find OrderedMemberSearchController $e');
                    }
                    return ret;
                  },
                  builder: (loadingWidget) {
                    final shouldShowRoles = channel != null &&
                        channel.type != ChatChannelType.guildCircle;
                    final shouldShowEveryone =
                        shouldShowRoles && c.isAllowMentionRole;
                    return Scrollbar(
                      child: CustomScrollView(
                        slivers: [
                          if (shouldShowEveryone)
                            GetBuilder<AtController>(
                                id: AtController.updateIdMentionEveryone,
                                builder: (_) => SliverVisibility(
                                    visible: _.mentionAll,
                                    sliver: _buildMentionAll(context))),
                          GetBuilder<AtController>(
                              id: AtController.updateIdAtUsers,
                              builder: (_) => SliverVisibility(
                                  visible: _.atList.isNotEmpty,
                                  sliver: _buildHeader(context, "可能@的人".tr))),
                          GetBuilder<AtController>(
                              id: AtController.updateIdAtUsers,
                              builder: (_) => _buildList(
                                  data: _.atList,
                                  builder: (e) =>
                                      _buildUserItem(context, null, userId: e),
                                  indent: 68)),
                          if (shouldShowRoles) ...[
                            GetBuilder<AtController>(
                                id: AtController.updateIdMentionRoles,
                                builder: (_) => SliverVisibility(
                                    visible: _.roles.isNotEmpty,
                                    sliver: _buildHeader(context, "全部角色".tr))),
                            GetBuilder<AtController>(
                                id: AtController.updateIdMentionRoles,
                                builder: (_) => _buildList(
                                    data: _.roles,
                                    builder: (e) => _buildRoleItem(context, e)))
                          ],
                          ...[
                            GetBuilder<OrderedMemberSearchController>(
                                init: OrderedMemberSearchController
                                    .fromDebouncedTextStream(
                                  guildId: channel == null
                                      ? guildId
                                      : (channel.type ==
                                              ChatChannelType.group_dm
                                          ? channel.id
                                          : channel.guildId),
                                  channelId: channel?.id,
                                  stream: c.searchInputModel.searchStream,
                                  channelType: channel?.type,
                                ),
                                builder: (_) => SliverVisibility(
                                    visible: _.list.isNotEmpty,
                                    sliver: _buildHeader(context, "全部成员".tr))),
                            GetBuilder<OrderedMemberSearchController>(
                                builder: (_) => _buildList(
                                    data: _.list,
                                    builder: (e) => _buildUserItem(context, e),
                                    indent: 68))
                          ],
                          _buildLoadingWidget(loadingWidget),
                          SliverToBoxAdapter(
                              child: SizedBox(height: getBottomViewInset())),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoadingWidget(Widget Function() loadingWidget) {
    return GetBuilder<OrderedMemberSearchController>(
        builder: (_) => SliverVisibility(
            visible: _.showLoadingWidget,
            sliver: SliverPadding(
                padding: const EdgeInsets.only(top: 8),
                sliver: SliverToBoxAdapter(
                  child: loadingWidget(),
                ))));
  }

  SliverList _buildList<T>(
      {List<T> data, Widget Function(T) builder, double indent = 16}) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
          (context, index) => index.isEven
              ? builder(data[index ~/ 2])
              : Divider(indent: indent, color: appThemeData.dividerColor),
          childCount: data.length * 2),
    );
  }

  SliverToBoxAdapter _buildMentionAll(BuildContext context) {
    final c = Get.find<AtController>();
    return SliverToBoxAdapter(
      child: FadeButton(
        onTap: () => _onSelect(context, [AtController.to.everyoneRole]),
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration:
                    BoxDecoration(shape: BoxShape.circle, color: primaryColor),
                alignment: Alignment.center,
                child: Text(
                  "All".tr,
                  style: const TextStyle(fontSize: 17, color: Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("全体成员 (%s)".trArgs([c.memberNum.toString()]),
                      style: Theme.of(context)
                          .textTheme
                          .headline3
                          .copyWith(fontSize: 16)),
                  const SizedBox(height: 4),
                  Text("提示所有成员".tr,
                      style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context).disabledColor)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String label) {
    return SliverToBoxAdapter(
      child: Container(
        // color: const Color(0xFFf5f5f8),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
        child: Text(
          label,
          style: Theme.of(context)
              .textTheme
              .bodyText2
              .copyWith(fontSize: 13, color: const Color(0xFF646A73)),
        ),
      ),
    );
  }

  Widget _buildRoleItem(BuildContext context, Role item) {
    return _wrapper(
      context,
      item,
      height: 52,
      keyId: item.id,
      child: Row(
        children: [
          sizeWidth16,
          Expanded(
            child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "@${item.name}",
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: item.color == 0 ? null : Color(item.color),
                  ),
                )),
          ),
        ],
      ),
    );
  }

  Widget _buildUserItem(BuildContext context, UserInfo userInfo,
      {String userId}) {
    if (userInfo != null) return getUserWidget(context, userInfo);
    final item = UserInfo.consume(userId, builder: (context, user, widget) {
      return getUserWidget(context, user);
    });
    return item;
  }

  Widget getUserWidget(BuildContext context, UserInfo user) {
    final c = Get.find<AtController>();
    return _wrapper(
      context,
      user,
      height: 52,
      keyId: user.userId,
      child: Row(
        children: <Widget>[
          sizeWidth16,
          SizedBox(
            width: 32,
            child: RealtimeAvatar(
              userId: user.userId,
              size: 32,
            ),
          ),
          sizeWidth12,
          Flexible(
            child: kIsWeb
                ? HighlightMemberNickName(
                    user,
                    guildId: guildId,
                  )
                : HighlightMemberNickName(
                    user,
                    keyword: c?.searchInputModel?.input,
                    guildId: guildId,
                  ),
          ),
          sizeWidth8,
          Text(
            "#${user.username}",
            style:
                TextStyle(fontSize: 13, color: Theme.of(context).disabledColor),
          ),
          sizeWidth16,
        ],
      ),
    );
  }

  Widget _wrapper(BuildContext context, object,
      {double height, @required Widget child, String keyId}) {
    if (kIsWeb) {
      return FadeButton(
        backgroundColor: Theme.of(context).backgroundColor,
        onTap: () {
          _onSelect(context, [object]);
        },
        child: SizedBox(
          key: ValueKey(keyId),
          height: height,
          child: child,
        ),
      );
    }
    return FadeButton(
      backgroundColor: Theme.of(context).backgroundColor,
      onTap: () {
        _onSelect(context, [object]);
      },
      child: SizedBox(
        height: height,
        child: child,
      ),
    );
  }

  void _onSelect(BuildContext context, List res) {
    onSelect?.call(res);
  }
}
