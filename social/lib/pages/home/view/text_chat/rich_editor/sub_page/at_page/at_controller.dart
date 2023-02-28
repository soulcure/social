import 'package:get/get.dart';
import 'package:im/common/permission/permission.dart';
import 'package:im/common/permission/permission_model.dart';
import 'package:im/common/permission/permission_utils.dart';
import 'package:im/pages/guild_setting/role/role.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/pages/home/model/text_channel_controller.dart';
import 'package:im/pages/search/model/search_model.dart';
import 'package:im/utils/im_utils/channel_util.dart';
import 'package:im/utils/string_filter_utils.dart';
import 'package:im/widgets/segment_list/segment_member_list_view_model.dart';

/// todo @binary.weng 思考如果进一步通用化
///富文本编辑：艾特列表Controller
class AtController extends GetxController {
  static int updateIdMentionEveryone = 0;
  static int updateIdMentionRoles = 1;
  static int updateIdAtUsers = 2;

  static AtController get to => Get.find();

  bool mentionAll = true;

  ///角色 list
  List<Role> roles = [];

  ///全体成员
  Role everyoneRole;

  final List<Role> _allRoles = [];

  ///可能@的人 list
  List<String> atList = [];
  final List<String> _atList = [];

  final ChatChannel channel;

  final searchInputModel = SearchInputModel();

  bool isAllowMentionRole = false;

  AtController(this.channel);

  @override
  void onInit() {
    if (channel != null &&
        channel.type != ChatChannelType.dm &&
        channel.type != ChatChannelType.guildCircle) {
      _assignRoles();
    }

    ///初始化 可能@的人
    if (channel != null) {
      _atList.addAll(ChannelUtil.instance.getGuildAtUserIdList(
          channel.type != ChatChannelType.group_dm
              ? channel.guildId
              : channel.id));
    }
    _getAtUsers(null);

    /// 临时： 群聊不支持at全体成员
    mentionAll =
        TextChannelController.dmChannel?.type != ChatChannelType.group_dm;

    /// 此订阅会被 searchInputModel.dispose 关闭，不需要单独关闭
    searchInputModel.searchStream.listen((event) {
      _checkMentionAll(event);
      _checkMentionRoles(event);
      _getAtUsers(event);
    });

    super.onInit();
  }

  @override
  void onClose() {
    searchInputModel.dispose();
    super.onClose();
  }

  void _assignRoles() {
    final guildPermission = PermissionModel.getPermission(channel.guildId);
    isAllowMentionRole = PermissionUtils.oneOf(
        guildPermission, [Permission.MENTION_EVERYONE],
        channelId: channel.id);
    if (guildPermission.roles.isNotEmpty && isAllowMentionRole) {
      everyoneRole = guildPermission.roles.last;
      _allRoles.addAll(guildPermission.roles.where((element) {
        if (element.id == channel.guildId) {
          return false; //不显示全体成员，需要独立添加
        }
        return !PermissionUtils.isRoleDisabledInChannel(guildPermission,
            Permission.VIEW_CHANNEL.value, channel.id, element.id);
      }));
      roles = _allRoles;
    }
  }

  void _checkMentionAll(String input) {
    final res = input.isEmpty || StringFilterUtils.checkMatch("全体成员".tr, input);
    update([updateIdMentionEveryone], res != mentionAll);
    mentionAll = res &&
        TextChannelController.dmChannel?.type != ChatChannelType.group_dm;
  }

  void _checkMentionRoles(String input) {
    if (input.isEmpty)
      roles = _allRoles;
    else
      roles = _allRoles
          .where((e) => StringFilterUtils.checkMatch(e.name, input))
          .toList(growable: false);
    update([updateIdMentionRoles]);
  }

  ///可能@的人: 搜索时不显示, 成员数为1时不显示
  void _getAtUsers(String input) {
    atList = (input == null || input.isEmpty) ? _atList : [];
    update([updateIdAtUsers]);
  }

  ///web端调用
  void loadAtUsers() {
    _atList.clear();
    _atList.addAll(ChannelUtil.instance.getGuildAtUserIdList(
        channel.type != ChatChannelType.group_dm
            ? channel.guildId
            : channel.id));
  }

  int get memberNum {
    try {
      final memberListModel = Get.find<SegmentMemberListViewModel>(
          tag: '${channel.guildId}-${channel.id}');
      return memberListModel.dataModel.memberCount;
    } catch (e) {
      return 0;
    }
  }
}
