import 'package:get/get.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';
import 'package:im/api/entity/mute_list_bean.dart';
import 'package:im/api/mute_list_api.dart';
import 'package:im/common/permission/permission_utils.dart';
import 'package:im/global.dart';
import 'package:im/pages/home/model/chat_index_model.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

/// - 描述：禁言列表
///
/// - author: seven
/// - data: 2021/12/13 11:16 上午
class MuteListController extends GetxController {
  /// - 刷新控制器
  RefreshController refreshController = RefreshController();

  /// - 默认为0，翻页时将接口返回的last_id带上
  int lastId = 0;

  /// - 禁言成员集合
  List<MuteListBean> mMuteList = [];

  static MuteListController get to {
    MuteListController c;
    try {
      c = Get.find<MuteListController>();
    } catch (_) {}
    return c ??= Get.put(MuteListController());
  }

  /// - 获取服务台Id
  String getGuildId() => ChatTargetsModel.instance.selectedChatTarget?.id;

  /// - 添加禁言
  Future<bool> addToMuteList(
      String userId, String guildId, String cycle) async {
    try {
      await MuteListApi.addToMuteList(userId, guildId, cycle);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// - 移除禁言
  Future<bool> removeFromMuteList(String userId, String guildId) async {
    try {
      await MuteListApi.removeFromMuteList(userId, guildId);
      removeMuteBean(userId);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// - 移除禁言对象
  void removeMuteBean(String userId) {
    mMuteList.remove(mMuteList.firstWhere(
        (element) => element.forbidUserId.toString() == userId,
        orElse: () => null));
    update();
  }

  /// - 获取某人的禁言时长, 等于0 ，代表没有被禁言；大于0，代表被禁言的时长，单位：秒
  Future<int> getMutedTime(String userId, String guildId) async {
    try {
      final muteString = await MuteListApi.checkIsMuted(userId, guildId);
      final int endTime = muteString['endtime'];
      return endTime;
    } catch (e) {
      return 0;
    }
  }

  /// - 刷新第一页
  Future onRefresh() async {
    lastId = 0;
    mMuteList.clear();
    await onLoadMore();
  }

  /// - 加载更多
  Future onLoadMore() async {
    final listMap = await MuteListApi.getMuteList(
      getGuildId(),
      lastId: lastId.toString(),
    );
    refreshController.loadComplete();
    if (listMap != null) {
      lastId = listMap['last_id'];
      final list = (listMap['record'] as List ?? [])
          .map((o) => MuteListBean.fromJson(o))
          .toList();
      mMuteList.addAll(list);
      if (mMuteList.length > 10 && list.isEmpty) {
        refreshController.loadNoData();
      }
    } else if (mMuteList.length > 10) {
      // 大于10条数据后，下一页接口没有数据了，显示'没有更多了'
      refreshController.loadNoData();
    }
    update();
  }

  /// - 解禁时间
  String getUnMuteTime(int endTime) {
    String unMuteTime = '';
    int lastTime;
    final day = endTime ~/ (24 * 60 * 60);
    lastTime = endTime % (24 * 60 * 60);
    if (day > 0) {
      unMuteTime = '$day天'.tr;
    }
    final hour = lastTime ~/ (60 * 60);
    lastTime = lastTime % (60 * 60);
    if (hour > 0) {
      unMuteTime += '$hour小时'.tr;
    }
    final minute = lastTime ~/ 60;
    if (minute > 0) {
      unMuteTime += '$minute分钟'.tr;
    } else if (unMuteTime.isEmpty) {
      unMuteTime = '1分钟'.tr;
    }
    return unMuteTime;
  }

  @override
  void onClose() {
    super.onClose();
    refreshController?.dispose();
  }

  /// - 是否可以操作'解除'功能
  bool enableRemove(MuteListBean muteBean) {
    final roleIds = muteBean.forbidRoles.map((e) => e.toString()).toList();
    bool hasPermission;
    if (!PermissionUtils.isGuildOwner(
        userId: muteBean.forbidUserId.toString())) {
      hasPermission = PermissionUtils.comparePosition(roleIds: roleIds) == 1;
    } else {
      hasPermission = PermissionUtils.isGuildOwner(userId: Global.user.id);
    }

    return hasPermission;
  }
}
