import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:math';
import 'dart:math' as math;
import 'dart:ui';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:fb_live_flutter/fb_live_flutter.dart';
import 'package:fb_live_flutter/live/api/fblive_provider.dart';
import 'package:fb_live_flutter/live/bloc/live_room_web_bloc.dart';
import 'package:fb_live_flutter/live/bloc/with/live_loading.dart';
import 'package:fb_live_flutter/live/bloc/with/live_mix.dart';
import 'package:fb_live_flutter/live/pages/close_room/close_room_anchor_web.dart';
import 'package:fb_live_flutter/live/utils/config/steam_info_config.dart';
import 'package:fb_live_flutter/live/utils/func/router.dart';
import 'package:fb_live_flutter/live/utils/log/live_log_up.dart';
import 'package:fb_live_flutter/live/utils/theme/my_toast.dart';
import 'package:fb_live_flutter/live/utils/ui/dialog_util.dart';
import 'package:fb_live_flutter/live/widget_common/image/sw_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oktoast/oktoast.dart';
import 'package:wakelock/wakelock.dart';
import 'package:zego_ww/zego_ww.dart';

import '../../bloc_model/chat_list_bloc_model.dart';
import '../../bloc_model/fb_refresh_widget_bloc_model.dart';
import '../../bloc_model/gift_click_bloc_model.dart';
import '../../bloc_model/gift_move_bloc_model.dart';
import '../../bloc_model/like_click_bloc_model.dart';
import '../../bloc_model/live_play_mask_bloc_model.dart';
import '../../bloc_model/live_preview_bloc_model.dart';
import '../../bloc_model/online_user_count_bloc_model.dart';
import '../../bloc_model/room_bottom_bloc_model.dart';
import '../../bloc_model/screen_clear_bloc_model.dart';
import '../../bloc_model/sheet_gifts_bottom_bloc_model.dart';
import '../../bloc_model/show_image_filter_bloc_model.dart';
import '../../bloc_model/user_join_live_room_model.dart';
import '../../event_bus_model/refresh_room_list_model.dart';
import '../../event_bus_model/sheet_gifts_bottom_model.dart';
import '../../model/close_audience_room_model.dart';
import '../../model/colse_room_model.dart';
import '../../model/online_user_count.dart';
import '../../model/room_infon_model.dart';
import '../../model/zego_token_model.dart';
import '../../net/api.dart';
import '../../utils/manager/event_bus_manager.dart';
import '../../utils/manager/zego_sdk_manager.dart';
import '../../utils/ui/frame_size.dart';
import '../../utils/ui/loading.dart';
import '../close_room/close_room_audience.dart';
import 'widget/anchor_bottom_widget.dart';
import 'widget/anchor_top_widgt.dart';
import 'widget/audiences_bottom_widget.dart';
import 'widget/chat_list_widget.dart';
import 'widget/gifts_give_widget.dart';
import 'widget/live_play_mask_widget.dart';
import 'widget/tips_login_widget.dart';
import 'widget/top_right_widget.dart';
import 'widget/up_click_widget.dart';

typedef RefreshCallBlock = void Function(bool? isAnchor);

class LiveRoomWeb extends StatefulWidget {
  final bool? isAnchor; //是否是主播
  final bool shared;
  final String? roomId;
  final String? inFanbook;
  final String? jump;
  final String? roomLogo;
  final RefreshCallBlock? refreshCallBlock;
  final bool? isWebFlip;
  final LiveValueModel? liveValueModel;

  const LiveRoomWeb({
    Key? key,
    this.isAnchor,
    this.roomId,
    this.inFanbook,
    this.isWebFlip,
    this.jump,
    this.refreshCallBlock,
    this.roomLogo,
    this.shared = false,
    required this.liveValueModel,
  }) : super(key: key);

  @override
  _LiveRoomWebState createState() => _LiveRoomWebState();
}

