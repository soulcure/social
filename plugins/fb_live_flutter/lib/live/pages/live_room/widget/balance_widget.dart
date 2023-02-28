/*
充值余额选项
 */
import 'dart:io';

import 'package:fb_live_flutter/fb_live_flutter.dart';
import 'package:fb_live_flutter/live/api/fblive_provider.dart';
import 'package:fb_live_flutter/live/utils/func/router.dart';
import 'package:fb_live_flutter/live/utils/theme/my_toast.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../net/api.dart';
import '../../../utils/ui/frame_size.dart';

typedef PaymentResultCallBack = void Function(PaymentResult paymentResult);

class BalanceChooseSheet extends StatefulWidget {
  final PaymentResultCallBack? paymentResultCallBack;
  final bool isScreenRotation;

  const BalanceChooseSheet(
      {Key? key, this.paymentResultCallBack, this.isScreenRotation = false})
      : super(key: key);

  @override
  _BalanceChooseSheetState createState() => _BalanceChooseSheetState();
}

class _BalanceChooseSheetState extends State<BalanceChooseSheet> {
  List balanceList = [];
  double balance = 0;
  int? _coinId;

  @override
  void initState() {
    super.initState();
    getCoinsList();
    getBalance();
  }

  Future getBalance() async {
    final Map status = await Api.queryBalance();
    if (status["code"] == 200) {
      String? _balance = status["data"]["balance"];
      _balance = _balance == '0' ? '0.0' : _balance;

      setState(() {
        balance = double.parse(_balance!);
      });
    }
  }

  Future getCoinsList() async {
    final Map status = await Api.coinsList(getPlatformType().toString());
    if (status["code"] == 200) {
      setState(() {
        balanceList = status['data'] ?? [];
      });
    } else {
      myToast(status['msg']);
      await getCoinsList();
    }
  }

  Future rechargeOrder(int? coinId) async {
    final Map status = await Api.order(coinId, getPlatformType());
    if (status["code"] == 200) {
      final String? payId = status["data"]["payId"];
      final double price = double.parse(status["data"]["money"]);
      final String productName = '${status["data"]["coinCount"]}乐豆';
      final String? productId = status["data"]["productId"];
      final String? appId = status["data"]["appId"];
      await fbApi
          .charge(
              context: context,
              orderId: payId!,
              productId: productId!,
              price: price,
              appId: appId!,
              productName: productName)
          .then((res) {
        widget.paymentResultCallBack?.call(res);
        RouteUtil.pop();
      });
    } else {
      // 充值失败，更新充值商品列表
      await getCoinsList();
      // 错误提醒
      myFailToast(status['msg']);
    }
  }

  int getPlatformType() {
    if (kIsWeb) {
      return 1;
    }
    if (Platform.isIOS) {
      return 3;
    } else if (Platform.isAndroid) {
      return 2;
    }
    return -1;
  }

