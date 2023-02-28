import 'package:im/api/data_model/user_info.dart';
import 'package:im/api/guild_api.dart';

class SearchMemberListModel {
  final String guildId;
  final String channelId;
  String _searchKey;

  String get searchKey => _searchKey;

  SearchMemberListModel(this.guildId, {this.channelId});

  /// 根据关键字搜索成员
  Future<List<UserInfo>> searchMembers(
    String key, {
    bool isNeedRole = false,
  }) async {
    _searchKey = key;
    if (key == null || key.isEmpty) {
      return null;
    }
    return GuildApi.searchMembers(guildId, key,
        isNeedRoles: isNeedRole, channelId: channelId);
  }
}
