enum TransactionType {
  topUp,
  consumption,
  earning,
}

class TransactionEntity {
  /// 充值订单号
  final String orderNum;

  /// 交易时间
  final DateTime date;

  /// 交易类型，充值或消费
  final TransactionType type;

  final double amount;

  final String merchandiseName;

  TransactionEntity(this.orderNum, this.date, this.type,this.amount,this.merchandiseName);
}

// /// 乐豆充值model
// class TopUpEntity extends TransactionEntity {
//   /// 充的乐豆数
//   final int ledou;
//
//   // /// 充值金额（单位：元）
//   // final double amount;
//
//   TopUpEntity(
//     String orderNum,
//     int date,
//     this.ledou,
//     // this.amount,
//   ) : super(orderNum, date, TransactionType.topUp);
// }

/// 乐豆消费model
// class ConsumptionEntity extends TransactionEntity {
//   /// 购买的礼物
//   final String gift;
//
//   /// 礼物单价（单位：乐豆）
//   final int unitPrice;
//
//   /// 购买礼物的数量
//   final int quantity;
//
//   /// 发起此消费的直播间
//   final String liveRoom;
//
//   /// 直播间主播昵称
//   final String streamer;
//
//   ConsumptionEntity(
//     String orderNum,
//     int date,
//     this.unitPrice,
//     this.gift,
//     this.quantity,
//     this.liveRoom,
//     this.streamer,
//   ) : super(orderNum, date, TransactionType.consumption);
// }

// /// 乐豆收益model
// class EarningEntity extends TransactionEntity {
//   /// 收到的礼物
//   final String gift;
//   /// 收益金额（单位：乐豆）
//   final int amount;
//
//   EarningEntity(
//       String orderNum,
//       int date,
//       this.gift,
//       this.amount,
//       ) : super(orderNum, date, TransactionType.earning);
// }