  @override
  Widget build(BuildContext context) {
    final double value = FrameSize.padBotH() > 0
        ? FrameSize.px(280) + FrameSize.padBotH()
        : FrameSize.px(280);
    return Container(
      alignment: Alignment.center,
      constraints: BoxConstraints(
        minHeight: value,
      ),
      decoration: const BoxDecoration(
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(12), topRight: Radius.circular(12)),
          color: Colors.white),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _headerView(),
          if (balanceList.isNotEmpty)
            _centBalanceView(context)
          else
            Container(
              height: FrameSize.px(194),
              alignment: Alignment.center,
              child: defaultTargetPlatform == TargetPlatform.iOS
                  ? const CupertinoActivityIndicator()
                  : const CircularProgressIndicator(strokeWidth: 2),
            ),
          _ButtonView(
            callBack: (buttonIndex) {
              if (buttonIndex == 0) {
                /// cancel
                Navigator.pop(context);
                return;
              }
              if (buttonIndex == 1) {
                if (_coinId == null || _coinId! < 1) {
                  myFailToast("请选择充值选项");
                  return;
                }
                if (kIsWeb) {
                  myFailToast('请到Fanbook APP进行充值');
                  return;
                }
                rechargeOrder(_coinId);
              }
            },
          ),
          _bottomView(),
        ],
      ),
    );
  }

  Widget _headerView() {
    return Container(
        padding: EdgeInsets.only(
            left: FrameSize.px(21),
            top: FrameSize.px(24),
            bottom: FrameSize.px(15)),
        height: FrameSize.px(59),
        child: Row(
          children: [
            Text("余额:",
                style: TextStyle(
                    color: const Color(0xFF8B8B8B),
                    fontSize: FrameSize.px(12))),
            SizedBox(width: FrameSize.px(5)),
            Image.asset(
              "assets/live/LiveRoom/money.png",
              width: FrameSize.px(18),
              height: FrameSize.px(18),
            ),
            SizedBox(width: FrameSize.px(4)),
            Text(balance.toString(),
                style: TextStyle(
                    color: const Color(0xFF0D0D0D),
                    fontSize: FrameSize.px(14))),
          ],
        ));
  }

  Widget _centBalanceView(BuildContext context) {
    return SizedBox(
        height: FrameSize.px(194),
        child: GridView.builder(
          padding: EdgeInsets.only(
            left: FrameSize.px(17),
            top: FrameSize.px(5),
            right: FrameSize.px(21),
            bottom: FrameSize.px(15),
          ),
          itemCount: balanceList.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              //纵轴间距
              mainAxisSpacing: FrameSize.px(10),
              //横轴间距
              crossAxisSpacing: FrameSize.px(10),
              //子组件宽高长度比例
              childAspectRatio: 1.52),
          itemBuilder: _getItemContainer,
        ));
  }

  Widget _getItemContainer(BuildContext context, int index) {
    bool selected = false;
    if (kIsWeb) {
      selected = _coinId == balanceList[index]["id"];
    }
    return GestureDetector(
      onTap: () {
        if (kIsWeb) {
          setState(() {
            _coinId = balanceList[index]["id"];
          });
        } else {
          _coinId = balanceList[index]["id"];
          rechargeOrder(_coinId);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.all(
            Radius.circular(FrameSize.px(12)),
          ),
          border: Border.all(
            color: selected
                ? const Color.fromRGBO(97, 121, 243, 1)
                : Colors.transparent,
          ),
          color: selected
              ? const Color.fromRGBO(216, 223, 255, 1)
              : const Color(0xFFF4F4F4),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: FrameSize.px(34.5),
              child:
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Image.asset(
                  "assets/live/LiveRoom/money.png",
                  width: FrameSize.px(14),
                  height: FrameSize.px(14),
                ),
                SizedBox(width: FrameSize.px(5)),
                Text(
                  balanceList[index]["coinCount"].toString(),
                  style: TextStyle(
                      fontSize: FrameSize.px(17), fontWeight: FontWeight.bold),
                )
              ]),
            ),
            Text('￥ ${balanceList[index]["price"].toString()}',
                style: TextStyle(
                    color: const Color(0xFF7D7D7D), fontSize: FrameSize.px(12)))
          ],
        ),
      ),
    );
  }

  Widget _bottomView() {
    return Container(
        padding: EdgeInsets.only(
            top: balanceList.length > 6 ? FrameSize.px(10) : FrameSize.px(0)),
        height: FrameSize.padBotH() > 0
            ? FrameSize.px(42) + FrameSize.padBotH()
            : FrameSize.px(42),
        child: RichText(
            text: TextSpan(
                style: DefaultTextStyle.of(context).style,
                children: <InlineSpan>[
              TextSpan(
                  text: "充值代表已阅读并同意",
                  style: TextStyle(
                      color: const Color(0xFF9F9F9F),
                      fontSize: FrameSize.px(12))),
              TextSpan(
                  text: "《用户充值协议》",
                  style: TextStyle(
                      color: const Color(0xFFB17B26),
                      fontSize: FrameSize.px(12)),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () {
                      final chargeUrl =
                          'https://${configProvider.protocolHost}/recharge/recharge.html';
                      fbApi.pushHTML(context, chargeUrl, title: '用户充值协议');
                    }),
            ])));
  }
}

class _ButtonView extends StatefulWidget {
  final ValueChanged<int>? callBack;

  const _ButtonView({this.callBack});

  @override
  _ButtonViewState createState() => _ButtonViewState();
}

class _ButtonViewState extends State<_ButtonView> {
  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) {
      return Container();
    }
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(
            top: 6,
          ),
          child: Container(),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _RechargeButton(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(100),
                border: Border.all(
                  color: const Color.fromRGBO(97, 121, 243, 1),
                ),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 7,
              ),
              onTap: () {
                widget.callBack?.call(0);
              },
              child: const Text(
                "取消",
                style: TextStyle(
                  color: Color.fromRGBO(97, 121, 243, 1),
                  fontSize: 14,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                left: 12,
              ),
              child: Container(),
            ),
            _RechargeButton(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(100),
                color: const Color.fromRGBO(97, 121, 243, 1),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 7,
              ),
              onTap: () {
                widget.callBack?.call(1);
              },
              child: const Text(
                "去充值",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(
            top: 27,
          ),
          child: Container(),
        ),
      ],
    );
  }
}

class _RechargeButton extends StatelessWidget {
  final Decoration? decoration;
  final EdgeInsets? padding;
  final Widget? child;
  final VoidCallback? onTap;

  const _RechargeButton({
    Key? key,
    this.decoration,
    this.padding,
    this.child,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: decoration ?? const BoxDecoration(),
        padding: padding ?? EdgeInsets.zero,
        child: child,
      ),
    );
  }
}
