import 'package:flutter/cupertino.dart';

class SendRedPackResp {
  //拉起支付宝发红包的字符串
  final String payRedBag;

  //红包唯一ID，用于后面抢红包
  final String forder;

  const SendRedPackResp({
    @required this.payRedBag,
    @required this.forder,
  });

  Map<String, dynamic> toMap() {
    return {
      'payRedBag': payRedBag,
      'forder': forder,
    };
  }

  factory SendRedPackResp.fromMap(Map<String, dynamic> map) {
    return SendRedPackResp(
      payRedBag: map['payRedBag'] as String,
      forder: map['forder'] as String,
    );
  }
}
