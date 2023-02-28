import 'package:fb_live_flutter/fb_live_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:im/api/data_model/user_info.dart';
import 'package:im/global.dart';
import 'package:im/live_provider/pages/assistants/add_assistants_controller.dart';
import 'package:im/pages/search/widgets/member_nickname.dart';
import 'package:im/pages/search/widgets/search_input_box.dart';
import 'package:im/themes/const.dart';
import 'package:im/utils/utils.dart';
import 'package:im/widgets/app_bar/appbar_button.dart';
import 'package:im/widgets/app_bar/custom_appbar.dart';
import 'package:im/widgets/avatar.dart';
import 'package:im/widgets/load_more.dart';
import 'package:im/widgets/search_widget/ordered_member_search_controller.dart';
import 'package:im/widgets/select_button.dart';

class AddAssistantsPage extends StatefulWidget {
  final String guildId;
  final List<FBUserInfo> defaultSelectedUsers;

  const AddAssistantsPage({this.guildId, this.defaultSelectedUsers});

  @override
  _AddAssistantsPageState createState() => _AddAssistantsPageState();
}

class _AddAssistantsPageState extends State<AddAssistantsPage> {
  @override
  void initState() {
    super.initState();
    final c = Get.put(AddAssistantsController());
    c.cleanSelected();
    if (widget.defaultSelectedUsers != null &&
        widget.defaultSelectedUsers.isNotEmpty) {
      c.defaultSelected(widget.defaultSelectedUsers);
    }
  }

  @override
  void dispose() {
    Get.delete<AddAssistantsController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // final ownerId =
    //     (ChatTargetsModel.instance.getChatTarget(guildId) as GuildTarget)
    //         .ownerId;
    final creatorId = Global.user.id;

    final ctr = Get.find<AddAssistantsController>();

    return GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
          backgroundColor: Theme.of(context).backgroundColor,
          appBar: CustomAppbar(
            title: '添加小助手'.tr,
            actions: [
              AppbarCustomButton(
                child: GetBuilder<AddAssistantsController>(
                  builder: (c) => AppbarTextButton(
                    onTap: () {
                      FocusScope.of(context).unfocus();
                      Navigator.of(context)
                          .pop(c.selectedUsers.values.toList());
                    },
                    text: '确认'.tr,
                  ),
                ),
              ),
            ],
          ),
          body: Column(
            children: [
              Container(
                height: 36,
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: SearchInputBox(
                  hintText: "搜索".tr,
                  inputController: ctr.inputController,
                  searchInputModel: ctr.searchInputModel,
                  height: 36,
                  autoFocus: false,
                  useFlutter: true,
                ),
              ),
              Container(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                height: 41,
                child: Text(
                  '选择需要添加到直播间的小助手。'.tr,
                  style:
                      const TextStyle(fontSize: 14, color: Color(0xFF646A73)),
                ),
              ),
              Expanded(
                child: GetBuilder<OrderedMemberSearchController>(
                  init: OrderedMemberSearchController.fromDebouncedTextStream(
                    guildId: widget.guildId,
                    channelId: "0",
                    stream: ctr.searchInputModel.searchStream,
                  ),
                  builder: (omsCtr) {
                    return LoadMore(
                      autoStart: true,
                      fetchNextPage: omsCtr.fetchNextPage,
                      builder: (loadingWidget) => Scrollbar(
                        child: CustomScrollView(
                          slivers: [
                            GetBuilder<AddAssistantsController>(
                              id: AddAssistantsController.inputChanged,
                              builder: (c) =>
                                  GetBuilder<OrderedMemberSearchController>(
                                      builder: (_) => SliverVisibility(
                                          visible: _.list
                                              .where((e) =>
                                                  // e.userId != ownerId &&
                                                  e.userId != creatorId)
                                              .toList()
                                              .isNotEmpty,
                                          sliver: _buildHeader(
                                              context, "全部成员".tr))),
                            ),
                            GetBuilder<OrderedMemberSearchController>(
                                builder: (_) => _buildList(
                                    data: _.list
                                        .where((e) =>
                                            // e.userId != ownerId &&
                                            e.userId != creatorId)
                                        .toList(),
                                    builder: (e) => _buildUserItem(context, e),
                                    indent: 68)),
                            _buildLoadingWidget(loadingWidget),
                            SliverToBoxAdapter(
                                child: SizedBox(height: getBottomViewInset())),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ));
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
              : Divider(
                  indent: indent,
                  color: Theme.of(context).dividerColor.withOpacity(0.1)),
          childCount: data.length * 2 - 1),
    );
  }

  Widget _buildHeader(BuildContext context, String label) {
    return SliverToBoxAdapter(
      child: Container(
        color: const Color(0xFFf5f5f8),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodyText1.copyWith(
              fontSize: 14, height: 1, color: const Color(0xFF646A73)),
        ),
      ),
    );
  }

  Widget _listCell({
    double height,
    GestureTapCallback onTap,
    @required Widget child,
  }) {
    return GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: onTap,
        child: SizedBox(
          height: height,
          child: child,
        ));
  }

  Widget _buildUserItem(BuildContext context, UserInfo userInfo) {
    return GetBuilder<AddAssistantsController>(
        id: AddAssistantsController.selectedUsersChanged,
        builder: (c) => _listCell(
            height: 64,
            child: Row(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(left: 18, right: 13.5),
                  child: CheckButton(
                    value: c.selectedUsers.keys.contains(userInfo.userId),
                  ),
                ),
                Avatar(
                  url: userInfo.avatar,
                  radius: 20,
                ),
                sizeWidth12,
                Expanded(
                    child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: <Widget>[
                        Flexible(
                          child: HighlightMemberNickName(
                            userInfo,
                            keyword: c.inputController.text,
                          ),
                        ),
                        sizeWidth8,
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "#${userInfo.username}",
                      style: TextStyle(
                          fontSize: 13, color: Theme.of(context).disabledColor),
                    ),
                  ],
                )),
              ],
            ),
            onTap: () {
              c.onTapUser(userInfo.userId, userInfo);
            }));
  }
}
