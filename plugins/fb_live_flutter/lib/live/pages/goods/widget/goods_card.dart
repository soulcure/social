import 'dart:async';

import 'package:fb_live_flutter/live/bloc/goods/goods_manage_bloc.dart';
import 'package:fb_live_flutter/live/model/goods/goods_add.dart';
import 'package:fb_live_flutter/live/model/room_infon_model.dart';
import 'package:fb_live_flutter/live/net/api.dart';
import 'package:fb_live_flutter/live/pages/goods/commom/goods_card_parent.dart';
import 'package:fb_live_flutter/live/utils/func/utils_class.dart';
import 'package:fb_live_flutter/live/utils/log/goods_log_up.dart';
import 'package:fb_live_flutter/live/utils/theme/my_toast.dart';
import 'package:fb_live_flutter/live/utils/ui/frame_size.dart';
import 'package:fb_live_flutter/live/utils/ui/ui.dart';
import 'package:fb_live_flutter/live/widget_common/button/small_button.dart';
import 'package:fb_live_flutter/live/widget_common/flutter/click_event.dart';
import 'package:fb_live_flutter/live/widget_common/image/sw_image.dart';
import 'package:flutter/material.dart';
import 'package:oktoast/oktoast.dart';

import '../goods_sku_dialog.dart';

typedef CallCart = Function(BuildContext context);

/// 商品列表-普通卡片:
/// 观众可见
class GoodsCard extends StatefulWidget {
  final GoodsStatus status;
  final int rank;
  final GoodsListModel item;
  final CallCart? callCart;
  final RoomInfon roomInfoObject;

  const GoodsCard(
    this.status,
    this.rank,
    this.item,
    this.callCart,
    this.roomInfoObject,
  );

  @override
  _GoodsCardState createState() => _GoodsCardState();
}

