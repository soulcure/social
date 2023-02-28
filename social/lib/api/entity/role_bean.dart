import 'package:flutter/cupertino.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:im/api/user_api.dart';
import 'package:im/common/extension/list_extension.dart';
import 'package:im/common/extension/string_extension.dart';
import 'package:im/db/db.dart';

part 'role_bean.g.dart';

@HiveType(typeId: 14)
class RoleBean extends HiveObject {
  @HiveField(0)
  String keyValue; // userId-guildId

  // 用户在服务器内的角色，为null表示不在服务器
  @HiveField(1)
  List<String> roleIds;

  RoleBean({
    this.keyValue,
    this.roleIds,
  });

  static final Set<String> _fetchQueue = {};
  static Future _fetchFuture;

  static String _getKey(String userId, String guildId) {
    return '$userId-$guildId';
  }

  static void set(String userId, String guildId, List<String> roleIds) {
    final key = _getKey(userId, guildId);
    RoleBean role = Db.guildRoleBox.get(key);
    if (roleIds.isEqualTo(role?.roleIds)) return;
    role ??= RoleBean(keyValue: key, roleIds: roleIds);
    role.roleIds = roleIds;

    if (role.isInBox)
      role.save();
    else
      Db.guildRoleBox.put(key, role);
  }

  static List<String> get(String userId, String guildId) {
    final key = _getKey(userId, guildId);
    return Db.guildRoleBox.get(key)?.roleIds;
  }

  // 是否包含
  static bool isContain(String userId, String guildId) {
    final key = _getKey(userId, guildId);
    return Db.guildRoleBox.containsKey(key);
  }

  // 通过角色判断是否在服务器
  static bool isInGuild(String userId, String guildId) {
    final isInGuild =
        isContain(userId, guildId) && get(userId, guildId) != null;
    return isInGuild;
  }

  /// 直接从服务器更新
  static Future<void> updateFromNet(
      {@required String userId, @required String guildId}) async {
    if (userId.noValue || guildId.noValue) return;

    _fetchQueue.add(userId);

    _fetchFuture ??= Future.delayed(const Duration(milliseconds: 100), () {
      UserApi.getUserInfo(_fetchQueue.toList(), guildId: guildId).then((list) {
        list.forEach((e) {
          if (e.roles != null) set(e.userId, guildId, e.roles);
        });
      });

      _fetchQueue.clear();
      _fetchFuture = null;
    });
  }

  /// 从消息中更新
  static void update(String userId, String guildId, List<String> roleIds) {
    if (userId.noValue || guildId.noValue) return;
    set(userId, guildId, roleIds);
  }

  static Widget consume({
    @required BuildContext context,
    @required String userId,
    String guildId,
    ValueWidgetBuilder<RoleBean> builder,
    Widget child,
    Widget placeHolder = const SizedBox(),
  }) {
    if (userId.noValue) return placeHolder;

    if (guildId.noValue) return builder(context, null, child);

    final key = '$userId-$guildId';

    if (!Db.guildRoleBox.containsKey(key))
      updateFromNet(userId: userId, guildId: guildId);

    return ValueListenableBuilder<Box<RoleBean>>(
      valueListenable: Db.guildRoleBox.listenable(keys: [key]),
      builder: (c, box, child) {
        final role = box.get(key);
        return builder(c, role ?? RoleBean(keyValue: key, roleIds: []), child);
      },
      child: child,
    );
  }
}
