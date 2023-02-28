import 'package:im/api/data_model/user_info.dart';

class BlackItem {
  String guildId;
  String userId;
  String blackReason;
  int isRelieve; //0为解除 1为禁用
  String createTime;
  String createId;
  String updateTime;
  String updateId;

  BlackItem(
      {this.guildId,
      this.userId,
      this.blackReason,
      this.isRelieve,
      this.createTime,
      this.createId,
      this.updateTime,
      this.updateId});

  factory BlackItem.fromMap(Map<String, dynamic> map) {
    return BlackItem(
      guildId: map['guild_id'] as String,
      userId: map['user_id'] as String,
      blackReason: map['black_reason'] as String,
      isRelieve: map['is_relieve'] as int,
      createTime: map['create_time'] as String,
      createId: map['creater_id'] as String,
      updateTime: map['update_time'] as String,
      updateId: map['update_id'] as String,
    );
  }

  Future<String> createName() async {
    final name = (await UserInfo.get(createId)).showName();
    return name;
  }
}
