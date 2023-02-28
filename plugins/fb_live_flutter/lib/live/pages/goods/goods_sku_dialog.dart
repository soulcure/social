import 'package:fb_live_flutter/live/bloc/goods/goods_sku_bloc.dart';
import 'package:fb_live_flutter/live/model/goods/goods_add.dart';
import 'package:fb_live_flutter/live/model/room_infon_model.dart';
import 'package:fb_live_flutter/live/pages/goods/widget/goods_det_card.dart';
import 'package:fb_live_flutter/live/pages/goods/widget/goods_message_field.dart';
import 'package:fb_live_flutter/live/utils/func/check.dart';
import 'package:fb_live_flutter/live/utils/func/utils_class.dart';
import 'package:fb_live_flutter/live/utils/theme/my_toast.dart';
import 'package:fb_live_flutter/live/utils/ui/frame_size.dart';
import 'package:fb_live_flutter/live/utils/ui/ui.dart';
import 'package:fb_live_flutter/live/widget_common/button/small_button.dart';
import 'package:fb_live_flutter/live/widget_common/dialog/sw_scroll_dialog.dart';
import 'package:fb_live_flutter/live/widget_common/image/sw_image.dart';
import 'package:fb_live_flutter/live/widget_common/view/main_input_body.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';

import 'commom/goods_chip.dart';
import 'commom/option_button.dart';
import 'commom/show_goods_dialog.dart';

/// 商品sku对话框
Future goodsSkuDialog(BuildContext context, bool isCar, GoodsListModel item,
    int rank, VoidCallback? addSuccess, final RoomInfon roomInfoObject) {
  return showGoodsDialog(
    context,
    child: BlocProvider(
      create: (context) {
        return GoodsSkuBloc();
      },
      child: MainInputBody(
        isOnlyCancelFocus: true,
        child: GoodsSkuDialog(isCar, item, rank, addSuccess, roomInfoObject),
      ),
    ),
  );
}

class GoodsSkuDialog extends StatefulWidget {
  final bool isCar;
  final GoodsListModel item;
  final int rank;
  final VoidCallback? addSuccess;
  final RoomInfon roomInfoObject;

  const GoodsSkuDialog(
    this.isCar,
    this.item,
    this.rank,
    this.addSuccess,
    this.roomInfoObject,
  );

  @override
  _GoodsSkuDialogState createState() => _GoodsSkuDialogState();
}

class _GoodsSkuDialogState extends State<GoodsSkuDialog> {
  final GoodsSkuBloc _bloc = GoodsSkuBloc();

  @override
  void initState() {
    super.initState();
    _bloc.init(this);
  }

