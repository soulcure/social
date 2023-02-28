import 'dart:async';

import 'package:fb_live_flutter/fb_live_flutter.dart';
import 'package:fb_live_flutter/live/model/goods/goods_add.dart';
import 'package:fb_live_flutter/live/model/room_infon_model.dart';
import 'package:fb_live_flutter/live/utils/func/check.dart';
import 'package:fb_live_flutter/live/utils/func/utils_class.dart';
import 'package:fb_live_flutter/live/utils/log/goods_log_up.dart';
import 'package:fb_live_flutter/live/utils/other/goods_util.dart';
import 'package:fb_live_flutter/live/utils/ui/frame_size.dart';
import 'package:fb_live_flutter/live/utils/ui/ui.dart';
import 'package:fb_live_flutter/live/widget_common/flutter/click_event.dart';
import 'package:fb_live_flutter/live/widget_common/image/sw_image.dart';
import 'package:flutter/material.dart';

import '../widget/goods_card.dart';

enum GoodsStatus {
  /// 正常
  ok,

  /// 已抢光
  gone,
}

typedef GoodsCardParentBuilder = List<Widget> Function(BuildContext context);

/// 商品列表-父卡片
///
/// 衍生的子卡片分别有:
/// [GoodsCard] 普通卡片
/// [GoodsPushCard] 推送卡片
/// [GoodsCheckCard] 商品列表-选择框卡片
class GoodsCardParent extends StatelessWidget {
  final GoodsStatus? status;
  final GoodsCardParentBuilder? builder;
  final int? rank;
  final GoodsListModel? item;
  final Widget? titleW;
  final bool isToDet;
  final RoomInfon roomInfoObject;

  const GoodsCardParent({
    this.status,
    this.builder,
    this.rank,
    this.item,
    this.titleW,
    this.isToDet = true,
    required this.roomInfoObject,
  });

  @override
  Widget build(BuildContext context) {
    const Color textColor = Color(0xffF24848);
    final body = Container(
      padding: EdgeInsets.symmetric(horizontal: 12.px, vertical: 10.px),
      child: Row(
        children: [
          Stack(
            children: [
              Container(
                width: 88.px,
                height: 88.px,
                decoration: BoxDecoration(
                  color: Colors.grey,
                  borderRadius: const BorderRadius.all(Radius.circular(6)),
                  image: DecorationImage(
                    image: swImageProvider(item?.image),
                  ),
                ),
              ),
              if (status == GoodsStatus.gone)
                Container(
                  width: 88.px,
                  height: 88.px,
                  decoration: BoxDecoration(
                    color: const Color(0xff000000).withOpacity(0.5),
                    borderRadius: const BorderRadius.all(Radius.circular(6)),
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: ['-', '已抢光', '-'].map((e) {
                      return Text(
                        e,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10.px,
                          fontWeight: e != "-" ? FontWeight.w600 : null,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              if (rank != null)
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xff000000).withOpacity(0.5),
                    borderRadius: BorderRadius.only(
                      bottomRight: Radius.circular(6.px),
                      topLeft: Radius.circular(6.px),
                    ),
                  ),
                  width: 24.px,
                  height: 16.px,
                  alignment: Alignment.center,
                  child: Text(
                    '${rank ?? ""}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10.px,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
            ],
          ),
          Space(width: 12.px),
          Expanded(
            child: SizedBox(
              height: 88.px,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  titleW ??
                      Text(
                        item?.title ?? "",
                        style: TextStyle(
                          color: const Color(0xff646A73),
                          fontSize: 13.px,
                          overflow: TextOverflow.ellipsis,
                        ),
                        maxLines: 2,
                      ),
                  Space(height: 1.px),
                  Text(
                    item?.summary ?? '',
                    style: TextStyle(color: textColor, fontSize: 11.px),
                  ),
                  const Spacer(),
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
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        formatNum(strNoEmpty(item?.price) ? item?.price : "0"),
                        style: TextStyle(
                          color: textColor,
                          fontSize: 19.px,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Space(width: 4.px),
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(bottom: 1.5.px),
                          child: LayoutBuilder(builder: (context, size) {
                            /// [ ] 新增取消推送的逻辑
                            /// 商品列表价格文字适配
                            /// 2021 11.20
                            // Build the textSpan
                            final span = TextSpan(
                              text:
                                  '￥${formatNum(strNoEmpty(item?.origin) ? item?.origin : "0")}',
                              style: TextStyle(
                                fontSize: 10.px,
                                color: const Color(0xff8F959E),
                                decoration: TextDecoration.lineThrough,
                              ),
                            );

                            // Use a textPainter to determine if it will exceed max lines
                            final tp = TextPainter(
                              maxLines: 1,
                              textAlign: TextAlign.left,
                              textDirection: TextDirection.ltr,
                              text: span,
                            );

                            // trigger it to layout
                            tp.layout(maxWidth: size.maxWidth);

                            // whether the text overflowed or not
                            final exceeded = tp.didExceedMaxLines;

                            /// 溢出了，直接什么都不显示
                            if (exceeded) {
                              return Container();
                            } else {
                              return Text.rich(
                                span,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              );
                            }
                          }),
                        ),
                      ),
                      Space(width: 16.px),
                      if (builder != null) ...builder!(context),
                    ],
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
    if (isToDet) {
      return ClickEvent(
        onTap: () async {
          unawaited(fbApi.pushLinkPage(
              context, GoodsUtil.joinMiniProgramSuffix(item!.detailUrl!),
              title: item?.title));
          unawaited(GoodsLogUp.clickProduct(item, rank,
              roomInfoObject: roomInfoObject));
        },
        child: body,
      );
    } else {
      return body;
    }
  }
}
