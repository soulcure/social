class TaskItem {
  int id;
  int type;
  String title;
  String description;
  String content;
  int status;

  TaskItem(
      {this.id,
      this.type,
      this.title,
      this.description,
      this.content,
      this.status});

  factory TaskItem.fromJson(Map<String, dynamic> json) => _itemFromJson(json);

// Map<String, dynamic> toInsertDbMap() {
//   final map = {
//     TaskTable.columnId: id,
//     TaskTable.columnType: type,
//     TaskTable.columnTitle: title,
//     TaskTable.columnDescription: description,
//     TaskTable.columnBeginTime: beginTime,
//     TaskTable.columnEndTime: endTime,
//     TaskTable.columnRule: toRuleJson(),
//     TaskTable.columnStatus: columnStatus,
//   };
//   return map;
// }
}

TaskItem _itemFromJson(Map<String, dynamic> json) {
  return TaskItem(
    id: json['id'] as int,
    type: json['type'] as int,
    title: json['title'] as String,
    description: json['description'] as String,
    content: json['content'] as String,
  );
}
