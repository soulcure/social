import 'package:hive/hive.dart';

part 'at_me_bean.g.dart';

@HiveType(typeId: 11)
class AtMeBean extends HiveObject {
  @HiveField(0)
  int num;

  @HiveField(1)
  String channelId;

  @HiveField(2)
  Map<String, String> messageIdMap;

  AtMeBean({this.num = 0, this.channelId, this.messageIdMap}) {
    messageIdMap ??= <String, String>{};
  }

  void clear() {
    num = 0;
    messageIdMap = {};
  }

  bool contains(String messageId) {
    return messageIdMap.containsKey(messageId);
  }

  void remove(String messageId) {
    if (num > 0) {
      num--;
    }
    messageIdMap.remove(messageId);
  }

  void add(String messageId) {
    if (messageIdMap.containsKey(messageId)) return;
    messageIdMap[messageId] = messageId;
    num++;
  }
}
