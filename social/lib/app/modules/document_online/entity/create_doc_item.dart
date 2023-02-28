import 'package:im/app/modules/document_online/document_enum_defined.dart';

// {
// "guild_id": "312107634121506816",
// "type": "doc",
// "dir_id": "12",
// "title": "小蝴蝶",
// "user_id": "232744506837958656",
// "file_id": "300000000$DeBsfAGFZhEE",
// "url": "https://docs.qq.com/doc/DRGVCc2ZBR0ZaaEVF",
// "group_id": "1519278962725789696",
// "policy": 3,
// "created_by": "232744506837958656",
// "updated_by": "232744506837958656",
// "created_at": "1651059306823",
// "updated_at": "1651059306823"
// }

class CreateDocItem {
  String fileId;
  String guildId;
  String userId; //现在所属谁
  String groupId; //权限组
  String title;
  DocType type;
  int dirId;
  String url; //预计会改为fanbook域名，服务器跳转到 腾讯地址
  int policy; //文档权限 1仅我  2权限组  3所有人
  int createdAt;
  int updatedAt;
  String createdBy; //一旦创建，不会在改变
  String updatedBy;
  bool canCopy;
  bool canReaderComment;

  CreateDocItem({
    this.fileId,
    this.guildId,
    this.userId,
    this.groupId,
    this.title,
    this.type,
    this.dirId,
    this.url,
    this.policy,
    this.createdAt,
    this.updatedAt,
    this.createdBy,
    this.updatedBy,
    this.canCopy,
    this.canReaderComment,
  });

  factory CreateDocItem.fromMap(Map<String, dynamic> map) {
    return CreateDocItem(
      fileId: map['file_id'] as String,
      guildId: map['guild_id'] as String,
      userId: map['user_id'] as String,
      groupId: map['group_id'] as String,
      title: map['title'] as String,
      type: DocTypeExtension.fromString(map['type']),
      dirId: map['dir_id'] as int,
      url: map['url'] as String,
      policy: map['policy'] as int,
      createdAt: int.tryParse(map['created_at'] ?? ''),
      updatedAt: int.tryParse(map['updated_at'] ?? ''),
      createdBy: map['created_by'] as String,
      updatedBy: map['updated_by'] as String,
      canCopy: map['can_copy'] == 1,
      canReaderComment: map['can_reader_comment'] == 1,
    );
  }

  @override
  String toString() {
    return 'CreateDocItem{fileId: $fileId, guildId: $guildId, userId: $userId, groupId: $groupId, title: $title, type: $type, url: $url, policy: $policy, createdAt: $createdAt, createdBy: $createdBy, updatedAt: $updatedAt, updatedBy: $updatedBy}';
  }
}
