import 'package:flutter/cupertino.dart';
import 'package:im/common/permission/permission_mixin.dart';

abstract class PermissionState<T extends StatefulWidget> extends State<T>
    with GuildPermissionListener {
  @mustCallSuper
  String guildId;

  @override
  void initState() {
    addPermissionListener();
    initPermissionState();
    super.initState();
  }

  ///  已经调用父类的initState方法，子类不需要再调用
  void initPermissionState();

  @override
  void dispose() {
    disposePermissionListener();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    throw UnimplementedError();
  }

  void onPermissionStateChange();

  @override
  void onPermissionChange() {
    if (mounted) onPermissionStateChange();
  }

  @override
  String get guildPermissionMixinId => guildId;
}
