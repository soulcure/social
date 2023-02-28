import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:im/common/permission/permission_utils.dart';
import 'package:im/db/db.dart';
import 'package:im/pages/guild_setting/role/role.dart';
import 'package:im/pages/home/model/chat_index_model.dart';
import 'package:im/pages/home/model/chat_target_model.dart';

part 'permission.g.dart';

// ignore_for_file: non_constant_identifier_names

class Permission {
  int value;
  List<ChatChannelType> channelType;

  // 服务器下面展示的名称
  String name1;

//  频道下面展示的名称
  String name2;

//  服务器下面展示的描述
  String desc1;

//  频道下面的描述
  String desc2;

  Permission._(this.value,
      {this.channelType = const [],
      this.name1,
      this.name2,
      this.desc1,
      this.desc2});

  static Permission CREATE_INSTANT_INVITE = Permission._(
    0x00000001,
    name1: '创建邀请'.tr,
    desc1: '拥有此权限的成员，可以邀请好友加入服务器'.tr,
    desc2: '拥有此权限的成员，可以邀请好友加入频道'.tr,
  );

  static Permission KICK_MEMBERS = Permission._(0x00000002,
      name1: '移出成员'.tr, desc1: '拥有此权限的成员，可以移出角色列表中低于该角色的其他角色中的成员'.tr);

  static Permission BAN_MEMBERS =
      Permission._(0x00000004, name1: '封锁成员'.tr, desc1: '');

  static Permission MANAGE_CHANNELS = Permission._(
    0x000000010,
    name1: '管理频道'.tr,
    name2: '编辑频道资料'.tr,
    desc1: '拥有此权限的成员，可以创建新的频道分类和频道，以及修改已存在的频道分类和频道的排序、名称、频道主题，或删除'.tr,
    desc2: '拥有此权限的成员，可以更改频道名字、主题，删除频道；该权限继承服务器下的“管理频道”'.tr,
  );

  static Permission MANAGE_GUILD = Permission._(0x000000020,
      name1: '管理服务器'.tr,
      desc1: '拥有此权限的成员，可以修改服务器名称头像和背景图，修改服务器欢迎语开关，修改欢迎语显示的频道，查看服务器数据'.tr);

  // static Permission GUILD_OPT_DATA =
  //     Permission._(0x000000020, name1: '服务器数据'.tr, desc1: '拥有此权限的成员，可以查看服务器运营数据');

  static Permission ADD_REACTIONS = Permission._(0x000000040,
      channelType: [ChatChannelType.guildText], name1: '消息表态'.tr, desc1: '');

  static Permission VIEW_AUDIT_LOG =
      Permission._(0x000000080, name1: '查看审计日志'.tr, desc1: '');

  static Permission CREATE_LIVE_ROOM = Permission._(
    0x00000100,
    name1: '开启直播'.tr,
    desc1: '拥有此权限的成员，可以在此频道内开启直播'.tr,
  );

  // 禁言
  static Permission MUTE = Permission._(
    0x00800000,
    name1: '禁言'.tr,
    desc1: '可以禁言在角色列表中低于该角色的其他成员；禁言范围包括频道聊天和圈子互动'.tr,
  );

  // static Permission CREATE_LIVE_ROOM = Permission._(
  //   0x00000100,
  //   channelType: [ChatChannelType.guildLive],
  //   name1: '直播间开播'.tr,
  //   desc1: '拥有此权限的成员，可以在服务器直播频道中开启直播'.tr,
  // );

  // static Permission STREAM = Permission._(0x000000200,
  //     channelType: [ChatChannelType.text], name: '', desc: '');

  static Permission VIEW_CHANNEL = Permission._(0x000000400,
      name1: '查看频道'.tr,
      desc1: '拥有此权限的成员，可以进入并查看频道消息'.tr,
      desc2: '拥有此权限的成员，可以进入并查看频道消息'.tr);

  static Permission SEND_MESSAGES = Permission._(0x000000800,
      channelType: [ChatChannelType.guildText], name1: '发送消息'.tr, desc1: '');

