/*
直播页面底部按钮
 */

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:fb_live_flutter/live/api/fblive_model.dart';
import 'package:fb_live_flutter/live/api/fblive_provider.dart';
import 'package:fb_live_flutter/live/bloc/logic/goods_logic.dart';
import 'package:fb_live_flutter/live/event_bus_model/send_gifts_model.dart';
import 'package:fb_live_flutter/live/pages/live_room/interface/live_interface.dart';
import 'package:fb_live_flutter/live/pages/live_room/widget/anchor_bottom_widget.dart';
import 'package:fb_live_flutter/live/utils/log/live_log_up.dart';
import 'package:fb_live_flutter/live/utils/theme/my_toast.dart';
import 'package:fb_live_flutter/live/utils/ui/dialog_util.dart';
import 'package:fb_live_flutter/live/utils/ui/show_right_dialog.dart';
import 'package:fb_live_flutter/live/widget/live/shop_widget.dart';
import 'package:fb_live_flutter/live/widget_common/flutter/click_event.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:just_throttle_it/just_throttle_it.dart';

// import 'package:rich_input/rich_input.dart';

import '../../../bloc_model/gift_click_bloc_model.dart';
import '../../../bloc_model/give_gift_bloc_model.dart';
import '../../../bloc_model/like_click_bloc_model.dart';
import '../../../bloc_model/sheet_gifts_bottom_bloc_model.dart';
import '../../../model/room_gift_model.dart';
import '../../../model/room_giftsendsuc_model.dart';
import '../../../model/room_infon_model.dart';
import '../../../net/api.dart';
import '../../../utils/ui/frame_size.dart';
import 'balance_widget.dart';
import 'gifts_choose_animation.dart';
import 'gifts_choose_widget.dart';

enum BtnType {
  share, //分享
  oneGift,
  upLikes, //点赞
  gift, //礼物
}

typedef UpLikeClickBlock = void Function(int likes, String type);

class AudiencesBottomView extends StatefulWidget {
  final String? roomId;
  final String? shareType;
  final SendClickBlock? sendClickBlock;
  final UpLikeClickBlock? upLikeClickBlock;
  final bool isScreenRotation;
  final bool isPlayBack; //是否回放
  final LiveInterface liveBloc;
  final LiveShopInterface liveShop;
  final RoomInfon? roomInfoObject;
  final GoodsLogic goodsLogic;

  const AudiencesBottomView({
    Key? key,
    this.sendClickBlock,
    required this.roomInfoObject,
    this.upLikeClickBlock,
    this.roomId,
    required this.liveBloc,
    required this.liveShop,
    this.shareType,
    this.isScreenRotation = false,
    this.isPlayBack = false,
    required this.goodsLogic,
  }) : super(key: key);

  @override
  _AudiencesBottomViewState createState() => _AudiencesBottomViewState();
}

class _AudiencesBottomViewState extends State<AudiencesBottomView> {
  TextEditingController? _controller;
  FocusNode? _focusNode;
  SendClickBlock? sendClickBlock;
  Timer? _timer;
  Result? gift;
  double opBalance = 0; //余额
  int appType = 2;
  late GiveGiftBlocModelQuick _quick;
  bool sendStatus = false;
  int count = 0;
  int? giftId; //第一次礼物ID和下次点击的礼物对比，防止当前礼物被下架

  /// 【2021 11.19】新版
  Color itemBgColor = const Color(0xff000000).withOpacity(0.25);

  RoomInfon get roomInfoObject {
    return widget.goodsLogic.getRoomInfoObject!;
  }

  @override
  void dispose() {
    _cancelTimer();
    _controller!.dispose();
    _focusNode!.dispose();
    Throttle.clear(chargeShowHandel);
    super.dispose();
  }

