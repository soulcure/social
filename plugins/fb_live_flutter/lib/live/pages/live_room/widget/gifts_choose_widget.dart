/*
 * 送礼物弹层
 */

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:fb_live_flutter/fb_live_flutter.dart';
import 'package:fb_live_flutter/live/event_bus_model/send_gifts_model.dart';
import 'package:fb_live_flutter/live/model/room_infon_model.dart';
import 'package:fb_live_flutter/live/utils/func/router.dart';
import 'package:fb_live_flutter/live/utils/log/live_log_up.dart';
import 'package:fb_live_flutter/live/utils/theme/my_toast.dart';
import 'package:fb_live_flutter/live/utils/ui/show_right_dialog.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../bloc_model/fb_refresh_widget_bloc_model.dart';
import '../../../bloc_model/give_gift_bloc_model.dart';
import '../../../model/room_gift_model.dart';
import '../../../model/room_giftsendsuc_model.dart';
import '../../../net/api.dart';
import '../../../utils/ui/frame_size.dart';
import 'balance_widget.dart';
import 'gifts_choose_animation.dart';
import 'indicator.dart';

typedef SendGiftsClickBlock = void Function(
    GiftSuccessModel giftSuccessModel); //发送礼物消息弹幕

class ChooseGifts extends StatefulWidget {
  final String? roomId;
  final bool isScreenRotation;
  final RoomInfon? roomInfoObject;

  const ChooseGifts(
      {Key? key,
      this.roomId,
      required this.roomInfoObject,
      this.isScreenRotation = false})
      : super(key: key);

  @override
  _ChooseGiftsState createState() => _ChooseGiftsState();
}

class _ChooseGiftsState extends State<ChooseGifts> {
  late RoomGiftsModel roomGiftsModel;
  List chooseList = [];
  List<Result>? giftsList = [];
  Result? currentResult;

  /// 旧礼物模型
  Result? lastTimeResult;
  int appType = 2;
  int giftId = 0;
  int count = 0;
  Timer? _timer;
  double balance = 0;
  double opBalance = 0;
  bool sendStatus = false;
  static const int pageSize = 8; //每页多少个
  int? pageViewCount = 0; //一共多少页
  int currentPage = 0; //当前页数

  late FBRefreshWidgetBlocModel _fbRefreshWidgetBlocModel;
  late GiveGiftBlocModel _giveGiftBlocModel;
  GiveGiftEvent? _preGiveGiftEvent;

