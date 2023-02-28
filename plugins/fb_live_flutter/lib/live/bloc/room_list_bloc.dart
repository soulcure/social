import 'dart:async';

import 'package:fb_live_flutter/fb_live_flutter.dart';
import 'package:fb_live_flutter/live/bloc/with/live_mix.dart';
import 'package:fb_live_flutter/live/event_bus_model/refresh_room_list_model.dart';
import 'package:fb_live_flutter/live/event_bus_model/room_list_model.dart';
import 'package:fb_live_flutter/live/model/room_list_model.dart';
import 'package:fb_live_flutter/live/pages/live_room/room_middle_page.dart';
import 'package:fb_live_flutter/live/pages/playback/playback_page.dart';
import 'package:fb_live_flutter/live/pages/room_list/room_list_body.dart';
import 'package:fb_live_flutter/live/pages/room_list/user_home_page.dart';
import 'package:fb_live_flutter/live/pages/room_list/widget/create_room_button.dart';
import 'package:fb_live_flutter/live/utils/config/route_path.dart';
import 'package:fb_live_flutter/live/utils/func/router.dart';
import 'package:fb_live_flutter/live/utils/func/utils_class.dart';
import 'package:fb_live_flutter/live/utils/manager/event_bus_manager.dart';
import 'package:fb_live_flutter/live/utils/manager/permission_manager.dart';
import 'package:fb_live_flutter/live/utils/other/float/float_mode.dart';
import 'package:fb_live_flutter/live/utils/other/float/float_preview_mode.dart';
import 'package:fb_live_flutter/live/utils/theme/my_toast.dart';
import 'package:fb_live_flutter/live/utils/ui/dialog_util.dart';
import 'package:fb_live_flutter/live/utils/ui/frame_size.dart';
import 'package:fb_live_flutter/live/utils/ui/loading.dart';
import 'package:fb_live_flutter/live/utils/ui/show_right_dialog.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:sliding_sheet/sliding_sheet.dart';

import '../net/api.dart';
import '../utils/live/base_bloc.dart';

class RoomListBloc extends BaseAppCubit<int> with BaseAppCubitState {
  RoomListBloc() : super(0);

  late State<RoomListBody> statePage;

  bool thisIsTapProcessing = false;

  RoomListBody get widget {
    return statePage.widget;
  }

  final List<RoomListModel> roomList = [];
  final RefreshController refreshController = RefreshController();
  StreamSubscription? _refreshSubscription;
  int pageSize = 20;
  int pageNum = 1;
  String? serverId = fbApi.getCurrentChannel()!.guildId;

  SheetController controller = SheetController();

  bool isRefresh = false;

  BuildContext? contextValue;

  StreamSubscription? _roomListEventBus;
  StreamSubscription? _roomListSetStateEventBus;

  /// 最终可使用的上下文
  BuildContext get context {
    return contextValue ?? statePage.context;
  }

  void init(State<RoomListBody> statePage) {
    this.statePage = statePage;

    if (kIsWeb) {
      onRefreshData();
    }

    getRoomList(false);

    // _roomListEventBus = roomListEventBus.on().listen((event) {
    //   onRefreshData();
    // });

    _roomListSetStateEventBus = roomListSetStateEventBus.on().listen((event) {
      onRefresh();
    });

    // WidgetsBinding.instance!.addPostFrameCallback((timeStamp) {
    //   _refreshSubscription =
    //       EventBusManager.eventBus.on<RefreshRoomListModel>().listen((event) {
    //     onRefreshData();
    //   });
    // });
  }

