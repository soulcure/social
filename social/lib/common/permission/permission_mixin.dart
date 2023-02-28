import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:im/common/permission/permission.dart';
import 'package:im/db/db.dart';
import 'package:hive_flutter/hive_flutter.dart';

mixin GuildPermissionListener {
  ValueListenable<Box<GuildPermission>> _box;
  GuildPermission _gp;

  GuildPermission get guildPermission => _gp;

  void addPermissionListener() {
    if (guildPermissionMixinId != null) {
      // 频道权限
      _box = Db.guildPermissionBox.listenable(keys: [guildPermissionMixinId]);
      _box.removeListener(_onChange);
      _box.addListener(_onChange);
      _gp = Db.guildPermissionBox.get(guildPermissionMixinId);
    }
  }

  void _onChange() {
    _gp = Db.guildPermissionBox.safeGet(guildPermissionMixinId);
    onPermissionChange();
  }

  void onPermissionChange();

  @mustCallSuper
  void disposePermissionListener() {
    _box?.removeListener(_onChange);
  }

  String get guildPermissionMixinId;
}
