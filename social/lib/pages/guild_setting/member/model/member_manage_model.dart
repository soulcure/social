import 'package:im/api/data_model/user_info.dart';
import 'package:im/api/role_api.dart';
import 'package:im/global.dart';
import 'package:im/pages/guild_setting/role/role.dart';
import 'package:im/widgets/refresh/list_model.dart';

class MemberManageModel extends ListModel<UserInfo> {
  static MemberManageModel _instance;

  // final String guildId;
  List<Role> roles = [];

  factory MemberManageModel({String guildId}) {
    if (guildId == null && _instance == null) return null;
    return _instance ??= MemberManageModel._(guildId);
  }

  MemberManageModel._(String guildId) {
    // pageSize = 10;
    // fetchData = _getAllMembers;
    fetchData = () => _getAllMembers(guildId);
  }

  void updateRoles(UserInfo member, List<String> roleIds) {
    final item = internalList.firstWhere(
        (element) => element.userId == member.userId,
        orElse: () => null);
    if (item != null) {
      item.roles = roleIds;
      notifyListeners();
    }
  }

  void removeMember(String memberId) {
    final item = internalList.firstWhere(
        (element) => element.userId == memberId,
        orElse: () => null);
    if (internalList.remove(item)) notifyListeners();
  }

  bool containMember(String memberId) {
    final item = internalList.firstWhere(
        (element) => element.userId == memberId,
        orElse: () => null);
    return item != null;
  }

  void destroy() {
    dispose();
    _instance = null;
  }

  Future<List<UserInfo>> _getAllMembers(String guildId) async {
    /// 搜索关键字为空，返回所有成员
    return RoleApi.getMemberList(
      guildId: guildId,
      userId: Global.user.id,
      limit: pageSize,
      lastId: internalList.isEmpty ? null : internalList.last.userId,
    );
  }
}
