//封禁等级 0 未设置 1：解散 2：无法查看
enum BanType {
  normal, // 0 未设置
  dissolve, //1：解散
  frozen, //2：无法查看
}

extension BanTypeExtension on BanType {
  static BanType fromInt(int value) {
    return BanType.values[value];
  }
}
