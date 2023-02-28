import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/api/circle_api.dart';
import 'package:im/api/entity/role_bean.dart';
import 'package:im/api/role_api.dart';
import 'package:im/common/extension/string_extension.dart';
import 'package:im/common/permission/permission.dart';
import 'package:im/db/db.dart';
import 'package:im/global.dart';
import 'package:im/pages/guild_setting/role/role.dart';
import 'package:im/pages/home/json/text_chat_json.dart';
import 'package:rxdart/rxdart.dart';
import 'package:tuple/tuple.dart';

import '../../loggers.dart';

class PermissionModel {
  // Tuple3<guildId, channelId, MessageAction>
  // ignore: close_sinks
  static BehaviorSubject<Tuple3<String, String, String>> selfChangeStream =
      BehaviorSubject<Tuple3<String, String, String>>();
  static BehaviorSubject<Tuple2<String, Map<String, dynamic>>> allChangeStream =
      BehaviorSubject<Tuple2<String, Map<String, dynamic>>>();

  static void initGuildPermission({
    @required String guildId,
    @required String ownerId,
    @required int permissions,
    @required List<dynamic> userRoles,
    @required List<dynamic> roles,
    @required List<dynamic> channels,
  }) {
    final List<Role> newRoles = roles.map((e) => Role.fromJson(e)).toList();
    newRoles.sort((a, b) => b.position.compareTo(a.position));

    RoleBean.update(Global.user.id, guildId, List.from(userRoles));

    PermissionModel.updatePermission(
      GuildPermission(
        guildId: guildId,
        ownerId: ownerId,
        permissions: permissions,
        userRoles: [...userRoles, guildId],
        roles: [
          ...newRoles,
          Role(
              id: guildId,
              name: '全体成员'.tr,
              position: 0,
              permissions: permissions),
        ],
        channelPermission: channels.map(
          (c) {
            final List<PermissionOverwrite> overwrites =
                ((c['overwrite'] ?? []) as List).map((e) {
              return PermissionOverwrite.fromJson(e);
            }).toList();
            final everyoneIdx =
                overwrites.indexWhere((element) => element.id == guildId);
            final PermissionOverwrite everyone = PermissionOverwrite(
                id: guildId,
                channelId: c['channel_id'],
                guildId: guildId,
                actionType: 'role',
                allows: 0,
                deny: 0,
                name: '全体成员'.tr);
            return ChannelPermission(
              channelId: c['channel_id'],
//              name: c['name'],
              overwrites:
                  everyoneIdx >= 0 ? overwrites : [...overwrites, everyone],
            );
          },
        ).toList(),
      ),
    );
  }

  static GuildPermission getPermission(String guildId) {
    if (guildId == null)
      return GuildPermission(guildId: '0', permissions: 0, ownerId: '0');
    final gp = Db.guildPermissionBox?.get(guildId,
        defaultValue:
            GuildPermission(guildId: '0', permissions: 0, ownerId: '0'));
    return gp;
  }

  static void removePermission(String guildId) {
    Db.guildPermissionBox.delete(guildId);
  }

  static Future<void> updatePermission(GuildPermission newer) async {
    await Db.guildPermissionBox.put(newer.guildId, newer);
  }

  static void initChannelPermission(String guildId, String channelId,
      List<PermissionOverwrite> initPermissions) {
    final GuildPermission gp = getPermission(guildId);
    final GuildPermission newer = gp.clone();
    final index = newer.channelPermission
        .indexWhere((element) => element.channelId == channelId);
    if (index < 0) {
      if (initPermissions == null || initPermissions.isEmpty) {
        final PermissionOverwrite everyone = PermissionOverwrite(
            id: guildId,
            channelId: channelId,
            guildId: guildId,
            actionType: 'role',
            allows: 0,
            deny: 0,
            name: '全体成员'.tr);
        initPermissions = [everyone];
      }
      final ChannelPermission cp =
          ChannelPermission(channelId: channelId, overwrites: initPermissions);
      newer.channelPermission.add(cp);
      updatePermission(newer);
    }
  }

