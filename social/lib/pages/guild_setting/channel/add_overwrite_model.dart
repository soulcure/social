import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:im/api/data_model/user_info.dart';
import 'package:im/api/role_api.dart';
import 'package:im/common/permission/permission.dart';
import 'package:im/common/permission/permission_mixin.dart';
import 'package:im/global.dart';
import 'package:im/pages/guild_setting/role/role.dart';
import 'package:im/pages/home/model/chat_index_model.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/widgets/refresh/list_model.dart';

abstract class AddOverwriteModel<T> extends ListModel<T>
    with GuildPermissionListener {
  final String channelId;
  List<String> _existOverwriteIds;
  String currentGuildId;

  GuildPermission get gp => guildPermission;

  AddOverwriteModel({@required this.channelId}) {
    addPermissionListener();
    final List<PermissionOverwrite> overwrites = guildPermission
            .channelPermission
            .firstWhere((element) => element.channelId == channelId,
                orElse: () => null)
            ?.overwrites ??
        [];
    _existOverwriteIds = overwrites.map((e) => e.id).toList();

    pageSize = 20;
    currentGuildId =
        (ChatTargetsModel.instance.selectedChatTarget as GuildTarget)
            ?.id
            .toString();
    fetchData = getData;
  }

  Future<List<T>> getData();

  String dataIdentifier(T data);

  List get dataList {
    return internalList
      ..removeWhere((e) => _existOverwriteIds.contains(dataIdentifier(e)));
  }

  @override
  void dispose() {
    disposePermissionListener();
    super.dispose();
  }

  void refresh() {
    notifyListeners();
  }

  @override
  String get guildPermissionMixinId =>
      ChatTargetsModel.instance.selectedChatTarget.id;

  @override
  void onPermissionChange() {
    refresh();
  }
}

class AddOverwriteRoleModel extends AddOverwriteModel<Role> {
  AddOverwriteRoleModel(String channelId) : super(channelId: channelId);

  @override
  String dataIdentifier(Role data) {
    return data.id;
  }

  @override
  Future<List<Role>> getData() async {
    final res = await RoleApi.getList(
      guildId: currentGuildId,
      channelId: channelId,
      userId: Global.user.id,
      limit: pageSize,
      lastId: internalList.isEmpty ? null : internalList.last.id,
    );
    return res;
  }
}

class AddOverwriteUserModel extends AddOverwriteModel<UserInfo> {
  AddOverwriteUserModel(String channelId) : super(channelId: channelId);

  @override
  String dataIdentifier(UserInfo data) {
    return data.userId;
  }

  UnmodifiableListView<UserInfo> get users => dataList;

  @override
  Future<List<UserInfo>> getData() {
    /// 获取成员列表
    return RoleApi.getMemberList(
      guildId: currentGuildId,
      channelId: channelId,
      userId: Global.user.id,
      limit: pageSize,
      lastId: internalList.isEmpty ? null : internalList.last.userId,
    );
  }
}
