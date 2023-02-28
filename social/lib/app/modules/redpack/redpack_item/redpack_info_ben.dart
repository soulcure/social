import 'package:flutter/widgets.dart';
import 'package:hive/hive.dart';

part 'redpack_info_ben.g.dart';

class RedPackStatus {
  static const int newRedPack = 0; //0 未开封
  static const int expiredRedPack = 1; //1 超时未领取，24小时后过期红包
  static const int noneLeftRedPack = 2; //2 红包领完,未抢到红包
  static const int GrabbedRedPack = 3; //3 成功领取
  static const int notOpenRedPack = 4; //4 红包未领取（只针对私信单发状态）
}

@HiveType(typeId: 23)
class RedPackInfoBean extends HiveObject {
  @HiveField(0)
  String messageId; //红包消息id

  @HiveField(1)
  String id; //红包id

  @HiveField(2)
  int status; //红包状态   0 未开封， 1超时未领取， 2红包领完， 3成功领取，4 红包未领取（只针对私信单发状态）

  @HiveField(3)
  String subMoney; //抢到的红包金额

  RedPackInfoBean({
    @required this.messageId,
    this.id,
    this.status,
    this.subMoney,
  });

  @override
  // ignore: avoid_equals_and_hash_code_on_mutable_classes
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RedPackInfoBean &&
          runtimeType == other.runtimeType &&
          (messageId == other.messageId || id == other.id);

  @override
  // ignore: avoid_equals_and_hash_code_on_mutable_classes
  int get hashCode => messageId.hashCode ^ id.hashCode;
}
