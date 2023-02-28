import 'package:get/get.dart';
import 'package:im/api/data_model/user_info.dart';
import 'package:im/api/entity/role_bean.dart';
import 'package:im/api/guild_api.dart';
import 'package:im/common/permission/permission.dart';
import 'package:im/common/permission/permission_model.dart';
import 'package:im/common/permission/permission_utils.dart';
import 'package:im/pages/guild_setting/role/role.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/pages/home/model/input_model.dart';
import 'package:im/utils/im_utils/channel_util.dart';
import 'package:im/utils/string_filter_utils.dart';
import 'package:im/widgets/segment_list/segment_member_list_service.dart';

import '../input_model.dart';
import 'base_input_prompt_model.dart';

///消息公屏：艾特列表Model
class AtSelectorModel extends InputPromptModel<dynamic> {
  AtSelectorModel(InputModel inputModel, this.channel) : super(inputModel, "@");

  ///当前频道
  ChatChannel channel;

  ///是否群聊
  bool get _isGroupDm => channel.type == ChatChannelType.group_dm;

  ///是否圈子频道
  bool get _isCircle => channel.type == ChatChannelType.guildCircle;

  @override
  Future<List> getCompleteList() async {
    final m = SegmentMemberListService.to
        .getDataModel(channel.guildId, channel.id, channel.type);
    await m.initialized;
    final users = m.memberSnapshot();
    // 更新角色
    users.forEach((u) {
      // 当用户没有任何角色时，成员列表返回的角色为null，需要给默认值[]
      RoleBean.update(u.userId, channel.guildId, u.roles ?? []);
    });
    final List<dynamic> res = [
      ..._getTopData(showRole: !_isGroupDm && !_isCircle),
      ListHeader('全部成员'.tr),
      ...users,
    ];
    return res;
  }

  @override
  Future<void> onMatch(String match) async {
    final matchList = [];
    matchList
        .addAll(_getTopData(match: match, showRole: !_isGroupDm && !_isCircle));
    try {
      final gid = _isGroupDm ? channel.id : channel.guildId;
      List remoteResult;
      if (_isGroupDm) {
        ///群聊：需要传 channelId
        remoteResult = await GuildApi.searchMembers(gid, match, channelId: gid);
      } else {
        remoteResult =
            await GuildApi.searchMembers(gid, match, isNeedRoles: true);
      }
      matchList.addAll(remoteResult);
    } catch (e) {
      // print('getChat at - onMatch e:$e');
    }
    list = [];
    list.addAll(matchList);
    visible = list.isNotEmpty;
  }

  ///获取'全部成员'上面的数据<p>
  ///match 搜索的字符
  ///showRole 是否显示角色
  ///showAt 如果成员数为1，不显示'可能@的人'
  List _getTopData({String match, bool showRole = true}) {
    // print('getChat at - match:$match, showRole:$showRole');
    final list = [];
    final guildPermission =
        showRole ? PermissionModel.getPermission(channel.guildId) : null;

    ///艾特角色的权限
    final atPermission = showRole
        ? PermissionUtils.oneOf(guildPermission, [Permission.MENTION_EVERYONE],
            channelId: channel.id)
        : null;

    ///全体成员
    if (showRole && atPermission && guildPermission.roles.isNotEmpty) {
      ///全体成员是最后一个角色
      final allRole = guildPermission.roles.last;
      if (match == null || StringFilterUtils.checkMatch(allRole.name, match)) {
        list.add(allRole);
      }
    }

    ///可能@的人
    if (match == null) {
      final String guildId =
          showRole || _isCircle ? channel.guildId : channel.id;
      final atList = ChannelUtil.instance.getGuildAtUserIdList(guildId);
      //  解决场景：被@过的用户在其他端被移除了服务器，本地的服务器成员列表没有展示过，导致@的时候还是会现实高亮（正常移除后不会高亮），所以需要实时更新用户角色（高亮的判断逻辑）
      atList.forEach((element) {
        UserInfo.getUserInfoRoles(element, guildId: guildId);
      });
      if (atList != null && atList.isNotEmpty) {
        list.add(ListHeader('可能@的人'.tr));
        list.addAll(atList);
      }
    }

    ///全部角色
    if (showRole && atPermission && guildPermission.roles.isNotEmpty) {
      final List<Role> roles = [];
      roles.addAll(guildPermission.roles);
      roles.removeLast();

      ///删除无查看频道权限的角色
      roles.removeWhere((e) => PermissionUtils.isRoleDisabledInChannel(
          guildPermission, Permission.VIEW_CHANNEL.value, channel.id, e.id));
      roles.retainWhere(
          (e) => match == null || StringFilterUtils.checkMatch(e.name, match));
      if (roles.isNotEmpty) {
        if (match == null) list.add(ListHeader('全部角色'.tr));
        list.addAll(roles);
      }
    }

    return list;
  }
}

class ListHeader {
  String name;

  ListHeader(this.name);
}