  // 获取直播列表
  Future getRoomList(bool pull) async {
    /// 【2021 12.02】修复列表回放/生成中数据重复
    ///
    /// 防多次点击
    if (thisIsTapProcessing) {
      return;
    }
    thisIsTapProcessing = true;

    try {
      String? _userId;

      if (widget.index == 1) {
        _userId = fbApi.getUserId();
      }

      Map? resData;
      try {
        resData = await Api.getLiveRoomList(serverId, pageNum, _userId);
      } catch (e) {
        refreshController.refreshFailed();
        refreshController.loadFailed();
        return;
      }

      if (resData!["code"] == 200) {
        List? dataList = resData["data"]["result"];
        // 如果是刷新，先清除当前数据
        if (pull) {
          // 获取全部(index==0)正在直播间的数量为0时，通知更新直播红点显示
          // 因为分页获取数据，所以非刷新行为或数量不为0的情况不考虑优化
          if (widget.index == 0 && dataList != null && dataList.isEmpty) {
            _liveStatisticsClearNotice();
          }
          roomList.clear();
        }
        if (listNoEmpty(dataList)) {
          dataList = await getLiveListShowName(dataList!);
          dataList.forEach((element) {
            final RoomListModel roomListModel = RoomListModel.fromJson(element);

            roomList.add(roomListModel);
          });
          if (pageNum == 1 || pull) {
            await playbackCreatingList();
          }
          // 标识为已经刷新过了
          isRefresh = true;
          // 直播请求不足10条，请求专辑列表
          if (dataList.length < 10) {
            await _loadDataNotFull();
          } else {
            refreshController.refreshCompleted();
            refreshController.loadComplete();
          }
        } else {
          if (pageNum == 1 || pull) {
            await playbackCreatingList();
          }
          //直播请求没有数据，请求专辑列表
          await _loadDataNotFull();
        }
        onRefresh();
      } else {
        refreshController.refreshFailed();
        refreshController.loadFailed();
      }
    } catch (e) {
      fbApi.fbLogger.info("加载列表数据出现错误:${e.toString()}");
      if (pageNum == 1) {
        refreshController.refreshFailed();
      } else {
        refreshController.loadFailed();
      }
      onRefresh();
    } finally {
      /// [2021 12.02] 取消防多次请求
      thisIsTapProcessing = false;
    }
  }

  /// 直播红点清0通知
  void _liveStatisticsClearNotice() {
    // TODO 此处channel不应该为空，目前空安全版本先这样处理
    final String? guildId = fbApi.getCurrentChannel()?.guildId;
    final String? channelId = fbApi.getCurrentChannel()?.id;
    if (guildId == null || channelId == null) return;
    fbApi.liveStatisticsNotice(guildId, channelId, 0);
  }

  /*
  * 数据不够时调用
  * */
  Future _loadDataNotFull() {
    return _getAlbumListFunc(widget.index == 0); // 0=直播列表；1=我发起的；
  }

  /*
  * 查看专辑列表&&查询主播回放列表
  * */
  Future _getAlbumListFunc(bool isAlbum) async {
    Map? resData;
    if (isAlbum) {
      resData = await Api.playbackAlbumList(pageNum);
    } else {
      final _userId = fbApi.getUserId();
      resData = await Api.playbackList(pageNum, _userId);
    }
    if (resData!['code'] != 200) {
      refreshController.refreshFailed();
      refreshController.loadFailed();

      isRefresh = true;
      onRefresh();
      return;
    }
    List? dataList = resData["data"]["result"];
    if (!listNoEmpty(dataList)) {
      refreshController.loadNoData();
      refreshController.refreshCompleted();

      isRefresh = true;
      onRefresh();
      return;
    }
    refreshController.refreshCompleted();
    refreshController.loadComplete();

    dataList = await getLiveListShowName(dataList!);

    dataList.forEach((element) {
      final RoomListModel roomListModel =
          RoomListModel.fromJson(element, openTypeContent: isAlbum ? 3 : 4);
      roomList.add(roomListModel);
    });

    isRefresh = true;
    onRefresh();
  }

  //下拉加载
  void onRefreshData() {
    pageNum = 1;
    getRoomList(true);
  }

  //上拉
  Future onLoadingData() async {
    pageNum++;
    await getRoomList(false);
  }

  /*
  * 关闭直播
  * */
  Future closeLive(String roomId) async {
    final Map status = await Api.mandatoryClose(roomId);
    if (status["code"] == 200) {
      mySuccessToast("已成功结束其他直播！");
    }
  }

  /*
  * 获取直播列表真实昵称
  *
  * 直播列表、专辑列表通用
  * */
  Future<List> getLiveListShowName(List list) async {
    final List<String> userIds = [];
    for (int i = 0; i < list.length; i++) {
      userIds.add(list[i]["anchorId"]);
    }

    final Map<String?, String> names = await fbApi.getShowNames(userIds,
        guildId: fbApi.getCurrentChannel()!.guildId);

    for (int i = 0; i < list.length; i++) {
      if (strNoEmpty(names[list[i]['anchorId']])) {
        list[i]['nickName'] = names[list[i]['anchorId']];
      }
    }
    return list;
  }

  /*
  * 查询主播生成中的回放列表
  * */

