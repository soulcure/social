import 'dart:async';

import 'package:fb_live_flutter/live/api/fblive_provider.dart';
import 'package:fb_live_flutter/live/bloc_model/emoji_keyborad_block_model.dart';
import 'package:fb_live_flutter/live/bloc_model/user_join_live_room_model.dart';
import 'package:fb_live_flutter/live/event_bus_model/goods/goods_push_rm_model.dart';
import 'package:fb_live_flutter/live/model/goods/goods_add.dart';
import 'package:fb_live_flutter/live/model/goods/goods_push_model.dart';
import 'package:fb_live_flutter/live/pages/live_room/interface/live_interface.dart';
import 'package:fb_live_flutter/live/utils/func/check.dart';
import 'package:fb_live_flutter/live/utils/func/utils_class.dart';
import 'package:fb_live_flutter/live/utils/log/goods_log_up.dart';
import 'package:fb_live_flutter/live/utils/other/goods_util.dart';
import 'package:fb_live_flutter/live/utils/ui/frame_size.dart';
import 'package:fb_live_flutter/live/utils/ui/ui.dart';
import 'package:fb_live_flutter/live/widget_common/flutter/click_event.dart';
import 'package:fb_live_flutter/live/widget_common/image/sw_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';

/// 【APP】推送时唤起键盘，推送时间将会加长
///
/// 怎么做【逻辑】？
/// 让倒计时时长与动画状态不受build方法影响。
///
/// 怎么做【技术】？
/// 在build方法接收到推送的数据时记录推送过期时间[expiredTime]，
/// 当下次调用build如推送过期时间[expiredTime]一致则直接返回，不处理。
///
/// 影响范围【之前/现在/未来】？
/// 再次推送覆盖显示、收起后再次推送显示；
///
/// ===================================
/// [2021 12.02]
/// 商品推送显示动画更新
class GoodsLiveCard extends StatefulWidget {
  final PushGoodsLiveRoomModel? pushGoodsLiveRoomModel;
  final GoodsPushModel item;
  final LiveInterface bloc;

  const GoodsLiveCard(this.pushGoodsLiveRoomModel, this.item, this.bloc);

  @override
  _GoodsLiveCardState createState() => _GoodsLiveCardState();
}

