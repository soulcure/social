import 'package:date_format/date_format.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:im/app/modules/document_online/document_enum_defined.dart';
import 'package:im/app/modules/document_online/entity/create_doc_item.dart';
import 'package:im/app/modules/tc_doc_add_group_page/entities/tc_doc_group.dart';
import 'package:im/common/extension/string_extension.dart';
import 'package:im/db/db.dart';
import 'package:im/icon_font.dart';
import 'package:im/locale/message_keys.dart';
import 'package:im/svg_icons.dart';
import 'package:im/themes/custom_color.dart';
import 'package:im/widgets/highlight_text.dart';
import 'package:intl/intl.dart';
import 'package:websafe_svg/websafe_svg.dart';

import '../../../../global.dart';
import 'doc_info_item.dart';

// {
// "viewed_at": "1652773206635",
// "collected_at": "1652773211874",
// "file_id": "300000000$DJUwaDrdyokk",
// "guild_id": "312107634121506816",
// "dir_id": 0,
// "user_id": "232744506837958656",
// "group_id": "1526467028446642176",
// "title": "2244",
// "type": "doc",
// "url": "https://test.fanbook.mobi/doc/300000000$DJUwaDrdyokk",
// "tx_url": "https://docs.qq.com/doc/DREpVd2FEcmR5b2tr",
// "policy": 3,
// "can_reader_comment": 1,
// "created_at": "1652773074492",
// "updated_at": "1652773074492",
// "created_by": "232744506837958656",
// "updated_by": "232744506837958656"
// }

class DocItem {
  String fileId;
  String guildId;
  String userId;
  String groupId;
  int dirId;
  String title;
  DocType type;
  String url;
  int policy;
  int createdAt;
  int updatedAt;
  String createdBy;
  String updatedBy;
  int collectedAt;
  int viewedAt;
  String txUrl;
  TcDocGroupRole role;
  bool canCopy;
  bool canReaderComment;

