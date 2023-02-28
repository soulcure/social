import 'package:hive/hive.dart';

part 'relation.g.dart';

@HiveType(typeId: 24)
enum RelationType {
  @HiveField(0)
  none,
  @HiveField(1)
  friend,
  @HiveField(2)
  blocked,
  @HiveField(3)
  pendingIncoming,
  @HiveField(4)
  pendingOutgoing,
  @HiveField(99) // 后端的值是 99
  unrelated,
}

extension RelationTypeExtension on RelationType {
  static RelationType fromInt(int value) {
    if (value == null || value < 0) {
      value = 0;
    } else if (value > 4) {
      value = 5;
    }
    return RelationType.values[value];
  }

  static int toInt(RelationType value) {
    if (value == null) return 0;
    if (value == RelationType.unrelated) return 99;
    return value.index;
  }
}

enum RelationAction {
  // 1=申请好友；2=好友建立完成；3=好友被删除；4=被人拒绝添加好友;5=申请者取消
  apply,
  friend,
  delete,
  refuse,
  cancel,
}

extension RelationActionExtension on RelationAction {
  // 1=申请好友；2=好友建立完成；3=好友被删除；4=被人拒绝添加好友;5=申请者取消
  static RelationAction fromInt(int value) {
    RelationAction res;
    switch (value) {
      case 1:
        res = RelationAction.apply;
        break;
      case 2:
        res = RelationAction.friend;
        break;
      case 3:
        res = RelationAction.delete;
        break;
      case 4:
        res = RelationAction.refuse;
        break;
      case 5:
        res = RelationAction.cancel;
        break;
      default:
        res = RelationAction.apply;
        break;
    }
    return res;
  }
}
