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
  final bool? isAnchor; //???????????????
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
  bool isStartLive = true; //????????????????????????
  bool isPlaying = true; //?????????????????????
  final int _previewViewID = -1;
  Timer? _timer;
  bool? _isanchor; //???????????????
  List onlineUser = []; //??????????????????

  OnlineUserCount? onlineUserCountModel; //??????????????????
  List? userOnlinelist; //????????????????????????
  late Loading _loading;
  bool isClickUp = false; //???????????????
  final Queue _userJoinQueue = Queue();
  final Queue<GiveGiftModel?> _giftQueue = Queue();
  FBUserInfo? _joinedUserInfo;
  Widget? _bottomView;
  int? shareType; //???????????????0-????????????1-??????
  GiveGiftModel? _giveGiftModel1, _giveGiftModel2, _giveGiftModel3;
  int deviceSeleteValue = -1; //????????????????????????
  bool showImageFilter = false; //????????????????????????
  bool stopLive = false; //???????????????
  /// ????????????--start
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

  /// ????????????--end
  final Connectivity _connectivity = Connectivity(); //????????????
  late StreamSubscription<ConnectivityResult>
      _connectivitySubscription; //??????????????????

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
    //?????????ZegoSDK
    _initZegoExpressEngine();
    // ??????????????????
    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
    WidgetsBinding.instance!.addPostFrameCallback((timeStamp) {
      // ??????FB????????????
      _fbApiRegisterMsgHandler();
      // ????????????loading
      _openLoading("???????????????...");
      //??????????????????
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

  // ?????????loading
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
        // ????????????
        Loading.showConfirmDialog(
            context,
            {
              'content': '??????????????????????????????????????????????????????',
              'confirmText': '??????',
              'cancelShow': false
            },
            _goback);
      });
    });
  }

  // ??????loading
  void _closeLoading() {
    Loading.cancelLoadingTimer();
    _loading.dismiss();
  }

  // ??????showConfirmDialog
  void _showConfirmDialog(Function _callback) {
    _closeLoading();
    _callback();
  }

  //????????????
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
        // ??????token??????????????????
        await getZegoToken();
      } else if (roomInfon!.status == 3) {
        _showConfirmDialog(() {
          Loading.showConfirmDialog(
              context,
              {
                'content': '??????????????????????????????????????????',
                'confirmText': '??????',
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
                'content': '???????????????????????????',
                'confirmText': '??????',
                'cancelShow': false
              },
              _goback);
        });
      }
    }
  }

  //??????
  Future getZegoToken() async {
    final Map resultData = await Api.getZegoToken(widget.roomId!);

    if (resultData["code"] == 200) {
      _liveRoomWebBloc.zegoTokenModel =
          ZegoTokenModel.fromJson(resultData["data"]);
      if (_liveRoomWebBloc.zegoTokenModel.userId ==
          _liveRoomWebBloc.zegoTokenModel.anchorId) {
        //???????????????ID??????  ??????????????????
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

  //??????????????????
  Future getonlineCount() async {
    final Map onlineData = await Api.getOnlineCount(widget.roomId!, roomInfon!);
    if (onlineData["code"] == 200) {
      onlineUserCountModel = OnlineUserCount.fromJson(onlineData["data"]);
      _onlineUserCountModel.add(onlineUserCountModel!.total);
      _likeClickPreviewBlocModel.add(onlineUserCountModel!.thumbCount);
    }
  }

  // ?????????????????????????????????
  Future setLiveEnter() async {
    await Api.liveEnter(
        widget.roomId, _liveRoomWebBloc.zegoTokenModel.userToken);

    // ???????????????????????????
    if (!widget.isAnchor!) {
      LiveLogUp.liveEnter(
          true,

          /// todo web???????????????????????????????????????
          widget.roomId!,
          roomInfon!.serverId,
          roomInfon!.channelId);
    }

    await getonlineCount(); //?????????????????????????????????
  }

  // ???????????????????????????
  Future setLiveExit() async {
    await Api.liveExit(widget.roomId, _liveRoomWebBloc.zegoTokenModel.userToken,
        widget.isAnchor!, roomInfon!);
  }

  // ????????????????????????
  void startTimerGetOnline() {
    _cancelTimer();
    _timer = Timer.periodic(const Duration(seconds: 30), (timer) {
      getonlineCount();
    });
  }

  // ??????????????????
  Future anchorStartlive() async {
    final Map status = await Api.starteLive(widget.roomId!);
    if (status['code'] == 200) {
      showImageFilter = true;
      _showImageFilterBlocModel.add(showImageFilter);
      // ???????????????
      await setLiveEnter();
      // ??????FB
      _fbApiEnterLiveRoom();
    } else {
      _showConfirmDialog(() {
        Loading.showConfirmDialog(
            context,
            {'content': '???????????????????????????', 'cancelText': '??????', 'confirmText': '??????'},
            anchorStartlive, cancelCallback: () {
          _goback();
        });
      });
    }
  }

  // ??????????????????
  Future anchorCloseLive() async {
    final Map status = await Api.closeLiveRoom(widget.roomId!);
    if (status["code"] == 200) {
      final CloseRoomModel closeRoomModel =
          CloseRoomModel.fromJson(status["data"]);
      _navigatorToAnchorClosePage(closeRoomModel);
    }
  }

  // ???????????????????????????
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
                'content': '??????????????????????????????????????????????????????',
                'confirmText': '??????',
                'cancelShow': false
              },
              _goback);
        });
      } else if (roomInfo.status == 1 || roomInfo.status == 2) {
        //  ???????????????
        showImageFilter = false;
        _showImageFilterBlocModel.add(showImageFilter);
        _showConfirmDialog(() {
          myToastLong('????????????????????????Ta???????????????????????????????????????',
              duration: const Duration(days: 1)); // ???????????????
        });
      }
    }
  }

  // FBAPI--??????????????????
  void _fbApiStopLive() {
    fbApi.stopLive(roomInfon!.serverId, roomInfon!.channelId,
        _liveRoomWebBloc.zegoTokenModel.roomId!);
  }

  // FBAPI--??????????????????
  void _fbApiEnterLiveRoom() {
    fbApi.enterLiveRoom(
        roomInfon!.channelId,
        _liveRoomWebBloc.zegoTokenModel.roomId!,
        _isanchor!,
        roomInfon!.serverId,
        false);
  }

  // FBAPI--??????????????????
  void _fbApiExitLiveRoom() {
    fbApi.exitLiveRoom(roomInfon!.serverId, roomInfon!.channelId,
        _liveRoomWebBloc.zegoTokenModel.roomId!);
  }

  // FBAPI--??????????????????
  void _fbApiSendLiveMsg(String content) {
    LiveLogUp.send(content, roomInfon!);
    final String json = _formatMsgJSON(content);
    fbApi.sendLiveMsg(roomInfon!.serverId, roomInfon!.channelId,
        _liveRoomWebBloc.zegoTokenModel.roomId!, json);
  }

  // FBAPI--????????????
  static String _formatMsgJSON(String content) {
    final Map msgJSON = {};
    msgJSON['content'] = content;
    return json.encode(msgJSON);
  }

  //2???????????????
  void _fbApiRegisterMsgHandler() {
    fbApi.registerLiveMsgHandler(this);
  }

  //3???????????????
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

          /// ????????????????????????????????????????????????????????????FBUserInfo
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
              //??????????????????
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
                                  //??????90???
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
                                              //??????????????????View
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
                                              // ??????????????????
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

  //??????view
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
                        ), //?????????bug
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
                      // ??????????????????
                      sendClickBlock: _fbApiSendLiveMsg,
                      buttonClickBlock: (index, text) {
                        if (index == 0) {
                          // ??????????????????
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
                    // ??????????????????
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

                        // ??????
                        _likeClickPreviewBlocModel
                            .add(onlineUserCountModel!.thumbCount);
                        if (isClickUp == false) {
                          _fbApiSendLiveMsg("??????????????????");
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
    // ???????????????????????????
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

  //???????????????SDK
  void _initZegoExpressEngine() {
    Wakelock.enable(); //??????????????????
    final int appID = configProvider.liveAppId; // ??????????????????????????????

    // ZegoSDKManager.createEngine(appID, "wss://webliveroom-test.zego.im/ws");
    ZegoSDKManager.createEngine(
      appID,
      server: configProvider.liveWssUrl,
      appSign: '',
      enablePlatformView: false,
      scenario: ZegoScenario.General,
    );
  }

  // ??????Zegeo????????????
  void _zegoOnEvent() {
    // ??????????????????
    ZegoSDKManager.onRoomStateUpdate =
        (roomID, roomState, errorCode, extendedData) {
      fbApi.fbLogger.info('onRoomStateUpdate $errorCode');
      if (roomState == ZegoRoomState.Connected) {
        netErrorTimerCancel();
      }

      /// ???1002051?????????????????????????????????
      if (errorCode != 1002051) {
        dismissAllToast();
        netErrorTimerCancel();
      }

      // ??????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????SDK????????????????????????
      // ??????????????????
      if (errorCode == 1002030 || errorCode == 1002031) {
        _showConfirmDialog(() {
          Loading.showConfirmDialog(
              context,
              {
                'content': '??????????????????????????????????????????????????????',
                'confirmText': '??????',
                'cancelShow': false
              },
              _goback);
        });
      } else if (errorCode == 1002051) {
        isNetError = true;

        /// ???????????????????????????????????????????????????1002051??????????????????
        /// ???????????????15??????????????????????????????????????????????????????????????? 15??????????????????????????????????????????
        netErrorStart(onComplete: () {
          if (isNetError) {
            // ?????????????????????????????????????????????????????????
            _openLoading('??????????????????????????????????????????', width: 260, callback: () {
              Loading.showConfirmDialog(context, {
                'content': '?????????????????????????????????????????????',
                'confirmText': '????????????',
                'cancelShow': false
              }, () {
                final String _closeTime = formatDateTime();
                // ???????????????
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
          'content': '?????????????????????????????????????????????',
          'confirmText': '????????????',
          'cancelShow': false
        }, () {
          final String _closeTime = formatDateTime();
          // ???????????????
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
        myFailToast('????????????????????????????????????',
            duration: const Duration(days: 1)); // ???????????????????????????????????????????????????
      } else if (errorCode == 1002050) {
        _showConfirmDialog(() {
          Loading.showConfirmDialog(context, {
            'content': '?????????????????????????????????????????????????????????????????????????????????????????????????????????????????????',
            'confirmText': '??????',
            'cancelShow': false
          }, () {
            _goback();
            EventBusManager.eventBus.fire(RefreshRoomListModel(true));
          });
        });
      }
    };
  }

  // ??????????????????
  void _zegoOnPushEvent() {
    ZegoSDKManager.onIMRecvCustomCommand = (roomID, command) {
      final Map? commandMap = jsonDecode(command);
      if (commandMap != null &&
          commandMap['mType'] == 1 &&
          commandMap['msg'] != null) {
        myToast(commandMap['msg'], duration: const Duration(seconds: 3));
      }
    };
    // ????????????????????????
    ZegoSDKManager.onPublisherStateUpdate =
        (streamID, state, errorCode, extendedData) {
      // ??????????????????????????????????????????????????????????????????????????????????????????????????????????????????SDK???????????????????????????????????????????????????
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
        // ?????????
      } else if (state == ZegoPublisherState.Publishing) {
        // ????????????????????????????????????????????????
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

          /// ????????????????????????????????????setState
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
        // ????????????????????????????????????????????????
        startTimerGetOnline();
      }
    };
  }

  // ??????????????????
  void _zegoOnPullEvent() {
    // ??????????????????
    ZegoSDKManager.onPlayerStateUpdate =
        (streamID, state, errorCode, extendedData) {
      // ??????????????????????????????????????????????????????????????????????????????????????????????????????????????????SDK???????????????????????????????????????????????????

      showImageFilter = false;
      _showImageFilterBlocModel.add(showImageFilter);
      fbApi.fbLogger.info('onPlayerStateUpdate $state');
      if (state == ZegoPlayerState.NoPlay) {
        // ?????????
        // ???????????????
        if (errorCode == 1004099) {
          _showConfirmDialog(() {
            Loading.showConfirmDialog(
                context,
                {
                  'content': '??????????????????????????????????????????????????????',
                  'confirmText': '??????',
                  'cancelShow': false
                },
                _goback);
          });
        } else if (errorCode != 0) {
          _showConfirmDialog(() {
            Loading.showConfirmDialog(
                context,
                {
                  'content': '???????????????????????????',
                  'confirmText': '??????',
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
        // ???????????????
        if (isPlaying) {
          // ???????????????
          setLiveEnter();
          // ??????FB[?????????????????????????????????????????????]
          // _fbApiEnterLiveRoom();
          isPlaying = false;
        }
        // ????????????????????????????????????????????????
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
        // ??????????????????
        getRoomStatus();
      }
    };
  }

  // ????????????
  void errorDialog(String content) {
    _showConfirmDialog(() {
      Loading.showConfirmDialog(
          context,
          {'content': content, 'confirmText': '??????', 'cancelShow': false},
          _goback);
    });
  }

  // ????????????
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

  // ????????????
  void _anchorPushStream(String roomId, localStream) {
    ZegoSDKManager.startPublishingStream(roomId,
        localStream: localStream,
        webPublishOption:
            ZegoWebPublishOption(streamParams: '', extraInfo: "web_Publish"));
  }

  // ??????????????????????????????
  Future _setStreamAndTexture() async {
    _liveRoomWebBloc.videoView = ZegoWwVideoView(
      onMediaModelCreated: (mediaModel) {
        _liveRoomWebBloc.mediaModel = mediaModel;
        _livePreviewBlocModel.add(0);
      },
    );

    // ????????????????????????
    _zegoOnEvent();
    if (_isanchor!) {
      //  ????????????????????????
      _zegoOnPushEvent();
    } else {
      // ??????????????????
      _zegoOnPullEvent();
    }
    // ????????????
    await _zegoLoginRoom();

    if (_isanchor!) {
      //  ??????
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
            // ????????????
            errorDialog('????????????????????????????????????????????????????????????');
          } else if ('$e'.contains('NotAllowedError')) {
            // ????????????
            errorDialog('??????????????????????????????????????????????????????????????????');
          } else if ('$e'.contains('NotFoundError')) {
            // ??????????????????
            errorDialog('?????????????????????????????????????????????????????????');
          } else if ('$e'.contains('NotReadableError')) {
            // ?????????????????????
            errorDialog('??????????????????????????????????????????????????????????????????');
          } else if ('$e'.contains('NotConstrainedError')) {
            // ????????????????????????
            errorDialog('?????????????????????????????????????????????');
          } else if ('$e'.contains('SecurityError')) {
            // ????????????
            errorDialog('???????????????????????????????????????????????????');
          } else if ('$e'.contains('TypeError')) {
            // ????????????
            errorDialog('?????????????????????????????????????????????');
          }
        },
      );
    } else {}
  }

  // ???????????????
  void _cancelTimer() {
    _timer?.cancel();
  }

  // ??????????????????-????????????
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

  // ????????????-????????????
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

  // ????????????????????????????????????
  void _destroyZego() {
    if (_isanchor!) {
      ZegoSDKManager.stopPublishingStream(streamID: widget.roomId!);
      ZegoSDKManager.destroyStream(localStream);
    } else {
      ZegoSDKManager.stopPlayingStream(widget.roomId!);
    }
    ZegoSDKManager.logoutRoom(widget.roomId!);
  }

  // ????????????
  void _loginOut() {
    // ????????????
    _destroyZego();
    // ????????????????????????????????????
    _cancelTimer();
    // ?????????????????????
    dismissAllToast();
    //??????????????????
    Wakelock.disable();
    // ??????IM????????????
    _fbApiRemoveLiveMsgHandler();
  }

  // ????????????????????????
  Future _anchorCloseRoom() async {
    await anchorCloseLive();
    // ????????????
    await setLiveExit();
    // FB ????????????????????????
    _fbApiStopLive();
  }

  // ???????????????????????????????????????
  Future _audienceCloseRoom() async {
    // ????????????
    _goback();
    EventBusManager.eventBus.fire(RefreshRoomListModel(true));
    // ????????????
    await setLiveExit();
    // FB ??????????????????
    _fbApiExitLiveRoom();
  }

  // ???????????????
  void _goback() {
    Navigator.of(context).pop();
  }

  //????????????
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

  /// ????????????????????????
  /// @param user: ???????????????????????????
  /// @param json: ???????????????????????????????????????
  @override
  void onReceiveChatMsg(FBUserInfo user, String json) {
    final Map textMap = jsonDecode(json);
    final String? text = textMap["content"];
    final Map chatMap = {"user": user, "text": text, "type": "user_chat"};
    widget.liveValueModel!.chatList.add(chatMap);
    _chatListBlocModel.add(chatMap);
  }

  /// ??????????????????
  /// @param user: ??????????????????
  /// @param json: ???????????????????????????????????????
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

  /// ?????????????????????
  /// @param user: ????????????????????????
  @override
  void onUserEnter(FBUserInfo user) {
    if (user.userId != roomInfon!.anchorId) {
      //?????????????????????
      final Map chatMap = {"user": user, "text": "??????", "type": "user_coming"};
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

  /// ?????????????????????
  /// @param user: ????????????????????????
  @override
  void onUserQuit(FBUserInfo user) {
    var _total = onlineUserCountModel!.total;
    if (_total != null) {
      _total--;
      onlineUserCountModel!.total = _total;
    }

    _onlineUserCountModel.add(onlineUserCountModel!.total);
  }

  // ??????????????????
  String formatDateTime() {
    final dateTime = DateTime.now();
    final String _str = dateTime.toString();
    return _str.substring(0, 19);
  }

  // ???????????????
  @override
  void onKickOutOfGuild() {
    if (!_isanchor!) {
      return;
    }
    _showConfirmDialog(() {
      myToastLong('????????????????????????????????????????????????????????????????????????',
          duration: const Duration(days: 1)); // ???????????????
    });
    // ??????3S,???????????????
    Future.delayed(const Duration(seconds: 3), _anchorCloseRoom);
  }

  @override
  void onGoodsNotice(FBUserInfo user, String type, String json) {
    // TODO: implement onGoodsNotice
  }
}
