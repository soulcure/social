import 'package:flutter/material.dart';
import 'package:im/api/entity/role_bean.dart';
import 'package:im/common/permission/permission.dart';
import 'package:im/common/permission/permission_model.dart';
import 'package:im/global.dart';
import 'package:im/pages/guild_setting/role/role.dart';
import 'package:im/pages/home/model/chat_index_model.dart';
import 'package:im/pages/home/model/chat_target_model.dart';

class PermissionUtils {
  // userId
  static bool isGuildOwner({String userId, String guildId}) {
    BaseChatTarget target;
    if (guildId == null) {
      target = ChatTargetsModel.instance.selectedChatTarget;
    } else {
      target = ChatTargetsModel.instance.getChatTarget(guildId);
    }
    if (target == null || target.runtimeType != GuildTarget) return false;
    userId ??= Global.user.id;
    return (target as GuildTarget).ownerId == userId;
  }

  static bool isAdmin({String userId, GuildPermission gp}) {
    final int permissions = computeBasePermission(gp, userId: userId);
    final isAdmin = contains(permissions, Permission.ADMIN.value);
    return isAdmin;
  }

  static int computeBasePermission(GuildPermission permission,
      {String excludeRoleId, String userId}) {
    final roles = permission.roles
        .where((element) => element.id != excludeRoleId)
        .toList();
    int permissions = 0;

    List<String> userRoles;
    // 自己的角色，暂时还是从permission.userRoles中取
    if (userId != null && userId != Global.user.id.toString()) {
      userRoles = [...RoleBean.get(userId, permission.guildId) ?? []];
    } else {
      userRoles = [...permission.userRoles];
    }
    // 先对everyOne角色进行处理，再进行其他角色的逻辑
    final everyOneRole = roles.firstWhere(
        (element) => element.id == permission.guildId,
        orElse: () => null);
    if (everyOneRole != null) permissions |= everyOneRole.permissions;

    if (userRoles.contains(permission.guildId))
      userRoles.remove(permission.guildId);
    for (final roleId in userRoles) {
      final Role role = roles.firstWhere((element) => element.id == roleId,
          orElse: () => null);
      if (role != null) permissions |= role.permissions;
    }
    return permissions;
  }

  /// - isCirclePermission: 是否是圈子权限
  static int computeOverwrite(GuildPermission gp, String channelId,
      {String excludeRoleId, String userId}) {
    int permissions =
        computeBasePermission(gp, excludeRoleId: excludeRoleId, userId: userId);

    // 查找频道、话题里面是否是有权限覆盖
    final List<PermissionOverwrite> overwrites = gp.channelPermission
            ?.firstWhere((element) => element.channelId == channelId,
                orElse: () => null)
            ?.overwrites ??
        [];

    final roleIds = gp.roles
        .where((element) => element.id != excludeRoleId)
        .map((e) => e.id)
        .toList();

    List<String> sUserRoles;
    // 自己的角色，暂时还是从permission.userRoles中取
    if (userId != null && userId != Global.user.id.toString()) {
      sUserRoles = [...RoleBean.get(userId, gp.guildId) ?? []];
    } else {
      sUserRoles = [...gp.userRoles];
    }
    // 先对everyOne角色进行处理，再进行其他角色的逻辑
    final everyOneOW = overwrites.firstWhere(
        (element) => element.actionType == 'role' && element.id == gp.guildId,
        orElse: () => null);
    if (everyOneOW != null) {
      // 合并拒绝、允许权限
      permissions &= ~everyOneOW.deny;
      permissions |= everyOneOW.allows;
    }
    // 计算覆盖的角色
    int allow = 0;
    int deny = 0;
    if (sUserRoles.contains(gp.guildId)) sUserRoles.remove(gp.guildId);
    final userRoles = sUserRoles.where((e) => e != excludeRoleId).toList();
    for (final ow in overwrites
        .where((element) =>
            element.actionType == 'role' &&
            userRoles.contains(element.id) &&
            roleIds.contains(element.id))
        .toList()) {
      // 需过滤掉跟自己无关的角色
      allow |= ow.allows;
      deny |= ow.deny;
    }

    permissions &= ~deny;
    permissions |= allow;

    // 计算覆盖的个人权限
    userId ??= Global.user.id.toString();
    final PermissionOverwrite ov = overwrites
        .firstWhere((element) => element.id == userId, orElse: () => null);
    if (ov != null) {
      permissions &= ~ov.deny;
      permissions |= ov.allows;
    }
    return permissions;
  }

