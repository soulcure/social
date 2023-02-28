import 'package:im/pages/home/json/text_chat_json.dart';

class TaskEntity extends MessageContentEntity {
  final List<String> rule; //["11545435", "22", "333", "444", "555555"]
  final String url;

  //{"title": "问卷","list": [],"open": 1}
  final Map content;
  final String welcomeMessage;
  final int taskType;
  final String taskTitle;

  TaskEntity({
    this.rule,
    this.url,
    this.content,
    this.welcomeMessage,
    this.taskType,
    this.taskTitle,
  }) : super(MessageType.task);

  Map<String, dynamic> toMap() {
    return {
      'rule': rule ?? [],
      'type': typeInString,
      'url': url ?? '',
      'content': content ?? {},
      'welcome_message': welcomeMessage ?? '',
      'task_type': taskType ?? 0,
      'task_title': taskTitle ?? '',
    };
  }

  ///是否是入门仪式任务
  bool isTaskIntroductionCeremony() {
    return taskType != null && taskType == 1;
  }

  factory TaskEntity.fromJson(Map<String, dynamic> map) {
    return TaskEntity(
      rule: map['rule']?.cast<String>(),
      url: map['url'],
      welcomeMessage: map['welcome_message'],
      content: map['content'],
      taskType: map['task_type'],
      taskTitle: map['task_title'],
    );
  }

  @override
  Map<String, dynamic> toJson() => toMap();

  @override
  String toString() {
    return 'TaskEntity(rule: $rule, type: $type, url: $url, content: $content, taskType: $taskType)';
  }

  String toNotificationString() {
    final children = content['children'];
    if (children != null && children is List && children.isNotEmpty) {
      final param = children[0]['param'];
      if (param != null) {
        final text = param['text'];
        if (text != null && text is String) {
          return text;
        }
      }
    }

    return '';
  }
}
