import 'package:date_format/date_format.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/api/entity/invite_code.dart';
import 'package:im/api/invite_api.dart';
import 'package:im/common/extension/string_extension.dart';
import 'package:im/icon_font.dart';
import 'package:im/pages/home/model/chat_index_model.dart';
import 'package:im/themes/const.dart';
import 'package:im/utils/orientation_util.dart';
import 'package:im/web/widgets/app_bar/web_appbar.dart';
import 'package:im/widgets/avatar.dart';
import 'package:im/widgets/default_tip_widget.dart';
import 'package:im/widgets/refresh/net_checker.dart';
import 'package:im/widgets/user_info/popup/user_info_popup.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class InviteCodeFriendPopup extends StatefulWidget {
  final String inviterName;
  final String hasInvited;
  final String code;
  final Function(String) totalUpdate;

  const InviteCodeFriendPopup({
    @required this.inviterName,
    @required this.hasInvited,
    @required this.code,
    @required this.totalUpdate,
  });

  @override
  _InviteCodeFriendPopupState createState() => _InviteCodeFriendPopupState();
}

class _InviteCodeFriendPopupState extends State<InviteCodeFriendPopup> {
  final _controller = RefreshController();
  ValueNotifier<EntityInviteUserInfoList> dataSource = ValueNotifier(null);
  final pageSize = 50;
  String _hasInvited;
  final _scrollController = ScrollController();

  @override
  void initState() {
    _hasInvited = widget.hasInvited;
    _scrollController.addListener(_onScroll);
    super.initState();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.offset ==
            _scrollController.position.maxScrollExtent &&
        !_controller.isLoading &&
        _controller.footerStatus != LoadStatus.noMore) {
      _controller.requestLoading();
    }
  }

  Future loadInitData() async {
    final Map data = await InviteApi.getCodeInvitedList({
      'code': widget.code,
      'list_id': '0',
      'size': pageSize,
    });
    if (data != null) {
      final list = EntityInviteUserInfoList.fromJson(data);
      dataSource.value = list;
      if (list.hasInvited != _hasInvited) {
        widget.totalUpdate.call(list.hasInvited);
        setState(() {
          _hasInvited = list.hasInvited;
        });
      }
    }
    return true;
  }

  Future<bool> loadMoreData() async {
    try {
      final Map data = await InviteApi.getCodeInvitedList({
        'code': widget.code,
        'size': pageSize,
        'list_id': dataSource.value.listId,
      });
      if (data != null) {
        final list = EntityInviteUserInfoList.fromJson(data);
        dataSource.value = EntityInviteUserInfoList(
          records: dataSource.value.records + list.records,
          listId: list.listId,
          next: list.next,
        );
      }
      _controller.loadComplete();
      return true;
    } catch (e) {
      _controller.loadComplete();
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final child = Column(
      children: [
        if (OrientationUtil.portrait)
          Container(
            height: 49,
            padding: const EdgeInsets.fromLTRB(16, 16, 0, 16),
            alignment: Alignment.centerLeft,
            child: Text(
              '%s 已邀请%s位好友'
                  .trArgs([widget.inviterName, _hasInvited.toString()]),
              style: Theme.of(context).textTheme.bodyText2.copyWith(
                  fontWeight: FontWeight.bold, fontSize: 17, height: 1),
            ),
          ),
        Expanded(
          child: NetChecker(
            futureGenerator: loadInitData,
            retry: () {
              setState(() => {});
            },
            builder: (_) {
              return ValueListenableBuilder<EntityInviteUserInfoList>(
                  valueListenable: dataSource,
                  builder: (context, list, _) {
                    if (list?.records == null || list.records.isEmpty) {
                      return Center(
                        child: DefaultTipWidget(
                          icon: IconFont.buffCommonNoData,
                          iconBackgroundColor: Colors.white,
                          text: '暂未创建邀请链接'.tr,
                        ),
                      );
                    }
                    return SmartRefresher(
                      controller: _controller,
                      enablePullDown: false,
                      enablePullUp: list.next == '1',
                      onLoading: loadMoreData,
                      footer: ClassicFooter(
                        idleText: '移动到底部加载更多'.tr,
                        loadingText: '加载中'.tr,
                        canLoadingText: '上拉加载更多'.tr,
                        failedText: '加载失败'.tr,
                      ),
                      child: ListView.builder(
                          itemCount: list.records.length,
                          controller: _scrollController,
                          itemBuilder: (context, index) {
                            return _item(index, list.records[index]);
                          }),
                    );
                  });
            },
          ),
        ),
      ],
    );
    if (OrientationUtil.portrait)
      return Container(
          height: 502, color: Theme.of(context).backgroundColor, child: child);
    else
      return Scaffold(
        backgroundColor: Theme.of(context).backgroundColor,
        appBar: WebAppBar(
          title: '%s 已邀请%s位好友'
              .trArgs([widget.inviterName, _hasInvited.toString()]),
          height: 68,
        ),
        body: child,
      );
  }

  Widget _item(int index, EntityInviteUserInfo data) {
    final time = data.created != null
        ? formatDate(DateTime.fromMillisecondsSinceEpoch(data.created * 1000),
            [yyyy, "/", m, "/", d, " ", HH, ":", nn])
        : '';
    String nickname = data.getNickName() ?? '';
    nickname = nickname.takeCharacter(8);
    return GestureDetector(
      onTap: () {
        if (kIsWeb) return;
        showUserInfoPopUp(
          context,
          userId: data.userId,
          guildId: ChatTargetsModel.instance.selectedChatTarget.id,
        );
      },
      child: Container(
        height: OrientationUtil.portrait ? 45 : 72,
        margin: EdgeInsets.symmetric(
            horizontal: OrientationUtil.portrait ? 16 : 24),
        decoration: BoxDecoration(
            border: Border(
                bottom:
                    BorderSide(color: Theme.of(context).dividerTheme.color))),
        child: Row(
          children: [
            if (data.avatar.isEmpty)
              SizedBox(
                width: OrientationUtil.portrait ? 32 : 40,
              ),
            Avatar(
              url: data.avatar,
              radius: OrientationUtil.portrait ? 16 : 20,
            ),
            sizeWidth12,
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  nickname,
                  style:
                      Theme.of(context).textTheme.bodyText2.copyWith(height: 1),
                ),
                const SizedBox(
                  height: 4,
                ),
                Text(
                  '%s 加入'.trArgs([time.toString()]),
                  style: Theme.of(context)
                      .textTheme
                      .bodyText1
                      .copyWith(fontSize: 12, height: 1),
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}
