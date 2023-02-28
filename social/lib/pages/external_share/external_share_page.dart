import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:im/api/data_model/user_info.dart';
import 'package:im/common/extension/string_extension.dart';
import 'package:im/global.dart';
import 'package:im/pages/external_share/external_share_send_dialog.dart';
import 'package:im/pages/external_share/external_share_user_list_page.dart';
import 'package:im/pages/home/model/chat_index_model.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/pages/search/model/search_model.dart';
import 'package:im/pages/search/widgets/search_input_box.dart';
import 'package:im/routes.dart';
import 'package:im/themes/const.dart';
import 'package:im/widgets/app_bar/custom_appbar.dart';
import 'package:im/widgets/avatar.dart';
import 'package:im/widgets/button/more_icon.dart';
import 'package:im/widgets/realtime_user_info.dart';
import 'package:provider/provider.dart';

import '../../global.dart';
import 'external_share_channel_list_page.dart';
import 'external_share_model.dart';

typedef ItemBuilder = Widget Function(BuildContext context, int index);

class ListIntroWidget extends StatelessWidget {
  final String title;
  final int maxIntroCount;
  final int currentCount;
  final VoidCallback onMore;
  final ItemBuilder buildItem;

  const ListIntroWidget(this.title, this.maxIntroCount, this.currentCount,
      this.buildItem, this.onMore);

  @override
  Widget build(BuildContext context) {
    if (currentCount <= 0) return const SizedBox();

    return Column(
      children: [
        _buildTitle(),
        ..._buildItems(context),
        if (currentCount > maxIntroCount) _buildMore(),
      ],
    );
  }

  Widget _buildTitle() {
    return Container(
      padding: const EdgeInsets.only(left: 16, right: 16),
      height: 44,
      child: Row(
        children: [
          Expanded(
            child: Text(title),
          )
        ],
      ),
    );
  }

  List<Widget> _buildItems(BuildContext context) {
    final List<Widget> items = [];
    for (int i = 0; i < maxIntroCount && i < currentCount; i++) {
      items.add(buildItem(context, i));
    }
    return items;
  }

  Widget _buildMore() {
    return Container(
        padding: const EdgeInsets.only(left: 16, right: 16),
        height: 44,
        child: Column(
          children: [
            Divider(
              height: 0.5,
              color: const Color(0xFF8F959E).withOpacity(0.2),
            ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    "查看更多".tr,
                    style: const TextStyle(
                        color: Color(0xFF363940), fontSize: 14, height: 1.214),
                  ),
                ),
                const MoreIcon(),
              ],
            ),
          ],
        ));
  }
}

class ExternalSharePage extends StatefulWidget {
  final ExternalShareModel model;

  const ExternalSharePage(this.model, {Key key}) : super(key: key);

  @override
  _ExternalSharePageState createState() => _ExternalSharePageState();
}

