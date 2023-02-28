import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/api/data_model/user_info.dart';
import 'package:im/app/modules/common_share_page/controllers/common_share_page_controller.dart';
import 'package:im/app/modules/direct_message/controllers/direct_message_controller.dart';
import 'package:im/common/extension/string_extension.dart';
import 'package:im/common/permission/permission_model.dart';
import 'package:im/common/permission/permission_utils.dart';
import 'package:im/pages/home/model/chat_index_model.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/pages/search/widgets/search_input_box.dart';
import 'package:im/themes/const.dart';
import 'package:im/widgets/app_bar/custom_appbar.dart';
import 'package:im/widgets/avatar.dart';
import 'package:im/widgets/channel_icon.dart';
import 'package:im/widgets/realtime_user_info.dart';

class CommonSharePageView extends StatefulWidget {
  const CommonSharePageView({Key key}) : super(key: key);

  @override
  _CommonSharePageViewState createState() => _CommonSharePageViewState();
}

class _CommonSharePageViewState extends State<CommonSharePageView> {
  @override
  void initState() {
    final guildId = ChatTargetsModel.instance.selectedChatTarget.id;
    Get.put(CommonShareController(guildId: guildId, data: Get.arguments));
    super.initState();
  }

  @override
  void dispose() {
    Get.delete<CommonShareController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: CustomAppbar(
        title: '选择'.tr,
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: GetBuilder<CommonShareController>(
          builder: (c) {
            return GestureDetector(
              onTapDown: (_) => c.focusNode.unfocus(),
              onVerticalDragStart: (_) => c.focusNode.unfocus(),
              onHorizontalDragStart: (_) => c.focusNode.unfocus(),
              child: Column(
                children: [
                  _buildSearchBox(c),
                  Expanded(
                    child: StreamBuilder(
                      stream: c.searchInputModel.searchStream,
                      builder: (_, snapshot) {
                        c.searchKey = snapshot.data;
                        if (!c.searchKey.hasValue) return _commonContentList(c);
                        return _searchContentList(c, c.searchKey);
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// 搜索结果列表
  Widget _searchContentList(CommonShareController c, String searchKey) {
    return FutureBuilder<List<UserInfo>>(
      future: c.searchMembers(searchKey),
      builder: (ctx, snap) {
        final List<UserInfo> items = snap.data;
        if (items == null) return const SizedBox();
        return ListView.separated(
          separatorBuilder: (context, index) => Divider(
            indent: 48,
            height: 0.5,
            color: const Color(0xFF8F959E).withOpacity(0.2),
          ),
          itemCount: items.length,
          itemBuilder: (ctx, index) {
            final user = items.elementAt(index);
            return _buildUser(
              user,
              onTap: () => c.onShareToUser(user),
            );
          },
        );
      },
    );
  }

  /// 搜索结果列表item
  Widget _buildUser(UserInfo user, {Divider divider, VoidCallback onTap}) {
    return UserInfo.consume(user.userId, builder: (context, u, widget) {
      return GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Container(
            padding: const EdgeInsets.only(left: 16),
            height: 64,
            child: Column(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      RealtimeAvatar(
                        userId: u.userId,
                        size: 40,
                      ),
                      sizeWidth12,
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            u.nickname,
                            style: const TextStyle(
                              fontSize: 16,
                              height: 20.0 / 16.0,
                              color: Color(0xFF363940),
                            ),
                          ),
                          Text("#${u.username}",
                              style: const TextStyle(
                                  fontSize: 13,
                                  height: 16.0 / 13.0,
                                  color: Color(0xFF8F959E))),
                        ],
                      ),
                    ],
                  ),
                ),
                if (divider != null) divider,
              ],
            ),
          ));
    });
  }

  /// 非搜索列表
  Widget _commonContentList(CommonShareController c) {
    return Column(
      children: [
        _buildTitle('最近联系人'.tr),
        Container(
          height: 91,
          color: Colors.white,
          child: _buildRecentUsers(c),
        ),
        const Divider(height: 8, thickness: 8, color: Color(0xFFF5F5F8)),
        _buildTitle('频道'.tr),
        Expanded(child: _buildChannelList()),
      ],
    );
  }

  /// 最近联系人列表
  Widget _buildRecentUsers(CommonShareController sc) {
    return GetBuilder<DirectMessageController>(
      builder: (c) {
        // 最多只显示10个联系人
        const int maxLength = 10;
        List<ChatChannel> dmList;
        if (c.channels.length > maxLength) {
          dmList = c.channels.sublist(0, maxLength);
        } else {
          dmList = c.channels;
        }
        if (dmList.isEmpty) {
          return const SizedBox();
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  // keyboardDismissBehavior:
                  //     ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: dmList
                        .where((element) => element.type == ChatChannelType.dm)
                        .map((channel) {
                      return Padding(
                        // padding: const EdgeInsets.symmetric(horizontal: 8),
                        padding:
                            const EdgeInsets.only(left: 8, right: 8, top: 6),
                        child: UserInfo.consume(
                            channel?.recipientId ?? channel?.guildId,
                            builder: (context, user, _) {
                          return GestureDetector(
                            onTap: () {
                              sc.onShareToUser(user);
                            },
                            child: Column(
                              children: <Widget>[
                                Avatar(url: user.avatar, radius: 24),
                                sizeHeight6,
                                SizedBox(
                                  width: 48,
                                  child: Center(
                                    child: RealtimeNickname(
                                      userId: user.userId,
                                      showNameRule: ShowNameRule.remarkAndGuild,
                                      // style:_theme.textTheme.bodyText2 ,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyText2
                                          .copyWith(height: 1, fontSize: 11),
                                    ),
                                  ),
                                )
                              ],
                            ),
                          );
                        }),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
            const Spacer(),
          ],
        );
      },
    );
  }

  /// 频道列表
  Widget _buildChannelList() => GetBuilder<CommonShareController>(
        builder: (controller) => ListView.builder(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          shrinkWrap: true,
          itemBuilder: (_, index) => _buildChannelItem(controller, index),
          // itemCount: controller.channelValue.length,
          itemCount: controller.channels.length,
        ),
      );

  /// 频道列表item
  Widget _buildChannelItem(CommonShareController controller, index) {
    final channel = controller.channels[index];
    final isPrivate = PermissionUtils.isPrivateChannel(
        PermissionModel.getPermission(channel.guildId), channel.id);
    return GestureDetector(
      onTap: () => controller.onChannelItemClick(index),
      behavior: HitTestBehavior.translucent,
      child: Obx(
        () => Container(
          color: controller.select == index
              ? const Color(0xFFF5F5F8)
              : Get.theme.backgroundColor,
          child: Column(
            children: [
              SizedBox(
                height: 52,
                child: Row(
                  children: [
                    sizeWidth16,
                    ChannelIcon(
                      ChatChannelType.guildText,
                      private: isPrivate,
                      size: 16,
                      color: Get.theme.disabledColor,
                    ),
                    sizeWidth12,
                    Expanded(
                      child: Text(
                        controller.channels[index].name,
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.normal,
                            height: 1.17,
                            color: Get.theme.iconTheme.color),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Visibility(
                      visible: controller.select == index,
                      child: MaterialButton(
                        height: 32,
                        minWidth: 60,
                        elevation: 0,
                        color: Get.theme.primaryColor,
                        textTheme: ButtonTextTheme.normal,
                        padding: EdgeInsets.zero,
                        textColor: Get.theme.backgroundColor,
                        shape: const RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(16))),
                        onPressed: () {
                          controller
                              .onShareToChannel(controller.selectedChannel.id);
                        },
                        child: Text('分享'.tr,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 14)),
                      ),
                    ),
                    sizeWidth16,
                  ],
                ),
              ),
              Divider(
                indent: 44,
                height: Get.theme.dividerTheme.thickness,
                color: Get.theme.dividerTheme.color,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBox(CommonShareController c) {
    return Container(
      color: Colors.white,
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: SearchInputBox(
        searchInputModel: c.searchInputModel,
        inputController: c.searchInputController,
        borderRadius: 18,
        hintText: "搜索".tr,
        autoFocus: false,
        height: 36,
        focusNode: c.focusNode,
      ),
    );
  }

  Widget _buildTitle(String title) {
    return Container(
      height: 40,
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Row(
              children: [
                sizeWidth16,
                Column(
                  children: [
                    const SizedBox(height: 14),
                    Text(
                      title,
                      style: Theme.of(context)
                          .textTheme
                          .bodyText1
                          .copyWith(fontSize: 14),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Divider(
            indent: 16,
            height: Get.theme.dividerTheme.thickness,
            color: Get.theme.dividerTheme.color,
          ),
        ],
      ),
    );
  }
}
