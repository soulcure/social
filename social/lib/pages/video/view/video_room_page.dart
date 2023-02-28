import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:get/get.dart';
import 'package:im/app/modules/home/controllers/home_scaffold_controller.dart';
import 'package:im/core/widgets/loading.dart';
import 'package:im/hybrid/webrtc/room/video_room.dart';
import 'package:im/hybrid/webrtc/room_manager.dart';
import 'package:im/hybrid/webrtc/tools/audio_help.dart';
import 'package:im/icon_font.dart';
import 'package:im/pages/home/model/chat_index_model.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/pages/home/view/check_permission.dart';
import 'package:im/pages/video/model/video_room_model.dart';
import 'package:im/themes/const.dart';
import 'package:im/widgets/realtime_user_info.dart';
import 'package:im/widgets/sound_meter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

class VideoRoomPage extends StatefulWidget {
  final String roomId;
  final String channelName;

  VideoRoomPage(this.roomId, this.channelName)
      : super(key: Key(roomId.toString()));

  @override
  _VideoRoomPageState createState() => _VideoRoomPageState();
}

class _VideoRoomPageState extends State<VideoRoomPage>
    with TickerProviderStateMixin {
  // 本地初始化是否完成
  Future<VideoRoomModel> _future;
  double _screenWidth;

  @override
  void initState() {
    _creteRoom();
    super.initState();
  }

  void _creteRoom() {
    _future = VideoRoomModel.create(widget.roomId);
  }

  @override
  Widget build(BuildContext context) {
    VideoRoomModel.onError = (error) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(error),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Get.back();
                VideoRoomModel.instance.closeAndDispose();
              },
              child: Text('确定'.tr),
            ),
          ],
        ),
      );
    };
    _screenWidth = MediaQuery.of(context).size.width;
    return FutureBuilder<VideoRoomModel>(
      future: _future,
      builder: (context, snapshot) {
        switch (snapshot.connectionState) {
          case ConnectionState.none:
          case ConnectionState.waiting:
            return Center(
                child: Loading.getActivityIndicator(color: Colors.grey));
          default:
            void goBack() {
              GlobalState.hangUp();
              HomeScaffoldController.to.gotoWindow(0);
              ChatTargetsModel.instance.selectedChatTarget
                  .selectDefaultTextChannel();
            }
            if (snapshot.hasError) {
              print(snapshot.error);
              RoomManager.close();
              if (snapshot.error == RoomManager.premissError) {
                checkSystemPermissions(
                  context: context,
                  permissions: [Permission.microphone, Permission.camera],
                  // rejectedTips: "请允许麦克风和摄像头权限",
                  onRejectedCancel: () {
                    print('----------------');
                    Get.back();
                    goBack();
                  },
                ).then((value) {
                  if (value == false) goBack();
                  if (value == true) setState(_creteRoom);
                });
                return const SizedBox();
              } else {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text("连接语音超时，请稍后重试！".tr),
                      sizeHeight20,
                      Text(snapshot.error.toString()),
                      sizeHeight20,
                      TextButton(
                        onPressed: () {
                          _creteRoom();
                          setState(() {});
                        },
                        child: Text("点击重试".tr),
                      ),
                    ],
                  ),
                );
              }
            } else {
              return GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: VideoRoomModel.instance?.toggleToolbar,
                child: Scaffold(
                  body: ChangeNotifierProvider.value(
                    value: VideoRoomModel.instance,
                    child: Stack(
                      children: [
                        _buildBackground(),
                        ValueListenableBuilder(
                          valueListenable: VideoRoomModel.networkError,
                          builder: (context, value, widget) {
                            return Stack(
                              children: <Widget>[
                                _buildUserVideo(),
                                _buildScrenShareVideo(),
                                SafeArea(
                                  top: false,
                                  child: Stack(
                                    children: <Widget>[
                                      if (!value) ...[
                                        _buildUserAvatar(),
                                      ],
                                      if (value) _buildNetworkError(),
                                      _buildBottom(),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        _buildTopBar(),
                      ],
                    ),
                  ),
                ),
              );
            }
        }
      },
    );
  }

  // 网络错误组件
  Widget _buildNetworkError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            '加载异常请重试'.tr,
            style: const TextStyle(color: Colors.white, fontSize: 17),
          ),
          sizeHeight20,
          Container(
            constraints: const BoxConstraints(minWidth: 134, minHeight: 44),
            decoration: const BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(22))),
            child: TextButton(
              style: TextButton.styleFrom(
                shape: const StadiumBorder(),
                backgroundColor: const Color(0xFF2469F2),
              ),
              onPressed: () {
                _future = VideoRoomModel.create(widget.roomId);
                // setState(() {});
              },
              child:
                  Text('重新加载'.tr, style: const TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  // 背景
  Widget _buildBackground() {
    return Container(color: const Color(0xFF2B2E33));
  }

  // 顶部导航栏
  SafeArea _buildTopBar() {
    const _textColor = Colors.white;
    final double _stausBarHeight = MediaQuery.of(context).padding.top;
    return SafeArea(
      child: Stack(
        children: <Widget>[
          ValueListenableBuilder(
            valueListenable:
                VideoRoomModel.instance?.hideToolbar ?? ValueNotifier(false),
            builder: (context, value, child) {
              return AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                top: value ? -(_stausBarHeight + 20) : 9,
                curve: Curves.fastOutSlowIn,
                child: SizedBox(width: _screenWidth, child: child),
              );
            },
            child: Row(
              children: <Widget>[
                IconButton(
                  icon: const Icon(IconFont.buffModuleMenuOpen),
                  color: _textColor,
                  onPressed: () => HomeScaffoldController.to.gotoWindow(0),
                ),
                const SizedBox(width: 21),
                Expanded(
                  child: Row(
                    children: <Widget>[
                      const Icon(
                        Icons.videocam,
                        color: _textColor,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.channelName,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: const TextStyle(
                            color: _textColor,
                            fontSize: 16,
                          ),
                        ),
                      )
                    ],
                  ),
                ),
                ValueListenableBuilder(
                    valueListenable: VideoRoomModel.instance.enableVideo,
                    builder: (context, value, widget) {
                      return Visibility(
                        visible: value,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: const Icon(IconFont.buffModuleSwitchCamera),
                          color: _textColor,
                          onPressed: () =>
                              VideoRoomModel.instance.switchCamera(),
                        ),
                      );
                    }),
                IconButton(
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.supervisor_account),
                  color: _textColor,
                  onPressed: () => HomeScaffoldController.to.gotoWindow(2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 屏幕共享
  Consumer<VideoRoomModel> _buildScrenShareVideo() {
    return Consumer<VideoRoomModel>(builder: (context, model, widget) {
      return SafeArea(
        child: model.hasScreenShared
            ? SizedBox(
                width: 100,
                height: 200,
                child: RTCVideoView(
                  model.screenShareUser.video,
                  key: Key(model.screenShareUser.userId.toString()),
                ))
            : const SizedBox(width: 100, height: 200),
      );
    });
  }

  // 主屏幕
  Consumer<VideoRoomModel> _buildUserVideo() {
    return Consumer<VideoRoomModel>(builder: (context, model, widget) {
      return Container(
        child: model.currentShowVideo && model.currentUser.video != null
            ? RTCVideoView(
                model.currentUser.video,
                key: Key(model.currentUser.userId.toString()),
                mirror: model.isSelf && model.currentUser.useFrontCamera,
              )
            : null,
      );
    });
  }

  // 用户头像 + 昵称
  Align _buildUserAvatar() {
    return Align(
      child: Consumer<VideoRoomModel>(builder: (context, model, widget) {
        if (model.currentShowVideo) return const SizedBox();
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            RealtimeAvatar(
              userId: model.currentUser.userId,
              size: 160,
            ),
            const SizedBox(height: 16),
            Text(
              model.currentUser.nickname,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 100),
          ],
        );
      }),
    );
  }

  // 底部（成员列表+工具栏）
  ValueListenableBuilder<bool> _buildBottom() {
    return ValueListenableBuilder(
      valueListenable: VideoRoomModel.instance.hideToolbar,
      builder: (context, value, _) {
        return AnimatedPositioned(
          duration: const Duration(milliseconds: 300),
          bottom: value ? -76 : 0,
          curve: Curves.fastOutSlowIn,
          child: SizedBox(
            width: _screenWidth,
            child: Column(children: [
              _buildMemberList(),
              const SizedBox(height: 12),
              _buildToolbar(value),
              const SizedBox(height: 20),
            ]),
          ),
        );
      },
    );
  }

  // 底部按钮栏
  Container _buildToolbar(bool hideToolbar) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xff474D54),
        borderRadius: BorderRadius.circular(50),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // 聊天室按钮
          // _buildOperationBtn(
          //   ValueListenableBuilder(
          //     builder: (context, value, child) {
          //       return SizedBox(
          //         width: 30,
          //         child: Stack(
          //           children: <Widget>[
          //             const Align(
          //                 child: Icon(
          //               IconFont.buffOtherGroupTalk,
          //               color: Colors.white,
          //             )),
          //             if (value > 0)
          //               Positioned(
          //                 bottom: 10,
          //                 right: 6,
          //                 child: Container(
          //                   width: 16,
          //                   height: 16,
          //                   decoration: BoxDecoration(
          //                     color: const Color(0xFFf24848),
          //                     borderRadius: BorderRadius.circular(50),
          //                   ),
          //                   child: Center(
          //                     child: Text(
          //                       value.toString(),
          //                       style: const TextStyle(
          //                           color: Colors.white, fontSize: 11),
          //                     ),
          //                   ),
          //                 ),
          //               )
          //           ],
          //         ),
          //       );
          //     },
          //     valueListenable: VideoRoomModel.instance.textRoomModel.unReadNum,
          //   ),
          //   onTap: _openTextRoom,
          // ),

          // 摄像头开启关闭按钮
          ValueListenableBuilder(
            builder: (context, value, child) {
              return _buildCommonBtn(
                Icons.videocam,
                inactiveIcon: Icons.videocam_off,
                active: value,
                onTap: () {
                  VideoRoomModel.instance.toggleCamera();
                },
              );
            },
            valueListenable: VideoRoomModel.instance.enableVideo,
          ),
          // 禁麦按钮
          ValueListenableBuilder(
            builder: (context, value, child) {
              return _buildOperationBtn(
                !value
                    ? const SoundMic(Colors.white)
                    : const Icon(
                        Icons.mic_off,
                        color: Colors.white,
                      ),
                onTap: () {
                  VideoRoomModel.instance.toggleMuted();
                },
              );
            },
            valueListenable: VideoRoomModel.instance.muted,
          ),

          // 摄像头切换按钮
          // _buildCommonBtn(IconFont.HomeSwitchCamera, onTap: () {
          //   if (!joined) return;
          //   VideoRoomModel.instance.switchCamera();
          // }),
          // 扬声器按钮
          AudioHelp.getAudioIcon(
            context,
            color: Colors.white,
            padding: const EdgeInsets.all(8),
          ),

          // 共享屏幕按钮
          // _buildOperationBtn(
          //   ValueListenableBuilder(
          //     builder: (context, value, child) {
          //       return SizedBox(
          //         width: 30,
          //         child: Stack(
          //           children: <Widget>[
          //             const Align(
          //                 child: Icon(
          //               Icons.screen_share,
          //               color: Colors.white,
          //             )),
          //             if (value > 0)
          //               Positioned(
          //                 bottom: 10,
          //                 right: 6,
          //                 child: Container(
          //                   width: 16,
          //                   height: 16,
          //                   decoration: BoxDecoration(
          //                     color: const Color(0xFFf24848),
          //                     borderRadius: BorderRadius.circular(50),
          //                   ),
          //                   child: Center(
          //                     child: Text(
          //                       value.toString(),
          //                       style: const TextStyle(
          //                           color: Colors.white, fontSize: 11),
          //                     ),
          //                   ),
          //                 ),
          //               )
          //           ],
          //         ),
          //       );
          //     },
          //     valueListenable: VideoRoomModel.instance.textRoomModel.unReadNum,
          //   ),
          //   onTap: _openScreenShare,
          // ),

          // 挂断 按钮
          _buildOperationBtn(
            const Icon(
              Icons.call_end,
              color: Color(0xFFf24848),
            ),
            onTap: () {
              VideoRoomModel.instance?.closeAndDispose("视频聊天已结束".tr);
            },
          )
        ],
      ),
    );
  }

  // 成员列表
  Consumer<VideoRoomModel> _buildMemberList() {
    const double _padding = 8;
    const double _cardWidth = 90;
    const double _separatorWidth = 8;
    const Widget _separator = SizedBox(width: _separatorWidth);
    return Consumer<VideoRoomModel>(builder: (context, model, widget) {
      // 屏幕共享的内容，需要绘制到另外的区域
      final List<VideoUser> users = model.users.where((element) {
        if (element.flag != "share_screen") {
          return true;
        }
        return false;
      }).toList();

      // 判断user数量是否���出屏幕显示，未超出则居中显示
      final bool isOverFlow = ((_screenWidth - _padding * 2) /
              (_cardWidth + _separatorWidth).floor()) <
          users.length;
      Widget _child;

      if (isOverFlow) {
        _child = ListView.separated(
            primary: true,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            scrollDirection: Axis.horizontal,
            itemBuilder: (_, i) {
              final bool _enableVideo =
                  VideoRoomModel.instance.enableVideo.value;
              final int audioLevel = model.getAudioLevel();
              return _buildMemberItem(users[i], _enableVideo, audioLevel);
            },
            separatorBuilder: (_, i) => _separator,
            itemCount: (users ?? []).length);
      } else {
        final List<Widget> _list = [];
        final bool _enableVideo = VideoRoomModel.instance.enableVideo.value;
        final int audioLevel = model.getAudioLevel();
        users.forEach((v) {
          _list
            ..add(_buildMemberItem(v, _enableVideo, audioLevel))
            ..add(_separator);
        });
        _child = ListView(
          shrinkWrap: true,
          scrollDirection: Axis.horizontal,
          children: _list,
        );
      }

      return Container(
          alignment: Alignment.center,
          height: 138,
          width: _screenWidth,
          child: _child);
    });
  }

  GestureDetector _buildMemberItem(
      VideoUser pb, bool enableVideo, int audioLevel) {
    // 判断显示头像还��视频
    final bool isSelf = VideoRoomModel.instance.me?.id == pb.id;
    final bool isShowVideo =
        (isSelf && enableVideo) || (!isSelf && pb.enableCamera == true);
    // const bool isShowVideo = true;

    return GestureDetector(
      onTap: () {
        VideoRoomModel.instance.switchVideo(pb);
      },
      child: SizedBox(
        width: 90,
        height: 138,
        child: Stack(children: [
          if (!isShowVideo)
            Container(
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: !isSelf
                      ? null
                      : const Border.fromBorderSide(
                          BorderSide(width: 2, color: Color(0xff38BE2C)),
                        )),
              child: Container(
                alignment: Alignment.topCenter,
                margin: const EdgeInsets.only(top: 32),
                child: Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    // border: Border.all(
                    //     color: audioLevel == 4
                    //         ? Color(0xff38BE2C)
                    //         : Colors.transparent,
                    //     width: 2),
                  ),
                  child: RealtimeAvatar(
                    userId: pb.userId,
                    size: 50,
                  ),
                ),
              ),
            ),
          // 视频
          if (isShowVideo && pb.video != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: RTCVideoView(
                pb.video,
                key: Key(pb.userId.toString()),
                objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                mirror: isSelf && pb.useFrontCamera,
              ),
            ),
          Container(
            padding: const EdgeInsets.only(top: 5, right: 5),
            alignment: Alignment.topRight,
            child: _buildVolumnIcon(pb.muted == true, pb.dBov != null),
          ),
          //用户名
          Align(
            alignment: Alignment.bottomCenter,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 30, 8, 10),
                  child: Text(
                    pb.nickname,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: isShowVideo ? Colors.white : Colors.black),
                  ),
                ),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  Container _buildVolumnIcon(bool muted, bool talking) {
    if (muted) {
      return Container(
        width: 16,
        height: 16,
        decoration: const BoxDecoration(
          color: Color(0xffF24848),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.mic_off,
          color: Colors.white,
          size: 10,
        ),
      );
    } else if (talking) {
      return Container(
        width: 16,
        height: 16,
        decoration: const BoxDecoration(
          color: Color(0xff38BE2C),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.volume_up,
          color: Colors.white,
          size: 10,
        ),
      );
    } else {
      return null;
    }
  }

  // 通用工具按钮
  GestureDetector _buildOperationBtn(Widget widget, {Function onTap}) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: onTap,
      child: SizedBox(
        width: 50,
        height: 56,
        child: widget,
      ),
    );
  }

  // 普通工具按钮
  GestureDetector _buildCommonBtn(
    IconData icon, {
    IconData inactiveIcon,
    bool active = true,
    bool disabled = false,
    Function onTap,
  }) {
    return _buildOperationBtn(
      Icon(
        disabled ? icon : (!active ? inactiveIcon : icon),
        size: 27,
        color: !disabled ? Colors.white : const Color(0xff9fa2a8),
      ),
      onTap: onTap,
    );
  }

// 打开屏幕共享
// Future<void> _openScreenShare() async {
//   VideoRoomModel.instance.toggleScreenShare();
// }

// 打开聊天弹窗
// Future<void> _openTextRoom() async {
//   final double _height = MediaQuery.of(context).size.height * 0.66;
//   // VideoRoomModel.instance.textRoomModel.updateVisible(visible: true);
//   await showModalBottomSheet(
//     isScrollControlled: true,
//     backgroundColor: Theme.of(context).backgroundColor,
//     shape: const RoundedRectangleBorder(
//         borderRadius:
//             BorderRadiusDirectional.vertical(top: Radius.circular(10))),
//     context: context,
//     builder: (_) {
//       return Container(
//         height: _height,
//         padding:
//             EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
//         child: GestureDetector(
//             behavior: HitTestBehavior.translucent,
//             onTap: () {
//               FocusScope.of(_).unfocus();
//             },
//             child: VideoRoomTextPage(VideoRoomModel.instance.textRoomModel)),
//       );
//     },
//   );
//   VideoRoomModel.instance.textRoomModel.updateVisible(visible: false);
// }
}