class _GoodsLiveCardState extends State<GoodsLiveCard>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  /// 缩放动画
  AnimationController? _secondAnimationController;
  late Animation<double> _secondAnimation;

  StreamSubscription? _goodsPushRmBus;

  double cardHeight = 0;

  /// 【2021 12.02】推送的商品卡片写死宽高
  double cardWidth = 0;

  /// 推送的商品卡片内的字体大小也缩放
  double titleSize = 0;
  double yuanSize = 0;
  double priceSize = 0;
  double indexSize = 0;

  Timer? timer;
  RxInt? count = 0.obs;

  String? currentExpiredTime = '';

  @override
  void initState() {
    super.initState();
    init();

    _goodsPushRmBus = goodsPushRmBus.on<GoodsPushRmModel>().listen((event) {
      if (_secondAnimationController != null) {
        _secondAnimationController!.reverse().then((value) {
          _secondAnimationController?.dispose();
          _secondAnimationController = null;
        });
      }
    });
  }

  void start() {
    timer?.cancel();
    timer = null;
    timer = Timer.periodic(const Duration(milliseconds: 1000), (_) {
      if (count!.value <= 0) {
        _secondAnimationController!.reverse().then((value) {
          timer?.cancel();
          timer = null;
          widget.pushGoodsLiveRoomModel!.add(null);
        });
        return;
      }
      count!.value--;
    });
  }

  void init() {
    count = 10.obs;

    if (_secondAnimationController != null) {
      _secondAnimationController?.dispose();
      _secondAnimationController = null;
    }

    _secondAnimationController = AnimationController(
        duration: const Duration(milliseconds: 600), vsync: this)
      ..addListener(() {
        cardHeight = 88.px * _secondAnimation.value;
        cardWidth = 289.px * _secondAnimation.value;
        titleSize = 14.px * _secondAnimation.value;
        yuanSize = 13.px * _secondAnimation.value;
        priceSize = 19.px * _secondAnimation.value;
        indexSize = 10.px * _secondAnimation.value;
        if (mounted) setState(() {});
      })

      /// 关闭
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed &&
            _secondAnimationController != null) {
          start();
        }
      });

    _secondAnimation =
        Tween<double>(begin: 0, end: 1).animate(_secondAnimationController!);
  }

  void setValueState() {
    /// 【APP】推送时唤起键盘，推送时间将会加长
    if (currentExpiredTime == widget.item.expiredTime) {
      return;
    }

    /// 【APP】推送商品展示结束，IM消息未回到原本位置
    /// 【APP】观众端推送展示结束时，主播点击推送商品，观众端不显示推送信息
    /// 2021 11.4
    if (strNoEmpty(widget.item.expiredTime)) {
      final sendMil = DateTime.parse(widget.item.expiredTime ?? 0 as String)
              .millisecondsSinceEpoch ~/
          1000;
      final nowMil = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      if (sendMil > nowMil) {
        count = widget.item.countdown?.obs; //widget.defSecond.obs
        currentExpiredTime = widget.item.expiredTime;
        _secondAnimationController!.forward();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    setValueState();
    return BlocBuilder<EmojiKeyBoradBlocModel, double?>(
      builder: (context, keyboardHeight) {
        final _keyboardHeight = keyboardHeight ?? 0;
        if ((count!.value <= 0 || _keyboardHeight > 0) &&
            _secondAnimationController == null) {
          return Container();
        }

        const Color textColor = Color(0xffF24848);

        return UnconstrainedBox(
          child: SizedBox(
            height: cardHeight + 12.px,
            width: cardWidth,
            child: ClickEvent(
              onTap: () async {
                final contextValue =
                    await widget.bloc.rotateScreenExec(context);
                if (contextValue == null) {
                  return;
                }

                await fbApi.pushLinkPage(contextValue,
                    GoodsUtil.joinMiniProgramSuffix(widget.item.detailUrl!),
                    title: widget.item.title);

                /// (直播页)点击推送商品卡片;
                final GoodsListModel goodsListModel = GoodsListModel(
                  detailUrl: widget.item.detailUrl,
                  itemId: widget.item.itemId,
                  title: widget.item.title,
                  price: widget.item.price,
                  origin: widget.item.origin,
                );
                await GoodsLogUp.clickProductCard(
                    goodsListModel, widget.item.index,
                    roomInfoObject: widget.bloc.getRoomInfoObject!);
              },
              child: Container(
                margin: EdgeInsets.only(bottom: 12.px),
                child: Stack(
                  children: [
                    Container(
                      width: cardWidth,
                      height: cardHeight,
                      decoration: BoxDecoration(
                        color: const Color(0xffF5F5F8),
                        borderRadius: BorderRadius.all(Radius.circular(6.px)),
                      ),
                    ),
                    Positioned.fill(
                      child: Row(
                        children: [
                          SwImage(
                            widget.item.image,
                            height: cardHeight,
                            width: cardHeight,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(6.px),
                              bottomLeft: Radius.circular(6.px),
                            ),
                            fit: BoxFit.cover,
                          ),
                          Space(width: 12.px),
                          Expanded(
                              child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.item.title ?? 'title',
                                style: TextStyle(
                                  color: const Color(0xff646A73),
                                  fontSize: titleSize,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Padding(
                                    padding: EdgeInsets.only(bottom: 1.5.px),
                                    child: Text(
                                      '¥ ',
                                      style: TextStyle(
                                          color: textColor,
                                          fontSize: yuanSize,
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                  Text(
                                    '${formatNum(widget.item.price)} ',
                                    style: TextStyle(
                                      color: textColor,
                                      fontSize: priceSize,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              )
                            ],
                          )),
                          Space(width: 12.px),
                        ],
                      ),
                    ),
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
                        '${widget.item.index ?? 0}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: indexSize,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _secondAnimationController?.dispose();
    _secondAnimationController = null;
    timer?.cancel();
    timer = null;

    _goodsPushRmBus?.cancel();
    _goodsPushRmBus = null;
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;
}