  void _startTimer(int? giftId, int count, GiveGiftEvent giveGiftEvent,
      {int? giftPrice}) {
    // 创建定时器
    _timer = Timer.periodic(const Duration(milliseconds: 600), (timer) {
      _giveGiftBlocModel.add(
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
      this.count = 0;
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

      setState(() {
        balance = double.parse(_balance!);
        opBalance = balance;
      });
    }
  }

  // 获取礼物列表
  Future getGifts(int pageNum, int pageSize) async {
    final value = await Api.getGiftPageList(pageSize, pageNum);
    if (value["code"] == 200) {
      roomGiftsModel = RoomGiftsModel.fromJson(value['data']);
      if (roomGiftsModel.result!.isNotEmpty) {
        setState(() {
          pageViewCount = roomGiftsModel.pageCount;
          giftsList = roomGiftsModel.result;
        });
      }
    }
  }

  //用户打赏选中状态
  void chooseType(Result? item) {
    /// 保留旧版模型，方便中断【切换新礼物连击】后送出礼物
    lastTimeResult = currentResult;
    currentResult = item;
    if (chooseList.contains(item) && sendStatus) {
      // chooseList.remove(item);
    } else {
      chooseList.clear();
      chooseList.add(item);
    }
  }

  // 用户打赏连击
  void onTapLiveReward(Result item, GiveGiftEvent giveGiftEvent) {
    currentResult = item;
    // 乏值小于当前值
    if (opBalance < item.price!) {
      giveGiftEvent.count = 1;
      _giveGiftBlocModel.add(
        giveGiftEvent,
      );
      _preGiveGiftEvent = null;
      _cancelTimer();
      // 已点击礼物数量
      if (count > 0) {
        // 上报
        postLiveReward(item.id, count, item.price);
        // 初始化页面计数器
        count = 0;
        // 余额额不足提醒
        myFailToast('余额不足，请及时充值！');
      } else {
        // 第一次点击就余额不足，弹起充值弹窗
        chargeShow();
      }
      // 点击动画
      giveGiftEvent.count = count;
      _giveGiftBlocModel.add(
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

      if (_preGiveGiftEvent != null &&
          item.id != _preGiveGiftEvent!.giftResultModel!.id) {
        _preGiveGiftEvent = giveGiftEvent;
        sendStatus = false;
        _cancelTimer();

        // 上报服务器【切换连击的礼物了，直接送出上次的】
        if (lastTimeResult != null) {
          postLiveReward(lastTimeResult!.id, count, lastTimeResult!.price);
          lastTimeResult = null;
        }
        count = 1;
      } else {
        if (!sendStatus) {
          // 自加本次计数器
          count++;
        } else {
          // 已上报上一次结果
          count = 1;
          // 初始化计时器状态
          sendStatus = false;
        }
        _preGiveGiftEvent = giveGiftEvent;
      }

      giveGiftEvent.count = count;
      _giveGiftBlocModel.add(
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
    _fbRefreshWidgetBlocModel.add(true);
  }

  // 打赏主播
  Future postLiveReward(int? giftId, int? count, int? giftPrice) async {
    if (count == 0 || count == null) {
      return;
    }
    appType = computedAppType();

    final value =
        await Api.postLiveReward(appType, giftId, count, widget.roomId);

    if (value["code"] == 200) {
      LiveLogUp.giveGifts(
          optContent: "$giftId", roomInfoObject: widget.roomInfoObject!);
      final GiftSuccessModel giftSucModel =
          GiftSuccessModel.fromJson(value["data"]);
      // 页面自减
      subBalance(giftPrice! * giftSucModel.giftQt!);
      // 发送礼物消息
      fbApiSendLiveGift(giftSucModel);
    } else {
      // 乏值校准
      correctOpBalance();
      myFailToast(value["msg"]);
    }
  }

  // FBAPI--发送礼物消息
  void fbApiSendLiveGift(GiftSuccessModel giftSucModel) {
    sendGiftsEventBus.fire(SendGitsEvent(giftSucModel));
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

  // 页面余额自减
  void subBalance(int price) {
    final subBalance = balance - price;
    if (mounted) {
      setState(() {
        balance = subBalance <= 0 ? 0 : subBalance;
        // 乏值校准
        correctOpBalance();
      });
    }
  }

  // 乏值校准
  void correctOpBalance() {
    opBalance = balance;
  }

  // 乏值自减
  void subOperationBalance(int price) {
    final subBalance = opBalance - price;
    opBalance = subBalance <= 0 ? 0 : subBalance;
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

  // 充值弹窗弹起
  void chargeShow() {
    RouteUtil.pop();
    if (kIsWeb) {
      showDialog(
        context: context,
        builder: (context) {
          return Center(
            child: Container(
              constraints: const BoxConstraints(
                maxWidth: 375,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: BalanceChooseSheet(
                  isScreenRotation: !FrameSize.isHorizontal(),
                ),
              ),
            ),
          );
        },
      );
      return;
    }
    showQ1Dialog(context,
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance!.addPostFrameCallback((timeStamp) {
      // 获取账户余额
      getBalance();
      // 获取礼物列表
      getGifts(1, pageSize);
    });
  }

  @override
  void dispose() {
    final _idEnd = giftId == 0 ? currentResult?.id : giftId;
    if (!sendStatus && _idEnd != null && count != 0) {
      postLiveReward(giftId == 0 ? currentResult!.id : giftId, count,
          currentResult!.price);
    }
    _cancelTimer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<GiveGiftBlocModel>(
          create: (context) {
            return _giveGiftBlocModel = GiveGiftBlocModel(GiveGiftState());
          },
        ),
        BlocProvider<FBRefreshWidgetBlocModel>(
          create: (context) {
            return _fbRefreshWidgetBlocModel =
                FBRefreshWidgetBlocModel(RefreshState.none);
          },
        ),
      ],
      child: Stack(
        children: [
          Container(
            width: !FrameSize.isHorizontal()
                ? FrameSize.winWidth()
                : FrameSize.winWidth() * 375 / 812,
            height: kIsWeb
                ? FrameSize.px(290)
                : !FrameSize.isHorizontal()
                    ? FrameSize.px(370)
                    : FrameSize.winHeight(),
            color: const Color(0xFF090B1B),
            padding: EdgeInsets.fromLTRB(
                FrameSize.px(16),
                FrameSize.px(!FrameSize.isHorizontal() ? 8 : 16),
                FrameSize.px(15),
                FrameSize.px(16)),
            child: Column(
              children: [
                Expanded(
                  child: GiftsView(
                    pageSize: pageSize,
                    pageViewCount: pageViewCount,
                    chooseType: chooseType,
                    onTapLiveReward: onTapLiveReward,
                    checkSelectState: (itemData) {
                      return chooseList.contains(itemData);
                    },
                    isHaveSelected: () {
                      return chooseList.isNotEmpty;
                    },
                  ),
                ),
                BlocBuilder<FBRefreshWidgetBlocModel, RefreshState?>(
                  builder: (context, refreshState) {
                    return _bottomView();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bottomView() {
    return SizedBox(
        height: FrameSize.px(49),
        child: Padding(
            padding: EdgeInsets.only(
                left: FrameSize.px(15), bottom: FrameSize.px(15)),
            child: Row(children: [
              Text("余额：",
                  style: TextStyle(
                      color: const Color(0xFF8B8B8B),
                      fontSize: FrameSize.px(12))),
              SizedBox(width: FrameSize.px(5)),
              Image.asset(
                "assets/live/LiveRoom/money.png",
                width: FrameSize.px(16),
                height: FrameSize.px(16),
              ),
              SizedBox(width: FrameSize.px(10)),
              Text(balance.toString(),
                  style: TextStyle(
                      color: Colors.white, fontSize: FrameSize.px(14))),
              const Expanded(child: SizedBox()),
              GestureDetector(
                onTap: chargeShow,
                child: SizedBox(
                  width: FrameSize.px(45),
                  child: Text(
                    "充值 >",
                    style: TextStyle(
                        color: Colors.white, fontSize: FrameSize.px(14)),
                  ),
                ),
              ),
              SizedBox(
                width: FrameSize.px(18),
              )
            ])));
  }
}

class GiftsView extends StatefulWidget {
  final int? pageViewCount;
  final int? pageSize;
  final Function(Result?)? chooseType;
  final Function(Result, GiveGiftEvent)? onTapLiveReward;
  final bool Function(Result?)? checkSelectState;
  final bool Function()? isHaveSelected;

  const GiftsView({
    this.pageViewCount,
    this.pageSize,
    this.chooseType,
    this.onTapLiveReward,
    this.checkSelectState,
    this.isHaveSelected,
  });

  @override
  _GiftsViewState createState() => _GiftsViewState();
}

class _GiftsViewState extends State<GiftsView>
    with AutomaticKeepAliveClientMixin {
  Map<int, GlobalObjectKey> pageMap = {};
  int _selectIndex = 0;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (widget.pageViewCount == null || widget.pageViewCount == 0) {
      return Container();
    }

    return Stack(
      children: [
        _sheetHeader(),
        PageView.builder(
          itemBuilder: (context, index) {
            final GlobalObjectKey key = pageMap.putIfAbsent(index, () {
              return GlobalObjectKey(index);
            });
            return GiftsBodyView(
              key: key,
              chooseType: (result) {
                pageMap.forEach((key, value) {
                  value.currentState?.setState(() {});
                });
                widget.chooseType!(result);
              },
              onTapLiveReward: widget.onTapLiveReward,
              checkSelectState: widget.checkSelectState,
              isHaveSelected: widget.isHaveSelected,
              pageNum: index,
              pageSize: widget.pageSize,
            );
          },
          itemCount: widget.pageViewCount ?? 0,
          onPageChanged: (index) {
            setState(() {
              _selectIndex = index;
            });
          },
        ),
        Positioned(
          bottom: 16,
          left: 0,
          right: 0,
          child: SizedBox(
            width: FrameSize.screenW() - FrameSize.px(32),
            // alignment: Alignment.center,
            child: Indicator(
              selectIndex: _selectIndex,
              itemCount: widget.pageViewCount ?? 0,
            ),
          ),
        )
      ],
    );
  }

  @override
  bool get wantKeepAlive => true;
}

class GiftsBodyView extends StatefulWidget {
  final Function(Result?)? chooseType;
  final Function(Result, GiveGiftEvent)? onTapLiveReward;
  final bool Function(Result?)? checkSelectState;
  final bool Function()? isHaveSelected;
  final int? pageNum;
  final int? pageSize;

  const GiftsBodyView({
    Key? key,
    this.chooseType,
    this.onTapLiveReward,
    this.checkSelectState,
    this.isHaveSelected,
    this.pageNum,
    this.pageSize,
  }) : super(key: key);

  @override
  _GiftsBodyViewState createState() => _GiftsBodyViewState();
}

class _GiftsBodyViewState extends State<GiftsBodyView>
    with AutomaticKeepAliveClientMixin {
  List? giftsList;

  @override
  void initState() {
    getGifts(widget.pageNum! + 1, widget.pageSize);
    super.initState();
  }

  // 获取礼物列表
  Future getGifts(int pageNum, int? pageSize) async {
    final value = await Api.getGiftPageList(pageSize, pageNum);
    if (value["code"] == 200) {
      final RoomGiftsModel roomGiftsModel =
          RoomGiftsModel.fromJson(value['data']);
      if (roomGiftsModel.result!.isNotEmpty) {
        setState(() {
          giftsList = roomGiftsModel.result;
          if (widget.pageNum == 0 &&
              giftsList!.isNotEmpty &&
              !widget.isHaveSelected!()) {
            widget.chooseType?.call(giftsList!.first);
          }
        });
      }
    } else {
      myToast(value['msg']);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (giftsList is List && giftsList!.isNotEmpty) {
      return GridView.builder(
        padding: EdgeInsets.only(
            left: FrameSize.px(16),
            top: FrameSize.px(8) + 10 + FrameSize.px(49),
            right: FrameSize.px(15)),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: giftsList!.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: kIsWeb ? 8 : 4,
            //纵轴间距
            mainAxisSpacing: FrameSize.px(12),
            //横轴间距
            crossAxisSpacing: FrameSize.px(6),
            //子组件宽高长度比例
            childAspectRatio: 0.8),
        itemBuilder: (context, index) {
          final Result itemData = giftsList![index];
          return _ItemView(
            itemData: itemData,
            index: index,
            pageNum: widget.pageNum,
            checkSelectState: widget.checkSelectState!,
            chooseType: (result) {
              BlocProvider.of<GiveGiftBlocModel>(context).add(GiveGiftState());
              widget.chooseType!.call(result);
            },
            onTapLiveReward: widget.onTapLiveReward,
          );
        },
      );
    }
    return Container();
  }

  @override
  bool get wantKeepAlive => true;
}

Widget _sheetHeader() {
  return Container(
      padding: EdgeInsets.only(left: FrameSize.px(22), top: FrameSize.px(16)),
      height: FrameSize.px(49),
      child: Row(
        children: [
          Image.asset(
            "assets/live/LiveRoom/gift_anchor.png",
            width: FrameSize.px(18),
            height: FrameSize.px(18),
          ),
          SizedBox(width: FrameSize.px(8)),
          Text("送礼物",
              style: TextStyle(color: Colors.white, fontSize: FrameSize.px(14)))
        ],
      ));
}

class _ItemView extends StatefulWidget {
  final Function(Result?)? chooseType;
  final Function(Result, GiveGiftEvent)? onTapLiveReward;
  final Result itemData;
  final bool Function(Result) checkSelectState;
  final int? index;
  final int? pageNum;

  const _ItemView({
    Key? key,
    this.chooseType,
    this.onTapLiveReward,
    required this.itemData,
    required this.checkSelectState,
    this.index,
    required this.pageNum,
  }) : super(key: key);

  @override
  _ItemViewState createState() => _ItemViewState();
}

class _ItemViewState extends State<_ItemView> {
  final GlobalKey _key = GlobalKey();

  double? itemWidth;

  @override
  Widget build(BuildContext context) {
    return Stack(
      // ignore: deprecated_member_use
      overflow: Overflow.visible,
      children: [
        BlocBuilder<GiveGiftBlocModel, GiveGiftState?>(
          builder: (context, giveGiftState) {
            if (giveGiftState == null ||
                giveGiftState.count == null ||
                !widget.checkSelectState.call(widget.itemData)) {
              return Container();
            }
            return GiftsChooseAnimationView(
              count: giveGiftState.count,
              position: Offset((giveGiftState.itemWidth! - 38.0) / 2.0, -30),
              onAnimationComplete: () {},
            );
          },
        ),
        GestureDetector(
          key: _key,
          onTap: () {
            final Size _size = context.size!;
            itemWidth = _size.width;
            if (widget.checkSelectState.call(widget.itemData)) {
              widget.onTapLiveReward?.call(
                widget.itemData,
                GiveGiftEvent(
                  position: Offset((itemWidth! - 38) / 2, 0),
                  giftResultModel: widget.itemData,
                  itemWidth: itemWidth,
                  count: 1,
                ),
              );
            } else {
              widget.chooseType?.call(widget.itemData);
            }
          },
          onTapDown: (touchEvent) {
            final Size _size = context.size!;
            itemWidth = _size.width;
          },
          child: BlocBuilder<GiveGiftBlocModel, GiveGiftState?>(
            builder: (context, giveGiftState) {
              return Container(
                height: FrameSize.px(118),
                decoration: BoxDecoration(
                  border: widget.checkSelectState.call(widget.itemData)
                      ? Border.all(color: const Color(0xFFB25BFF))
                      : Border.all(color: const Color(0xFF090B1B)),
                  borderRadius: const BorderRadius.all(Radius.circular(12)),
                  color: widget.checkSelectState.call(widget.itemData)
                      ? const Color(0xFF090B1B) //Color(0x339013FE)
                      : const Color(0xFF090B1B),
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(
                        top: 3,
                      ),
                      child: Container(),
                    ),
                    Expanded(
                      child: widget.itemData.imgUrl == null
                          ? Image.asset(
                              "assets/live/LiveRoom/money.png",
                            )
                          : Image.network(widget.itemData.imgUrl!),
                    ),
                    Container(
                      constraints: BoxConstraints(
                        minWidth: (FrameSize.screenW() - FrameSize.px(75)) / 4,
                      ),
                      decoration: const BoxDecoration(
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(11),
                          bottomRight: Radius.circular(11),
                        ),
                      ),
                      height: FrameSize.px(24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            "assets/live/LiveRoom/money.png",
                            width: FrameSize.px(14),
                            height: FrameSize.px(14),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            widget.itemData.price == null
                                ? '0'
                                : widget.itemData.price.toString(),
                            style: const TextStyle(
                                color: Colors.white, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    Offstage(
                      offstage: false,
                      child: Container(
                        padding: const EdgeInsets.only(top: 4, bottom: 4),
                        height: FrameSize.px(24),
                        alignment: Alignment.center,
                        decoration:
                            widget.checkSelectState.call(widget.itemData)
                                ? const BoxDecoration(
                                    color: Color(0xFFB25BFF),
                                    borderRadius: BorderRadius.only(
                                      bottomLeft: Radius.circular(11),
                                      bottomRight: Radius.circular(11),
                                    ),
                                  )
                                : const BoxDecoration(),
                        child: widget.checkSelectState.call(widget.itemData)
                            ? const Text("赠送",
                                style: TextStyle(
                                    color: Colors.white, fontSize: 12))
                            : Container(),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
