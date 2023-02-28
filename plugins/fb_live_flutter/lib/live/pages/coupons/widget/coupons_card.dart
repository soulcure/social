import 'dart:io';

import 'package:fb_live_flutter/live/bloc/coupons/coupons_card_logic.dart';
import 'package:fb_live_flutter/live/bloc/logic/goods_logic.dart';
import 'package:fb_live_flutter/live/model/coupons/coupons_list_model.dart';
import 'package:fb_live_flutter/live/model/room_infon_model.dart';
import 'package:fb_live_flutter/live/pages/goods/goods_dialog.dart';
import 'package:fb_live_flutter/live/pages/goods/goods_manage_dialog.dart';
import 'package:fb_live_flutter/live/utils/func/check.dart';
import 'package:fb_live_flutter/live/utils/func/utils_class.dart';
import 'package:fb_live_flutter/live/utils/log/coupons_log_up.dart';
import 'package:fb_live_flutter/live/utils/theme/my_toast.dart';
import 'package:fb_live_flutter/live/utils/ui/frame_size.dart';
import 'package:fb_live_flutter/live/utils/ui/ui.dart';
import 'package:fb_live_flutter/live/widget/live/price_view.dart';
import 'package:fb_live_flutter/live/widget_common/button/small_button.dart';
import 'package:fb_live_flutter/live/widget_common/flutter/click_event.dart';
import 'package:fb_live_flutter/live/widget_common/image/sw_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:oktoast/oktoast.dart';

import 'coupons_bg.dart';

enum CouponsStatus {
  /// 正常
  ok,

  /// 已抢光
  gone,

  /// 已领取
  received,

  /// 已过期
  expired,
}

enum CouponsType {
  /// 满减券
  fullReduction,

  /// 随机金额券
  random,

  /// 折扣券
  discount,
}

class CouponsCard extends StatefulWidget {
  final int rank;
  final CouponListModel? item;
  final double? space;
  final bool isShowReceive;
  final RoomInfon roomInfoObject;
  final GoodsLogic goodsLogic;

  const CouponsCard(
    this.rank,
    this.item, {
    this.space,
    this.isShowReceive = true,
    required this.roomInfoObject,
    required this.goodsLogic,
  });

  @override
  State<CouponsCard> createState() => _CouponsCardState();
}

