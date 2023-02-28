import 'package:azlistview/azlistview.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/app/modules/friend_apply_page/controllers/friend_apply_page_controller.dart';
import 'package:im/app/modules/friend_list_page/views/item.dart';
import 'package:im/app/routes/app_pages.dart';
import 'package:im/core/widgets/button/fade_background_button.dart';
import 'package:im/icon_font.dart';
import 'package:im/pages/friend/widgets/custom_index_bar.dart';
import 'package:im/pages/home/components/red_dot.dart';
import 'package:im/svg_icons.dart';
import 'package:im/themes/const.dart';
import 'package:im/widgets/app_bar/appbar_builder.dart';
import 'package:im/widgets/button/more_icon.dart';
import 'package:im/widgets/refresh/net_checker.dart';
import 'package:im/widgets/svg_tip_widget.dart';

import '../controllers/friend_list_page_controller.dart';

class PortraitFriendListPageView extends StatefulWidget {
  const PortraitFriendListPageView({Key key}) : super(key: key);

  @override
  _PortraitFriendListPageViewState createState() =>
      _PortraitFriendListPageViewState();
}

class _PortraitFriendListPageViewState
    extends State<PortraitFriendListPageView> {
  final int _itemHeight = 64;

  Widget _addFriendWidget() {
    return Column(
      children: [
        FadeBackgroundButton(
          tapDownBackgroundColor: Theme.of(context).scaffoldBackgroundColor,
          onTap: () => Get.toNamed(Routes.FRIEND_APPLY_PAGE),
          child: SizedBox(
            height: 68,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                sizeWidth16,
                Container(
                  height: 40,
                  width: 40,
                  decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      borderRadius: BorderRadius.circular(20)),
                  child: const Icon(
                    IconFont.buffModuleMenuOpen,
                    color: Colors.white,
                  ),
                ),
                sizeWidth12,
                Expanded(
                  child: Text(
                    '新的朋友'.tr,
                    style: Theme.of(context).textTheme.bodyText2,
                  ),
                ),
                ValueListenableBuilder(
                    valueListenable: FriendApplyPageController.friendApplyNum,
                    builder: (context, value, widget) {
                      return RedDot(
                        value,
                        fontSize: 11,
                      );
                    }),
                sizeWidth4,
                const MoreIcon(),
                sizeWidth16,
              ],
            ),
          ),
        ),
        Container(
          color: Theme.of(context).scaffoldBackgroundColor,
          height: 16,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      appBar: FbAppBar.custom('通讯录'.tr),
      body: NetChecker(
          futureGenerator: FriendListPageController.to.init,
          retry: () {
            setState(() {});
          },
          builder: (v) {
            return GetBuilder<FriendListPageController>(builder: (c) {
              final list = c.friendList;
              return list.isEmpty
                  ? Stack(
                      children: [
                        _addFriendWidget(),
                        Center(
                            child: SvgTipWidget(
                          svgName: SvgIcons.nullState,
                          text: '暂无好友'.tr,
                          desc: '快去添加同服务器的其他成员为好友吧'.tr,
                        )),
                      ],
                    )
                  : AzListView(
                      header: AzListViewHeader(
                          height: 84,
                          builder: (_) {
                            return _addFriendWidget();
                          }),
                      suspensionHeight: 0,
                      data: list,
                      itemBuilder: (context, model) => _item(model),
                      shrinkWrap: false,
                      itemHeight: _itemHeight,
                      indexHintBuilder: (context, hint) {
                        return Card(
                          color: Colors.black54,
                          shape: const CircleBorder(),
                          child: Container(
                            alignment: Alignment.center,
                            width: 60,
                            height: 60,
                            child: Text(
                              hint,
                              style: const TextStyle(
                                fontSize: 24,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        );
                      },
                      indexBarBuilder: (context, tags, onTouch) {
                        return Container(
                          margin: const EdgeInsets.fromLTRB(16, 65, 0, 16),
                          child: CustomIndexBar(
                            touchDownColor: Colors.transparent,
                            data: tags,
                            width: 38,
                            itemHeight: 22,
                            textStyle: Theme.of(context)
                                .textTheme
                                .bodyText1
                                .copyWith(fontSize: 12),
                            touchDownTextStyle: Theme.of(context)
                                .textTheme
                                .bodyText1
                                .copyWith(fontSize: 12),
                            onTouch: (details) {
                              onTouch(details);
                            },
                          ),
                        );
                      });
            });
          }),
    );
  }

  Widget _item(UserInfoBean bean) {
    final userId = bean.user.userId;
    return FriendItem(userId: userId);
  }
}
