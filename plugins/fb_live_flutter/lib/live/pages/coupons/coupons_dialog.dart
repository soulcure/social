import 'package:fb_live_flutter/live/bloc/coupons/coupons_dialog_bloc.dart';
import 'package:fb_live_flutter/live/bloc/logic/goods_logic.dart';
import 'package:fb_live_flutter/live/model/room_infon_model.dart';
import 'package:fb_live_flutter/live/pages/coupons/widget/coupons_card.dart';
import 'package:fb_live_flutter/live/pages/goods/commom/goods_app_bar.dart';
import 'package:fb_live_flutter/live/pages/goods/commom/show_goods_dialog.dart';
import 'package:fb_live_flutter/live/pages/goods/widget/goods_no_data.dart';
import 'package:fb_live_flutter/live/utils/log/coupons_log_up.dart';
import 'package:fb_live_flutter/live/utils/ui/frame_size.dart';
import 'package:fb_live_flutter/live/utils/ui/listview_custom_view.dart';
import 'package:fb_live_flutter/live/utils/ui/ui.dart';
import 'package:fb_live_flutter/live/widget_common/flutter/click_event.dart';
import 'package:fb_live_flutter/live/widget_common/view/bottom_option_bar.dart';
import 'package:fb_live_flutter/live/widget_common/view/loading_text_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

/// 优惠券对话框
Future couponsDialog(BuildContext context, bool? isAdmin, bool isShowReceive,
    final RoomInfon roomInfoObject, final GoodsLogic goodsLogic) {
  /// (直播页)点击领券卡片; 【日志上报】
  CouponsLogUp.clickCouponsCard(roomInfoObject: roomInfoObject);

  return showGoodsDialog(
    context,
    child: BlocProvider(
      create: (context) {
        return CouponsDialogBloc();
      },
      child:
          CouponsDialogPage(isAdmin, isShowReceive, roomInfoObject, goodsLogic),
    ),
  );
}

class CouponsDialogPage extends StatefulWidget {
  final bool? isAdmin;
  final bool isShowReceive;
  final RoomInfon roomInfoObject;
  final GoodsLogic goodsLogic;

  const CouponsDialogPage(
    this.isAdmin,
    this.isShowReceive,
    this.roomInfoObject,
    this.goodsLogic,
  );

  @override
  CouponsDialogPageState createState() => CouponsDialogPageState();
}

class CouponsDialogPageState extends State<CouponsDialogPage>
    with AutomaticKeepAliveClientMixin {
  final double rate = 609 / 821;

  final CouponsDialogBloc _manageBloc = CouponsDialogBloc();

  @override
  void initState() {
    super.initState();
    _manageBloc.init(this);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return BlocBuilder<CouponsDialogBloc, int>(
      builder: (context, value) {
        return SizedBox(
          width: FrameSize.winWidth(),
          height: (FrameSize.maxValue() * rate) - 20.px - FrameSize.padBotH(),
          child: Column(
            children: [
              GoodsAppBar(
                /// 【2021 11.27】【APP】优惠券数量超过20个，顶上显示数量为20，下滑加载出新的优惠券后显示正常数量
                title: "优惠券 (${_manageBloc.total ?? 0})",
                items: const [],

                /// 【2021 11.19】【优惠卷】优惠卷列表- 仅在主播端展示刷新按钮，观众端不需要
                ///
                /// 怎么做【逻辑】？
                /// - 在显示的地方判断是否【主播/小助手】
                ///
                /// isAdmin：是否为【主播/小助手】
                rWidget: !widget.isAdmin!
                    ? Container()
                    : ClickEvent(
                        onTap: () async {
                          /// 优惠券-无数据时加载中
                          if (!_manageBloc.isHaveData) {
                            _manageBloc.initState();
                            await _manageBloc.init(this);
                            return;
                          }

                          /// 点击刷新先状态变更
                          _manageBloc.scrollController.jumpTo(0);
                          _manageBloc.initState();

                          await _manageBloc.refreshStockNew();
                        },
                        child: Container(
                          height: 21.px,
                          alignment: Alignment.center,
                          child: Row(
                            children: [
                              Image.asset(
                                'assets/live/main/coupons_right_refresh.png',
                                width: 20.px,
                                height: 20.px,
                              ),
                              Space(width: 4.px),
                              Container(
                                height: 20.px,
                                alignment: Alignment.center,
                                child: Text(
                                  '刷新',
                                  style: TextStyle(
                                    color: const Color(0xff646A73),
                                    fontSize: 14.px,
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                goodCall: (value) {
                  _manageBloc.action(value);
                },
              ),

              /// 【APP】快速购买页，上方固定的一栏，与商品列表间距过大
              /// 原本20.px
              // Space(height: 15.px),
              Expanded(
                child: _manageBloc.isRefreshing
                    ? const LoadingTextView("刷新中...")
                    : !_manageBloc.isLoadOk
                        ? const LoadingTextView()
                        : !_manageBloc.isHaveData
                            ? CouponsNoData(widget.isAdmin, _manageBloc.models,
                                widget.goodsLogic)
                            : SmartRefresher(
                                enablePullUp: true,
                                enablePullDown: false,
                                footer: const CustomFooterView(),
                                controller: _manageBloc.refreshController,
                                onLoading: () async {
                                  _manageBloc.pageNum++;
                                  return _manageBloc.liveCouponList(0,
                                      isToast: true, isRefresh: false);
                                },
                                child: ListView.builder(
                                  controller: _manageBloc.scrollController,
                                  padding: const EdgeInsets.all(0),
                                  itemCount: _manageBloc.models.length,
                                  itemBuilder: (context, index) {
                                    final int rank =
                                        _manageBloc.models.length - index;
                                    final item = _manageBloc.models[index];
                                    return Padding(
                                      /// [ ] 多选按钮没跟优惠券居中对齐
                                      /// [2021 11.20]
                                      padding: EdgeInsets.only(bottom: 10.px),
                                      child: CouponsCard(
                                        rank,
                                        item,
                                        isShowReceive: widget.isShowReceive,
                                        roomInfoObject: widget.roomInfoObject,
                                        goodsLogic: widget.goodsLogic,
                                      ),
                                    );
                                  },
                                ),
                              ),
              ),

              /// 【管理/添加】按钮
              if (widget.isAdmin! && _manageBloc.isHaveData)
                BottomOptionBarState(_manageBloc.action),
            ],
          ),
        );
      },
      bloc: _manageBloc,
    );
  }

  @override
  void dispose() {
    super.dispose();
    _manageBloc.close();
  }

  @override
  bool get wantKeepAlive => true;
}
