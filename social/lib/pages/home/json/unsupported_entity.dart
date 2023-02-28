import 'package:get/get.dart';
import 'package:im/pages/home/json/text_chat_json.dart';

class UnSupportedEntity extends MessageContentEntity {
  final String messageId;
  final Map<String, dynamic> unSupportContent;

  UnSupportedEntity({this.messageId, this.unSupportContent})
      : super(MessageType.unSupport);

  factory UnSupportedEntity.fromJson(Map<String, dynamic> json) {
    return UnSupportedEntity(
      unSupportContent: json,
    );
  }

  Map<String, dynamic> toMap() {
    return unSupportContent;
  }

  @override
  Map<String, dynamic> toJson() => toMap();

  Future<String> toNotificationString() async {
    return '当前版本暂不支持查看此信息类型'.tr;
  }
}