class _GoodsCardState extends State<GoodsCard>
    with AutomaticKeepAliveClientMixin {
  GoodsStatus? _status;

  @override
  void initState() {
    super.initState();
    _status = widget.status;

    GoodsLogUp.shoppingCartShow(widget.item, widget.rank,
        roomInfoObject: widget.roomInfoObject);
  }

  /*
  * 库存不足相应处理
  * */
  void stockNot(Map value) {
    /// 700=处理库存不足ui效果
    if (value['code'] == 700) {
      _status = GoodsStatus.gone;
      if (mounted) setState(() {});
    }
  }

  Future action(bool isCar, {VoidCallback? addSuccess}) async {
    if (_status == GoodsStatus.gone) {
      myToast("商品库存不够无法进行购买");
      return;
    }

    /// 【2021 11.24】【商品列表对话框】点击进入sku检测库存中提示  应：正在加载
    myLoadingToast(tips: "正在加载");
    final value =
        await Api.shopGoodsDetail(widget.item.shopId, widget.item.itemId);
    if (value['code'] != 200) {
      stockNot(value);
      return;
    }
    dismissAllToast();

    final GoodsListModel detModel = GoodsListModel.fromJson(value['data']);
    if ((detModel.quantity ?? 0) > 0) {
      if (isCar) {
        await GoodsLogUp.clickAdd(widget.item, widget.rank,
            roomInfoObject: widget.roomInfoObject);
      } else {
        await GoodsLogUp.clickGrab(widget.item, widget.rank,
            roomInfoObject: widget.roomInfoObject);
      }
      return goodsSkuDialog(context, isCar, widget.item, widget.rank,
          addSuccess, widget.roomInfoObject);
    } else {
      /// 列表，点击商品的立即买，和优惠券的立即抢，需要实时去查询库存。
      myToast("商品库存不够无法进行购买");
      _status = GoodsStatus.gone;
      if (mounted) setState(() {});
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return GoodsCardParent(
      status: _status,
      rank: widget.rank,
      item: widget.item,
      builder: (context) {
        return [
          /// 【2021 12.02】商品列表判断虚拟商品隐藏购物车按钮
          if (_status == GoodsStatus.ok && widget.item.itemType != 60)
            Builder(
              builder: (context) {
                return SwImage(
                  'assets/live/main/goods_car_red.png',
                  width: 24.px,
                  height: 24.px,
                  onTap: () async {
                    await action(true, addSuccess: () {
                      if (widget.callCart != null) {
                        widget.callCart!(context);
                      }
                    });
                  },

                  /// [ ] 购物车跟「马上抢」没对齐
                  /// [2021 11.20]
                  margin:
                      EdgeInsets.symmetric(horizontal: 8.px, vertical: 4.px),
                );
              },
            ),
          SmallButton(
            color: _status == GoodsStatus.gone
                ? const Color(0xff8F959E).withOpacity(0.15)
                : const Color(0xffF24848),
            width: 76.px,
            height: 32.px,
            borderRadius: BorderRadius.all(Radius.circular(16.px)),
            margin: const EdgeInsets.all(0),
            padding: const EdgeInsets.all(0),
            onPressed: () {
              return action(false);
            },
            child: Text(
              '马上抢',
              style: TextStyle(
                  color: _status == GoodsStatus.gone
                      ? const Color(0xff8F959E).withOpacity(0.65)
                      : Colors.white,
                  fontSize: 14.px),
            ),
          )
        ];
      },
      roomInfoObject: widget.roomInfoObject,
    );
  }

  @override
  bool get wantKeepAlive => true;
}

/// 商品列表-推送卡片:
/// 主播/小助手可见

class GoodsPushCard extends StatefulWidget {
  final GoodsCheckValueCall call;
  final int rank;
  final GoodsListModel item;
  final GoodsManageBloc manageBloc;
  final RoomInfon roomInfoObject;

  const GoodsPushCard(
    this.rank,
    this.item,
    this.call,
    this.manageBloc,
    this.roomInfoObject,
  );

  @override
  _GoodsPushCardState createState() => _GoodsPushCardState();
}

class _GoodsPushCardState extends State<GoodsPushCard>
    with AutomaticKeepAliveClientMixin {
  bool isCountText(String value) {
    return value != "推送" && value != "移除";
  }

  int? get count {
    return widget.manageBloc.count;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return GoodsCardParent(
      status: widget.item.quantity == 0 ? GoodsStatus.gone : GoodsStatus.ok,
      rank: widget.rank,
      item: widget.item,
      builder: (context) {
        return [
          if (count == 0 ||
              widget.manageBloc.currentPushID != widget.item.itemId)
            '推送'
          else
            "$count" "s",

          /// 移除已迁移到管理模式
          // '移除'
        ].map((e) {
          if (isCountText(e)) {
            return ClickEvent(
              onTap: () async {
                /// 【2021 12.15】
                /// 【APP】推送商品取消前面推送的，后面推送的商品时间会一直停留
                if (widget.manageBloc.isPushing) {
                  return;
                }
                await widget.manageBloc.cancelPush(e, this, onComplete: () {
                  widget.call('取消推送');
                  if (mounted) setState(() {});
                }, onCardRefresh: () {
                  ///  【APP】当商品库存为0的时候，主播商品列表商品头像没有变
                  if (mounted) setState(() {});
                });
              },
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xffF5F5F8),
                  borderRadius: BorderRadius.all(Radius.circular(32.px)),
                ),
                width: (254 / 2).px,
                alignment: Alignment.center,

                /// [2021 11.23] 取消推送没对齐
                padding: EdgeInsets.symmetric(vertical: 8.5.px),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '取消推送',
                      style: TextStyle(
                        color: const Color(0xFF198CFE),
                        fontSize: 14.px,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    ///  58s 颜色不对
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 5.px),
                      child: VerticalLine(
                        height: 15.px,
                        color: const Color(0xff8F959E).withOpacity(0.5),
                        width: 1.px,
                      ),
                    ),
                    Text(
                      e,
                      style: TextStyle(
                        color: const Color(0xff8F959E).withOpacity(0.65),
                        fontSize: 14.px,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final bool isPush = e == '推送';
          return SmallButton(
            /// 2. 显示出商品的库存状态，库存为0的不可以推送，可以被移除
            color: isCountText(e) || (isPush && widget.item.quantity == 0)
                ? const Color(0xff8F959E).withOpacity(0.15)
                : isPush
                    ? Theme.of(context).primaryColor
                    : const Color(0xffF24848),
            width: 76.px,
            height: 32.px,
            borderRadius: BorderRadius.all(Radius.circular(16.px)),
            margin: const EdgeInsets.only(

                /// 由于【移除已迁移到管理模式】所以不需要边距
                // right: e != "移除" ? 8.px : 0,
                ),
            padding: const EdgeInsets.all(0),
            onPressed: () async {
              if (isCountText(e)) {
                return;
              }

              /// 2. 显示出商品的库存状态，库存为0的不可以推送，可以被移除
              if (isPush && widget.item.quantity == 0) {
                ///
                /// @何旭 这个可能需要沟通：推送的时候库存不足、加数量时库存不足、减数量时库存不足、点击数量输入时库存不足【目前库存为0不能输入】
                /// @王增阳 经沟通，就都改成商品库存不够无法进行购买吧[捂脸]
                myToast('商品库存不够无法进行购买');
                return;
              }

              if (e != "移除") {
                /// 标识正在推送中，不允许点击取消推送
                widget.manageBloc.isPushing = true;

                await widget.manageBloc.actionPush(e, this, onComplete: () {
                  widget.call(e);
                  setState(() {});
                }, onCardRefresh: () {
                  ///  【APP】当商品库存为0的时候，主播商品列表商品头像没有变
                  if (mounted) setState(() {});
                }).whenComplete(() {
                  /// 标识推送处理完了，可以点击取消推送了
                  ///
                  /// 【2021 12.15】
                  /// 【APP】推送商品取消前面推送的，后面推送的商品时间会一直停留
                  widget.manageBloc.isPushing = false;
                });
              } else {
                widget.call(e);
              }
            },
            child: Text(
              e,
              style: TextStyle(

                  /// 2. 显示出商品的库存状态，库存为0的不可以推送，可以被移除
                  color: isCountText(e) || (isPush && widget.item.quantity == 0)
                      ? const Color(0xff8F959E).withOpacity(0.65)
                      : Colors.white,
                  fontSize: 14.px),
            ),
          );
        }).toList();
      },
      roomInfoObject: widget.roomInfoObject,
    );
  }

  @override
  bool get wantKeepAlive => true;
}

/// 商品列表-选择框卡片:
/// 主播/小助手可见
typedef GoodsCheckCall = Function(GoodsListModel? value);
typedef GoodsCheckValueCall = Function(String value);

class GoodsCheckCard extends StatelessWidget {
  final int rank;
  final GoodsCheckCall? call;
  final bool? isSelect;
  final GoodsListModel? item;
  final Widget? titleW;
  final String? cantSelectTip;
  final RoomInfon roomInfoObject;

  const GoodsCheckCard(
    this.rank, {
    this.call,
    this.isSelect,
    this.item,
    this.titleW,
    this.cantSelectTip,
    required this.roomInfoObject,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        if (!(item?.isCanSelect ?? true)) {
          if (strNoEmpty(cantSelectTip)) {
            myToast(cantSelectTip);
          }
          return;
        }
        if (call != null) {
          call!(item);
        }
      },
      child: Row(
        children: [
          Space(width: 12.px),

          ///  多选按钮模糊找俊杰要多选的组件
          ///  [2021 11.29]是否选中【禁用状态】使用已选择的多选框
          checkboxIcon(
            isSelect! || !(item?.isCanSelect ?? true),
            disabled: !(item?.isCanSelect ?? true),

            /// 多选按钮大小[2021 12.1]
            size: 18.33.px,
          ),
          Space(width: 2.px),
          Expanded(
            child: GoodsCardParent(
              rank: rank,
              status: GoodsStatus.ok,
              item: item,
              titleW: titleW,
              isToDet: false,
              roomInfoObject: roomInfoObject,
            ),
          ),
        ],
      ),
    );
  }
}
