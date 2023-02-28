import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/api/relation_api.dart';
import 'package:im/app/modules/friend_apply_page/controllers/friend_apply_page_controller.dart';
import 'package:im/svg_icons.dart';
import 'package:im/utils/orientation_util.dart';
import 'package:im/widgets/app_bar/appbar_builder.dart';
import 'package:im/widgets/refresh/net_checker.dart';
import 'package:im/widgets/svg_tip_widget.dart';

import 'item.dart';

class FriendApplyPageView extends StatefulWidget {
  const FriendApplyPageView({Key key}) : super(key: key);

  @override
  _FriendApplyPageViewState createState() => _FriendApplyPageViewState();
}

class _FriendApplyPageViewState extends State<FriendApplyPageView>
    with AutomaticKeepAliveClientMixin {
  @override
  // ignore: must_call_super
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: OrientationUtil.portrait ? FbAppBar.custom('新的朋友'.tr) : null,
      body: NetChecker(
          futureGenerator: FriendApplyPageController.to.init,
          retry: () => setState(() {}),
          builder: (v) {
            return GetBuilder<FriendApplyPageController>(builder: (controller) {
              if (controller.incomingList.isEmpty &&
                  controller.outgoingList.isEmpty)
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 100),
                    child: SvgTipWidget(
                      svgName: SvgIcons.nullState,
                      text: '暂无好友请求'.tr,
                      desc: '在服务器中遇到有趣的朋友\n要主动Say Hi 呀~'.tr,
                    ),
                  ),
                );

              return ListView(
                children: <Widget>[
                  _buildOutgoingList(),
                  _buildIncomingList(),
                ],
              );
            });
          }),
    );
  }

  Widget _buildIncomingList() {
    final list = FriendApplyPageController.to.incomingList;
    if (list.isEmpty) return const SizedBox();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text('我收到的请求'.tr,
              style:
                  Theme.of(context).textTheme.bodyText1.copyWith(fontSize: 12)),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: list.map(_item).toList(),
        )
      ],
    );
  }

  Widget _buildOutgoingList() {
    final list = FriendApplyPageController.to.outgoingList;
    if (list.isEmpty) return const SizedBox();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text('我发出的请求'.tr,
              style:
                  Theme.of(context).textTheme.bodyText1.copyWith(fontSize: 12)),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: list.map(_item).toList(),
        )
      ],
    );
  }

  Widget _item(FriendApply request) {
    return FriendApplyItem(request: request);
  }

  @override
  bool get wantKeepAlive => true;
}