  static Permission SEND_TTS_MESSAGES = Permission._(0x000001000,
      channelType: [ChatChannelType.guildText],
      name1: '发送语音转文字消息'.tr,
      desc1: '');

  static Permission MANAGE_MESSAGES = Permission._(
    0x000002000,
    channelType: [ChatChannelType.guildText],
    name1: '管理消息'.tr,
    desc1: '拥有此权限的成员，可以撤回在角色列表中低于该角色的其他角色发出的消息，以及pin和置顶消息'.tr,
    desc2: '拥有此权限的成员，可以撤回在角色列表中低于该角色的其他角色发出的消息，以及pin和置顶消息'.tr,
  );

  static Permission EMBED_LINKS = Permission._(0x00004000,
      channelType: [ChatChannelType.guildText], name1: '嵌入链接'.tr, desc1: '');

  static Permission ATTACH_FILES = Permission._(0x00008000,
      channelType: [ChatChannelType.guildText], name1: '添加附件'.tr, desc1: '');

  static Permission READ_MESSAGE_HISTORY = Permission._(0x00010000,
      channelType: [ChatChannelType.guildText], name1: '查看历史消息'.tr, desc1: '');

  static Permission MENTION_EVERYONE = Permission._(0x00020000,
      channelType: [ChatChannelType.guildText],
      name1: '@全体成员、@某个角色'.tr,
      desc1: '');

  static Permission USE_EXTERNAL_EMOJIS = Permission._(0x00040000,
      channelType: [ChatChannelType.guildText], name1: '使用外部表情'.tr, desc1: '');

  // static const Permission VIEW_GUILD_INSIGHTS = Permission._(0x00 080000,
  //     channelType: [ChatChannelType.text], name: '', desc: '');

  static Permission CONNECT = Permission._(0x00100000,
      channelType: [ChatChannelType.guildVoice],
      name1: '进入语音频道'.tr,
      desc1: '拥有此权限的成员，可以进入语音频道'.tr);

  static Permission SPEAK = Permission._(0x00200000,
      channelType: [ChatChannelType.guildVoice],
      name1: '发言'.tr,
      desc1: '拥有此权限的成员，可以开启麦克风进行发言'.tr);

  static Permission MUTE_MEMBERS = Permission._(0x00400000,
      channelType: [ChatChannelType.guildVoice],
      name1: '闭麦成员'.tr,
      desc1: '拥有此权限的成员，可以将当前频道内所有成员的麦克风关闭，拥有发言权限的用户可以主动开麦'.tr);

  // static const Permission DEAFEN_MEMBERS = Permission._(0x00800000,
  //     channelType: [ChatChannelType.text], name: '屏蔽成员语音接收', desc: '');

  static Permission MOVE_MEMBERS = Permission._(0x01000000,
      channelType: [ChatChannelType.guildVoice],
      name1: '移除成员'.tr,
      desc1: '拥有此权限的成员，可以将无此权限的成员移出语音频道'.tr);

  // static const Permission USE_VAD = Permission._(0x02000000,
  //     channelType: [ChatChannelType.text], name: '', desc: '');

  static Permission CHANGE_NICKNAME =
      Permission._(0x04000000, name1: '修改昵称'.tr, desc1: '');

  static Permission MANAGE_NICKNAMES =
      Permission._(0x08000000, name1: '管理昵称'.tr, desc1: '');

  static Permission MANAGE_ROLES = Permission._(0x10000000,
      name1: '管理角色'.tr,
      desc1: '拥有此权限的成员，可以创建新的角色，以及编辑/删除在角色列表中低于该角色的其他角色'.tr,
      name2: '管理频道权限'.tr,
      desc2:
          '拥有此权限的成员，可以在当前频道范围内，管理其他角色的权限（其中，其他角色在角色列表中低于该角色及成员，权限只能是该角色及成员已拥有的）；该权限继承服务器下的“管理角色”'
              .tr);

  static Permission MANAGE_WEBHOOKS =
      Permission._(0x20000000, name1: '管理webhook'.tr, desc1: '');

  static Permission MANAGE_EMOJIS = Permission._(0x40000000,
      name1: '管理服务器表情'.tr, desc1: '拥有此权限的成员，可以设置服务器专属表情'.tr);

