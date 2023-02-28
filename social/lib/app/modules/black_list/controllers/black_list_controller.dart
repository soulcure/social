import 'package:get/get.dart';
import 'package:im/app/modules/black_list/black_item.dart';
import 'package:im/app/modules/black_list/black_list_api.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

const int LOAD_SIZE = 30;

class BlackListController extends GetxController {
  int curPage = 1; //默认第1页开始
  int total = 0; //总黑名单个数
  final List<BlackItem> users = [];

  bool noData = false;
  String guildId;

  final RefreshController refreshController = RefreshController();

  @override
  void onInit() {
    super.onInit();
    onLoading();
  }

  void onLoading() {
    guildId ??= Get.arguments;
    _reqData(guildId);
  }

  Future<void> _reqData(String guildId) async {
    final Map res =
        await BlackListApi.getBlackList(guildId, curPage, LOAD_SIZE);
    if (res != null && res.isNotEmpty) {
      total = res['total'];
      final List temp = res['list'];
      if (temp != null && temp.isNotEmpty) {
        final test = temp.map((e) => BlackItem.fromMap(e)).toList();
        users.addAll(test);
      }

      if (users.length < total) {
        refreshController.loadComplete();
        curPage++;
        update();
        return;
      }
    }

    refreshController.loadNoData();
    noData = true;
    update();
  }

  void removeItem(BlackItem item) {
    users.remove(item);
    total--;
    update();
  }
}
