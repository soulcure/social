import 'package:azlistview/azlistview.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/app/modules/friend_apply_page/controllers/friend_apply_page_controller.dart';
import 'package:im/app/modules/friend_apply_page/views/friend_apply_page_view.dart';
import 'package:im/icon_font.dart';
import 'package:im/pages/friend/widgets/custom_index_bar.dart';
import 'package:im/pages/home/components/red_dot.dart';
import 'package:im/svg_icons.dart';
import 'package:im/themes/const.dart';
import 'package:im/themes/custom_color.dart';
import 'package:im/widgets/refresh/net_checker.dart';
import 'package:im/widgets/shape/row_bottom_border.dart';
import 'package:im/widgets/svg_tip_widget.dart';

import '../controllers/friend_list_page_controller.dart';
import 'item.dart';

class LandscapeFriendListPageView extends StatefulWidget {
  const LandscapeFriendListPageView({Key key}) : super(key: key);

  @override
  _LandscapeFriendListPageViewState createState() =>
      _LandscapeFriendListPageViewState();
}

class _LandscapeFriendListPageViewState
    extends State<LandscapeFriendListPageView> {
  // final SearchInputModel _model = SearchInputModel();
  final int _itemHeight = 64;
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      body: Column(
        children: [
          Container(
            decoration:
                const ShapeDecoration(shape: RowBottomBorder(leading: 0)),
            height: 56,
            child: Row(
              children: [
                sizeWidth24,
                Icon(
                  IconFont.buffNaviFriendList,
                  size: 18,
                  color: Theme.of(context).textTheme.bodyText2.color,
                ),
                sizeWidth10,
                Text(
                  '好友'.tr,
                  style: Theme.of(context)
                      .textTheme
                      .bodyText2
                      .copyWith(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                  child: VerticalDivider(),
                ),
                TextButton(
                    onPressed: () {
                      setState(() {
                        _index = 0;
                      });
                    },
                    child: Text(
                      '全部'.tr,
                      style: _index == 0
                          ? Theme.of(context).textTheme.bodyText2.copyWith(
                              fontWeight: FontWeight.bold, fontSize: 16)
                          : Theme.of(context)
                              .textTheme
                              .bodyText1
                              .copyWith(fontSize: 16),
                    )),
                const SizedBox(
                  width: 40,
                ),
                RedDotFillListenable(
                  valueListenable: FriendApplyPageController.friendApplyNum,
                  offset: const Offset(38, -2),
                  borderColor: CustomColor(context).backgroundColor1,
                  child: TextButton(
                      onPressed: () {
                        setState(() {
                          _index = 1;
                        });
                      },
                      child: Text(
                        '请求'.tr,
                        style: _index == 1
                            ? Theme.of(context).textTheme.bodyText2.copyWith(
                                fontWeight: FontWeight.bold, fontSize: 16)
                            : Theme.of(context)
                                .textTheme
                                .bodyText1
                                .copyWith(fontSize: 16),
                      )),
                ),
              ],
            ),
          ),
          Expanded(
            child: _index == 0
                ? NetChecker(
                    futureGenerator: FriendListPageController.to.init,
                    retry: () {
                      setState(() {});
                    },
                    builder: (v) {
                      return GetBuilder<FriendListPageController>(builder: (c) {
                        final list = c.friendList;
                        return list.isEmpty
                            ? Center(
                                child: SvgTipWidget(
                                svgName: SvgIcons.nullState,
                                text: '暂无好友'.tr,
                                desc: '快去添加同服务器的其他成员为好友吧'.tr,
                              ))
                            : AzListView(
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
                                    margin:
                                        const EdgeInsets.fromLTRB(16, 8, 0, 8),
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
                    })
                : const FriendApplyPageView(),
          ),
        ],
      ),
    );
  }

  Widget _item(UserInfoBean bean) {
    final userId = bean.user.userId;
    return FriendItem(userId: userId);
  }
}
