import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:im/app/modules/document_online/document_enum_defined.dart';
import 'package:im/app/modules/document_online/entity/doc_item.dart';
import 'package:im/app/modules/tc_doc_add_group_page/entities/tc_doc_group.dart';
import 'package:im/common/extension/string_extension.dart';
import 'package:im/db/db.dart';
import 'package:im/global.dart';

// {
// "type": "在线文档",
// "title": "副本-小蝴蝶",
// "user_id": "232744506837958656",
// "guild_id": "312107634121506816",
// "created_at": "1651059668153",
// "role": 2,
// "updated_at": "1651059668153",
// "updated_by": "232744506837958656",
// "viewed_at": "",
// "viewed_by": ""
// }
class DocInfoItem {
  String fileId;

  ///以下为必须
  DocType type;
  String title;
  String userId;
  String guildId;
  String url;
  int createdAt;
  String createdBy;
  TcDocGroupRole role; //对文档的权限|1:阅读,2:编辑
  bool canCopy;
  bool canReaderComment;

  ///以下为非必须
  int updatedAt;
  String updatedBy;
  int viewedAt;
  String viewedBy;
  int collectedAt;
  List<String> viewList;

  bool get isOwner => userId == Global.user?.id;

  DocInfoItem({
    ///以下为必须
    this.fileId,
    this.type,
    this.title,
    this.userId,
    this.guildId,
    this.url,
    this.createdAt,
    this.createdBy,
    this.role,
    this.canCopy,
    this.canReaderComment,

    ///以下为非必须
    this.updatedAt,
    this.updatedBy,
    this.viewedAt,
    this.viewedBy,
    this.collectedAt,
    this.viewList,
  });

  factory DocInfoItem.fromDocItem(DocItem item) {
    return DocInfoItem(
      ///以下为必须
      fileId: item.fileId,
      type: item.type,
      title: item.title,
      url: item.url,
      userId: item.userId,
      guildId: item.guildId,
      createdAt: item.createdAt,
      createdBy: item.createdBy,
      role: item.role,
      canCopy: item.canCopy,
      canReaderComment: item.canReaderComment,

      ///以下为非必须
      updatedAt: item.updatedAt,
      updatedBy: item.updatedBy,
      collectedAt: item.collectedAt,
    );
  }

  factory DocInfoItem.fromMap(Map<String, dynamic> map) {
    final List resList = map["view_list"];
    final List<String> lists = resList?.map((e) => e)?.cast<String>()?.toList();

    return DocInfoItem(
      ///以下为必须
      fileId: map['file_id'] as String,
      type: DocTypeExtension.fromString(map['type']),
      title: map['title'] as String,
      userId: map['user_id'] as String,
      guildId: map['guild_id'] as String,
      url: map['url'] as String,
      createdAt: int.tryParse(map['created_at'] ?? ''),
      createdBy: map['created_by'] as String,
      role: TcDocGroupRoleExtension.fromInt(map['role']),
      canCopy: map['can_copy'] == 1,
      canReaderComment: map['can_reader_comment'] == 1,

      ///以下为非必须
      updatedAt: int.tryParse(map['updated_at'] ?? ''),

      updatedBy: map['updated_by'],
      viewedAt: int.tryParse(map['viewed_at'] ?? ''),

      viewedBy: map['viewed_by'],
      collectedAt: int.tryParse(map['collected_at'] ?? ''),
      viewList: lists,
    );
  }

  bool isCollect() {
    return collectedAt != null && collectedAt > 0;
  }

  void setCollect(bool status) {
    if (status) {
      collectedAt = DateTime.now().millisecondsSinceEpoch;
    } else {
      collectedAt = 0;
    }
  }

  String getOwnerNickName() {
    if (userId.noValue) return '';

    final userinfo = Db.userInfoBox?.get(userId);
    return userinfo?.showName(guildId: guildId);
  }

  String getUpdateTime() {
    if (updatedAt == null) return '';
    return DocItem.getTimeString(updatedAt);
  }

  //最近编辑
  bool hasUpdate() {
    return updatedBy.hasValue;
  }

  //最近编辑
  String getUpdateNickName() {
    if (updatedBy.noValue) return '';

    final userinfo = Db.userInfoBox?.get(updatedBy);
    return userinfo?.showName(guildId: guildId);
  }

  //最近查看
  bool hasView() {
    return viewedBy.hasValue;
  }

  String getViewTime() {
    if (viewedAt == null) return '';
    return DocItem.getTimeString(viewedAt);
  }

  //最近查看
  String getViewNickName() {
    if (viewedBy.noValue) return '';

    final userinfo = Db.userInfoBox?.get(viewedBy);
    return userinfo?.showName(guildId: guildId);
  }

  //创建时间
  bool hasCreate() {
    return createdBy.hasValue;
  }

  String getCreateTime() {
    return DocItem.getTimeString(createdAt);
  }

  //创建时间
  String getCreateNickName() {
    if (createdBy.noValue) return '';

    final userinfo = Db.userInfoBox?.get(createdBy);
    return userinfo?.showName(guildId: guildId);
  }

  String getTitle() {
    return title ?? "文档已被删除".tr;
  }

  Widget docStatus() {
    final style = TextStyle(
      fontSize: 12,
      color: Get.theme.iconTheme.color.withOpacity(0.8),
    );
    if (role == null) {
      return Text('', style: style);
    } else if (role == TcDocGroupRole.edit) {
      return Text('可编辑'.tr, style: style);
    } else {
      return Text('可阅读'.tr, style: style);
    }
  }
}
