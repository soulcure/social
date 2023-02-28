import 'package:flutter/material.dart';
import 'package:fb_live_flutter/live/utils/ui/frame_size.dart';
import 'package:fb_live_flutter/live/model/goods/goods_add.dart';
import 'package:fb_live_flutter/live/utils/theme/my_toast.dart';
import 'package:fb_live_flutter/live/utils/ui/ui.dart';
import 'package:fb_live_flutter/live/utils/func/utils_class.dart';
import 'package:fb_live_flutter/live/widget_common/image/sw_image.dart';

class GoodsChip extends StatelessWidget {
  final bool isSelect;
  final SkuValues valueItem;
  final GestureTapCallback? onTap;

  const GoodsChip(this.isSelect, this.valueItem, {this.onTap});

  @override
  Widget build(BuildContext context) {
    final bool isNotStock = valueItem.status == 3;
    final color = isNotStock
        ? const Color(0xff8F959E).withOpacity(0.15)
        : isSelect

            /// 修复sku对话框筛选的背景颜色过深
            ? const Color(0xffF24848).withOpacity(0.075)
            : const Color(0xff8F959E).withOpacity(0.075);
    final textColor = isNotStock
        ? const Color(0xff8F959E)
        : isSelect
            ? const Color(0xffF24848)
            : const Color(0xff363940);
    return InkWell(
      onTap: () {
        if (isNotStock) {
          myToast('商品库存不够无法进行购买');
          return;
        }
        if (onTap != null) {
          onTap!();
        }
      },

      /// 有图片的筛选器样式
      child: strNoEmpty(valueItem.image)
          ? Container(
              padding: EdgeInsets.symmetric(horizontal: 3.px, vertical: 3.px),
              margin: EdgeInsets.only(right: 12.px, bottom: 6.px),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.all(
                  Radius.circular(2.5.px),
                ),
              ),
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Container(
                    width: 22.px,
                    height: 22.px,
                    decoration: BoxDecoration(
                      color: const Color(0xffD8D8D8),
                      borderRadius: const BorderRadius.all(
                        Radius.circular(1),
                      ),
                      image: DecorationImage(
                        image: swImageProvider(valueItem.image),
                      ),
                    ),
                  ),
                  Space(width: 8.px),
                  Text(
                    valueItem.valueName ?? '',
                    style: TextStyle(color: textColor, fontSize: 11.px),
                  ),
                  Space(width: 8.px),
                ],
              ),
            )

          /// 无图片的筛选器样式
          : Container(
              /// 修复筛选器宽度问题
              /// 【2021 11.22】修复筛选器高度问题
              padding: EdgeInsets.symmetric(horizontal: 8.px, vertical: 5.5.px),
              margin: EdgeInsets.only(right: 12.px, bottom: 6.px),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.all(
                  Radius.circular(2.5.px),
                ),
              ),
              child: Text(
                valueItem.valueName ?? '',
                style: TextStyle(color: textColor, fontSize: 12.px),
              ),
            ),
    );
  }
}