  // 修改角色列表
  static Future<void> updateRoles(String guildId, List<Role> roles) async {
    final GuildPermission gp = getPermission(guildId);
    final GuildPermission newer = gp.clone();
    newer.roles = roles;
    await updatePermission(newer);
  }

  static Future<Role> updateRole(String guildId, String roleId,
      {int permissions,
      int color,
      String name,
      int position,
      bool mentionable,
      bool hoist}) async {
    final res = await RoleApi.save(guildId, Global.user.id, roleId,
        permissions: permissions,
        color: color,
        name: name,
        mentionable: mentionable,
        hoist: hoist);
    final gp = getPermission(guildId);
    if (gp != null) {
      final roleIdx = gp.roles.indexWhere((element) => element.id == roleId);

      if (roleIdx >= 0) {
        /// 角色修改逻辑
        final Role role = gp.roles[roleIdx];
        final Role newer = Role(
          id: role.id,
          name: name ?? role.name,
          position: position ?? role.position,
          permissions: permissions ?? role.permissions,
          color: color ?? role.color,
          mentionable: mentionable ?? role.mentionable,
          hoist: hoist ?? role.hoist,
        );
        gp.roles[roleIdx] = newer;
      } else {
        /// 角色创建
        final Role newer = Role.fromJson(res);

        final _list = gp.roles;

        final index = _list.length - 1;
        if (newer.id.isNotEmpty) {
          _list.insert(index > 0 ? index : 0, newer);
        }

        /// 创建完角色需要对角色进行角色排序
        for (var i = 0; i < _list.length; i++) {
          _list[i].setPosition(_list.length - i - 1);
        }
      }

      await updateRoles(guildId, gp.roles);
    }
    return Role.fromJson(res);
  }

  static void removeRole(String guildId, Role role) {
    final gp = getPermission(guildId);
    if (gp != null) {
      gp.roles.removeWhere((element) => element.id == role.id);
      for (var i = 0; i < gp.roles.length; i++) {
        role.position = gp.roles.length - i - 1;
      }
      // 删除角色需遍历删除频道覆盖权限相关的role
      gp.channelPermission.forEach((cp) {
        cp.overwrites.removeWhere((ov) => ov.id == role.id);
      });
      updateRoles(guildId, gp.roles);
    }
  }

  /// - 更新覆盖权限
  /// - isCirclePermission：是否是圈子权限
  static Future<void> updateOverwrite(PermissionOverwrite ov,
      {bool isCirclePermission = false}) async {
    await RoleApi.updateOverwrite(
      id: ov.id,
      userId: Global.user.id,
      channelId: ov.channelId,
      guildId: ov.guildId,
      actionType: ov.actionType,
      allows: ov.allows,
      deny: ov.deny,
    );

    final gp = getPermission(ov.guildId).clone();
    if (gp != null) {
      final channelPermission = gp.channelPermission.firstWhere(
          (element) => element.channelId == ov.channelId,
          orElse: () => null);
      if (channelPermission == null) return;
      final oldOverwriteIdx = channelPermission.overwrites
          .indexWhere((element) => element.id == ov.id);
      if (oldOverwriteIdx >= 0) {
        channelPermission.overwrites
          ..removeAt(oldOverwriteIdx)
          ..insert(oldOverwriteIdx, ov);
      } else {
        channelPermission.overwrites.add(ov);
      }
      await updatePermission(gp);
    }
  }

