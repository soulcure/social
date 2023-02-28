import 'package:flutter/widgets.dart';

class GrabRedPackResp {
  //红包状态   0 未开封， 1超时未领取， 2红包领完， 3成功领取
  final int flag;

  //抢到的红包金额，flag=0 && money>0,代表这是最后一个红包
  final String subMoney;

  const GrabRedPackResp({
    @required this.flag,
    @required this.subMoney,
  });

  Map<String, dynamic> toMap() {
    return {
      'flag': flag,
      'sub_money': subMoney,
    };
  }

  factory GrabRedPackResp.fromMap(Map<String, dynamic> map) {
    return GrabRedPackResp(
      flag: map['flag'] as int,
      subMoney: map['sub_money'] as String,
    );
  }
}
