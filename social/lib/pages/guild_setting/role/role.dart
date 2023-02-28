import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

part 'role.g.dart';

@HiveType(typeId: 5)
class Role {
  @HiveField(0)
  final String id;
  @HiveField(1)
  String name;

  // 用来标记该角色是否在成员列表显示 (null / false为显示 true 为不显示)
  @HiveField(2)
  bool hoist;
  @HiveField(3)
  int color;
  @HiveField(4)
  int position;
  @HiveField(5)
  int permissions;
  // 添加机器人自动生成的角色managed为ture
  @HiveField(6)
  bool managed;
  @HiveField(7)
  final bool mentionable;
  @HiveField(8)
  int memberCount;

  Role({
    @required this.id,
    @required this.name,
    @required this.position,
    this.hoist = false,
    this.color = 0,
    this.permissions = 0,
    this.managed = false,
    this.mentionable = true,
    this.memberCount = 0,
  });

  Role clone() {
    return Role(
      id: id,
      name: name,
      position: position,
      hoist: hoist,
      color: color,
      permissions: permissions,
      managed: managed,
      mentionable: mentionable,
      memberCount: memberCount,
    );
  }

  // ignore: use_setters_to_change_properties
  void setPosition(int index) {
    position = index;
  }

  // ignore: use_setters_to_change_properties
  void setPermissions(int permissionsValue) {
    permissions = permissionsValue;
  }

  factory Role.fromJson(Map json) {
    return Role(
      id: json['role_id'],
      name: json['name'],
      position: json['position'],
      hoist: json['hoist'],
      color: json['color'],
      permissions: json['permissions'],
      managed: json['managed'] ?? false,
      mentionable: json['mentionable'],
      memberCount: json['member_count'],
    );
  }

  bool equal(Role role) {
    if (id == role.id &&
        name == role.name &&
        position == role.position &&
        hoist == role.hoist &&
        color == role.color &&
        permissions == role.permissions &&
        managed == role.managed &&
        mentionable == role.mentionable) return true;
    return false;
  }
}
