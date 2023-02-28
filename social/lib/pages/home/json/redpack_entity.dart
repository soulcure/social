import 'package:get/get.dart';
import 'package:im/pages/home/json/text_chat_json.dart';

class RedPackEntity extends MessageContentEntity {
  //红包唯一ID，用于后面抢红包
  final String id;
  final int redPackType;
  final String redPackGreetings;

  final double money;
  final int num;
  final String picture;

  RedPackEntity({
    this.id,
    this.redPackType,
    this.redPackGreetings,
    this.money,
    this.num,
    this.picture = '',
  }) : super(MessageType.redPack);

  Map<String, dynamic> toMap() {
    return {
      'type':
          redPackType == 1 ? MessageAction.redPack1 : MessageAction.redPack2,
      'id': id,
      'redPackType': redPackType,
      'redPackGreetings': redPackGreetings,
      'money': money,
      'num': num,
      'picture': picture ?? '',
    };
  }

  factory RedPackEntity.fromJson(Map<String, dynamic> map) {
    return RedPackEntity(
      id: map['id'] as String,
      redPackType: map['redPackType'] as int,
      redPackGreetings: map['redPackGreetings'] as String,
      money: double.tryParse(map['money']?.toString()),
      num: map['num'] as int,
      picture: map['picture'] as String,
    );
  }

  @override
  Map<String, dynamic> toJson() => toMap();

  @override
  String toString() {
    return 'RedPackEntity{id: $id, redPackType: $redPackType, redPackGreetings: $redPackGreetings, money: $money, num: $num, picture: $picture}';
  }

  String toNotificationString() {
    return '[红包]'.tr;
  }
}