  @override
  void initState() {
    _controller = TextEditingController();
    _focusNode = FocusNode();
    sendClickBlock = widget.sendClickBlock;
    _getGifts();
    getBalance();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    Widget field = SizedBox(
      width: FrameSize.px(130),
      child: _textView(context),
    );
    if (!kIsWeb && !widget.isScreenRotation) {
      field = Expanded(child: field);
    }
    return BlocProvider<GiveGiftBlocModelQuick>(
      create: (context) => _quick = GiveGiftBlocModelQuick(GiveGiftState()),
      child: SizedBox(
        width: kIsWeb
            ? double.infinity
            : !widget.isScreenRotation
                ? FrameSize.winWidth() - 32.px
                : null,
        child: Row(
            children: widget.isPlayBack
                ? []
                : [
                    ShopWidget(
                      widget.liveShop,
                      widget.liveBloc,
                      margin: EdgeInsets.only(right: 14.px),
                      goodsLogic: widget.goodsLogic,
                    ),
                    field,
                    SizedBox(width: FrameSize.px(12)),
                    _clickBtn(context, BtnType.share),
                    SizedBox(width: FrameSize.px(8)),
                    SizedBox(
                      width: FrameSize.px(36),
                      height: FrameSize.px(36),
                      child: Stack(
                        children: [
                          BlocBuilder<GiveGiftBlocModelQuick, GiveGiftState?>(
                            builder: (context, giveGiftState) {
                              if (giveGiftState == null ||
                                  giveGiftState.count == null) {
                                return Container();
                              }
                              return GiftsChooseAnimationView(
                                count: giveGiftState.count,
                                position: Offset(
                                    (giveGiftState.itemWidth! - 38.0) / 2.0,
                                    -30),
                                onAnimationComplete: () {},
                              );
                            },
                          ),
                          _clickBtn(context, BtnType.oneGift),
                        ],
                      ),
                    ),
                    SizedBox(width: FrameSize.px(8)),
                    _clickBtn(context, BtnType.gift),
                    SizedBox(width: FrameSize.px(8)),
                    _clickBtn(context, BtnType.upLikes)
                  ]),
      ),
    );
  }