  static Future<void> updateOverwrites(List<PermissionOverwrite> ovs) async {
    // 判空逻辑
    final channelId = ovs.first?.channelId;
    final guildId = ovs.first?.guildId;
    if (channelId.noValue || guildId.noValue) return;
    // 构建数据
    final permissionOverwrites = ovs
        .map((e) => {
              'id': e.id,
              'action_type': e.actionType,
              'allows': e.allows,
              'deny': e.deny
            })
        .toList();

    final res = await RoleApi.updateOverwrites(
      channelId: channelId,
      guildId: guildId,
      permissionOverwrites: permissionOverwrites,
    );

    final gp = getPermission(guildId).clone();
    if (gp != null) {
      final channelPermission = gp.channelPermission
          .firstWhere((e) => e.channelId == channelId, orElse: () => null);

      if (channelPermission == null) return;
      final List<String> failureIds = res['failure'].cast<String>();

      // 整合原来的权限，对修改的进行统一处理
      ovs.forEach((e) {
        // 过滤掉修改失败的操作
        if (failureIds.contains(e.id)) return;

        final index = channelPermission.overwrites
            .indexWhere((element) => element.id == e.id);
        // 原来有就更新，无就添加
        if (index >= 0) {
          channelPermission.overwrites[index].allows = e.allows;
          channelPermission.overwrites[index].deny = e.deny;
        } else {
          channelPermission.overwrites.add(e);
        }
      });
      // 更新该频道所有权限，统一更新
      await updatePermission(gp);
    }
  }

  static Future<void> onGuildChange(
      String messageAction, Map<String, dynamic> data) async {
    final String guildId = data['guild_id'];
    final String channelId = data['channel_id'];
    bool isSelfChanged = true;
    switch (messageAction) {
      case MessageAction.roleUp:
        final Map<String, dynamic> roleData = data['roles'];
        await _onRoleChange(guildId, roleData);
        break;
      case MessageAction.rolesUpdate:
        final List<Role> roles =
            (data['roles'] as List).map((e) => Role.fromJson(e)).toList();
        await _onRolesChange(guildId, roles);
        break;
      case MessageAction.userRolesUpdate:
        final List<String> roles = (data['roles'] as List)
            .cast<Map>()
            .map((e) => e['role_id'] as String)
            .toList();
        final String userId = data['user_id'];
        if (userId == Global.user.id) {
          await _onUserRolesChange(guildId, roles);
          isSelfChanged = false;
        }
        break;
      case MessageAction.overwriteUpdate:
        await _onOverwriteChange(guildId, channelId, data);
        break;

      case MessageAction.overwriteDel:
        await _onOverwriteDel(guildId, channelId, data);
        break;

      case MessageAction.overwriteCircleUpdate:
        await _onOverwriteChange(
          guildId,
          channelId,
          data,
          isCirclePermission: true,
        );
        break;

      default:
    }
    if (isSelfChanged) {
      selfChangeStream.add(Tuple3(guildId, channelId, messageAction));
    }
    allChangeStream.add(Tuple2(messageAction, data));
  }

  static Future<void> _onRolesChange(
      String guildId, List<Role> changeRoles) async {
    final gp = getPermission(guildId);
    if (gp != null) {
      changeRoles.sort((a, b) => b.position.compareTo(a.position));
      final Role everyone = gp.roles
          .firstWhere((element) => element.id == guildId, orElse: () => null);
      await updateRoles(guildId, [...changeRoles, everyone]);
    }
  }

  static Future<void> _onUserRolesChange(
      String guildId, List<String> userRoles) async {
    final gp = getPermission(guildId);
    if (gp != null) {
      final GuildPermission newer = gp.clone();
      newer.userRoles = [...userRoles, guildId];
      await updatePermission(newer);
    }
  }

  static Future<void> _onRoleChange(String guildId, Map roleData) async {
    final gp = getPermission(guildId);
    if (gp != null) {
      final role = gp.roles.firstWhere(
          (element) => element.id == roleData['role_id'],
          orElse: () => null);
      if (role != null) {
        role.name = roleData['name'] ?? role.name;
        role.color = roleData['color'] ?? role.color;
        role.hoist = roleData['hoist'] ?? role.hoist;
        role.permissions = roleData['permissions'] ?? role.permissions;
      }
      await updateRoles(guildId, gp.roles);
    }
  }

