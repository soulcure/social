import 'package:hive/hive.dart';
import 'package:im/db/db.dart';

part 'remark_bean.g.dart';

@HiveType(typeId: 8)
class RemarkListBean extends HiveObject {
  @HiveField(0)
  int size;

  @HiveField(1)
  String listId;

  @HiveField(2)
  String next;

  @HiveField(3)
  Map<String, RemarkBean> remarks;

  RemarkListBean(
      {this.size = 100, this.listId, this.next = '1', this.remarks = const {}});

  factory RemarkListBean.fromJson(map) {
    if (map == null || map is! Map) return null;
    final Map<String, RemarkBean> localRecords = {};
    (map['records'] as List ?? []).forEach((o) {
      final bean = RemarkBean.fromJson(o);
      Db.remarkBox.put(bean.friendUserId, bean);
      localRecords[bean.friendUserId] = bean;
    });
    return RemarkListBean(
        remarks: localRecords,
        size: map['size'],
        listId: map['list_id'],
        next: map['next']);
  }

  Map toJson() => {
        "records": remarks,
        "size": size,
        "list_id": listId,
        "next": next,
      };

  Map<String, Map> get transformRecords {
    final result = {};
    remarks.forEach((key, value) {
      result[key] = value.toJson();
    });
    return result;
  }
}

/// friend_user_id : 116439315705237504
/// name : "lzc"
/// user_remark_id : 151568708244865024
///

@HiveType(typeId: 9)
class RemarkBean {
  @HiveField(0)
  String friendUserId;

  @HiveField(1)
  String name;

  @HiveField(2)
  String userRemarkId;

  RemarkBean(this.friendUserId, this.name, this.userRemarkId);

  factory RemarkBean.fromJson(Map<String, dynamic> map) {
    final friendUserId = map['friend_user_id']?.toString();
    final name = map['name'];
    final userRemarkId = map['user_remark_id']?.toString();
    return RemarkBean(friendUserId, name, userRemarkId);
  }

  Map toJson() => {
        "friend_user_id": friendUserId,
        "name": name,
        "user_remark_id": userRemarkId,
      };
}
