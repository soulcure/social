import 'package:flutter/material.dart';

class TcDocGroup {
  final String groupId;
  final String fileId;
  final TcDocGroupType type;
  final TcDocGroupRole role;
  final String targetId;

  TcDocGroup({
    this.groupId,
    @required this.fileId,
    @required this.type,
    @required this.role,
    @required this.targetId,
  });

  TcDocGroup copyWith({
    String groupId,
    String fileId,
    String type,
    TcDocGroupRole role,
    String targetId,
  }) {
    return TcDocGroup(
        groupId: groupId ?? this.groupId,
        fileId: fileId ?? this.fileId,
        type: type ?? this.type,
        role: role ?? this.role,
        targetId: targetId ?? this.targetId);
  }

  Map<String, dynamic> toJson() {
    return {
      'group_id': groupId,
      'file_id': fileId,
      'type': type.toInt(),
      'role': role.toInt(),
      'target_id': targetId,
    };
  }

  Map<String, dynamic> toBatchJson() {
    return {
      'type': type.toInt(),
      'role': role.toInt(),
      'target_id': targetId,
    };
  }

  static TcDocGroup fromJson(Map<String, dynamic> json) {
    return TcDocGroup(
      groupId: json['group_id'],
      fileId: json['file_id'],
      type: TcDocGroupTypeExtension.fromInt(json['type']),
      role: TcDocGroupRoleExtension.fromInt(json['role']),
      targetId: json['target_id'],
    );
  }
}

enum TcDocGroupRole {
  view,
  edit,
}

extension TcDocGroupRoleExtension on TcDocGroupRole {
  static TcDocGroupRole fromInt(int val) {
    if (val == null) return null;
    if (val > 0 && val <= TcDocGroupRole.values.length) {
      return TcDocGroupRole.values[val - 1];
    }
    return TcDocGroupRole.view;
  }

  int toInt() {
    final idx = TcDocGroupRole.values.indexOf(this);
    return idx + 1;
  }

  String toText() {
    if (this == TcDocGroupRole.view) {
      return '可查看';
    } else if (this == TcDocGroupRole.edit) {
      return '可编辑';
    }
    return '';
  }
}

enum TcDocGroupType {
  guild,
  channel,
  role,
  user,
}

extension TcDocGroupTypeExtension on TcDocGroupType {
  static TcDocGroupType fromInt(int val) {
    if (val > 0 && val <= TcDocGroupType.values.length) {
      return TcDocGroupType.values[val - 1];
    }
    return TcDocGroupType.user;
  }

  int toInt() {
    final idx = TcDocGroupType.values.indexOf(this);
    return idx + 1;
  }
}