  // static const Permission MANAGE_GUILD_EDIT = Permission._(
  //   0x80000000,
  //   name1: '编辑服务器资料',
  //   desc1: '拥有此权限的成员，可以修改服务器头像、名称',
  // );

  static Permission MANAGE_CIRCLES = Permission._(
    0x80000000,
    name1: '管理圈子'.tr,
    desc1: '拥有此权限的成员，可以修改圈子资料、设置圈子置顶、删除动态和回复'.tr,
  );

  static Permission CREATE_DOCUMENT = Permission._(
    0x00008000,
    name1: '创建在线文档'.tr,
    desc1: '拥有此权限的成员，可以在服务器内创建在线文档'.tr,
  );

  static Permission CIRCLE_POST = Permission._(
    0x00001000,
    channelType: [ChatChannelType.guildCircleTopic],
    name1: '发布动态'.tr,
    desc1: '拥有此权限的成员，可以在圈子中发布动态'.tr,
  );

  static Permission CIRCLE_REPLY = Permission._(
    0x00000200,
    channelType: [ChatChannelType.guildCircleTopic],
    name1: '回复动态'.tr,
    desc1: '拥有此权限的成员，可以对动态进行回复'.tr,
  );

  static Permission CIRCLE_ADD_REACTION = Permission._(
    0x00080000,
    channelType: [ChatChannelType.guildCircleTopic],
    name1: '点赞动态'.tr,
    desc1: '拥有此权限的成员，可以对动态点赞'.tr,
  );

  /// 超级管理员
  /// 无法管理服务器同级管理员
  /// 无法解散服务器
  static Permission ADMIN = Permission._(
    0x00000008,
    channelType: [],
    name1: '超级管理员'.tr,
    desc1: '拥有此权限的成员将具有完整的管理权限，也能绕开频道的特定权限或限制（比如：访问所有私密频道）。此权限属于高危权限，请谨慎授予'.tr,
  );
}

@HiveType(typeId: 4)
class GuildPermission extends HiveObject {
  @HiveField(0)
  final String guildId;
  @HiveField(1)
  final String ownerId;
  @HiveField(2)
  int permissions;

  // 用户在该服务器下的角色
  @HiveField(3, defaultValue: [])
  List<String> userRoles;

  // 服务器的所有角色id
  @HiveField(4, defaultValue: [])
  List<Role> roles;
  @HiveField(5, defaultValue: [])
  final List<ChannelPermission> channelPermission;

  // 获取可以分配的角色（不包含机器人角色）
  List<Role> get rolesUnManaged => roles
      .where((element) => element.managed != true && element.id != guildId)
      .toList(growable: false);

  // 获取除所有人以外的角色
  List<Role> get rolesExcludeEveryone =>
      roles.where((element) => element.id != guildId).toList(growable: false);

  // @HiveField(6) 已经1.6.50 用过

  GuildPermission({
    @required this.guildId,
    @required this.permissions,
    @required this.ownerId,
    this.userRoles = const [],
    this.roles = const [],
    this.channelPermission = const [],
  });

  // 浅拷贝
  GuildPermission clone() {
    return GuildPermission(
      guildId: guildId,
      permissions: permissions,
      ownerId: ownerId,
      userRoles: [...userRoles],
      roles: [...roles],
      channelPermission: [...channelPermission],
    );
  }

  GuildPermission deepCopy() {
    final List<ChannelPermission> tempChannelPermission = [];
    channelPermission.forEach((e) {
      final List<PermissionOverwrite> tempOverwrites = [];
      e.overwrites.forEach((element) {
        tempOverwrites.add(element.copyWith());
      });

      tempChannelPermission
          .add(e.copyWith(channelId: e.channelId, overwrites: tempOverwrites));
    });

    final List<Role> tempRoleList = [];
    roles.forEach((element) {
      tempRoleList.add(element.clone());
    });

    return GuildPermission(
      guildId: guildId,
      permissions: permissions,
      ownerId: ownerId,
      userRoles: userRoles,
      roles: tempRoleList,
      channelPermission: tempChannelPermission,
    );
  }
}