  /// - isCirclePermission 是否是圈子权限变更
  static Future<void> _onOverwriteChange(
      String guildId, String channelId, Map overwriteData,
      {bool isCirclePermission = false}) async {
    final gp = getPermission(guildId)?.clone();
    if (gp != null) {
      final channelPermission = gp.channelPermission.firstWhere(
          (element) => element.channelId == overwriteData['channel_id'],
          orElse: () => null);
      if (channelPermission == null) return;
      final oldOverwriteIdx = channelPermission.overwrites.indexWhere(
        (element) => element.id == overwriteData['id'],
      );
      final PermissionOverwrite newOverwrite =
          PermissionOverwrite.fromJson(overwriteData);
      if (oldOverwriteIdx >= 0) {
        channelPermission.overwrites
          ..removeAt(oldOverwriteIdx)
          ..insert(oldOverwriteIdx, newOverwrite);
      } else {
        channelPermission.overwrites.add(newOverwrite);
      }
      await updatePermission(gp);
    }
  }

  static Future<void> _onOverwriteDel(
      String guildId, String channelId, Map overwriteData) async {
    final gp = getPermission(guildId)?.clone();
    if (gp != null) {
      final channelPermission = gp.channelPermission.firstWhere(
          (element) => element.channelId == overwriteData['channel_id'],
          orElse: () => null);
      if (channelPermission == null) return;
      final oldOverwriteIdx = channelPermission.overwrites.indexWhere(
        (element) => element.id == overwriteData['id'],
      );
      if (oldOverwriteIdx >= 0) {
        channelPermission.overwrites.removeAt(oldOverwriteIdx);
        await updatePermission(gp);
      }
    }
  }

  static void onRemoveUser(String guildId, String userId) {
    final gp = getPermission(guildId)?.clone();
    if (gp != null) {
      gp.channelPermission.forEach((element) {
        element.overwrites.removeWhere((overwrite) => overwrite.id == userId);
      });

      updatePermission(gp);
    }
  }

  /// - 更新对应服务台的话题权限
  /// - guidId: 服务台ID
  /// - permissionRes: 话题接口返回的覆盖权限json原始数据
  static void updateGuildCircleOverridePermission(
      String guildId, List<dynamic> rawRes) {
    if (rawRes == null) {
      return;
    }

    // 圈子权限
    final List<ChannelPermission> circlePermission = [];
    var guildPermission = getPermission(guildId);

    rawRes.forEach((e) {
      try {
        final list = e['overwrite'];
        List topicOverwrites = list?.map((json) {
              // 这里取 topic_id 替换到 channelId
              return PermissionOverwrite(
                id: json['id'],
                guildId: json['guild_id'],
                channelId: json['topic_id'],
                name: json['name'] ?? '',
                deny: json['deny'],
                allows: json['allows'],
                actionType: json['action_type'],
              );
            })?.toList() ??
            [];

        topicOverwrites = topicOverwrites.cast<PermissionOverwrite>();

        // 添加 全体成员 选项，
        final everyoneIndex =
            topicOverwrites.indexWhere((element) => element.id == guildId);
        if (everyoneIndex < 0) {
          // 这里取 topic_id
          final PermissionOverwrite everyone = PermissionOverwrite(
              id: guildId,
              channelId: e['topic_id'],
              guildId: guildId,
              actionType: 'role',
              allows: 0,
              deny: 0,
              name: '全体成员'.tr);
          topicOverwrites.add(everyone);
        }
        circlePermission.add(ChannelPermission(
          channelId: e['topic_id'],
          overwrites: topicOverwrites,
        ));
        // 移除老的圈子频道权限
        guildPermission.channelPermission
            .removeWhere((element) => element.channelId == e['topic_id']);
      } catch (e) {
        logger.info('permission',
            '---------updateGuildTopicOverridePermission e:${e.toString()}');
      }
    });
    guildPermission.channelPermission.addAll(circlePermission);
    if (guildPermission.guildId == '0') {
      // 如果本地缓存没有，则构建一个
      guildPermission = GuildPermission(
        guildId: guildId,
        permissions: 0,
        ownerId: '0',
        channelPermission: circlePermission,
      );
    }
    updatePermission(guildPermission);
  }

  /// - 请求对应服务台的话题权限
  /// - guidId: 服务台ID
  static Future<void> fetchGuildTopicPermission(String guildId) async {
    // 首页获取接口异常不显示异常toast
    final rawTopics =
        await CircleApi.getTopics(guildId, showDefaultErrorToast: false);
    updateGuildCircleOverridePermission(guildId, rawTopics);
  }
}
