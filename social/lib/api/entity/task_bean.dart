import 'package:hive/hive.dart';

part 'task_bean.g.dart';

@HiveType(typeId: 15)
class TaskBean extends HiveObject {
  @HiveField(0)
  String messageId;

  @HiveField(1)
  String undoneChannel; //未完成任务频道

  @HiveField(2)
  String guildId;

  @HiveField(3)
  String channelId;

  @HiveField(4)
  String taskMessageId; //任务id

  @HiveField(5)
  String sendId; //发送任务者id

  @HiveField(6)
  int status; //1 未完成；2 已完成

  TaskBean();

  TaskBean.fromList(List<String> list) {
    if (list != null && list.length == 6) {
      messageId = list[0];
      undoneChannel = list[1];
      guildId = list[2];
      channelId = list[3];
      taskMessageId = list[4];
      sendId = list[5];
    }
  }

  @override
  String toString() {
    return "$messageId;$undoneChannel;$guildId;$channelId;$taskMessageId;$sendId";
  }
}
