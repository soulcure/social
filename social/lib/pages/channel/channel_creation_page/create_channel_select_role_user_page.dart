import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/api/channel_api.dart';
import 'package:im/api/data_model/user_info.dart';
import 'package:im/api/role_api.dart';
import 'package:im/common/permission/permission.dart';
import 'package:im/common/permission/permission_model.dart';
import 'package:im/common/permission/permission_utils.dart';
import 'package:im/core/http_middleware/http.dart';
import 'package:im/global.dart';
import 'package:im/pages/channel/channel_creation_page/create_channel_controller.dart';
import 'package:im/pages/channel/select_role_user_page.dart';
import 'package:im/pages/guild_setting/role/role.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/utils/utils.dart';
import 'package:im/widgets/app_bar/appbar_action_model.dart';
import 'package:im/widgets/app_bar/appbar_builder.dart';
import 'package:oktoast/oktoast.dart';

class CreateChannelRoleOrUserSelectPage extends SelectRoleUserPage {
  CreateChannelRoleOrUserSelectPage(String guildId, String cateId, {Key key})
      : super(key: key, guildId: guildId, cateId: cateId) {
    final c = Get.find<CreateChannelController>();
    if (c != null) {
      c.clearSelected();
    }
  }

  @override
  _CreateChannelRoleOrUserSelectPageState createState() =>
      _CreateChannelRoleOrUserSelectPageState();
}

class _CreateChannelRoleOrUserSelectPageState
    extends SelectRoleUserPageState<CreateChannelRoleOrUserSelectPage> {
  @override
  void initState() {
    super.initState();

    RoleApi.getList(
            guildId: widget.guildId, showDefaultErrorToast: false, size: 999)
        .then((_roleMemberNumList) {
      final List<Role> roleList =
          List.from(PermissionModel.getPermission(widget.guildId).roles);
      _roleMemberNumList.forEach((element) {
        for (final role in roleList) {
          if (role.id == element.id) {
            role.memberCount = element.memberCount;
            role.hoist = element.hoist;
            role.managed = element.managed;
            break;
          }
        }
      });
      setState(() {});
    });
  }

  @override
  List<UserInfo> filterUser(List<UserInfo> users) {
    /// 创建频道过滤掉自己
    final creatorId = Global.user.id;
    return users.where((e) => e.userId != creatorId).toList();
  }

  @override
  Widget appBar() {
    return PreferredSize(
      preferredSize: const Size(double.infinity, kFbAppBarHeight),
      child: GetBuilder<CreateChannelController>(
          id: CreateChannelController.createButtonTag,
          builder: (c) {
            return FbAppBar.custom(
              '选择角色或成员'.tr,
              actions: [
                if (selectedUserIds.isEmpty && selectedRoleIds.isEmpty)
                  AppBarTextLightActionModel('跳过'.tr,
                      isLoading: c.createLoading,
                      isEnable: !c.createLoading, actionBlock: () {
                    createChannel(c);
                  })
                else
                  AppBarTextPrimaryActionModel('保存'.tr,
                      isLoading: c.createLoading,
                      isEnable: !c.createLoading, actionBlock: () {
                    createChannel(c);
                  })
              ],
            );
          }),
    );
  }

  Future<void> createChannel(CreateChannelController c) async {
    FocusScope.of(context).unfocus();
    final resp = await create();
    if (resp.code == CreateChannelResponse.CodeSuccess) {
      Get.back(result: resp);
    }
    showToast(resp.desc);
  }

  Future<CreateChannelResponse> create() async {
    final ctr = Get.find<CreateChannelController>();

    final _channelName = ctr.channelName.trim();

    final errMsg = ctr.checkParam([
      CreateChannelController.checkItemName,
      CreateChannelController.checkItemLink
    ]);
    if (errMsg.isNotEmpty) {
      return CreateChannelResponse(CreateChannelResponse.CodeError,
          desc: errMsg);
    }

    ctr.createLoading = true;

    try {
      List<Map<String, dynamic>> permissionOverwrites = [];
      if (ctr.isPrivateChannel) {
        permissionOverwrites = [
          {
            "id": widget.guildId,
            "action_type": "role",
            "allows": 0,
            "deny": Permission.VIEW_CHANNEL.value,
          }
        ];

        if (selectedRoleIds.isNotEmpty) {
          final List<Map<String, dynamic>> rolePermissions = selectedRoleIds
              .map((e) => {
                    "id": e,
                    "action_type": "role",
                    "allows": Permission.VIEW_CHANNEL.value,
                    "deny": 0
                  })
              .toList();

          permissionOverwrites = [...permissionOverwrites, ...rolePermissions];
        }

        // 默认加上创建者权限。所有者权限不用特别的添加
        if (!PermissionUtils.isGuildOwner(guildId: widget.guildId)) {
          selectedUserIds.add(Global.user.id);
        }

        if (selectedUserIds.isNotEmpty) {
          final List<Map<String, dynamic>> userPermissions = selectedUserIds
              .map((e) => {
                    "id": e,
                    "action_type": "user",
                    "allows": Permission.VIEW_CHANNEL.value,
                    "deny": 0
                  })
              .toList();
          permissionOverwrites = [...permissionOverwrites, ...userPermissions];
        }
        // 再清理
        if (!PermissionUtils.isGuildOwner(guildId: widget.guildId)) {
          selectedUserIds.remove(Global.user.id);
        }
      }

      final _channelLink = ctr.channelLinkBean?.toLinkString();
      final res = await ChannelApi.createChannel(widget.guildId, Global.user.id,
          _channelName, ctr.channelType, widget.cateId,
          permissionOverwrites: permissionOverwrites,
          link: _channelLink,
          showDefaultErrorToast: false);

      final _channelId = res['channel_id'];
      if (res != null && isNotNullAndEmpty(_channelId.toString())) {
        final _chatChannel = ChatChannel(
            id: _channelId,
            guildId: widget.guildId,
            name: _channelName,
            type: ctr.channelType,
            parentId: widget.cateId,
            link: _channelLink);

        // 如果有overwrite，扔到外面，通过add添加
        final overwrites = (res["permission_overwrites"] as List).map((e) {
          return PermissionOverwrite.fromJson(e);
        }).toList();

        /// 延迟 500ms 是为了服务器 push {type: string} 的消息被插入到本地数据库中
        await Future.delayed(const Duration(milliseconds: 500));

        ctr.createLoading = false;

        return CreateChannelResponse(CreateChannelResponse.CodeSuccess,
            channel: _chatChannel, overwrite: overwrites, desc: '创建成功'.tr);
      } else {
        return CreateChannelResponse(CreateChannelResponse.CodeError,
            desc: "未知错误".tr);
      }
    } catch (e) {
      final isDioError = e is DioError;
      ctr.createLoading = false;
      return CreateChannelResponse(CreateChannelResponse.CodeError,
          desc: isDioError ? networkErrorText : e?.message ?? "");
    }
  }
}
