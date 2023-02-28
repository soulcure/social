import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:im/core/config.dart';
import 'package:im/global.dart';

class ReactionItem {
  final BigInt msgId;
  String name;
  int count;
  int me;

  ReactionItem({
    this.msgId,
    this.name,
    this.count,
    this.me,
  });

  ReactionItem copyWith({
    BigInt msgId,
    String name,
    int count,
    int me,
  }) {
    return ReactionItem(
      msgId: msgId ?? this.msgId,
      name: name ?? this.name,
      count: count ?? this.count,
      me: me ?? this.me,
    );
  }

  Map<String, dynamic> toMap() {
    if (Config.env == Env.newtest ||
        Config.env == Env.dev ||
        Config.env == Env.dev2) {
      debugPrint(
          "reaction save to DB msgId=$msgId emojiName=$name count=$count me=$me");
    }
    return {
      'msgId': msgId.toInt(),
      'name': name,
      'count': count > 0 ? count : 1,
      'me': me,
    };
  }

  factory ReactionItem.fromMapOld(Map<String, dynamic> map) {
    final List<String> userList = [];
    int me = 0;
    final String users = map['users'];
    if (users != null) {
      if (users.contains(',')) {
        userList.addAll(users.split(','));
      } else {
        userList.add(users);
      }

      final index = userList.indexWhere((e) => e == Global.user.id);
      if (index > -1) {
        me = 1;
      }
    }

    final int count = userList.length;

    String name = map['name'] as String;
    try {
      name = Uri.decodeComponent(name);
    } catch (e) {
      print(e);
    }

    return ReactionItem(
      msgId: BigInt.from(map['msgId']),
      name: name,
      count: count,
      me: me,
    );
  }

  factory ReactionItem.fromMap(Map<String, dynamic> map) {
    return ReactionItem(
      msgId: BigInt.from(map['msgId']),
      name: map['name'] as String,
      count: map['count'] as int ?? 1,
      me: map['me'] as int ?? 0,
    );
  }

  String toJson() => json.encode(toMap());

  factory ReactionItem.fromJson(String source) =>
      ReactionItem.fromMap(json.decode(source));

  @override
  String toString() {
    return 'ReactionItem(msgId: $msgId, name: $name, count: $count, me: $me)';
  }
}