  //会话框
  Widget _textView(BuildContext context) {
    return kIsWeb
        ? Container(
            height: FrameSize.px(36),
            decoration: BoxDecoration(
              color: const Color(0x8C000000).withOpacity(0.4),
              borderRadius: BorderRadius.circular(FrameSize.px(20)),
            ),
            child: Padding(
              padding: EdgeInsets.only(
                  left: FrameSize.px(15), right: FrameSize.px(15)),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      focusNode: _focusNode,
                      controller: _controller,
                      cursorColor: Colors.white,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: "聊一聊",
                        hintStyle:
                            TextStyle(color: Colors.white38, fontSize: 15.px),
                        suffixIcon: GestureDetector(
                          onTap: () {
                            fbApi.showEmojiKeyboard(
                              context,
                              inputController: _controller,
                              // onSendText: (text) {
                              //   sendClickBlock(text);
                              // },
                            );
                          },
                          child: Image.asset(
                              "assets/live/LiveRoom/keyboard_emoji.png"),
                        ),
                      ),
                      onSubmitted: (value) {
                        sendClickBlock!(value);
                        _controller!.clear();
                      },
                    ),
                  ),
                ],
              ),
            ),
          )
        : GestureDetector(
            onTap: () async {
              fbApi.showEmojiKeyboard(
                context,
                onSendText: (text) {
                  sendClickBlock!(text);
                },
              );
            },
            child: Container(
              height: FrameSize.px(36),
              decoration: BoxDecoration(
                color: itemBgColor,
                borderRadius: BorderRadius.circular(FrameSize.px(20)),
              ),
              child: Padding(
                padding: EdgeInsets.only(
                    left: FrameSize.px(15), right: FrameSize.px(15)),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        "聊一聊",
                        style: TextStyle(
                            fontSize: FrameSize.px(15),
                            color: const Color(0xffFFFFFF).withOpacity(0.35)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
  }

  Future action(BtnType type) async {
    if (type != BtnType.oneGift && type != BtnType.upLikes) {
      if (FrameSize.isNeedRotate()) {
        await widget.liveBloc.rotationHandle(false);
      }
    }

    // 【IOS】【OBS&普通直播】直播带货同时点击礼物按画面异常
    if (type == BtnType.share) {
      // 分享弹窗

      bool canWatchOutside;
      if (widget.shareType == "1") {
        canWatchOutside = true;
      } else {
        canWatchOutside = false;
      }

      final FBShareContent fbShareContent = FBShareContent(
        type: ShareType.webLive,
        roomId: widget.roomId!,
        canWatchOutside: canWatchOutside,
        guildId: roomInfoObject.serverId,
        channelId: roomInfoObject.channelId,
        coverUrl: roomInfoObject.avatarUrl!,
        anchorName: roomInfoObject.nickName!,
      );
      LiveLogUp.audioShare(roomInfoObject);
      await fbApi.showShareLinkPopUp(
          widget.liveBloc.context ?? context, fbShareContent);
    } else if (type == BtnType.oneGift) {
      // print("点击了一次");
      // await getBalance();

      final value = await Api.getGiftPageList(1, 1);
      if (value["code"] == 200) {
        if (value['data']['result'] != null &&
            value['data']['result'].isNotEmpty) {
          gift = Result.fromJson(value['data']['result'][0]);

          if (giftId == gift!.id) {
            //礼物未下架
            final bool? isShow = fbApi.isShowGiftConfirmDialog();

            if (isShow == true) {
              ///点击1乐豆礼物
              BlocProvider.of<GiftClickBlocModel>(context).add(1);
              final int giftCount =
                  (BlocProvider.of<GiftClickBlocModel>(context).count ?? 0) + 1;

              await onTapLiveReward(
                gift!,
                GiveGiftEvent(
                  position: Offset.zero,
                  giftResultModel: gift,
                  itemWidth: FrameSize.px(36),
                  count: giftCount,
                ),
              );
            } else {
              DialogUtil.sendGift(context,
                  onPressed: alertButtonClick,
                  text: "本次消费需要支付${gift!.price}乐豆，确定是否要支付？");
            }
          } else {
            myToast(
              '礼品列表已更新，请重新送礼',
            );
            setState(() {
              giftId = gift!.id;
            });
          }

          setState(() {
            gift = Result.fromJson(value['data']['result'][0]);
          });
        }
      } else {
        myToast('msg');
      }
    } else if (type == BtnType.upLikes) {
      BlocProvider.of<LikeClickBlocModel>(context).add(1);
      widget.upLikeClickBlock!(0, 'animation');
      _startTimerUpLick(
        () async {
          final int count = BlocProvider.of<LikeClickBlocModel>(context).count;
          final Map status = await Api.thumbUp(widget.roomId, count);
          if (status["code"] == 200) {
            LiveLogUp.audioLike(roomInfoObject);
            widget.upLikeClickBlock!(count, 'licknum');
            BlocProvider.of<LikeClickBlocModel>(context).reset();
          }
        },
      );
    } else {
      if (!widget.isScreenRotation) {
        BlocProvider.of<SheetGiftsBottomBlocModel>(context).add(100);
      }
      await showQ1Dialog(
        fbApi.globalNavigatorKey.currentContext,
        alignmentTemp:
            // FrameSize.winWidth() > FrameSize.winHeight()
            //     ? Alignment.centerRight
            //     :
            Alignment.bottomCenter,
        widget: ChooseGifts(
          roomId: widget.roomId,
          // isScreenRotation: FrameSize.winWidth() > FrameSize.winHeight(),
          roomInfoObject: widget.roomInfoObject,
        ),
      );
    }
  }

  //点击按钮
  Widget _clickBtn(BuildContext context, BtnType type) {
    final Widget view = Container(
      alignment: Alignment.center,
      width: FrameSize.px(36),
      height: FrameSize.px(36),
      decoration: BoxDecoration(
        color: itemBgColor,
        borderRadius: BorderRadius.circular(FrameSize.px(21)),
      ),
      child: UnconstrainedBox(
        child: SizedBox(
          width: 24.px,
          height: 24.px,
          child: type == BtnType.gift
              ? Image.asset(
                  "assets/live/LiveRoom/gift_btn.png",
                  fit: BoxFit.cover,
                )
              : (type == BtnType.share
                  ? Image.asset("assets/live/LiveRoom/live_share.png")
                  : type == BtnType.upLikes
                      ? Image.asset("assets/live/LiveRoom/up_lick.png")
                      : gift?.imgUrl == null
                          ? Image.asset("assets/live/LiveRoom/cooffe.png")
                          : Image.network(
                              gift!.imgUrl!,
                              fit: BoxFit.cover,
                            )),
        ),
      ),
    );
    if (type != BtnType.oneGift && type != BtnType.upLikes) {
      return ClickEvent(
        onTap: () async {
          await action(type);
        },
        child: view,
      );
    }
    return InkWell(
      onTap: () async {
        await action(type);
      },
      child: view,
    );
  }

  void _startTimerUpLick(VoidCallback? cancelCallBack) {
    _cancelTimer();
    // 创建定时器
    _timer = Timer.periodic(const Duration(milliseconds: 300), (timer) {
      try {
        _cancelTimer();
        if (cancelCallBack != null) {
          cancelCallBack();
        }
      } catch (e) {
        _cancelTimer();
      }
    });
  }

  // 清除定时器
  void _cancelTimer() {
    _timer?.cancel();
  }

  // 获取乐豆账户余额
  Future getBalance() async {
    final Map status = await Api.queryBalance();
    if (status["code"] == 200) {
      String? _balance = status["data"]["balance"];
      _balance = _balance == '0' ? '0.0' : _balance;
      opBalance = double.parse(_balance!);
    }
  }

  Future _getGifts() async {
    final value = await Api.getGiftPageList(1, 1);
    if (value["code"] == 200) {
      if (value['data']['result'] != null &&
          value['data']['result'].isNotEmpty) {
        if (mounted) {
          setState(() {
            gift = Result.fromJson(value['data']['result'][0]);
            giftId = gift!.id;
          });
        }
      }
    }
  }

  void alertButtonClick() {
    fbApi.setShowGiftConfirmDialog(true);
    if (opBalance < gift!.price!) {
      chargeShow();
    } else {
      postLiveReward(gift?.id, 1, gift?.price);
    }
  }

  // 用户打赏连击
  Future onTapLiveReward(Result item, GiveGiftEvent giveGiftEvent) async {
    if (count == 0) {
      await getBalance();
    }

    // 乏值小于当前值
    if (opBalance < item.price!) {
      /// 余额不足不显示+1
      // giveGiftEvent.count = 1;
      // _quick.add(
      //   giveGiftEvent,
      // );

      // _preGiveGiftEvent = null;
      _cancelTimer();
      // 已点击礼物数量
      if (count > 0) {
        // 上报
        await postLiveReward(item.id, count, item.price);
        // 初始化页面计数器
        count = 0;
        // 余额额不足提醒
        myFailToast('余额不足，请及时充值！');
        unawaited(chargeShow());
      } else {
        // 第一次点击就余额不足，弹起充值弹窗
        unawaited(chargeShow());
      }
      // 点击动画
      giveGiftEvent.count = count;
      _quick.add(
        GiveGiftEvent(
          position: giveGiftEvent.position,
          giftResultModel: item,
          itemWidth: giveGiftEvent.itemWidth,
          count: count,
        ),
      );
    } else {
      // 乏值自减
      subOperationBalance(item.price!);
      if (!sendStatus) {
        // 自加本次计数器
        count++;
      } else {
        // 已上报上一次结果
        count = 1;
        // 初始化计时器状态
        sendStatus = false;
      }
      giveGiftEvent.count = count;
      _quick.add(
        GiveGiftEvent(
          position: giveGiftEvent.position,
          giftResultModel: item,
          itemWidth: giveGiftEvent.itemWidth,
          count: count,
        ),
      );
      // 开启定时器
      _cancelTimer();
      _startTimer(item.id, count, giveGiftEvent, giftPrice: item.price);
    }
  }

  // 打赏主播
  Future postLiveReward(int? giftId, int count, int? giftPrice) async {
    appType = computedAppType();

    final value =
        await Api.postLiveReward(appType, giftId, count, widget.roomId);

    if (value["code"] == 200) {
      LiveLogUp.giveGifts(
          optContent: "$giftId", roomInfoObject: roomInfoObject);
      final GiftSuccessModel giftSucModel =
          GiftSuccessModel.fromJson(value["data"]);
      // 发送礼物消息
      sendGiftsEventBus.fire(SendGitsEvent(giftSucModel));
      fbApiSendLiveGift(giftSucModel);

      /// 重置
      this.count = 0;
    } else {
      // 乏值校准
      // correctOpBalance();
      myToast(value["msg"]);
    }
  }

  // 乏值自减
  void subOperationBalance(int price) {
    final subBalance = opBalance - price;
    opBalance = subBalance <= 0 ? 0 : subBalance;
  }

  // FBAPI--发送礼物消息
  void fbApiSendLiveGift(GiftSuccessModel giftSucModel) {
    final json = _formatGiftJSON(
        giftId: giftSucModel.giftId,
        giftName: giftSucModel.giftName,
        giftQt: giftSucModel.giftQt,
        giftImgUrl: giftSucModel.giftImgUrl);

    // 调用发礼物消息sdk
    fbApi.sendLiveGift(widget.roomInfoObject!.serverId,
        widget.roomInfoObject!.channelId, widget.roomId!, json);
  }

  // 礼物发送消息-JSON
  String _formatGiftJSON(
      {int? giftId, String? giftName, int? giftQt, String? giftImgUrl}) {
    final Map giftJSON = {};
    giftJSON['giftId'] = giftId;
    giftJSON['giftName'] = giftName;
    giftJSON['giftQt'] = giftQt;
    giftJSON['giftImgUrl'] = giftImgUrl;

    return json.encode(giftJSON);
  }

  // 计算平台类型
  int computedAppType() {
    if (kIsWeb) {
      return 1;
    }
    if (Platform.isIOS) {
      return 3;
    } else if (Platform.isAndroid) {
      return 2;
    } else if (Platform.isWindows) {
      return 1;
    } else {
      return 1;
    }
  }

  /*
  * 充值弹窗弹起入口
  * */
  Future chargeShow() async {
    Throttle.milliseconds(1000, chargeShowHandel);
  }

  // 充值弹窗弹起【处理】
  Future chargeShowHandel() async {
    final contextValue = await widget.liveBloc.rotateScreenExec(context);
    if (contextValue == null) {
      return;
    }

    if (kIsWeb) {
      await showDialog(
          context: contextValue,
          builder: (context) {
            return Center(
              child: Container(
                constraints: const BoxConstraints(
                  maxWidth: 375,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: const BalanceChooseSheet(),
                ),
              ),
            );
          });
      return;
    }
    await showQ1Dialog(contextValue,
        alignmentTemp: !FrameSize.isHorizontal()
            ? Alignment.bottomCenter
            : Alignment.centerRight,
        widget: SizedBox(
          width: !FrameSize.isHorizontal()
              ? FrameSize.winWidth()
              : FrameSize.winWidth() * (375 / 812),
          height: !FrameSize.isHorizontal()
              ? FrameSize.px(300)
              : FrameSize.winHeight(),
          child: const BalanceChooseSheet(),
        ));
  }

  void _startTimer(int? giftId, int count, GiveGiftEvent giveGiftEvent,
      {int? giftPrice}) {
    // 创建定时器
    _timer = Timer.periodic(const Duration(milliseconds: 600), (timer) {
      _quick.add(
        GiveGiftEvent(
          position: giveGiftEvent.position,
          giftResultModel: giveGiftEvent.giftResultModel,
          itemWidth: giveGiftEvent.itemWidth,
          count: 0,
        ),
      );
      sendStatus = true;
      _cancelTimer();

      // 上报服务器
      postLiveReward(giftId, count, giftPrice);
    });
  }
}