  static bool oneOf(GuildPermission gp, List<Permission> list,
      {String channelId, String userId}) {
    if (isGuildOwner(userId: userId, guildId: gp?.guildId)) return true;
    if (isAdmin(userId: userId, gp: gp)) return true;
    if (gp == null) return false;
    if (channelId == null) {
      final int permissions = computeBasePermission(gp, userId: userId);
      final isAllowed =
          list.any((element) => contains(permissions, element.value));
      return isAllowed;
    } else {
      final int permissions = computeOverwrite(
        gp,
        channelId,
        userId: userId,
      );
      final isAllowed =
          list.any((element) => contains(permissions, element.value));
      return isAllowed;
    }
  }

  static bool all(
    GuildPermission gp,
    List<Permission> list, {
    String channelId,
    String userId,
  }) {
    if (isGuildOwner()) return true;
    if (isAdmin(userId: userId, gp: gp)) return true;

    if (gp == null) return false;
    if (channelId == null) {
      final int permissions = computeBasePermission(gp, userId: userId);
      return list.every((element) => contains(permissions, element.value));
    } else {
      final int permissions = computeOverwrite(gp, channelId, userId: userId);
      return list.every((element) => contains(permissions, element.value));
    }
  }

  static bool contains(int permissions, int permission) {
    return permissions & permission > 0;
  }

  /// 获取用户角色列表里最高的position, roleIds不传表示取当前用户的position
  static int getMaxRolePosition(
      {GuildPermission guildPermission, List<String> roleIds}) {
    guildPermission ??= PermissionModel.getPermission(
        ChatTargetsModel.instance.selectedChatTarget.id);
    // 服务器创建者
    if (isGuildOwner() && roleIds == null) return 99999;
    final roleList = (roleIds ?? guildPermission.userRoles).map((e) {
      final role = guildPermission.roles
          .firstWhere((element) => element.id == e, orElse: () => null);
      return role?.position ?? 0;
    }).toList();
    roleList.sort();
    return roleList.isEmpty ? 0 : roleList.last;
  }

  /// 对比当前用户 和 另一用户的position，-1 小于，0 等于， 1大于
  static int comparePosition({GuildPermission gp, List<String> roleIds}) {
    gp ??= PermissionModel.getPermission(
        ChatTargetsModel.instance.selectedChatTarget.id);
    final int myMaxRolePosition = getMaxRolePosition(guildPermission: gp);
    final int otherMaxRolePosition =
        getMaxRolePosition(guildPermission: gp, roleIds: roleIds);
    return myMaxRolePosition.compareTo(otherMaxRolePosition);
  }

  static Color getRoleColor(List<String> roleIds) {
    if (roleIds == null) return null;

    final gp = PermissionModel.getPermission(
        ChatTargetsModel.instance?.selectedChatTarget?.id);
    final List<Role> roles =
        gp.roles.where((e) => roleIds.contains(e.id))?.toList();
    if (roles.isEmpty) {
      return null;
    } else {
      for (final role in roles) {
        /// 该用户该角色在角色列表中显示
        if (role.hoist == null || role.hoist == false) {
          /// 角色色值不为空时返回对应的色值
          /// 角色色值为空就返回 null,外层逻辑有默认颜色处理
          return role.color != 0 ? Color(role.color) : null;
        }
      }
      return null;
    }
  }

  // 是否有管理成员的权限
  static bool isManager({GuildPermission gp}) {
    gp ??= PermissionModel.getPermission(
        ChatTargetsModel.instance.selectedChatTarget.id);
    if (gp == null) {
      return false;
    }
    return PermissionUtils.oneOf(gp, [Permission.MANAGE_ROLES]);
  }

  // 全体成员不能修改的权限
  static bool isEveryoneDisablePermission(Permission p) {
    return [
      Permission.KICK_MEMBERS,
      Permission.MANAGE_ROLES,
      Permission.MANAGE_MESSAGES,
      Permission.MANAGE_GUILD,
      Permission.MANAGE_CIRCLES,
      Permission.MANAGE_CHANNELS,
      Permission.MANAGE_EMOJIS,
      Permission.ADMIN,
      Permission.MUTE_MEMBERS,
      Permission.MOVE_MEMBERS,
      Permission.MUTE,
    ].contains(p);
  }