  Widget chipBuild(SkuProps e) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// 【APP】快速购买页，页面样式问题
        Space(height: 7.5.px),
        LabelTitle(e.propName ?? '规则标题'),
        Space(height: 12.px),
        Wrap(
          children: e.values?.map((inItem) {
                return GoodsChip(
                  e.selectValueId != null && e.selectValueId == inItem.valueId,
                  inItem,
                  onTap: () {
                    /// 输入数量焦点取消
                    _bloc.countFocusNode.unfocus();

                    /// 总库存为0，不可以选择规格
                    if (_bloc.totalIsNull) {
                      myToast('商品总库存为0');
                      return;
                    }

                    if (e.selectValueId == inItem.valueId) {
                      e.selectValueId = null;
                      e.selectValueName = null;
                      _bloc.skuList = null;
                      _bloc.selectedCombo = null;

                      /// sku规格标记为未选中
                      inItem.status = 1;

                      /// 处理当前选择的规格列表【删除当前值】
                      _bloc.selectValueIdList.remove(inItem.valueId);

                      /// 封面图片处理【未选择】
                      _bloc.image.value =
                          _bloc.detModel?.image ?? widget.item.image!;

                      /// 取消规格选择后剩余数量显示总数量
                      _bloc.stockNum.value = _bloc.detModel!.quantity!;

                      /// 取消规格选择后价格显示总价格
                      _bloc.price.value = _bloc.detModel!.price!;

                      /// 刷新当前选择的
                      if (_bloc.currentCount.value <= 0 &&
                          _bloc.stockNum.value > 0) {
                        _bloc.currentCount.value = 1;
                      }

                      /// 刷新加号和减号
                      _bloc.handleEnable();
                    } else {
                      e.selectValueId = inItem.valueId;
                      e.selectValueName = inItem.valueName;

                      /// sku规格标记为已选中
                      inItem.status = 2;

                      /// 当前规格组其他规格表示为未选中
                      e.values!.forEach((element) {
                        if (element.status == 2 &&
                            element.valueId != inItem.valueId) {
                          element.status = 1;
                        }
                      });

                      /// 封面图片处理【已选择】
                      if (strNoEmpty(inItem.image)) {
                        _bloc.image.value = inItem.image!;
                      } else {
                        _bloc.image.value =
                            _bloc.detModel?.image ?? widget.item.image!;
                      }

                      /// 处理价格
                      _bloc.handlePrice();
                    }

                    /// 处理规格
                    _bloc.handleProp();

                    setState(() {});
                  },
                );
              }).toList() ??
              [],
        ),
        Space(height: 10.px),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GoodsSkuBloc, int>(
      bloc: _bloc,
      builder: (context, value) {
        /// 【APP】观众点击马上抢商品。当商品库存为0的时候还可以选择规格
        final noQuantity = _bloc.stockNum.value == 0;
        return Stack(
          children: [
            Container(
              padding: EdgeInsets.only(left: 12.px),
              height: () {
                const double rate = 609 / 821;
                return (FrameSize.maxValue() * rate) -
                    FrameSize.padBotH() -
                    20.px;
              }(),
              child: Column(
                children: [
                  GoodsDetCard(
                    widget.item,
                    _bloc.detModel,
                    Obx(
                      () => Text(
                        '${formatNum(_bloc.price.value)} ',
                        style: TextStyle(
                          color: const Color(0xffF24848),
                          fontSize: 19.px,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Obx(
                      () => Text(
                        '剩余 ${_bloc.stockNum.value} 件',
                        style: TextStyle(
                            color: const Color(0xff646A73), fontSize: 11.px),
                      ),
                    ),
                    _bloc.selectedCombo,
                    Obx(
                      () => Container(
                        width: 88.px,
                        height: 88.px,
                        decoration: BoxDecoration(
                          color: Colors.grey,
                          borderRadius:
                              const BorderRadius.all(Radius.circular(6)),
                          image: DecorationImage(
                            image: swImageProvider(strNoEmpty(_bloc.image.value)
                                ? _bloc.image.value
                                : widget.item.image),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                    widget.rank,
                    widget.roomInfoObject,
                  ),
                  Expanded(
                    child: ScrollConfiguration(
                      behavior: MyBehavior(),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Space(height: 4.5.px),
                            ..._bloc.detModel?.skuProps
                                    ?.map(chipBuild)
                                    .toList() ??
                                [],
                            Space(height: 12.px),
                            Row(
                              children: [
                                const LabelTitle("购买数量"),
                                Space(width: 8.px),
                                Text(
                                  _bloc.maxCountDet == 0
                                      ? ''
                                      : '每人限购 ${_bloc.maxCountDet} 件',
                                  style: TextStyle(
                                      color: const Color(0xff646A73),
                                      fontSize: 11.px),
                                ),
                                const Spacer(),
                                Obx(
                                  () => OptionButton(
                                    option: "-",
                                    isEnable: _bloc.enableSubtract.value,
                                    onTap: () {
                                      /// 输入数量焦点取消
                                      _bloc.countFocusNode.unfocus();

                                      if (_bloc.underStock) {
                                        myFailToast(_bloc.underStockStr);
                                        return;
                                      } else if (!_bloc.enableSubtract.value) {
                                        /// 【商品类别】选择商品数量小于最小值提示“商品最少要购买1件”，与需求提示信息不符
                                        myFailToast("购买数量低于范围");
                                        return;
                                      }
                                      _bloc.currentCount.value--;
                                      _bloc.handleEnable();
                                    },
                                  ),
                                ),
                                Container(
                                  width: 30.px,
                                  alignment: Alignment.center,
                                  child: Obx(() {
                                    if (_bloc.isInputCount.value) {
                                      return TextField(
                                        textAlign: TextAlign.center,
                                        focusNode: _bloc.countFocusNode,
                                        controller: _bloc.countController,
                                        decoration: const InputDecoration(
                                          border: InputBorder.none,
                                          isDense: true,
                                          contentPadding: EdgeInsets.all(0),
                                        ),
                                        style: TextStyle(
                                            color: const Color(0xff363940),
                                            fontSize: 11.px),
                                        keyboardType: TextInputType.number,
                                        inputFormatters: [
                                          FilteringTextInputFormatter(
                                              RegExp('[0-9]'),
                                              allow: true),
                                        ],
                                        onSubmitted: _bloc.inputCount,
                                      );
                                    }
                                    return InkWell(
                                      onTap: () {
                                        if (_bloc.underStock) {
                                          myFailToast(_bloc.underStockStr);
                                          return;
                                        } else {
                                          _bloc.enterInputCount();
                                        }
                                      },
                                      child: Container(
                                        width: 30.px,
                                        alignment: Alignment.center,
                                        child: Obx(
                                          () => Text(
                                            '${_bloc.currentCount}',
                                            style: TextStyle(
                                                color: const Color(0xff363940),
                                                fontSize: 11.px),
                                          ),
                                        ),
                                      ),
                                    );
                                  }),
                                ),
                                Obx(
                                  () => OptionButton(
                                    isEnable: _bloc.enableAdd.value,
                                    option: "+",
                                    onTap: () {
                                      /// 输入数量焦点取消
                                      _bloc.countFocusNode.unfocus();

                                      if (_bloc.underStock) {
                                        myFailToast(_bloc.underStockStr);
                                        return;
                                      } else if (_bloc.currentCount.value + 1 >
                                          _bloc.stockNum.value) {
                                        /// 如果超出数量了但没选规格,则提示:"请选择商品规格"
                                        if (_bloc.isUnSelectItem) {
                                          myFailToast("请选择商品规格");
                                        } else {
                                          myToast("购买数量超出范围");
                                        }
                                        return;
                                      }

                                      if (!_bloc.enableAdd.value) {
                                        /// 【APP】轻提示每次最多可购买2件轻提示多了一个叉号
                                        myToast("每次最多可购买${_bloc.maxCountDet}件");

                                        return;
                                      }
                                      _bloc.currentCount.value++;
                                      _bloc.handleEnable();
                                    },
                                  ),
                                ),
                                Space(width: 12.px),
                              ],
                            ),

                            /// 添加购物车也需要填写留言&&校验留言填写
                            /// 【2021 12.2】
                            Space(height: 17.5.px),

                            /// 购物车不设置留言显示
                            ///
                            /// 添加购物车也需要填写留言&&校验留言填写
                            /// 【2021 12.2】
                            ..._bloc.detModel?.messages?.map<Widget>((e) {
                                  return GoodsMessageField(e);
                                }).toList() ??
                                [],

                            /// 快速购买页，三种以上规格时，购买数量和确认键会重合
                            /// [2021 11.17]
                            Space(height: 99.px + FrameSize.padBotH()),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              /// iOS iPhone xs max写0的话与安全区中间会有瑕疵
              bottom: -0.02,
              child: Container(
                color: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 12.px),
                child: SmallButton(
                  color: Color(noQuantity ||
                          _bloc.detModel == null ||
                          _bloc.isUnSelectItem
                      ? 0xffEEEFF1
                      : 0xffF24848),
                  width: FrameSize.winWidth() - 24.px,
                  margin: EdgeInsets.symmetric(horizontal: 12.px),
                  borderRadius: BorderRadius.all(Radius.circular(20.px)),
                  height: 40.px,
                  onPressed: _bloc.placeAnOrder,
                  child: Text(
                    '确定',
                    style: TextStyle(
                      color: noQuantity ||
                              _bloc.detModel == null ||
                              _bloc.isUnSelectItem
                          ? const Color(0xff8F959E)
                          : Colors.white,
                      fontSize: 14.px,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            )
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    super.dispose();
    _bloc.close();
  }
}

class LabelTitle extends StatelessWidget {
  final String? text;

  const LabelTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text ?? 'label',
      style: TextStyle(color: const Color(0xff363940), fontSize: 13.px),
    );
  }
}