class _ExternalSharePageState extends State<ExternalSharePage> {
  SearchInputModel _searchInputModel;
  TextEditingController _searchInputController;
  String searchKey;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);

    _searchInputModel = SearchInputModel();
    _searchInputController = TextEditingController();

    final GuildTarget guild = ChatTargetsModel.instance.chatTargets.firstWhere(
        (element) => element.id == widget.model.toGuildId,
        orElse: () => null) as GuildTarget;
    if (guild != null) {
      scheduleMicrotask(() {
        Navigator.push(
          Global.navigatorKey.currentContext,
          MaterialPageRoute(
            builder: (_) => ExternalShareChannelListPage(widget.model, guild),
          ),
        );
      });
    }
  }

  Widget _buildUser(String userId, {Divider divider, VoidCallback onTap}) {
    return UserInfo.consume(userId, builder: (context, u, widget) {
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

  Widget _buildGuild(GuildTarget guild, {Divider divider, VoidCallback onTap}) {
    return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            height: 64,
            child: Column(
              children: [
                Expanded(
                    child: Row(
                  children: [
                    Avatar(
                      url: guild.icon,
                      radius: 20,
                    ),
                    sizeWidth12,
                    Text(
                      guild.name,
                      style: const TextStyle(
                          fontSize: 16,
                          height: 20.0 / 16.0,
                          color: Color(0xFF363940)),
                    ),
                  ],
                )),
                if (divider != null) divider,
              ],
            )));
  }

  Widget _buildMore(VoidCallback onTapMore) {
    return GestureDetector(
      onTap: onTapMore,
      behavior: HitTestBehavior.opaque,
      child: Container(
          padding: const EdgeInsets.only(left: 16),
          alignment: Alignment.centerLeft,
          height: 44,
          child: Column(
            children: [
              Divider(
                thickness: 0.5,
                color: const Color(0xFF8F959E).withOpacity(0.2),
              ),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        "查看更多".tr,
                        style: const TextStyle(
                            color: Color(0xFF363940),
                            fontSize: 14,
                            height: 1.214),
                      ),
                    ),
                    const MoreIcon(),
                    sizeWidth16,
                  ],
                ),
              ),
            ],
          )),
    );
  }

  // 介绍列表
  // maxCount 为 -1 展示所有
  List<Widget> _buildIntroduction(String title, int maxCount, int itemCount,
      NullableIndexedWidgetBuilder builder,
      {VoidCallback onTapMore}) {
    // 没有数据，则不显示
    if (itemCount == 0) return [];
    final count = maxCount == -1
        ? itemCount
        : (maxCount < itemCount ? maxCount : itemCount);

    return [
      SliverToBoxAdapter(
          child: Container(
              padding: const EdgeInsets.only(left: 16),
              height: 40,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Container(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        title,
                        style: const TextStyle(
                            fontSize: 14,
                            height: 17.0 / 14.0,
                            color: Color(0xFF646A73)),
                      ),
                    ),
                  ),
                  Divider(
                    thickness: 0.5,
                    color: const Color(0xFF8F959E).withOpacity(0.2),
                  ),
                ],
              ))),
      // 当列表项高度固定时，使用 SliverFixedExtendList 比 SliverList 具有更高的性能
      SliverFixedExtentList(
          delegate: SliverChildBuilderDelegate(builder, childCount: count),
          itemExtent: 64),

      // 有更多，才显示更多
      if (itemCount > count)
        SliverToBoxAdapter(
          child: _buildMore(onTapMore),
        ),
    ];
  }

  Widget _buildSearchList() {
    return StreamBuilder(
      stream: _searchInputModel.searchStream,
      builder: (context, snapshot) {
        searchKey = snapshot.data;
        if (!searchKey.hasValue) return normalContentList();
        return searchedContentList(searchKey);
      },
    );
  }

  Widget normalContentList() {
    return ChangeNotifierProvider.value(
      value: widget.model,
      child: Consumer<ExternalShareModel>(
        builder: (ctx, model, _) {
          final recentIds = widget.model.recentUserListIds();
          final friendIds = widget.model.friendListIds();
          return CustomScrollView(slivers: [
            ..._buildIntroduction("最近联系人".tr, 3, recentIds.length,
                (context, index) {
              final userId = recentIds.elementAt(index);
              final divider = Divider(
                height: 0.5,
                thickness: 0.5,
                indent: 52,
                color: const Color(0xFF8F959E).withOpacity(0.2),
              );
              return _buildUser(userId,
                  divider:
                      (index < widget.model.recentUserListIds().length - 1) &&
                              index < 3
                          ? divider
                          : null, onTap: () async {
                await widget.model.selectUser(userId);
                final currContext = Global.navigatorKey.currentContext;
                await showDialog(
                    context: currContext,
                    builder: (cxt) {
                      return ExternalShareSendDialog(
                        widget.model,
                        onConfirm: () {
                          Navigator.pop(cxt, true);
                          widget.model.share();
                        },
                        onCancel: () {
                          Navigator.pop(cxt, true);
                        },
                      );
                    },
                    barrierDismissible: false);
              });
            }, onTapMore: () async {
              await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (ctx) =>
                          ExternalShareUserListPage(widget.model, "recents")));
            }),
            SliverToBoxAdapter(
              child: Container(height: 8, color: const Color(0xFFF5F5F8)),
            ),
            ..._buildIntroduction("好友".tr, 3, friendIds.length,
                (context, index) {
              final userId = friendIds.elementAt(index);
              final divider = Divider(
                  thickness: 0.5,
                  height: 0.5,
                  indent: 52,
                  color: const Color(0xFF8F959E).withOpacity(0.2));
              return _buildUser(userId,
                  divider: (index < friendIds.length - 1) && index < 3
                      ? divider
                      : null, onTap: () async {
                await widget.model.selectUser(userId);
                final currContext = Global.navigatorKey.currentContext;
                await showDialog(
                    context: currContext,
                    builder: (cxt) {
                      return ExternalShareSendDialog(
                        widget.model,
                        onConfirm: () {
                          Navigator.pop(cxt, true);
                          widget.model.share();
                        },
                        onCancel: () {
                          Navigator.pop(cxt, true);
                        },
                      );
                    },
                    barrierDismissible: false);
              });
            }, onTapMore: () {
              Routes.push(
                  context,
                  ExternalShareUserListPage(widget.model, "friends"),
                  "external_share_user_list");
            }),
            SliverToBoxAdapter(
              child: Container(height: 8, color: const Color(0xFFF5F5F8)),
            ),
            ..._buildIntroduction("服务器".tr, -1, widget.model.guildList().length,
                (context, index) {
              final item = widget.model.guildList().elementAt(index);
              final divider = Divider(
                  thickness: 0.5,
                  height: 0.5,
                  indent: 52,
                  color: const Color(0xFF8F959E).withOpacity(0.2));
              return _buildGuild(item,
                  divider: (index < widget.model.guildList().length - 1)
                      ? divider
                      : null, onTap: () {
                // 进入频道列表
                Routes.push(
                    context,
                    ExternalShareChannelListPage(widget.model, item),
                    "external_share_user_list");
              });
            }),
          ]);
        },
      ),
    );
  }

  Widget searchedContentList(String searchKey) {
    return FutureBuilder(
      future: widget.model.searchMembers(searchKey),
      builder: (ctx, snap) {
        final List<String> items = snap.data;
        if (items == null) return const SizedBox();
        return ListView.separated(
            separatorBuilder: (context, index) => Divider(
                indent: 48,
                height: 0.5,
                color: const Color(0xFF8F959E).withOpacity(0.2)),
            itemCount: items.length,
            itemBuilder: (ctx, index) {
              final userId = items.elementAt(index);
              return _buildUser(userId, onTap: () async {
                await widget.model.selectUser(userId);
                final currContext = Global.navigatorKey.currentContext;
                await showDialog(
                    context: currContext,
                    builder: (cxt) {
                      return ExternalShareSendDialog(
                        widget.model,
                        onConfirm: () {
                          Navigator.pop(cxt, true);
                          widget.model.share();
                        },
                        onCancel: () {
                          Navigator.pop(cxt, true);
                        },
                      );
                    },
                    barrierDismissible: false);
              });
            });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () {
        widget.model.back();
        return Future.value(false);
      },
      child: Scaffold(
        appBar: CustomAppbar(
          leadingCallback: widget.model.back,
          title: '选择'.tr,
        ),
        backgroundColor: Colors.white,
        body: SafeArea(
          child: FutureBuilder(
              future: widget.model.init(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: TextButton(
                      onPressed: () => setState(() {}),
                      child: Text("请求失败，点击重试".tr),
                    ),
                  );
                }

                return Column(
                  children: [
                    /// 标题
                    _buildSearchBox(),
                    Expanded(child: _buildSearchList()),
                  ],
                );
              }),
        ),
      ),
    );
  }

  Widget _buildSearchBox() {
    return Container(
      color: Colors.white,
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: SearchInputBox(
        searchInputModel: _searchInputModel,
        inputController: _searchInputController,
        borderRadius: 18,
        hintText: "搜索联系人或好友".tr,
        autoFocus: false,
        height: 36,
      ),
    );
  }
}