  // 是否用户有权限
  static bool isChannelVisible(
    GuildPermission gp,
    String channelId, {
    String userId,
  }) {
    return PermissionUtils.oneOf(gp, [Permission.VIEW_CHANNEL],
        channelId: channelId, userId: userId);

    // 先注释，看服务器端下发的情况，如果使用上面的逻辑，将在聊天界面的逻辑判断不准确
    // // TODO 可能会更新设计，目前的逻辑是，公开频道直接就是可见的。即使你单独设置了这个人
    // if(PermissionUtils.isPrivateChannel(gp, channelId)){
    //   return PermissionUtils.oneOf(gp, [Permission.VIEW_CHANNEL],
    //       channelId: channelId, userId: userId);
    // }else{
    //   return true;
    // }
  }

  // 判断是否为私密频道（everyOne的VIEW权限未false）
  // 只看VIEW_CHANNEL是否有，且配置为false。不看角色，不看个人属性
  static bool isPrivateChannel(GuildPermission gp, String channelId) {
    if (gp == null) return false;
    if (channelId == null) {
      return false;
    } else {
      List<PermissionOverwrite> overwrites = gp.channelPermission
              .firstWhere((element) => element.channelId == channelId,
                  orElse: () => null)
              ?.overwrites ??
          [];

      // TODO 使用 overwrites.retainWhere 代替
      // 过滤出"全体成员".tr角色设置为"deny"的"overwrites"
      overwrites = overwrites.where((element) {
        if (element.actionType == 'role' && element.id == gp.guildId) {
          if (element.deny & Permission.VIEW_CHANNEL.value > 0) {
            return true;
          }
          return false;
        } else {
          return false;
        }
      }).toList();
      if (overwrites.isNotEmpty) {
        return true;
      } else {
        return false;
      }
    }
  }

  // 查看某个角色的某个权限是否被禁用
  static bool isRoleDisabledInChannel(
      GuildPermission gp, int permission, String channelId, String roleId) {
    if (gp == null || channelId == null || roleId == null) return false;

    final List<PermissionOverwrite> overwrites = gp.channelPermission
            .firstWhere((element) => element.channelId == channelId,
                orElse: () => null)
            ?.overwrites ??
        [];
    if (overwrites.isEmpty) return false;

    final PermissionOverwrite roleOverwrite = overwrites.firstWhere(
        (e) => e.actionType == "role" && e.id == roleId,
        orElse: () => null);
    if (roleOverwrite != null && (permission & ~roleOverwrite.deny) == 0) {
      // 渠道配置，本角色明确禁止
      return true;
    } else if (roleOverwrite != null &&
        (permission & roleOverwrite.allows) > 0) {
      // 渠道配置，本角色明确同意
      return false;
    }

    // 不管everyOne角色。只看确定的角色
    // // 本角未配置/继承，看EveryOne角色设置
    // final PermissionOverwrite everyOneOverwrite = overwrites.firstWhere(
    //     (e) => e.actionType == "role" && e.id == gp.guildId,
    //     orElse: () => null);
    // if (everyOneOverwrite != null &&
    //     (permission & ~everyOneOverwrite.deny) == 0) {
    //   // 渠道配置，everyOne明确禁止
    //   return true;
    // } else if (everyOneOverwrite != null &&
    //     (permission & everyOneOverwrite.allows) > 0) {
    //   // 渠道配置，everyOne明确同意
    //   return false;
    // }

    // 渠道均未配置，看服务器配置
    int guildPermissions = 0;
    final role = gp.roles
        .firstWhere((element) => element.id == roleId, orElse: () => null);
    if (role != null) guildPermissions |= role.permissions;

    // 不看服务器中everyOne配置
    // final everyOneRole = gp.roles
    //     .firstWhere((element) => element.id == gp.guildId, orElse: () => null);
    // if (everyOneRole != null) guildPermissions |= everyOneRole.permissions;

    if (permission & guildPermissions > 0) {
      return false;
    } else {
      return true;
    }
  }

  // 频道是否真实的公开频道（真正的全员可见）
  static bool isChannelActuallyPublic(GuildPermission gp, String channelId) {
    if (gp == null) return false;
    if (channelId == null || channelId.isEmpty) return false;

    return false;
  }

  // 判断服务器台和频道的某个权限
  static bool hasPermission({
    @required Permission permission,
    String guildId,
    String channelId,
  }) {
    final gid = guildId ?? ChatTargetsModel.instance.selectedChatTarget?.id;
    if (gid == null) return false;
    final gp = PermissionModel.getPermission(gid);
    return PermissionUtils.oneOf(gp, [permission], channelId: channelId);
  }

  // 获取某个角色
  static Role getRole(String guildId, String roleId) {
    final gp = PermissionModel.getPermission(guildId);
    return gp.roles.firstWhere((r) => r.id == roleId, orElse: () => null);
  }
}