@HiveType(typeId: 6)
class ChannelPermission {
  @HiveField(0)
  final String channelId;

  // 角色和成员
  @HiveField(1)
  final List<PermissionOverwrite> overwrites;

  ChannelPermission({@required this.channelId, this.overwrites = const []});

  ChannelPermission copyWith(
      {String channelId, List<PermissionOverwrite> overwrites}) {
    return ChannelPermission(channelId: channelId, overwrites: overwrites);
  }
}

@HiveType(typeId: 7)
class PermissionOverwrite {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String guildId;
  @HiveField(2)
  final String channelId;
  @HiveField(3)
  int deny;
  @HiveField(4)
  int allows;
  @HiveField(5)
  final String actionType;
  @HiveField(6)
  final String name;

  @HiveField(7)
  PermissionOverwrite({
    @required this.id,
    @required this.guildId,
    @required this.channelId,
    @required this.deny,
    @required this.allows,
    @required this.actionType,
    @required this.name,
  });

  Map<Object, Object> toJson() => {
        id: id,
        guildId: guildId,
        channelId: channelId,
        name: name,
        deny: deny,
        allows: allows,
        actionType: actionType,
      };

  factory PermissionOverwrite.fromJson(Map<String, dynamic> json) {
    return PermissionOverwrite(
      id: json['id'],
      guildId: json['guild_id'],
      channelId: json['channel_id'],
      name: json['name'],
      deny: json['deny'],
      allows: json['allows'],
      actionType: json['action_type'],
    );
  }

  PermissionOverwrite copyWith({int allows, int deny}) {
    return PermissionOverwrite(
      id: id,
      guildId: guildId,
      channelId: channelId,
      name: name,
      deny: deny ?? this.deny,
      allows: allows ?? this.allows,
      actionType: actionType,
    );
  }
}

/// 角色权限分类枚举
/// 通用、文字频道、语音频道、视频频道、圈子频道、高级权限
enum PermissionType {
  general,
  text,
  voice,
  video,
  topic,
  advance,
}

List<Permission> buffPermissions = [
  Permission.VIEW_CHANNEL,
  Permission.MANAGE_GUILD,
  Permission.CREATE_INSTANT_INVITE,
  Permission.MANAGE_CHANNELS,
  Permission.MANAGE_ROLES,
  Permission.KICK_MEMBERS,

  Permission.READ_MESSAGE_HISTORY,
  Permission.SEND_MESSAGES,
  Permission.ADD_REACTIONS,
//  Permission.VIEW_AUDIT_LOG,
//  Permission.SEND_TTS_MESSAGES,
  Permission.MANAGE_MESSAGES,
//  Permission.EMBED_LINKS,
//  Permission.ATTACH_FILES,
  Permission.MENTION_EVERYONE,
//  Permission.USE_EXTERNAL_EMOJIS,
//  Permission.CHANGE_NICKNAME,
//  Permission.MANAGE_NICKNAMES,
//  Permission.MANAGE_WEBHOOKS,
  Permission.MANAGE_EMOJIS,
  Permission.MANAGE_CIRCLES,
  Permission.CREATE_DOCUMENT,
  Permission.CREATE_LIVE_ROOM,
  // Permission.TEXT_CHANNEL_LIVE,
  Permission.MUTE,
  Permission.CONNECT,
  Permission.SPEAK,
  Permission.MOVE_MEMBERS,
  Permission.MUTE_MEMBERS,

  Permission.CIRCLE_POST,
  Permission.CIRCLE_REPLY,
  Permission.CIRCLE_ADD_REACTION,
  Permission.ADMIN,
];
// 分类权限
Map<PermissionType, List<Permission>> classifyPermissions = {
  // 通用权限，原定通用权限是指各种类型的频道都适用的权限
  // 超级管理员权限特殊处理
  PermissionType.general: buffPermissions
      .where((e) => e.channelType.isEmpty && e != Permission.ADMIN)
      .toList(),
  // 文字频道权限
  PermissionType.text: buffPermissions
      .where((e) => e.channelType.contains(ChatChannelType.guildText))
      .toList(),
  //  音频房间权限
  PermissionType.voice: buffPermissions
      .where((e) => e.channelType.contains(ChatChannelType.guildVoice))
      .toList(),
  //  圈子权限
  PermissionType.topic: buffPermissions
      .where((e) => e.channelType.contains(ChatChannelType.guildCircleTopic))
      .toList(),
  // 高级权限
  PermissionType.advance: [
    Permission.ADMIN,
  ],
};
//分类权限在服务器和频道显示不同，过滤掉不需要的权限
Map<PermissionType, List<Permission>> canOverwritePermissions = {
  PermissionType.general: classifyPermissions[PermissionType.general]
      .where(
        (ele) => ![
          Permission.MANAGE_GUILD,
          Permission.MANAGE_CIRCLES,
          Permission.KICK_MEMBERS,
          Permission.MANAGE_EMOJIS,
          Permission.ADMIN,
        ].contains(ele),
      )
      .toList(),
  PermissionType.text: classifyPermissions[PermissionType.text],
  PermissionType.voice: classifyPermissions[PermissionType.voice],
  PermissionType.topic: classifyPermissions[PermissionType.topic],
};