  DocItem({
    this.fileId,
    this.guildId,
    this.userId,
    this.groupId,
    this.dirId,
    this.title,
    this.type,
    this.url,
    this.policy,
    this.canCopy,
    this.canReaderComment, //阅读者是否可以批注，现在默认都可以
    this.createdAt,
    this.updatedAt,
    this.createdBy,
    this.updatedBy,
    this.collectedAt,
    this.viewedAt,
    this.txUrl,
    this.role,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['file_id'] = fileId;
    data['guild_id'] = guildId;
    data['user_id'] = userId;
    data['group_id'] = groupId;
    data['dir_id'] = dirId;
    data['title'] = title;
    data['type'] = DocTypeExtension.name(type);
    data['url'] = url;
    data['policy'] = policy;
    data['can_copy'] = canCopy ? 1 : 0;
    data['can_reader_comment'] = canReaderComment ? 1 : 0;
    data['created_at'] = createdAt?.toString();
    data['updated_at'] = updatedAt?.toString();
    data['created_by'] = createdBy;
    data['updated_by'] = updatedBy;
    data['collected_at'] = collectedAt?.toString();
    data['viewed_at'] = viewedAt?.toString();
    data['tx_url'] = txUrl;
    data['role'] = role?.index;
    return data;
  }

  factory DocItem.fromMap(Map<String, dynamic> map) {
    return DocItem(
        fileId: map['file_id'] as String,
        guildId: map['guild_id'] as String,
        userId: map['user_id'] as String,
        groupId: map['group_id'] as String,
        dirId: map['dir_id'] as int,
        title: map['title'] as String,
        type: DocTypeExtension.fromString(map['type']),
        url: map['url'] as String,
        policy: map['policy'] as int,
        canCopy: map['can_copy'] == 1,
        canReaderComment: map['can_reader_comment'] == 1,
        createdAt: int.tryParse(map['created_at'] ?? ''),
        updatedAt: int.tryParse(map['updated_at'] ?? ''),
        createdBy: map['created_by'] as String,
        updatedBy: map['updated_by'] as String,
        collectedAt: int.tryParse(map['collected_at'] ?? ''),
        viewedAt: int.tryParse(map['viewed_at'] ?? ''),
        txUrl: map['tx_url'] as String,
        role: TcDocGroupRoleExtension.fromInt(map['role']));
  }

  factory DocItem.fromCreate(CreateDocItem item) {
    return DocItem(
      fileId: item.fileId,
      guildId: item.guildId,
      userId: item.userId,
      groupId: item.groupId,
      title: item.title,
      type: item.type,
      url: item.url,
      policy: item.policy,
      createdAt: item.createdAt,
      updatedAt: item.updatedAt,
      createdBy: item.createdBy,
      viewedAt: item.updatedAt,
      canCopy: item.canCopy,
      canReaderComment: item.canReaderComment,
    );
  }

  factory DocItem.fromInfo(DocInfoItem item) {
    return DocItem(
      fileId: item.fileId,
      guildId: item.guildId,
      userId: item.userId,
      title: item.title,
      type: item.type,
      createdAt: item.createdAt,
      createdBy: item.createdBy,
      role: item.role,
      url: item.url,
      updatedAt: item.updatedAt,
      viewedAt: item.viewedAt,
      //DocItem和DocInfoItem 对应不上的字段
      //updatedAt: item.updatedBy, //DocItem和DocInfoItem 对应不上的字段

      // viewedBy: item.viewedBy, //DocItem和DocInfoItem 对应不上的字段
      // viewList: item.viewList, //DocItem和DocInfoItem 对应不上的字段

      collectedAt: item.collectedAt,
      canCopy: item.canCopy,
      canReaderComment: item.canReaderComment,
    );
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

  String getOwnerNickName() {
    if (userId.noValue) return '';

    final userinfo = Db.userInfoBox?.get(userId);
    return userinfo?.showName(guildId: guildId);
  }

  String getCreateNickName() {
    if (createdBy.noValue) return '';

    final userinfo = Db.userInfoBox?.get(createdBy);
    return userinfo?.showName(guildId: guildId);
  }

  String getUpdateTime() {
    if (updatedAt == null) return '';
    return getTimeString(updatedAt);
  }

  String getViewTime() {
    if (viewedAt == null) return '';
    return getTimeString(viewedAt);
  }

  String getCreateTime() {
    return getTimeString(createdAt);
  }

  String getCollectTime() {
    if (collectedAt == null) return '';
    return getTimeString(collectedAt);
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

  ///userId为文档所有者，可以被转让
  bool get isCreator => userId == Global?.user?.id;

  Widget getDocIcon({double size = 32}) {
    Widget icon;
    switch (type) {
      case DocType.doc:
        icon = WebsafeSvg.asset(SvgIcons.doc, width: size, height: size);
        break;
      case DocType.sheet:
        icon = WebsafeSvg.asset(SvgIcons.sheet, width: size, height: size);
        break;
      case DocType.form:
        icon = WebsafeSvg.asset(SvgIcons.form, width: size, height: size);
        break;
      case DocType.slide:
        icon = WebsafeSvg.asset(SvgIcons.slide, width: size, height: size);
        break;
      case DocType.mind:
        icon = WebsafeSvg.asset(SvgIcons.mind, width: size, height: size);
        break;
      case DocType.flowchart:
        icon = WebsafeSvg.asset(SvgIcons.flowchart, width: size, height: size);
        break;
      default:
        icon = WebsafeSvg.asset(SvgIcons.doc, width: size, height: size);
        break;
    }
    return icon;
  }

  Widget getDocTitle() {
    return Text(
      title,
      maxLines: 2,
      style: const TextStyle(
        fontSize: 16,
        height: 20 / 16,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget getDocSubTitle({EntryType entryType}) {
    final List<Widget> children = [];
    final color = Get.theme.disabledColor;

    createdBy ??= Global.user.id;
    if (createdBy == Global.user.id) {
      children.add(Text('我'.tr));
      children.add(Text('创建'.tr));
    } else {
      final userInfo = Db.userInfoBox.get(createdBy);
      final nickname = userInfo?.showName(guildId: guildId);
      children.add(Text(nickname ?? ''));
      children.add(Text('创建'.tr));
    }

    children.add(SizedBox(
      height: 13,
      child: VerticalDivider(
        width: 12.5,
        thickness: 0.5,
        color: color,
      ),
    ));

    ///文档列表功能移除文档的编辑或共享状态
    // if (canReaderComment == 1) {
    //   children.add(Text('所有人可编辑'.tr));
    // } else {
    //   children.add(Text('指定人共享'.tr));
    // }

    // children.add(SizedBox(
    //   height: 13,
    //   child: VerticalDivider(
    //     width: 12.5,
    //     thickness: 0.5,
    //     color: color,
    //   ),
    // ));

    if (entryType == EntryType.view)
      children.add(Text(getViewTime()));
    else if (entryType == EntryType.collect)
      children.add(Text(getCollectTime()));
    else
      children.add(Text(getUpdateTime()));

    children.addAll(getCollect());

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: DefaultTextStyle(
          style: TextStyle(
            fontSize: 12,
            height: 14 / 12,
            color: Get.textTheme.headline2.color,
          ),
          child: Row(children: children)),
    );
  }

  List<Widget> getCollect() {
    if (isCollect()) {
      return [
        SizedBox(
          height: 13,
          child: VerticalDivider(
            width: 12.5,
            thickness: 0.5,
            color: Get.theme.disabledColor,
          ),
        ),
        const Icon(
          IconFont.buffCollect,
          color: CustomColor.collect,
          size: 14,
        )
      ];
    }
    return [const SizedBox()];
  }

  Widget getHighlightTitle(String keyword) {
    const contentStyle = TextStyle(color: Colors.black, fontSize: 16);
    final highlightStyle =
        TextStyle(color: Get.theme.primaryColor, fontSize: 16);

    return HighlightText(
      title,
      keyword: keyword,
      style: contentStyle,
      highlightStyle: highlightStyle,
      maxLines: 2,
    );
  }

  ///  一分钟内（包含60s）：刚刚
  ///  一小时内（包含60m）：x分钟前
  ///  今天内（自然日）：x小时前
  ///  昨天：昨天+时分
  ///  昨天之前：x月x日
  ///  去年及去年以前：x年x月x日
  static String getTimeString(int time) {
    final now = DateTime.now();
    final updateTime = DateTime.fromMillisecondsSinceEpoch(time);
    final Duration duration = now.difference(updateTime);

    final inSeconds = duration.inSeconds;
    if (inSeconds <= 60) {
      return '刚刚'.tr;
    }

    final inMinutes = duration.inMinutes;
    if (inMinutes <= 60) {
      return '%s分钟前'.trArgs([inMinutes.toString()]);
    }

    final inHours = duration.inHours;
    final inDays = duration.inDays;

    if (inDays == 0) {
      return '%s小时前'.trArgs([inHours.toString()]);
    } else if (inDays == 1) {
      final String time = DateFormat.Hm().format(updateTime);
      return '${'昨天'.tr} $time';
    } else {
      ///不在同一年
      final bool crossYear = now.year != updateTime.year;
      final List<String> timeFormat = crossYear
          ? [yyyy, "年".tr, m, "月".tr, d, "日".tr]
          : [m, "月".tr, d, "日".tr];

      String timeString;
      if (Get.locale.languageCode == MessageKeys.zh) {
        timeString = formatDate(updateTime, timeFormat);
      } else {
        if (crossYear) {
          timeString = DateFormat.yMMMd().format(updateTime);
        } else {
          timeString = DateFormat.MMMd().format(updateTime);
        }
      }
      return timeString;
    }
  }
}