  /// 如果是刷新，不管直播数据是否为空，都要查看是否有正在生成中
  Future<void> playbackCreatingList() async {
    if (widget.index == 0) {
      return;
    }

    /// 修复直播相关bugly问题总结【2】
    final creatingData =
        await Api.playbackCreatingList(fbApi.getCurrentChannel()!.id);
    if (creatingData['code'] != 200) {
      return;
    }

    creatingData["data"].forEach((e) {
      final RoomListModel roomListModel = RoomListModel.fromJson(e);

      /// 设置为是回放生成中
      roomListModel.isCreating = true;
      roomList.add(roomListModel);
    });
  }

  Future action(RoomListModel item) async {
    final bool isCreating = item.isCreating != null && item.isCreating!;
    if (isCreating) {
      return;
    }

    final bool isInAVChannel = fbApi.inAVChannel();

    if (item.openType == 3 && !kIsWeb) {
      // 用户回放专辑 点击进入用户个人主页
      await showBottomSheetDialog(
        context,
        child: UserHomePage(
          item: item,
          isDownClose: true,
          anchorId: item.anchorId,
          isFromList: true,
        ),
      );
    } else if (item.openType == 3 && kIsWeb) {
      await showQ1Dialog(
        context,
        alignmentTemp: Alignment.centerRight,
        widget: Container(
          color: Colors.white,
          width: FrameSize.winWidth() * (480.px / 1128.px),
          height: FrameSize.winHeight(),
          child: WebUserHomePage(
            item: item,
          ),
        ),
      );
    } else if (item.openType == 4) {
      item.okNickName = (await fbApi.getUserInfo(fbApi.getUserId()!,
              guildId: fbApi.getCurrentChannel()!.guildId))
          .name;
      item.avatarUrl = (await fbApi.getUserInfo(fbApi.getUserId()!,
              guildId: fbApi.getCurrentChannel()!.guildId))
          .avatar;

      await RouteUtil.push(context, PlaybackPage(item), RoutePath.playBack);
    } else if (isInAVChannel) {
      // 有音视频线程
      final _bool = await fbApi.exitAVChannel();
      if (_bool) {
        await _navigatorToLiveRoom(context, item);
      }
      return;
    } else {
      // 无音视频线程
      await _navigatorToLiveRoom(context, item);
    }
  }

