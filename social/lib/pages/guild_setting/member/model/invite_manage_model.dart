import 'package:im/api/entity/invite_code.dart';
import 'package:im/api/invite_api.dart';
import 'package:im/widgets/refresh/list_model.dart';

class InviteManageModel extends ListModel<EntityInviteCode> {
  static InviteManageModel _instance;

  final String guildId;
  String listId = '0';

  List<EntityInviteCode> records = [];

  factory InviteManageModel({String guildId}) {
    if (guildId == null && _instance == null) return null;
    return _instance ?? InviteManageModel._(guildId);
  }

  InviteManageModel._(this.guildId) {
    pageSize = 50;
    fetchData = () async {
      final Map data = await InviteApi.getCodeList({
        'guild_id': guildId,
        'size': pageSize,
        'list_id': listId,
      });
      if (data != null) {
        final list = EntityInviteCodeList.fromJson(data);
        records = list.records;
        listId = list.listId;
      }
      return records;
    };
  }

  void updateItem(EntityInviteCode item, int index) {
    if (item != null) {
      internalList[index] = item;
      notifyListeners();
    }
  }

  void destroy() {
    dispose();
    _instance = null;
  }
}