/// - 判断权限集合是不是圈子权限
bool isTopicPermission(List<Permission> permissionList) {
  if (permissionList == null || permissionList.isEmpty) {
    return false;
  }
  for (final item in permissionList) {
    if (!classifyPermissions[PermissionType.topic].contains(item)) {
      return false;
    }
  }
  return true;
}

enum ValidType { all, oneOf }

/// TODO: 最好能够知道是哪个权限发生变化了，使用数组形式传递到外层
typedef PermissionBuilder = Widget Function(bool value, bool isOwner);

class ValidPermission extends StatefulWidget {
  /// 需要的权限
  final List<Permission> permissions;
  final PermissionBuilder builder;

  /// 判断类型 oneOf：符合一个即返回ture，否则返回false；all：符合所有才返回true，否则返回false；
  final ValidType validType;

  /// 服务台ID，默认是当前服务台，但是私信列表的圈子消息可能是其他服务台的
  final String guildId;

  /// 指定要计算的channelId
  final String channelId;

  const ValidPermission({
    @required this.permissions,
    @required this.builder,
    this.guildId,
    this.channelId,
    this.validType = ValidType.oneOf,
    Key key,
  }) : super(key: key);

  @override
  _ValidPermissionState createState() => _ValidPermissionState();
}

class _ValidPermissionState extends State<ValidPermission> {
  ValueListenable<Box<GuildPermission>> _permissionBox;

  /// NOTE(jp@jin.dev): 2022/5/27 在Home页面更新一次的情况下，总是获取准确的guildId
  String get guildId =>
      widget.guildId ?? ChatTargetsModel.instance.selectedChatTarget?.id;

  @override
  void initState() {
    if (guildId == null) return;

    /// FIXME(jp@jin.dev): 2022/5/27 此处权限模型实际一直使用的是另外一个服务器的
    /// 会导致其他端修改了权限，实际监听不到对应的服务器权限模型
    _permissionBox = Db.guildPermissionBox.listenable(keys: [guildId]);

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    /// FIXME(jp@jin.dev): 2022/5/27 同上，_permissionBox不准确
    if (_permissionBox == null) {
      return widget.builder(true, false);
    }

    return ValueListenableBuilder<Box<GuildPermission>>(
      valueListenable: _permissionBox,
      builder: (context, box, w) {
        final gp = box.safeGet(guildId);
        if (gp == null) {
          return widget.builder(false, PermissionUtils.isGuildOwner());
        }
        bool isAllowed;
        if (widget.validType == ValidType.all) {
          isAllowed = PermissionUtils.all(
            gp,
            widget.permissions,
            channelId: widget.channelId,
          );
        } else {
          isAllowed = PermissionUtils.oneOf(
            gp,
            widget.permissions,
            channelId: widget.channelId,
          );
        }
        return widget.builder(isAllowed, PermissionUtils.isGuildOwner());
      },
    );
  }
}
