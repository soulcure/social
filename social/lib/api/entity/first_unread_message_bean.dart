import 'package:hive/hive.dart';

part 'first_unread_message_bean.g.dart';

@HiveType(typeId: 12)
class FirstUnreadMessageBean extends HiveObject {
  @HiveField(0)
  int time;

  @HiveField(1)
  String messageId;

  FirstUnreadMessageBean({this.time = 0, this.messageId});
}