class _LiveRoomWebState extends State<LiveRoomWeb>
    with
        TickerProviderStateMixin,
        FBLiveMsgHandler,
        WidgetsBindingObserver,
        LiveNetErrorLogic {
  bool isStartLive = true; //是否已经开启直播
  bool isPlaying = true; //第一次拉流上报
  final int _previewViewID = -1;
  Timer? _timer;
  bool? _isanchor; //是否是主播
  List onlineUser = []; //在线用户列表

  OnlineUserCount? onlineUserCountModel; //在线人数数量
  List? userOnlinelist; //在线用户详情列表
  late Loading _loading;
  bool isClickUp = false; //是否点过赞
  final Queue _userJoinQueue = Queue();
  final Queue<GiveGiftModel?> _giftQueue = Queue();
  FBUserInfo? _joinedUserInfo;
  Widget? _bottomView;
  int? shareType; //分享类型：0-不分享、1-分享
  GiveGiftModel? _giveGiftModel1, _giveGiftModel2, _giveGiftModel3;
  int deviceSeleteValue = -1; //当前选择的摄像头
  bool showImageFilter = false; //是否显示蒙层图片
  bool stopLive = false; //是否是禁播
  /// 状态管理--start
  late LivePreviewBlocModel _livePreviewBlocModel;
  late ChatListBlocModel _chatListBlocModel;
  late ScreenClearBlocModel _screenClearBlocModel;
  late LikeClickPreviewBlocModel _likeClickPreviewBlocModel;

  LikeClickBlocModel? _likeClickBlocModel;
  GiftClickBlocModel? _giftClickBlocModel;
  late UserJoinLiveRoomModel _userJoinLiveRoomModel;
  late OnlineUserCountBlocModel _onlineUserCountModel;
  late RoomBottomBlocModel _roomBottomBlocModel;
  LivePlayMaskBlocModel? _livePlayMaskBlocModel;
  late GiftMoveBlocModel _giftMoveBlocModel;
  late GiftMoveBlocModel2 _giftMoveBlocModel2;
  late GiftMoveBlocModel3 _giftMoveBlocModel3;
  late SheetGiftsBottomBlocModel _sheetGiftsBottomBlocModel;
  StreamSubscription? _subscription;
  late ShowImageFilterBlocModel _showImageFilterBlocModel;

  final LiveRoomWebBloc _liveRoomWebBloc = LiveRoomWebBloc();

  /// 状态管理--end
  final Connectivity _connectivity = Connectivity(); //网络监测
  late StreamSubscription<ConnectivityResult>
      _connectivitySubscription; //网络监测刷新

  dynamic localStream;
  bool _showPlayMask = false;

  StreamController<List<Widget>> widgetListStreamController =
      StreamController();
  List<Widget> upLickWidgetList = [];
  List<AnimationController> animationControllerList = [];

  @override
  void initState() {
    super.initState();
    _isanchor = widget.isAnchor;
    //初始化ZegoSDK
    _initZegoExpressEngine();
    // 网络中断监听
    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
    WidgetsBinding.instance!.addPostFrameCallback((timeStamp) {
      // 监听FB注册回调
      _fbApiRegisterMsgHandler();
      // 开启房间loading
      _openLoading("直播等待中...");
      //获取房间信息
      getRoomInfo();
      _subscription =
          EventBusManager.eventBus.on<SheetGiftsBottomModel>().listen((event) {
        final double? ph = event.height;
        _sheetGiftsBottomBlocModel.add(ph);
      });
    });
    _liveRoomWebBloc.init();
    _liveRoomWebBloc.statePageProperty(this);
  }

  RoomInfon? get roomInfon {
    return _liveRoomWebBloc.roomInfon;
  }

  // 初始化loading
  void _openLoading(String text,
      {int width = 150, int height = 130, Function? callback}) {
    Future.delayed(Duration.zero, () async {
      _loading = await Loading.timerToast(context, text,
          openTimer: true, width: width, height: height, cancel: () {
        _closeLoading();
        _goback();
      }, cb: () {
        _closeLoading();

        if (callback != null) {
          callback();
          return;
        }
        // 默认弹窗
        Loading.showConfirmDialog(
            context,
            {
              'content': '网络问题，无法开启直播，退出房间重试',
              'confirmText': '退出',
              'cancelShow': false
            },
            _goback);
      });
    });
  }

  // 关闭loading
  void _closeLoading() {
    Loading.cancelLoadingTimer();
    _loading.dismiss();
  }

  // 开启showConfirmDialog
  void _showConfirmDialog(Function _callback) {
    _closeLoading();
    _callback();
  }

  //房间信息
  Future getRoomInfo() async {
    final Map resultData = await Api.getRoomInfo(widget.roomId!);
    if (resultData["code"] == 200) {
      _liveRoomWebBloc.roomInfon = RoomInfon.fromJson(resultData["data"]);

      shareType = roomInfon!.shareType;
      _roomBottomBlocModel.add(true);

      if (roomInfon!.tips != null && roomInfon!.tips!.length > 1) {
        _chatListBlocModel.add({});
      }

      if (roomInfon!.status == 1 || roomInfon!.status == 2) {
        // 获取token，并登录房间
        await getZegoToken();
      } else if (roomInfon!.status == 3) {
        _showConfirmDialog(() {
          Loading.showConfirmDialog(
              context,
              {
                'content': '主播已经下线了，感谢你的观看',
                'confirmText': '退出',
                'cancelShow': false
              },
              _goback);
        });
      } else if (roomInfon!.status == 4) {
        DialogUtil.liveWillClose(context, onPressed: () {
          if (_isanchor!) {
            _anchorCloseRoom();
          } else {
            _goback();
          }
        });
      } else {
        _showConfirmDialog(() {
          Loading.showConfirmDialog(
              context,
              {
                'content': '直播超时已自动关闭',
                'confirmText': '退出',
                'cancelShow': false
              },
              _goback);
        });
      }
    }
  }

  //即构
  Future getZegoToken() async {
    final Map resultData = await Api.getZegoToken(widget.roomId!);

    if (resultData["code"] == 200) {
      _liveRoomWebBloc.zegoTokenModel =
          ZegoTokenModel.fromJson(resultData["data"]);
      if (_liveRoomWebBloc.zegoTokenModel.userId ==
          _liveRoomWebBloc.zegoTokenModel.anchorId) {
        //主播与用户ID一样  主播重新进入
        _isanchor = true;
      } else {
        _isanchor = false;
      }
      if (widget.refreshCallBlock != null) {
        widget.refreshCallBlock!(_isanchor);
      }

      await _setStreamAndTexture();
    }
  }

  //在线人数数量
  Future getonlineCount() async {
    final Map onlineData = await Api.getOnlineCount(widget.roomId!, roomInfon!);
    if (onlineData["code"] == 200) {
      onlineUserCountModel = OnlineUserCount.fromJson(onlineData["data"]);
      _onlineUserCountModel.add(onlineUserCountModel!.total);
      _likeClickPreviewBlocModel.add(onlineUserCountModel!.thumbCount);
    }
  }

  // 上报当前角色进入直播间
  Future setLiveEnter() async {
    await Api.liveEnter(
        widget.roomId, _liveRoomWebBloc.zegoTokenModel.userToken);

    // 进入直播间日志上报
    if (!widget.isAnchor!) {
      LiveLogUp.liveEnter(
          true,

          /// todo web需要添加是否来自列表的变量
          widget.roomId!,
          roomInfon!.serverId,
          roomInfon!.channelId);
    }

    await getonlineCount(); //进入直播后查询在线人数
  }

  // 上报当前角色直播间
  Future setLiveExit() async {
    await Api.liveExit(widget.roomId, _liveRoomWebBloc.zegoTokenModel.userToken,
        widget.isAnchor!, roomInfon!);
  }

  // 定时查询线上人数
  void startTimerGetOnline() {
    _cancelTimer();
    _timer = Timer.periodic(const Duration(seconds: 30), (timer) {
      getonlineCount();
    });
  }

  // 主播开始直播
  Future anchorStartlive() async {
    final Map status = await Api.starteLive(widget.roomId!);
    if (status['code'] == 200) {
      showImageFilter = true;
      _showImageFilterBlocModel.add(showImageFilter);
      // 通知服务端
      await setLiveEnter();
      // 通知FB
      _fbApiEnterLiveRoom();
    } else {
      _showConfirmDialog(() {
        Loading.showConfirmDialog(
            context,
            {'content': '出现故障，直播失败', 'cancelText': '退出', 'confirmText': '重试'},
            anchorStartlive, cancelCallback: () {
          _goback();
        });
      });
    }
  }

  // 主播关闭直播
  Future anchorCloseLive() async {
    final Map status = await Api.closeLiveRoom(widget.roomId!);
    if (status["code"] == 200) {
      final CloseRoomModel closeRoomModel =
          CloseRoomModel.fromJson(status["data"]);
      _navigatorToAnchorClosePage(closeRoomModel);
    }
  }

  // 用户端查询房间状态
  Future getRoomStatus() async {
    final Map resultData = await Api.getRoomInfo(widget.roomId!);
    if (resultData["code"] == 200) {
      final roomInfo = RoomInfon.fromJson(resultData["data"]);
      if (roomInfo.status == 3) {
        _showConfirmDialog(_navigatorToAudienceClosePage);
      } else if (roomInfo.status == 4) {
        _showConfirmDialog(() {
          Loading.showConfirmDialog(
              context,
              {
                'content': '由于直播内容违规，主播被管理员禁播。',
                'confirmText': '退出',
                'cancelShow': false
              },
              _goback);
        });
      } else if (roomInfo.status == 1 || roomInfo.status == 2) {
        //  房间还存在
        showImageFilter = false;
        _showImageFilterBlocModel.add(showImageFilter);
        _showConfirmDialog(() {
          myToastLong('主播暂时离开了，Ta有可能是去上厕所了，等等吧',
              duration: const Duration(days: 1)); // 固定半透明
        });
      }
    }
  }

  // FBAPI--主播停止直播
  void _fbApiStopLive() {
    fbApi.stopLive(roomInfon!.serverId, roomInfon!.channelId,
        _liveRoomWebBloc.zegoTokenModel.roomId!);
  }

  // FBAPI--用户进入房间
  void _fbApiEnterLiveRoom() {
    fbApi.enterLiveRoom(
        roomInfon!.channelId,
        _liveRoomWebBloc.zegoTokenModel.roomId!,
        _isanchor!,
        roomInfon!.serverId,
        false);
  }

  // FBAPI--用户退出房间
  void _fbApiExitLiveRoom() {
    fbApi.exitLiveRoom(roomInfon!.serverId, roomInfon!.channelId,
        _liveRoomWebBloc.zegoTokenModel.roomId!);
  }

  // FBAPI--发送弹幕消息
  void _fbApiSendLiveMsg(String content) {
    LiveLogUp.send(content, roomInfon!);
    final String json = _formatMsgJSON(content);
    fbApi.sendLiveMsg(roomInfon!.serverId, roomInfon!.channelId,
        _liveRoomWebBloc.zegoTokenModel.roomId!, json);
  }

  // FBAPI--消息回调
  static String _formatMsgJSON(String content) {
    final Map msgJSON = {};
    msgJSON['content'] = content;
    return json.encode(msgJSON);
  }

  //2、注册回调
  void _fbApiRegisterMsgHandler() {
    fbApi.registerLiveMsgHandler(this);
  }

  //3、移除回调
  void _fbApiRemoveLiveMsgHandler() {
    fbApi.removeLiveMsgHandler(this);
  }

  List<BlocProvider> get providers {
    final List<BlocProvider> _providers = [
      BlocProvider<ChatListBlocModel>(
        create: (context) {
          // ignore: join_return_with_assignment
          _chatListBlocModel = ChatListBlocModel({});
          return _chatListBlocModel;
        },
      ),
      BlocProvider<LikeClickBlocModel>(
        create: (context) {
          // ignore: join_return_with_assignment
          _likeClickBlocModel = LikeClickBlocModel(0);
          return _likeClickBlocModel!;
        },
      ),
      BlocProvider<GiftClickBlocModel>(
        create: (context) {
          // ignore: join_return_with_assignment
          _giftClickBlocModel = GiftClickBlocModel(0);
          return _giftClickBlocModel!;
        },
      ),
      BlocProvider<GiftMoveBlocModel>(
        create: (context) {
          // ignore: join_return_with_assignment
          _giftMoveBlocModel = GiftMoveBlocModel(null);
          return _giftMoveBlocModel;
        },
      ),
      BlocProvider<GiftMoveBlocModel2>(
        create: (context) {
          // ignore: join_return_with_assignment
          _giftMoveBlocModel2 = GiftMoveBlocModel2(null);
          return _giftMoveBlocModel2;
        },
      ),
      BlocProvider<GiftMoveBlocModel3>(
        create: (context) {
          // ignore: join_return_with_assignment
          _giftMoveBlocModel3 = GiftMoveBlocModel3(null);
          return _giftMoveBlocModel3;
        },
      ),
      BlocProvider<LivePreviewBlocModel>(
        create: (context) {
          // ignore: join_return_with_assignment
          _livePreviewBlocModel = LivePreviewBlocModel(_previewViewID);
          return _livePreviewBlocModel;
        },
      ),
      BlocProvider<ScreenClearBlocModel>(
        create: (context) {
          // ignore: join_return_with_assignment
          _screenClearBlocModel = ScreenClearBlocModel(false);
          return _screenClearBlocModel;
        },
      ),
      BlocProvider<LikeClickPreviewBlocModel>(
        create: (context) {
          // ignore: join_return_with_assignment
          _likeClickPreviewBlocModel = LikeClickPreviewBlocModel(0);
          return _likeClickPreviewBlocModel;
        },
      ),
      BlocProvider<UserJoinLiveRoomModel>(
        create: (context) {
          // ignore: join_return_with_assignment
          _userJoinLiveRoomModel = UserJoinLiveRoomModel(null);

          /// 如果要提示自己加入房间，则传入自己信息的FBUserInfo
          // _userJoinLiveRoomModel = UserJoinLiveRoomModel(FBUserInfo());
          return _userJoinLiveRoomModel;
        },
      ),
      BlocProvider<RoomBottomBlocModel>(
        create: (context) {
          // ignore: join_return_with_assignment
          _roomBottomBlocModel = RoomBottomBlocModel(RefreshState.none);
          return _roomBottomBlocModel;
        },
      ),
      BlocProvider<LivePlayMaskBlocModel>(
        create: (context) {
          // ignore: join_return_with_assignment
          _livePlayMaskBlocModel = LivePlayMaskBlocModel(false);
          return _livePlayMaskBlocModel!;
        },
      ),
      BlocProvider<SheetGiftsBottomBlocModel>(create: (context) {
        return _sheetGiftsBottomBlocModel = SheetGiftsBottomBlocModel(0);
      }),
      BlocProvider<ShowImageFilterBlocModel>(
        create: (context) =>
            _showImageFilterBlocModel = ShowImageFilterBlocModel(false),
      ),
    ];

    try {
      _onlineUserCountModel =
          BlocProvider.of<OnlineUserCountBlocModel>(context);
      return _providers;
    } catch (e) {
      _providers.add(BlocProvider<OnlineUserCountBlocModel>(
        create: (context) {
          // ignore: join_return_with_assignment
          _onlineUserCountModel = OnlineUserCountBlocModel(0);
          return _onlineUserCountModel;
        },
      ));
      return _providers;
    }
  }

  Widget get liveVideo {
    final Widget liveContent = AbsorbPointer(
      child: _liveRoomWebBloc.videoView ?? Container(),
    );
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.rotationY(widget.isWebFlip! ? math.pi : 0),
      child: AbsorbPointer(
        child: liveContent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: providers,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle.light,
          child: Material(
              child: Scaffold(
                  body: WillPopScope(
            onWillPop: () async {
              //手势返回禁止
              return false;
            },
            child: GestureDetector(
                onTap: () {
                  _screenClearBlocModel.switchScreenClearState();
                },
                // behavior: HitTestBehavior.deferToChild,
                child: Container(
                    color: Colors.black,
                    child: SafeArea(
                        child: SingleChildScrollView(
                            // ignore: sized_box_for_whitespace
                            child: Container(
                      height: FrameSize.screenH() -
                          FrameSize.padTopH() -
                          FrameSize.padBotH(),
                      child: Stack(children: [
                        // ignore: sized_box_for_whitespace
                        Container(
                          height: FrameSize.screenH(),
                          decoration: const BoxDecoration(
                              color: Color(0xFF0E122A),
                              image: DecorationImage(
                                  fit: BoxFit.cover,
                                  // repeat: ImageRepeat.repeatY,
                                  image: AssetImage(
                                      "assets/live/LiveRoom/live_bgImage.png"))),
                          child: BlocBuilder<LivePreviewBlocModel, int>(
                            builder: (context, textureID) {
                              if (_liveRoomWebBloc.isScreenRotation) {
                                return Transform.rotate(
                                  //旋转90度
                                  angle: math.pi / 2,
                                  child: liveVideo,
                                );
                              }
                              return liveVideo;
                            },
                          ),
                        ),
                        BlocBuilder<ShowImageFilterBlocModel, bool>(
                          builder: (context, _showImageFilter) {
                            return Offstage(
                              offstage: _showImageFilter,
                              // ignore: sized_box_for_whitespace
                              child: Container(
                                height: FrameSize.screenH(),
                                width: FrameSize.screenW(),
                                child: Stack(
                                  children: [
                                    Image.network(
                                      widget.roomLogo ?? "",
                                      height: FrameSize.screenH(),
                                      width: FrameSize.screenW(),
                                      fit: BoxFit.fitHeight,
                                    ),
                                    BackdropFilter(
                                      filter: ImageFilter.blur(
                                          sigmaX: 18, sigmaY: 18),
                                      child: Container(
                                        color: Colors.black54,
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        // ignore: avoid_unnecessary_containers
                        Container(
                          padding: const EdgeInsets.only(
                              left: 33, top: 30, right: 33),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Stack(
                                children: [
                                  BlocBuilder<ScreenClearBlocModel, bool>(
                                    builder: (context, clearState) {
                                      return Offstage(
                                        offstage: clearState,
                                        child: BlocBuilder<
                                            LikeClickPreviewBlocModel, int?>(
                                          builder: (context, likeNum) {
                                            return AnchorTopView(
                                              //直播间左上角View
                                              imageUrl: roomInfon?.avatarUrl,
                                              anchorName: roomInfon?.nickName,
                                              anchorId: roomInfon?.anchorId,
                                              serverId: roomInfon?.serverId,
                                              likesCount: likeNum,
                                              countBloc: _liveRoomWebBloc,
                                            );
                                          },
                                        ),
                                      );
                                    },
                                  ),
                                  BlocBuilder<ScreenClearBlocModel, bool>(
                                    builder: (context, clearState) {
                                      return Offstage(
                                        offstage: clearState,
                                        child: BlocBuilder<
                                            OnlineUserCountBlocModel, int>(
                                          builder: (context, onlineNum) {
                                            return TopRightView(
                                              countBloc: _liveRoomWebBloc,
                                              isAnchor: _isanchor,
                                              onlineUserCountModel:
                                                  onlineUserCountModel,
                                              roomId: widget.roomId,
                                              userOnlineList: userOnlinelist,
                                              // 用户关闭直播
                                              closeClickBlock:
                                                  _audienceCloseRoom,
                                              roomInfoObject: roomInfon!,
                                            );
                                          },
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        BlocBuilder<ScreenClearBlocModel, bool>(
                          builder: (context, clearState) {
                            return Offstage(
                              offstage: clearState,
                              child: _bottomView ??
                                  (_bottomView = _bottomViews(context)),
                            );
                          },
                        ),
                        BlocBuilder<LivePlayMaskBlocModel, bool>(
                          builder: (context, showMask) {
                            return LivePlayMaskWidget(
                              onTap: () {
                                if (widget.shared &&
                                    _showPlayMask == false &&
                                    _liveRoomWebBloc.mediaModel != null) {
                                  _liveRoomWebBloc.mediaModel!.play();
                                  _livePlayMaskBlocModel!.add(false);
                                  _showPlayMask = true;
                                }
                              },
                              showMask: showMask,
                            );
                          },
                        ),
                        if (_isanchor!)
                          Container()
                        else
                          StreamBuilder<List<Widget>>(
                            stream: widgetListStreamController.stream,
                            builder: (context, snapshot) {
                              if (snapshot.data != null) {
                                return Positioned(
                                  right: FrameSize.px(16),
                                  bottom: FrameSize.px(50),
                                  child: SizedBox(
                                    width: 42,
                                    height: 240,
                                    child: Stack(
                                      children: snapshot.data!
                                          .map<Widget>((f) => f)
                                          .toList(),
                                    ),
                                  ),
                                );
                              } else {
                                return Container();
                              }
                            },
                          ),
                        Positioned(
                          right: 100.px,
                          top: 30.px,
                          child: BlocBuilder<ScreenClearBlocModel, bool>(
                            builder: (context, clearState) {
                              return Offstage(
                                offstage: clearState,
                                child: StatefulBuilder(
                                  builder: (c, onRefresh) {
                                    return SwImage(
                                      'assets/live/main/ic_screen_rotation${_liveRoomWebBloc.isScreenRotation ? '' : '_left'}.png',
                                      color: Colors.white,
                                      width: 30,
                                      onTap: () async {
                                        _liveRoomWebBloc.isScreenRotation =
                                            !_liveRoomWebBloc.isScreenRotation;
                                        _livePreviewBlocModel.add(0);
                                        onRefresh(() {});
                                      },
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                      ]),
                    ))))),
          )))),
    );
  }

  //底部view
  Widget _bottomViews(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: FrameSize.px(24), right: FrameSize.px(24)),
      child: Stack(
        children: [
          Positioned(
              bottom: FrameSize.padBotH() + 7 + 42 + 10 + 208,
              child: Column(
                children: [
                  SizedBox(
                    height: FrameSize.px(42) * 3 + 2 * FrameSize.px(5),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        BlocBuilder<GiftMoveBlocModel, GiveGiftModel?>(
                          buildWhen: (previous, current) {
                            return true;
                          },
                          builder: (context, giveGiftModel) {
                            if (giveGiftModel == null) {
                              return Container();
                            }
                            return GiftsGiveView(
                              giveGiftModel: giveGiftModel,
                              count: giveGiftModel.count,
                              animationComplete: (_giveGifModel) {
                                _giveGiftModel1 = null;
                                checkGiftMoveMsg(null, next: true);
                              },
                              refreshListener:
                                  (Function(GiveGiftModel) refreshCallBack) {},
                            );
                          },
                        ), //展示有bug
                        Padding(
                          padding: EdgeInsets.only(
                            top: FrameSize.px(5),
                          ),
                          child: Container(),
                        ),
                        BlocBuilder<GiftMoveBlocModel2, GiveGiftModel?>(
                          buildWhen: (previous, current) {
                            return true;
                          },
                          builder: (context, giveGiftModel) {
                            if (giveGiftModel == null) {
                              return Container();
                            }
                            return GiftsGiveView(
                              giveGiftModel: giveGiftModel,
                              count: giveGiftModel.count,
                              animationComplete: (_giveGifModel) {
                                _giveGiftModel2 = null;
                                checkGiftMoveMsg(null, next: true);
                              },
                              refreshListener:
                                  (Function(GiveGiftModel) refreshCallBack) {},
                            );
                          },
                        ),
                        Padding(
                          padding: EdgeInsets.only(
                            top: FrameSize.px(5),
                          ),
                          child: Container(),
                        ),

                        BlocBuilder<GiftMoveBlocModel3, GiveGiftModel?>(
                          buildWhen: (previous, current) {
                            return true;
                          },
                          builder: (context, giveGiftModel) {
                            if (giveGiftModel == null) {
                              return Container();
                            }
                            return GiftsGiveView(
                              giveGiftModel: giveGiftModel,
                              count: giveGiftModel.count,
                              animationComplete: (_giveGifModel) {
                                _giveGiftModel3 = null;
                                checkGiftMoveMsg(null, next: true);
                              },
                              refreshListener:
                                  (Function(GiveGiftModel) refreshCallBack) {},
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: FrameSize.px(5)),
                  BlocBuilder<SheetGiftsBottomBlocModel, double?>(
                    builder: (context, height) {
                      return SizedBox(
                        height: FrameSize.px(height ?? 0),
                      );
                    },
                  ),
                  BlocBuilder<UserJoinLiveRoomModel, FBUserInfo?>(
                    builder: (context, joinedUserInfo) {
                      return TipsLoginView(
                        userInfo: joinedUserInfo,
                        animationCompete: () {
                          if (_userJoinQueue.isNotEmpty) {
                            _joinedUserInfo = _userJoinQueue.removeFirst();
                          } else {
                            _joinedUserInfo = null;
                          }
                          _userJoinLiveRoomModel.add(_joinedUserInfo!);
                        },
                      );
                    },
                  ),
                ],
              )),
          Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: FrameSize.px(5)),
              BlocBuilder<ChatListBlocModel, Map?>(
                builder: (context, msgMap) {
                  return ChartListView(
                    tips: roomInfon?.tips,
                    isOverlayViewPush: false,
                    roomInfoObject: roomInfon,
                    bloc: _liveRoomWebBloc,
                  );
                },
              ),
              SizedBox(height: FrameSize.px(10)),
              BlocBuilder<RoomBottomBlocModel, RefreshState?>(
                buildWhen: (previous, current) {
                  return true;
                },
                builder: (context, value) {
                  if (_isanchor!) {
                    return AnchorBottomView(
                      isStartLive: isStartLive,
                      roomId: widget.roomId,
                      shareType: shareType.toString(),
                      // 发送弹幕消息
                      sendClickBlock: _fbApiSendLiveMsg,
                      buttonClickBlock: (index, text) {
                        if (index == 0) {
                          // 发送弹幕消息
                          // _fbApiSendLiveMsg(text);
                        } else if (index == 1) {
                        } else if (index == 3) {
                          DialogUtil.confirmEndLiveTip(context,
                              onPressed: _anchorCloseRoom);
                        }
                      },
                      liveBloc: _liveRoomWebBloc,
                      liveShop: _liveRoomWebBloc,
                      goodsLogic: _liveRoomWebBloc,
                    );
                  }
                  return AudiencesBottomView(
                    roomId: widget.roomId,
                    liveBloc: _liveRoomWebBloc,
                    liveShop: _liveRoomWebBloc,
                    shareType: shareType.toString(),
                    // 发送弹幕消息
                    sendClickBlock: _fbApiSendLiveMsg,
                    upLikeClickBlock: (likeNum, typeString) {
                      if (typeString == 'animation') {
                        final AnimationController controller =
                            AnimationController(
                                duration: const Duration(milliseconds: 1500),
                                vsync: this);

                        controller.forward().orCancel;
                        upLickWidgetList.add(UpClickAnimation(
                          randomNum: Random().nextInt(6),
                          controller: controller,
                        ));
                        animationControllerList.add(controller);
                        widgetListStreamController.sink.add(upLickWidgetList);
                      } else {
                        var _thumbCount = onlineUserCountModel!.thumbCount;
                        if (_thumbCount != null) {
                          _thumbCount += likeNum;
                          onlineUserCountModel!.thumbCount = _thumbCount;
                        }

                        // 点赞
                        _likeClickPreviewBlocModel
                            .add(onlineUserCountModel!.thumbCount);
                        if (isClickUp == false) {
                          _fbApiSendLiveMsg("为主播点赞了");
                          isClickUp = true;
                        }
                      }
                    },
                    roomInfoObject: roomInfon!,
                    goodsLogic: _liveRoomWebBloc,
                  );
                },
              ),
              SizedBox(height: FrameSize.px(7))
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _likeClickBlocModel?.close();
    _giftClickBlocModel?.close();
    // 网络异常计时器取消
    netErrorTimerCancel();
    _liveRoomWebBloc.close();
    if (stopLive == false) {
      widgetListStreamController.close();
      for (final AnimationController c in animationControllerList) {
        c.dispose();
      }
      upLickWidgetList.clear();
      animationControllerList.clear();

      _subscription?.cancel();
      _subscription = null;
      _connectivitySubscription.cancel();
      _loginOut();
    }
    super.dispose();
  }

  //初始化即构SDK
  void _initZegoExpressEngine() {
    Wakelock.enable(); //设置屏幕常亮
    final int appID = configProvider.liveAppId; // 请通过官网注册获取，

    // ZegoSDKManager.createEngine(appID, "wss://webliveroom-test.zego.im/ws");
    ZegoSDKManager.createEngine(
      appID,
      server: configProvider.liveWssUrl,
      appSign: '',
      enablePlatformView: false,
      scenario: ZegoScenario.General,
    );
  }

  // 监听Zegeo公共回调
  void _zegoOnEvent() {
    // 房间状态回调
    ZegoSDKManager.onRoomStateUpdate =
        (roomID, roomState, errorCode, extendedData) {
      fbApi.fbLogger.info('onRoomStateUpdate $errorCode');
      if (roomState == ZegoRoomState.Connected) {
        netErrorTimerCancel();
      }

      /// 在1002051改变时需要清除计时器。
      if (errorCode != 1002051) {
        dismissAllToast();
        netErrorTimerCancel();
      }

      // 房间状态更新回调，登陆房间后，当房间连接状态发生变更（如出现房间断开，登陆认证失败等情况），SDK会通过该回调通知
      // 监听网络状态
      if (errorCode == 1002030 || errorCode == 1002031) {
        _showConfirmDialog(() {
          Loading.showConfirmDialog(
              context,
              {
                'content': '网络问题，无法开启直播，退出房间重试',
                'confirmText': '退出',
                'cancelShow': false
              },
              _goback);
        });
      } else if (errorCode == 1002051) {
        isNetError = true;

        /// 好的，那需求调整一下：如何出现的是1002051的错误代码，
        /// 就可以延后15秒再提示“网络连接不稳定，正在重新连接”， 15秒内连接成功后，不提示内容。
        netErrorStart(onComplete: () {
          if (isNetError) {
            // 网络原因导致房间连接临时中断，正在重试
            _openLoading('网络连接不稳定，正在重新连接', width: 260, callback: () {
              Loading.showConfirmDialog(context, {
                'content': '连接不成功，检查网络之后再试？',
                'confirmText': '退出再试',
                'cancelShow': false
              }, () {
                final String _closeTime = formatDateTime();
                // 主播关闭页
                final CloseRoomModel closeRoomModel = CloseRoomModel(
                    roomId: widget.roomId,
                    liveTime: roomInfon!.liveTime,
                    closeTime: _closeTime,
                    audience: onlineUserCountModel!.total,
                    thumbCount: onlineUserCountModel!.thumbCount,
                    coin: '0');
                _navigatorToAnchorClosePage(closeRoomModel);
              });
            });
          }
        });
      } else if (errorCode == 1002052 || errorCode == 1002053) {
        Loading.showConfirmDialog(context, {
          'content': '连接不成功，检查网络之后再试？',
          'confirmText': '退出再试',
          'cancelShow': false
        }, () {
          final String _closeTime = formatDateTime();
          // 主播关闭页
          final CloseRoomModel closeRoomModel = CloseRoomModel(
              roomId: widget.roomId,
              liveTime: roomInfon!.liveTime,
              closeTime: _closeTime,
              audience: onlineUserCountModel!.total,
              thumbCount: onlineUserCountModel!.thumbCount,
              coin: '0');
          _navigatorToAnchorClosePage(closeRoomModel);
        });
      } else if (errorCode == 1000055 || errorCode == 1000060) {
        myFailToast('网络错误，请检查网络配置',
            duration: const Duration(days: 1)); // 固定，半透明【刷新】，重新登录房间
      } else if (errorCode == 1002050) {
        _showConfirmDialog(() {
          Loading.showConfirmDialog(context, {
            'content': '你的账号当前在另一台设备中登录，如果这不是你本人的操作，请立刻重新登录修改密码',
            'confirmText': '退出',
            'cancelShow': false
          }, () {
            _goback();
            EventBusManager.eventBus.fire(RefreshRoomListModel(true));
          });
        });
      }
    };
  }

  // 监听推流回调
  void _zegoOnPushEvent() {
    ZegoSDKManager.onIMRecvCustomCommand = (roomID, command) {
      final Map? commandMap = jsonDecode(command);
      if (commandMap != null &&
          commandMap['mType'] == 1 &&
          commandMap['msg'] != null) {
        myToast(commandMap['msg'], duration: const Duration(seconds: 3));
      }
    };
    // 推流回调状态回调
    ZegoSDKManager.onPublisherStateUpdate =
        (streamID, state, errorCode, extendedData) {
      // 调用推流接口成功后，当推流器状态发生变更，如出现网络中断导致推流异常等情况，SDK在重试推流的同时，会通过该回调通知
      fbApi.fbLogger.info('onPublisherStateUpdate $state');

      if (state == ZegoPublisherState.NoPublish && errorCode != 0) {
        if (errorCode == 1103027) {
          //1103027
          stopLive = true;
          _loginOut();
          DialogUtil.liveWillClose(context, onPressed: () {
            roomInfon!.status = 4;
            anchorCloseLive();
          });
        }
      } else if (state == ZegoPublisherState.PublishRequesting) {
        // 重试中
      } else if (state == ZegoPublisherState.Publishing) {
        // 发送流附加消息告诉其他端是否镜像
        ZegoSDKManager.setStreamExtraInfo(
            sendSteamInfo(
                screenShare: false,
                mirror: widget.isWebFlip,
                liveValueModel: widget.liveValueModel!),
            webStreamID: widget.roomId!,
            nativeChannel: ZegoPublishChannel.Main);

        _closeLoading();

        if (isStartLive) {
          anchorStartlive();

          /// 已采用状态管理，暂时隐藏setState
          isStartLive = false;
          _roomBottomBlocModel.add(true);
        }
        ZegoSDKManager.setVideoConfig(
          videoConfigWeb: ZegoWebVideoConfig(
            localStream: _liveRoomWebBloc.mediaModel!.src,
            constraints: ZegoWebVideoOptions(
              width: 1920,
              height: 1080,
              frameRate: 25,
              maxBitrate: 1500,
            ),
          ),
        );
        // 推流成功，开启定时器轮询线上人数
        startTimerGetOnline();
      }
    };
  }

  // 监听拉流回调
  void _zegoOnPullEvent() {
    // 拉流状态回调
    ZegoSDKManager.onPlayerStateUpdate =
        (streamID, state, errorCode, extendedData) {
      // 调用拉流接口成功后，当拉流器状态发生变更，如出现网络中断导致推流异常等情况，SDK在重试拉流的同时，会通过该回调通知

      showImageFilter = false;
      _showImageFilterBlocModel.add(showImageFilter);
      fbApi.fbLogger.info('onPlayerStateUpdate $state');
      if (state == ZegoPlayerState.NoPlay) {
        // 没拉流
        // 主播被禁播
        if (errorCode == 1004099) {
          _showConfirmDialog(() {
            Loading.showConfirmDialog(
                context,
                {
                  'content': '由于直播内容违规，主播被管理员禁播。',
                  'confirmText': '退出',
                  'cancelShow': false
                },
                _goback);
          });
        } else if (errorCode != 0) {
          _showConfirmDialog(() {
            Loading.showConfirmDialog(
                context,
                {
                  'content': '拉流失败，请重试！',
                  'confirmText': '确认',
                  'cancelShow': false
                },
                _setStreamAndTexture);
          });
        }
      } else if (state == ZegoPlayerState.PlayRequesting) {
      } else if (state == ZegoPlayerState.Playing) {
        showImageFilter = true;
        _showImageFilterBlocModel.add(showImageFilter);
        _closeLoading();
        // 通知服务端
        if (isPlaying) {
          // 上报服务器
          setLiveEnter();
          // 通知FB[防止调用了两次进入房间，先注释]
          // _fbApiEnterLiveRoom();
          isPlaying = false;
        }
        // 拉流成功，开启定时器轮询线上人数
        startTimerGetOnline();
      }
    };

    ZegoSDKManager.onRoomStreamUpdate =
        (roomID, updateType, streamList, extendedData) {
      if (updateType == ZegoUpdateType.Add) {
        for (var i = 0; i < streamList.length; i++) {
          if (isPlaying) {
            ZegoSDKManager.startPlayingStream(streamList[i].streamID!).then(
                (value) {
              _liveRoomWebBloc.mediaModel!.src = value;
              _liveRoomWebBloc.mediaModel!.muted = false;
              if (!widget.shared) {
                _liveRoomWebBloc.mediaModel!.autoplay = true;
                _liveRoomWebBloc.mediaModel!.play();
              } else {
                _livePlayMaskBlocModel?.add(true);
              }
            }, onError: (e) {
              fbApi.fbLogger
                  .warning('startPlayingStream failed, ${e.toString()}');
            });
          } else {
            dismissAllToast();
          }
        }
      } else if (updateType == ZegoUpdateType.Delete) {
        // 查询房间状态
        getRoomStatus();
      }
    };
  }

  // 错误弹窗
  void errorDialog(String content) {
    _showConfirmDialog(() {
      Loading.showConfirmDialog(
          context,
          {'content': content, 'confirmText': '退出', 'cancelShow': false},
          _goback);
    });
  }

  // 登录房间
  Future _zegoLoginRoom() async {
    final Completer _completer = Completer();
    if (_isanchor!) {
      await ZegoSDKManager.loginRoom(
        roomId: _liveRoomWebBloc.zegoTokenModel.roomId!,
        token: _liveRoomWebBloc.zegoTokenModel.token!,
        userId: _liveRoomWebBloc.zegoTokenModel.userId!,
        userUpdate: true,
      ).then((value) {
        _completer.complete(true);
        //
      }, onError: (e) {
        _completer.completeError(e);
      });
    } else {
      await ZegoSDKManager.loginRoom(
        roomId: _liveRoomWebBloc.zegoTokenModel.roomId!,
        token: _liveRoomWebBloc.zegoTokenModel.token!,
        userId: _liveRoomWebBloc.zegoTokenModel.userId!,
        userUpdate: true,
      ).then((value) {
        _completer.complete(true);
      }, onError: (e) {
        _completer.completeError(e);
      });
    }
    return _completer.future;
  }

  // 主播推流
  void _anchorPushStream(String roomId, localStream) {
    ZegoSDKManager.startPublishingStream(roomId,
        localStream: localStream,
        webPublishOption:
            ZegoWebPublishOption(streamParams: '', extraInfo: "web_Publish"));
  }

  // 设置推拉流及视频画面
  Future _setStreamAndTexture() async {
    _liveRoomWebBloc.videoView = ZegoWwVideoView(
      onMediaModelCreated: (mediaModel) {
        _liveRoomWebBloc.mediaModel = mediaModel;
        _livePreviewBlocModel.add(0);
      },
    );

    // 监听房间回调状态
    _zegoOnEvent();
    if (_isanchor!) {
      //  注册推流回调事件
      _zegoOnPushEvent();
    } else {
      // 拉流回调事件
      _zegoOnPullEvent();
    }
    // 登录房间
    await _zegoLoginRoom();

    if (_isanchor!) {
      //  推流
      ZegoSDKManager.createStream().then(
        (value) {
          _liveRoomWebBloc.mediaModel!.src = value;
          _liveRoomWebBloc.mediaModel!.src.active
              ? _liveRoomWebBloc.mediaModel!.play()
              : _liveRoomWebBloc.mediaModel!.pause();
          _liveRoomWebBloc.mediaModel!.muted = true;
          localStream = value;
          _anchorPushStream(widget.roomId!, localStream);
        },
        onError: (e) {
          if ('$e'.contains('AbortError')) {
            // 中止错误
            errorDialog('检测到麦克风或摄像头设备异常或者驱动异常');
          } else if ('$e'.contains('NotAllowedError')) {
            // 拒绝错误
            errorDialog('检测到麦克风或摄像头权限受限，请授权同意调用');
          } else if ('$e'.contains('NotFoundError')) {
            // 找不到的错误
            errorDialog('检测到缺少麦克风或摄像头，无法开始直播');
          } else if ('$e'.contains('NotReadableError')) {
            // 无法读取的错误
            errorDialog('麦克风或摄像头缺失或被系统禁止，无法进行直播');
          } else if ('$e'.contains('NotConstrainedError')) {
            // 无法满足要求错误
            errorDialog('当前设备版本太低，无法进行直播');
          } else if ('$e'.contains('SecurityError')) {
            // 安全错误
            errorDialog('当前域名受到播放限制，无法开始直播');
          } else if ('$e'.contains('TypeError')) {
            // 类型错误
            errorDialog('直播传参出现错误，无法开始直播');
          }
        },
      );
    } else {}
  }

  // 清除定时器
  void _cancelTimer() {
    _timer?.cancel();
  }

  // 主播直播结束-主播跳转
  void _navigatorToAnchorClosePage(CloseRoomModel closeRoomModel) {
    RouteUtil.push(
        context,
        CloseRoomAnchorWeb(
          closeRoomModel: closeRoomModel,
          roomInfoObject: roomInfon,
        ),
        "liveCloseRoom",
        isReplace: true);
  }

  // 直播结束-用户跳转
  void _navigatorToAudienceClosePage() {
    final nickName = roomInfon?.nickName ?? '';
    final anchorId = roomInfon?.anchorId ?? '';
    final avatarUrl = roomInfon?.avatarUrl ?? '';
    final roomLogo = roomInfon?.roomLogo ?? '';
    final serverId = roomInfon?.serverId ?? '';
    final int audienceCount = onlineUserCountModel?.total ?? 0;
    final CloseAudienceRoomModel closeAudienceRoomModel =
        CloseAudienceRoomModel(
      nickName: nickName,
      avatarUrl: avatarUrl,
      audienceCount: audienceCount,
      roomLogo: roomLogo,
      userId: anchorId,
      serverId: serverId,
    );
    RouteUtil.push(
        context,
        CloseAudienceRoom(
            roomId: roomInfon!.roomId,
            closeAudienceRoomModel: closeAudienceRoomModel),
        "liveCloseAudienceRoom",
        isReplace: true);
  }

  // 退出房间，销毁房间和实例
  void _destroyZego() {
    if (_isanchor!) {
      ZegoSDKManager.stopPublishingStream(streamID: widget.roomId!);
      ZegoSDKManager.destroyStream(localStream);
    } else {
      ZegoSDKManager.stopPlayingStream(widget.roomId!);
    }
    ZegoSDKManager.logoutRoom(widget.roomId!);
  }

  // 页面登出
  void _loginOut() {
    // 销毁实例
    _destroyZego();
    // 关闭定线上人数查询定时器
    _cancelTimer();
    // 关闭常显示弹窗
    dismissAllToast();
    //关闭屏幕常亮
    Wakelock.disable();
    // 移除IM消息回调
    _fbApiRemoveLiveMsgHandler();
  }

  // 主播关闭直播下线
  Future _anchorCloseRoom() async {
    await anchorCloseLive();
    // 统计上报
    await setLiveExit();
    // FB 主播关闭直播上报
    _fbApiStopLive();
  }

  // 观众关闭直播页面，退出房间
  Future _audienceCloseRoom() async {
    // 手势返回
    _goback();
    EventBusManager.eventBus.fire(RefreshRoomListModel(true));
    // 统计上报
    await setLiveExit();
    // FB 用户退出上报
    _fbApiExitLiveRoom();
  }

  // 返回上一页
  void _goback() {
    Navigator.of(context).pop();
  }

  //网络监测
  // ignore: avoid_void_async
  void _updateConnectionStatus(ConnectivityResult result) async {}

  void checkGiftMoveMsg(GiveGiftModel? giveGiftModel, {bool next = false}) {
    if (!next) {
      _giftQueue.addLast(giveGiftModel);
    }
/**/

    if (_giveGiftModel3 == null) {
      if (_giftQueue.isNotEmpty) {
        _giveGiftModel3 = _giftQueue.removeFirst()!;
        _giveGiftModel3!.count = 1;
        Future.delayed(
            const Duration(
              milliseconds: 30,
            ), () {
          _giftMoveBlocModel3.add(_giveGiftModel3);
        });
      }
    } else if (_giftQueue.isNotEmpty) {
      if (next) {
        final GiveGiftModel? firstGiftModel = _giftQueue.first;
        if (_giftMoveBlocModel3.containsGiveGiftModel(
            firstGiftModel, _giveGiftModel3)) {
          var _count = _giveGiftModel3!.count;
          if (_count != null) {
            _count++;
            _giveGiftModel3!.count = _count;
          }

          final GiveGiftModel nextModel = _giftQueue.removeFirst()!;
          nextModel.count = _giveGiftModel3!.count;
          _giveGiftModel3 = nextModel;
          _giftMoveBlocModel3.add(_giveGiftModel3);
        }
      }
    } else {
      if (next) {
        _giftMoveBlocModel3.add(null);
      }
    }

    if (_giveGiftModel2 == null) {
      if (_giftQueue.isNotEmpty) {
        _giveGiftModel2 = _giftQueue.removeFirst();
        _giveGiftModel2!.count = 1;
        Future.delayed(const Duration(milliseconds: 100), () {
          _giftMoveBlocModel2.add(_giveGiftModel2!);
        });
      }
    } else if (_giftQueue.isNotEmpty) {
      if (next) {
        final GiveGiftModel? firstGiftModel = _giftQueue.first;
        if (_giftMoveBlocModel2.containsGiveGiftModel(
            firstGiftModel, _giveGiftModel2)) {
          var _count = _giveGiftModel2!.count;
          if (_count != null) {
            _count++;
            _giveGiftModel2!.count = _count;
          }

          final GiveGiftModel nextModel = _giftQueue.removeFirst()!;
          nextModel.count = _giveGiftModel2!.count;
          _giveGiftModel2 = nextModel;
          _giftMoveBlocModel2.add(nextModel);
        }
      }
    } else {
      if (next) {
        _giftMoveBlocModel2.add(null);
      }
    }

    if (_giveGiftModel1 == null) {
      if (_giftQueue.isNotEmpty) {
        _giveGiftModel1 = _giftQueue.removeFirst();
        _giveGiftModel1!.count = 1;
        Future.delayed(const Duration(milliseconds: 150), () {
          _giftMoveBlocModel.add(_giveGiftModel1);
        });
      }
    } else if (_giftQueue.isNotEmpty) {
      if (next) {
        final GiveGiftModel? firstGiftModel = _giftQueue.first;
        if (_giftMoveBlocModel.containsGiveGiftModel(
            firstGiftModel, _giveGiftModel1)) {
          var _count = _giveGiftModel1!.count;
          if (_count != null) {
            _count++;
            _giveGiftModel1!.count = _count;
          }

          final GiveGiftModel nextModel = _giftQueue.removeFirst()!;
          nextModel.count = _giveGiftModel1!.count;
          _giveGiftModel1 = nextModel;

          _giftMoveBlocModel.add(nextModel);
        }
      }
    } else {
      if (next) {
        _giftMoveBlocModel.add(null);
      }
    }
  }

  @override
  void onLiveStop() {
    // TODO: implement onLiveStop
  }

  /// 收到聊天弹幕消息
  /// @param user: 发送弹幕消息的用户
  /// @param json: 发送弹幕消息时的自定义消息
  @override
  void onReceiveChatMsg(FBUserInfo user, String json) {
    final Map textMap = jsonDecode(json);
    final String? text = textMap["content"];
    final Map chatMap = {"user": user, "text": text, "type": "user_chat"};
    widget.liveValueModel!.chatList.add(chatMap);
    _chatListBlocModel.add(chatMap);
  }

  /// 收到送礼消息
  /// @param user: 送礼物的用户
  /// @param json: 发送礼物消息时的自定义消息
  @override
  void onSendGift(FBUserInfo user, String jsonMsg) {
    getonlineCount();

    final Map<String, dynamic>? giftInfo = json.decode(jsonMsg);
    final GiveGiftModel giveGiftModel =
        GiveGiftModel(sendUserInfo: user, giftInfo: giftInfo);
    checkGiftMoveMsg(giveGiftModel);
    final Map chatMap = {"user": user, "text": giftInfo, "type": "give_gifts"};
    widget.liveValueModel!.chatList.add(chatMap);
    _chatListBlocModel.add(chatMap);
  }

  /// 用户进入直播间
  /// @param user: 进入直播间的用户
  @override
  void onUserEnter(FBUserInfo user) {
    if (user.userId != roomInfon!.anchorId) {
      //用户进入直播间
      final Map chatMap = {"user": user, "text": "来了", "type": "user_coming"};
      widget.liveValueModel!.chatList.add(chatMap);

      _chatListBlocModel.add(chatMap);

      var _total = onlineUserCountModel?.total;
      if (_total != null) {
        ++_total;
        onlineUserCountModel?.total = _total;
      }

      _onlineUserCountModel.add(onlineUserCountModel?.total);
      _userJoinQueue.addLast(user);
      if (_joinedUserInfo == null) {
        _joinedUserInfo = _userJoinQueue.removeFirst();
        _userJoinLiveRoomModel.add(_joinedUserInfo);
      }
    }
  }

  /// 用户退出直播间
  /// @param user: 退出直播间的用户
  @override
  void onUserQuit(FBUserInfo user) {
    var _total = onlineUserCountModel!.total;
    if (_total != null) {
      _total--;
      onlineUserCountModel!.total = _total;
    }

    _onlineUserCountModel.add(onlineUserCountModel!.total);
  }

  // 获取当前时间
  String formatDateTime() {
    final dateTime = DateTime.now();
    final String _str = dateTime.toString();
    return _str.substring(0, 19);
  }

  // 踢出服务器
  @override
  void onKickOutOfGuild() {
    if (!_isanchor!) {
      return;
    }
    _showConfirmDialog(() {
      myToastLong('您已被管理员踢出服务器。如果有疑问，请联系管理员',
          duration: const Duration(days: 1)); // 固定半透明
    });
    // 延迟3S,关闭直播间
    Future.delayed(const Duration(seconds: 3), _anchorCloseRoom);
  }

  @override
  void onGoodsNotice(FBUserInfo user, String type, String json) {
    // TODO: implement onGoodsNotice
  }
}
