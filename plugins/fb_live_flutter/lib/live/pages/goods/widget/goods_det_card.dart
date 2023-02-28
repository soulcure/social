import 'dart:async';

import 'package:fb_live_flutter/live/api/fblive_provider.dart';
import 'package:fb_live_flutter/live/model/goods/goods_add.dart';
import 'package:fb_live_flutter/live/model/room_infon_model.dart';
import 'package:fb_live_flutter/live/utils/func/check.dart';
import 'package:fb_live_flutter/live/utils/func/utils_class.dart';
import 'package:fb_live_flutter/live/utils/log/goods_log_up.dart';
import 'package:fb_live_flutter/live/utils/other/goods_util.dart';
import 'package:fb_live_flutter/live/utils/ui/frame_size.dart';
import 'package:fb_live_flutter/live/utils/ui/ui.dart';
import 'package:fb_live_flutter/live/widget_common/flutter/click_event.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class GoodsDetCard extends StatelessWidget {
  final GoodsListModel item;
  final GoodsListModel? det;
  final Widget priceWidget;
  final Widget quantity;
  final Widget coverW;
  final String? selectedCombo;
  final int rank;
  final RoomInfon roomInfoObject;

  const GoodsDetCard(
    this.item,
    this.det,
    this.priceWidget,
    this.quantity,
    this.selectedCombo,
    this.coverW,
    this.rank,
    this.roomInfoObject,
  );

  @override
  Widget build(BuildContext context) {
    const Color textColor = Color(0xffF24848);
    return Container(
      padding: EdgeInsets.symmetric(vertical: 10.px),
      child: Row(
        children: [
          coverW,
          Space(width: 12.px),
          Expanded(
            child: SizedBox(
              height: 88.px,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Space(height: 16.5.px),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(bottom: 1.5.px),
                        child: Text(
                          '¥ ',
                          style: TextStyle(
                              color: textColor,
                              fontSize: 13.px,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                      priceWidget,
                      Space(width: 4.px),
                      Padding(
                        padding: EdgeInsets.only(bottom: 1.5.px),
                        child: Text(
                          '￥${formatNum(det?.origin ?? item.origin)}',
                          style: TextStyle(
                              color: const Color(0xff8F959E),
                              fontSize: 10.px,
                              decoration: TextDecoration.lineThrough),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  quantity,
                  const Spacer(),
                  Row(
                    children: [
                      Text(
                        strNoEmpty(selectedCombo) ? '已选择 $selectedCombo' : "",
                        style: TextStyle(
                            color: const Color(0xff363940), fontSize: 11.px),
                      ),
                      const Spacer(),
                      ClickEvent(
                        onTap: () async {
                          unawaited(fbApi.pushLinkPage(
                              context,
                              GoodsUtil.joinMiniProgramSuffix(
                                  det?.detailUrl ?? item.detailUrl!),
                              title: det?.title ?? item.title));

                          unawaited(GoodsLogUp.clickProductDetail(det, rank,
                              roomInfoObject: roomInfoObject));
                        },
                        child: Row(
                          children: [
                            Text(
                              '商品详情',
                              style: TextStyle(
                                  color: const Color(0xff646A73),
                                  fontSize: 11.px),
                            ),
                            Space(width: 12.px),
                            Image.asset(
                              'assets/live/main/sku_det_arrow.png',
                              width: 16.px,
                              height: 16.px,
                            ),
                            Space(width: 1.5.px),
                            Space(width: 12.px),
                          ],
                        ),
                      )
                    ],
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