class _CouponsCardState extends State<CouponsCard>
    with AutomaticKeepAliveClientMixin {
  RxDouble rHeight = 0.0.obs;

  double? expandedHeight;

  RxDouble textSize = 0.0.obs;

  GlobalKey globalKey = GlobalKey();
  final CouponsCardBloc _bloc = CouponsCardBloc();

  ///value: 文本内容；fontSize : 文字的大小；fontWeight：文字权重；maxWidth：文本框的最大宽度；maxLines：文本支持最大多少行
  double calculateTextHeight(String value, double fontSize,
      FontWeight fontWeight, double maxWidth, int maxLines) {
    final TextPainter painter = TextPainter(
      ///AUTO：华为手机如果不指定locale的时候，该方法算出来的文字高度是比系统计算偏小的。
      locale: Localizations.localeOf(context),
      maxLines: maxLines,
      textDirection: TextDirection.ltr,
      text: TextSpan(
        text: value,
        style: TextStyle(
          fontWeight: fontWeight,
          fontSize: fontSize,
        ),
      ),
    );
    painter.layout(maxWidth: maxWidth);

    ///文字的宽度:painter.width
    return painter.height;
  }

  void changeExpanded() {
    widget.item!.isExpanded!.value = !widget.item!.isExpanded!.value;

    WidgetsBinding.instance!.addPostFrameCallback((timeStamp) {
      refreshHeight();
    });
  }

  @override
  void initState() {
    super.initState();
    _bloc.init(this);

    WidgetsBinding.instance!.addPostFrameCallback((timeStamp) {
      refreshHeight();
    });
  }

  void refreshHeight() {
    final RenderBox? box =
        globalKey.currentContext?.findRenderObject() as RenderBox?;
    final size = box?.size;
    if (size != null) {
      rHeight.value = size.height;
    }
  }

  /*
  * 使用优惠券-去商品列表对话框
  * */
  Future<void> toDialog() async {
    myLoadingToast(tips: "加载中");
    try {
      final bool isAssistantValue =
          await widget.goodsLogic.isAssistant(widget.roomInfoObject.roomId);
      GoodsLogicValue.isAssistantValue = isAssistantValue;
      dismissAllToast();
      if (isAssistantValue) {
        await goodsManageDialog(context, false, widget.roomInfoObject);
      } else {
        await goodsDialog(context, widget.item!.shopId, widget.roomInfoObject);
      }
    } catch (e) {
      dismissAllToast();
      myFailToast("出现错误");
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    Future.delayed(const Duration(milliseconds: 10)).then((value) {
      refreshHeight();
    });
    return BlocBuilder(
      bloc: _bloc,
      builder: (context, _) {
        final isExpired = widget.item!.status == CouponsStatus.expired;
        final isReceived = widget.item!.status == CouponsStatus.received;
        final isGone = widget.item!.status == CouponsStatus.gone;
        final _w = FrameSize.winWidth() - 24.px - (widget.space ?? 0);
        final textColor = Color(isExpired || isGone ? 0xff8F959E : 0xffF24848);
        final rWidth = _w * 242.5 / 351;
        final rCheckWidth = _w * 209 / 317.5;
        final lCheckWidth = _w * 108 / 317.5;
        final leftWidth = widget.space != null ? lCheckWidth : _w * 108 / 351;

        final rWidthResult = widget.space != null ? rCheckWidth : rWidth;
        final String des = widget.item?.description ?? '描述为空';
        final bool isGrey = isExpired || isGone;

        return Container(
          margin: EdgeInsets.only(left: 12.px, right: 12.px),
          child: Stack(
            children: [
              Obx(() {
                return CouponsBg(
                  leftWidth,
                  widget.item!.isExpanded!.value,
                  isGrey,
                  rHeight.value,
                );
              }),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    alignment: Alignment.topCenter,
                    children: [
                      Container(
                        width: leftWidth,
                        padding: EdgeInsets.symmetric(horizontal: 0.px),
                        child: SizedBox(
                          /// 旧值【89/2】.px
                          height: 89.px,
                          child: Column(
                            children: [
                              Obx(() => Space(
                                  height: textSize.value == 28
                                      ? 22.px
                                      : textSize.value == 16
                                          ? 30.px
                                          : textSize.value == 12
                                              ? 33.px
                                              : 25.px)),
                              if (widget.item?.couponsType ==
                                  CouponsType.random)
                                () {
                                  final strSize =
                                      "¥${formatNum(widget.item?.minValue)}~${formatNum(widget.item?.maxValue)}";
                                  return Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      PriceView(
                                        textColor,
                                        formatNum(widget.item?.minValue),
                                        fontSize: textSize.value =
                                            fontSizeGet(strSize),
                                      ),
                                      Text(
                                        '~',
                                        style: TextStyle(
                                          color: textColor,
                                          fontSize: fontSizeGet(strSize),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      PriceView(
                                        textColor,
                                        formatNum(widget.item?.maxValue),
                                        isShowYuan: false,
                                        fontSize: textSize.value =
                                            fontSizeGet(strSize),
                                      ),
                                    ],
                                  );
                                }()
                              else if (widget.item?.couponsType ==
                                  CouponsType.fullReduction)
                                () {
                                  final str = formatNum(widget.item?.value);
                                  final String strSize = "¥$str";
                                  return PriceView(
                                    textColor,
                                    str,
                                    fontSize: textSize.value =
                                        fontSizeGet(strSize),
                                  );
                                }()
                              else if (widget.item?.couponsType ==
                                  CouponsType.discount)
                                () {
                                  final content = widget.item?.value ?? '0';
                                  final String sizeStr = "$content折";
                                  final double fontSize = fontSizeGet(sizeStr);
                                  return Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        content,
                                        style: TextStyle(
                                          color: textColor,
                                          fontSize: textSize.value = fontSize,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Padding(
                                        padding: EdgeInsets.only(
                                            bottom: fontSize *
                                                (Platform.isIOS
                                                    ? 0.08.px
                                                    : 0.11.px)),
                                        child: Text(
                                          '折',
                                          style: TextStyle(
                                            color: textColor,
                                            fontSize: fontSize * 0.53,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                }(),
                              Obx(() => Space(
                                  height: textSize.value == 28 ? 8.px : 10.px)),
                              Text(
                                widget.item?.usingLimit ?? '',
                                style: TextStyle(
                                    color: const Color(0xff646A73),
                                    fontSize: 13.px),
                                maxLines: 1,
                              ),
                            ],
                          ),
                        ),
                      ),
                      Container(
                        width: 68.px,
                        height: 12.px,

                        /// [ ] 展开之后「随机金额券」顶部多了一条线
                        /// 【2021 11.21】
                        margin: EdgeInsets.only(top: 1.px),
                        decoration: BoxDecoration(
                          image: DecorationImage(
                              image: AssetImage(
                            'assets/live/main/coupons_card_top${isGrey ? "_grey" : ""}.png',
                          )),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          widget.item!.typeStr!,
                          style: TextStyle(
                              color: isGrey
                                  ? const Color(0xff8F959E)
                                  : const Color(0xffF24848),
                              fontSize: 9.px),
                        ),
                      ),
                    ],
                  ),
                  Obx(() {
                    return Container(
                      key: globalKey,
                      width: rWidthResult,
                      padding: EdgeInsets.symmetric(
                          vertical: 16.px, horizontal: 11.5.px),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.item?.title ?? '未知',
                                      style: TextStyle(
                                        color: const Color(0xff000000),
                                        fontSize: 13.px,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Space(height: 10.px),
                                    ClickEvent(
                                      onTap: () async {
                                        changeExpanded();
                                      },
                                      child: Padding(
                                        padding: EdgeInsets.only(top: 9.px),
                                        child: Row(
                                          children: [
                                            Text(
                                              widget.item?.timeRule ?? '',
                                              style: TextStyle(
                                                  color:
                                                      const Color(0xff646A73),
                                                  fontSize: 11.px),
                                            ),
                                            Space(width: 5.5.px),
                                            Image.asset(
                                              /// 【APP】优惠券使用详情的下拉箭头错误
                                              ///
                                              /// 又改了一次
                                              'assets/live/main/coupons_${widget.item!.isExpanded!.value ? 'up' : 'down'}.png',
                                              width: 12.px,
                                              height: 12.px,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (!widget.isShowReceive ||
                                  isExpired ||
                                  isGone ||
                                  widget.space != null)
                                Container()
                              else
                                SmallButton(
                                  minWidth: 69.px,
                                  minHeight: 24.px,
                                  onPressed: () async {
                                    if (isReceived) {
                                      await toDialog();

                                      await CouponsLogUp.clickUseCoupons(
                                          widget.item, widget.rank,
                                          roomInfoObject:
                                              widget.roomInfoObject);
                                    } else {
                                      await _bloc.receiveHandle();

                                      await CouponsLogUp.clickReceiveCoupons(
                                          widget.item, widget.rank,
                                          roomInfoObject:
                                              widget.roomInfoObject);
                                    }
                                  },
                                  margin: EdgeInsets.zero,
                                  padding: EdgeInsets.zero,
                                  color: isReceived
                                      ? Colors.white.withOpacity(0.5)
                                      : const Color(0xffF24848),
                                  border: Border.all(
                                      color: const Color(0xffF24848)
                                          .withOpacity(1),
                                      width: 0.5),
                                  borderRadius: BorderRadius.all(

                                      /// [2021 11.30] 优惠券（立即领取）按钮方圆改成圆
                                      Radius.circular(24.px / 2)),
                                  child: Text(
                                    isReceived ? "去使用" : '立即领取',
                                    style: TextStyle(
                                        color: isReceived
                                            ? const Color(0xffF24848)
                                            : Colors.white,
                                        fontSize: 12.px,
                                        fontWeight: FontWeight.w500),
                                  ),
                                )
                            ],
                          ),
                          ...widget.item!.isExpanded!.value
                              ? [
                                  Space(height: 4.px),
                                  InkWell(
                                    onTap: changeExpanded,
                                    child: Text(
                                      des,
                                      style: TextStyle(
                                        color: const Color(0xff000000)
                                            .withOpacity(0.5),
                                        fontSize: 10.px,
                                        height: 1.7, //1.7倍行高
                                      ),
                                    ),
                                  )
                                ]
                              : [],
                          Space(height: 4.px),
                        ],
                      ),
                    );
                  }),
                ],
              ),
              Positioned(
                right: 0,
                top: 0,
                child: () {
                  final bool _isShow =
                      widget.item!.status == CouponsStatus.expired ||
                          widget.item!.status == CouponsStatus.gone ||
                          widget.item!.status == CouponsStatus.received;
                  if (_isShow) {
                    return SwImage(
                      'assets/live/main/coupons_${widget.item!.status == CouponsStatus.expired ? 'expired' : widget.item!.status == CouponsStatus.gone ? "gone" : 'received'}.png',
                      width: 67.5.px,
                      height: 31.5.px,
                    );
                  } else {
                    return Container();
                  }
                }(),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    super.dispose();
    _bloc.close();
  }

  @override
  bool get wantKeepAlive => true;
}