  Future _navigatorToLiveRoom(BuildContext context, RoomListModel item) async {
    final String? userId = fbApi.getUserId();

    if (!kIsWeb && (userId == item.anchorId)) {
      if (!await PermissionManager.requestPermission(
          type: PermissionType.createRoom)) {
        myFailToast(
          '切换APP直播需要相机/录音权限，当前权限被禁用',
        );
        return;
      }
    }

    if (kIsWeb) {
      final LiveValueModel liveValueModel = LiveValueModel();

      liveValueModel.setRoomInfo(
          roomId: item.roomId!,
          serverId: item.serverId!,
          channelId: item.channelId!,
          roomLogo: item.roomLogo ?? "",
          status: item.status!,
          liveType: item.liveType!,
          roomInfoObject: liveValueModel.roomInfoObject);

      liveValueModel.isAnchor = false;

      await fbApi
          .push(context, RoomMiddlePage(liveValueModel: liveValueModel),
              "liveRoomWebContainer")
          .then((value) => onRefreshData());
    } else {
      if (floatPreViewWindow.isHaveFloat) {
        Loading.cleanContext();
        Loading.showConfirmDialog(
            context,
            {
              'content': '你当前正处在直播预览中，请关闭直播预览后再重试',
              'confirmText': '确认',
              "cancelShow": false
            },
            () {});
        return;
      }

      //检测是否在直播
      final Map dataMap = await Api.checkRoom();
      if (dataMap["code"] == 200) {
        final String? roomId = dataMap["data"]["roomId"];
        final String? roomLogo = dataMap["data"]["roomLogo"];
        final String? serverId = dataMap["data"]["serverId"];
        final String? channelId = dataMap["data"]["channelId"];
        final int? liveType = dataMap["data"]["liveType"];

        final bool cantRestoreHandle = await DialogUtil.cantRestoreHandle(
            context, channelId, serverId, roomId, liveType);
        if (cantRestoreHandle) {
          return;
        }

        // status =2 在直播  是主播
        if (dataMap["data"]["status"] == 2) {
          final FBChatChannel? currentChannel = fbApi.getCurrentChannel();

          //判断是否是本服务器
          if (currentChannel!.guildId == serverId) {
            // 判断点击的房间是否是正在直播的直播间 是的话恢复直播  不是的话提示
            if (roomId == item.roomId) {
              //判断是否有浮窗  有浮窗  isOverlayViewPush = false   不需要重新初始化即构SDK
              bool isOverlayViewPush = false;

              /// 修复点击列表卡片重新加载了直播间
              /// 屏幕共享时-点进卡片进的不是屏幕共享的直播
              // OverlayView.removeOverlayEntry();

              if (!floatWindow.isHaveFloat) {
                await _pushLiveRoom(
                    roomLogo, true, roomId, isOverlayViewPush, item);
              } else {
                //原本应该为true,因为obs初始化原因需进行修改，防止不必要操作
                isOverlayViewPush = true;

                // 推送到直播页面
                floatWindow.pushToLive(FBLiveEvent.fullscreen);
              }
            } else {
              //无浮窗
              if (!floatWindow.isHaveFloat) {
                Loading.showConfirmDialog(context, {
                  'content': '直播意外中断了,是否继续直播?',
                  'confirmText': '恢复直播',
                }, () {
                  if (currentChannel.guildId == serverId) {
                    againLive(context, roomId, roomLogo,
                        dataMap["data"]["liveType"] == 3);
                  } else {
                    closeLive(roomId!);
                  }
                });
              } else {
                Loading.cleanContext();
                Loading.showConfirmDialog(
                    context,
                    {
                      'content': '你当前正处在直播中，请关闭直播后再重试',
                      'confirmText': '确认',
                      "cancelShow": false
                    },
                    () {});
              }
            }
          } else {
            //无浮窗
            if (!floatWindow.isHaveFloat) {
              Loading.showConfirmDialog(context, {
                'content': '发现你在其它服务器有直播中断了 是否关闭其它直播间?',
                'confirmText': '结束其它直播',
              }, () {
                closeLive(roomId!);
              });
            } else {
              Loading.cleanContext();
              Loading.showConfirmDialog(
                  context,
                  {
                    'content': '你当前正处在直播中，请关闭直播后再重试',
                    'confirmText': '确认',
                    "cancelShow": false
                  },
                  () {});
            }
          }
        }
      } else {
        if (!floatWindow.isHaveFloat) {
          await _pushLiveRoom(item.roomLogo, false, item.roomId, false, item);
        } else {
          if (floatWindow.liveValueModel!.getRoomId != item.roomId) {
            await _pushLiveRoom(item.roomLogo, false, item.roomId, false, item);
            return;
          }

          /// 关闭小窗UI
          floatWindow.pushToLive(FBLiveEvent.fullscreen);
        }
      }
    }
  }

  Future _pushLiveRoom(String? roomLogo, bool isAnchor, String? roomId,
      bool isOverlayViewPush, RoomListModel item) async {
    unawaited(floatWindow.close());

    final bool isExternal = item.liveType == 3;

    final LiveValueModel liveValueModel = LiveValueModel();

    liveValueModel.setRoomInfo(
        roomId: roomId!,
        serverId: item.serverId!,
        channelId: item.channelId!,
        roomLogo: item.roomLogo ?? "",
        status: 2,
        liveType: 4,
        roomInfoObject: liveValueModel.roomInfoObject);

    liveValueModel.isAnchor = isAnchor;
    liveValueModel.setObs(isExternal);

    await fbApi
        .push(
            context,
            RoomMiddlePage(
              // ignore: avoid_bool_literals_in_conditional_expressions
              isOverlayViewPush: !isExternal ? isOverlayViewPush : false,
              liveValueModel: liveValueModel,
            ),
            "/liveRoom")
        .then((value) async {
      /// 如果还是横屏则先等待反应好后再执行刷新列表
      if (FrameSize.isHorizontal()) {
        await Future.delayed(const Duration(milliseconds: 200));
      }
      // if (statePage.mounted) {
      //   await refreshController.requestRefresh();
      // }
    });
  }

  @override
  Future<void> close() {
    refreshController.dispose();
    _refreshSubscription?.cancel();
    _refreshSubscription = null;

    _roomListEventBus?.cancel();
    _roomListEventBus = null;

    _roomListSetStateEventBus?.cancel();
    _roomListSetStateEventBus = null;

    return super.close();
  }
}
