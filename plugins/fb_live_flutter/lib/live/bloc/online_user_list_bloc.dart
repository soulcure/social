import 'dart:async';

import 'package:fb_live_flutter/fb_live_flutter.dart';
import 'package:fb_live_flutter/live/model/live/oline_rank_model.dart';
import 'package:fb_live_flutter/live/model/online_user_count.dart';
import 'package:fb_live_flutter/live/pages/live_room/widget/online_userlist_widget.dart';
import 'package:fb_live_flutter/live/utils/func/utils_class.dart';
import 'package:fb_live_flutter/live/utils/theme/my_toast.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

import '../net/api.dart';
import '../utils/live/base_bloc.dart';

/// 【2022 02.25】
/// # 直播在线人数列表数据排重，使用id
/// 1. 获取完列表数据之后判断原本是否有数据；
/// 2. 如果有数据则使用新的跟原本的进行对比；
/// 3. 发现有id重复的，删除新获取的内重复的值；
/// 4. 处理好的数据再添加到原有数据内；
/// 5. 刷新列表视图；
///
class OnlineUserListBloc extends BaseAppCubit<int> with BaseAppCubitState {
  OnlineUserListBloc() : super(0);

  late State<OnlineUserList> statePage;

  OnlineUserList get widget {
    return statePage.widget;
  }

  bool get mounted {
    return statePage.mounted;
  }

  /// 页码
  int pageNum = 1;

  /// 每页数量
  int pageSize = 20;

  /// 是否最后一页了
  bool pageEnd = false;

  /// 余额
  String? balanceValue;

  /// 用户列表数据
  List? userList = [];

  /// 在线人数总数量【只有web使用了】
  String? onlineUserCount;

  /// 页面刷新控制器
  final RefreshController refreshController = RefreshController();

  /// 我的排名【数据模型】
  OnlineRankModel? onMyLineRankModel;

  /// 底部悬浮卡片刷新使用的key
  GlobalKey mineKey = GlobalKey();

  void init(State<OnlineUserList> statePage) {
    this.statePage = statePage;

    onlineUserCount = widget.onLineCount ?? '0';

    onRefreshData();
  }

/*
* 获取本人信息
* */
  Future getMyInfo() async {
    final data = await Api.onlineMyRank(widget.roomId!);
    if (data['code'] == 200) {
      onMyLineRankModel = OnlineRankModel.fromJson(data['data']);

      /// 显示自己排行的昵称的问题-应该每个服务台都显示独立的昵称
      final user = await fbApi.getUserInfo(onMyLineRankModel!.userId!,
          guildId: widget.roomInfoObject!.serverId);
      onMyLineRankModel!.nickName = user.name;

      /// 使用新Api获取真实昵称
      if (mounted) onRefresh();
    }
  }

  // 获取乐豆账户余额
  Future getBalance() async {
    final Map status = await Api.queryBalance();
    if (status["code"] == 200) {
      if (mounted) {
        final String? balance = status["data"]["balance"];
        balanceValue = balance == '0' ? '0.0' : balance;
        onRefresh();
      }
    }
  }

  Future _getOnlineCount() async {
    /// 在线人数总数只有web需要
    if (!kIsWeb) {
      return;
    }

    final Map onlineData =
        await Api.getOnlineCount(widget.roomId!, widget.roomInfoObject!);
    if (onlineData["code"] == 200) {
      final OnlineUserCount onlineUserCountModel =
          OnlineUserCount.fromJson(onlineData["data"]);
      if (mounted) {
        onlineUserCount = onlineUserCountModel.total.toString();
        onRefresh();
      }
    }
  }

  /*
  * 刷新和加载更多是分开的，某些处理分别都要进行
  * */
  Future onRefreshData() async {
    unawaited(_getOnlineCount());
    pageNum = 1;
    final Map data =
        await Api.getOnlineUserList(widget.roomId, pageSize, pageNum);
    if (data["code"] == 200) {
      userList!.clear();
      refreshController.refreshCompleted();

      if (data["data"] != null && data["data"].isNotEmpty) {
        userList = data["data"];
        userList = await getShowName(userList!);
        if (List.from(data["data"] ?? []).length < pageSize) {
          pageEnd = true;
        }
        if (mounted) onRefresh();
      } else {
        // myToast("暂无在线用户");
      }
      if (userList!.length >= 200) {
        refreshController.loadNoData();
      }
      await getMyInfo();
    } else {
      refreshController.refreshFailed();
      myToast(data["msg"]);
    }
  }

  //上拉加载
  Future onLoadingData() async {
    if (pageEnd) {
      return;
    }
    unawaited(_getOnlineCount());
    pageNum++;
    final Map data =
        await Api.getOnlineUserList(widget.roomId, pageSize, pageNum);
    if (data["code"] == 200) {
      List userListInner = removeDuplicateData(data['data']);

      print("拿到数据::${userListInner.toString()}");

      userListInner = await getShowName(userListInner);
      if (listNoEmpty(userListInner)) {
        userListInner.forEach((element) {
          userList!.add(element);
        });

        if (mounted) {
          onRefresh();
          if (userList!.length >= 200) {
            refreshController.loadNoData();
          } else {
            refreshController.loadComplete();
          }
        }
      } else {
        // 加载更多结束
        pageEnd = true;
        refreshController.loadNoData();
      }
    } else {
      refreshController.loadFailed();
      myToast(data["msg"]);
    }
  }

  /*
  * 【2022 01.25】
  *
  * 使用数据id去掉重复的
  * */
  List removeDuplicateData(List newListData) {
    /// 重复的数据【存储器】
    final List duplicateData = [];
    userList!.forEach((element) {
      newListData.forEach((newElement) {
        if (element["userId"] == newElement["userId"]) {
          duplicateData.add(newElement);
        }
      });
    });

    /// 删除重复的数据
    duplicateData.forEach((element) {
      newListData.remove(element);
    });

    return newListData;
  }

  /*
  * 获取真实昵称
  * */
  Future<List> getShowName(List userList) async {
    final List<String> userIds = [];
    for (int i = 0; i < userList.length; i++) {
      /// 不是游客才添加
      if (!userList[i]['isGuest']) {
        userIds.add(userList[i]["userId"]);
      }
    }

    final Map<String?, String> names = await fbApi.getShowNames(
      userIds,
      guildId: widget.roomInfoObject!.serverId,
    );

    for (int i = 0; i < userList.length; i++) {
      if (strNoEmpty(names[userList[i]['userId']])) {
        userList[i]['nickName'] = names[userList[i]['userId']];
      }
    }
    return userList;
  }

  // 获取列表是否有MarkName
  Future<List> formatMarkName(List? userList) {
    final List userMarkList = [];
    final List<String> userIdList = [];
    final Completer<List> completer = Completer();

    if (userList == null || userList.isEmpty) {
      completer.complete(userMarkList);
    } else {
      userList.forEach((user) {
        userIdList.add(user['userId']);
      });

      // 获取用户备注姓名
      final Map markUser = fbApi.getMarkNames(userIdList);
      userList.forEach((listUser) {
        if (markUser['${listUser['userId']}'] != null) {
          listUser['markName'] = markUser['${listUser['userId']}'];
        }
        userMarkList.add(listUser);
      });
      completer.complete(userMarkList);
    }

    return completer.future;
  }
}
