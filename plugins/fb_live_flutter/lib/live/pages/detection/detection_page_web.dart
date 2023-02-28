// ignore: avoid_web_libraries_in_flutter
import 'dart:html';
import 'dart:math' as math;

import 'package:event_bus/event_bus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:fb_live_flutter/live/bloc/detection_bloc.dart';
import 'package:fb_live_flutter/live/pages/detection/widget/detection_item.dart';
import 'package:fb_live_flutter/live/pages/detection/widget/detection_voice_widget.dart';
import 'package:fb_live_flutter/live/utils/ui/frame_size.dart';
import 'package:fb_live_flutter/live/utils/func/router.dart';
import 'package:fb_live_flutter/live/utils/theme/my_theme.dart';
import 'package:fb_live_flutter/live/utils/theme/my_toast.dart';
import 'package:fb_live_flutter/live/utils/ui/ui.dart';
import 'package:fb_live_flutter/live/widget_common/button/theme_button.dart';
import 'package:fb_live_flutter/live/widget_common/web/web_title.dart';
import 'package:oktoast/oktoast.dart';

EventBus detectionBus = EventBus();

class DetectionPageEvent {
  DetectionPageEvent();
}

/*
* 直播前检测，只有web需要用到
* */
class DetectionPage extends StatefulWidget {
  final String? roomTitle;
  final String? roomLogo;
  final int? shareType;

  const DetectionPage({
    Key? key,
    this.roomTitle,
    this.roomLogo,
    this.shareType,
  }) : super(key: key);

  @override
  _DetectionPageState createState() => _DetectionPageState();
}

class _DetectionPageState extends State<DetectionPage> {
  final DetectionBloc _detectionBloc = DetectionBloc();

  //摄像头是否开启
  bool? _isCamera;

  //麦克风是否开启
  bool? _isMicrophone;
  final RxBool _microphoneIsClick = true.obs;
  final RxBool _cameraIsClick = true.obs;
  final RxBool _speakersIsClick = true.obs;
  final RxBool _isTestSpeaker = false.obs;
  final RxBool _isTestSpeakerFail = false.obs;
  bool isTestedSpeaker = false;
  late AudioElement _webcamAudioElement;

  @override
  void initState() {
    super.initState();
    _webcamAudioElement = AudioElement();
    _webcamAudioElement.src = "assets/MP3/tonight.mp3";
    _detectionBloc.init(this);
    detectionBus.on().listen((event) {
      if (mounted)
        setState(() {
          _isCamera = _detectionBloc.isCamera;
          _isMicrophone = _detectionBloc.isMicrophone;
        });
    });
  }

  /*
  * 选择扬声器设备
  * */
  void audioSetSink(String deviceId) {
    _webcamAudioElement.setSinkId(deviceId);
  }

  @override
  Widget build(BuildContext context) {
    final body = ListView(
      children: [
        Container(
            margin: const EdgeInsets.only(left: 24),
            child: const WebTitle("直播前检测")),
        Space(height: 48.px),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DetectionItem(
                    isFail: _isMicrophone,
                    title: "麦克风",
                    controller: _detectionBloc.microphoneC,
                    onTap: () {
                      // FocusManager.instance.primaryFocus.unfocus();
                      if (mounted)
                        setState(() {
                          _microphoneIsClick.value = !_microphoneIsClick.value;
                        });
                    },
                    isArrow: _detectionBloc.microphoneList!.isNotEmpty,
                  ),
                  Container(
                    margin: const EdgeInsets.only(left: 24),
                    child: Stack(
                      children: [
                        Column(
                          children: [
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 10.px),
                              child: Obx(
                                () => Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: List.generate(24, (index) {
                                    final localValue =
                                        (_detectionBloc.localSoundLevel.value /
                                                100) *
                                            24;
                                    return Container(
                                      margin:
                                          EdgeInsets.symmetric(vertical: 24.px),
                                      width: 4.px,
                                      height: 12.px,
                                      decoration: BoxDecoration(
                                        color: localValue <= index
                                            ? const Color(0xffDEE0E3)
                                            : MyTheme.themeColor,
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(4.px)),
                                      ),
                                    );
                                  }),
                                ),
                              ),
                            ),
                            StatefulBuilder(
                              builder: (_, refresh) {
                                return DetectionVoiceWidget(
                                  value: _detectionBloc.microphoneValue,
                                  onChanged: (v) {
                                    _detectionBloc.microphoneValue = v;
                                    refresh(() {});
                                  },
                                  onChangeEnd: _detectionBloc.setCaptureVolume,
                                );
                              },
                            ),
                            Space(height: 10.px),
                            if (_isMicrophone != null && !_isMicrophone!)
                              Text.rich(
                                TextSpan(children: [
                                  const TextSpan(
                                    text: '未检测到麦克风的声音，',
                                    style: TextStyle(
                                      color: Color(0xffF24848),
                                    ),
                                  ),
                                  const TextSpan(text: '请重新插拔麦克风，或换个设备 '),
                                  TextSpan(
                                    text: '重试',
                                    style: const TextStyle(
                                      color: Color(0xff6179F2),
                                    ),
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = () {
                                        myToast('敬请期待');
                                      },
                                  )
                                ]),
                                textAlign: TextAlign.start,
                                style:
                                    const TextStyle(color: Color(0xff17181A)),
                              )
                            else
                              Container(),
                            Space(height: 48.px),
                            // Stack(
                            //   children: [
                            //     Column(
                            //       children: [
                            DetectionItem(
                              isArrow: false,
                              centerW: Obx(
                                () => Row(
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        _isTestSpeaker.value =
                                            !_isTestSpeaker.value;

                                        _isTestSpeaker.value
                                            ? _webcamAudioElement.play()
                                            : _webcamAudioElement.pause();
                                        isTestedSpeaker = true;
                                        if (_isTestSpeaker.value &&
                                            _isTestSpeakerFail.value) {
                                          _isTestSpeakerFail.value = false;
                                        }
                                      },
                                      child: Container(
                                        width: 146.px,
                                        height: 40.px,
                                        margin: EdgeInsets.only(
                                            bottom: 10.px, top: 5.px),
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          border: Border.all(
                                              color: const Color(0xffDEE0E3)),
                                          borderRadius:
                                              BorderRadius.circular(4.px),
                                        ),
                                        child: _isTestSpeaker.value
                                            ? Image.asset(
                                                'assets/live/CreateRoom/test_speaker.png',
                                                width: 24.px,
                                                height: 24,
                                              )
                                            : Text(
                                                '点此测试扬声器',
                                                style: TextStyle(
                                                  color:
                                                      const Color(0xff6179F2),
                                                  fontSize: 14.px,
                                                ),
                                              ),
                                      ),
                                    ),
                                    const Space(width: 16),
                                    Offstage(
                                      offstage: !_isTestSpeaker.value,
                                      child: GestureDetector(
                                        onTap: () {
                                          _isTestSpeakerFail.value = true;
                                        },
                                        child: Container(
                                          margin: EdgeInsets.only(
                                              bottom: 10.px, top: 5.px),
                                          height: 40.px,
                                          alignment: Alignment.center,
                                          child: const Text(
                                            '没听到声音?',
                                            style: TextStyle(
                                                color: Color(0xff6179F2),
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              title: "扬声器",
                              controller: _detectionBloc.speakerC,
                              onTap: () {
                                // FocusManager.instance.primaryFocus
                                //     .unfocus();
                                if (mounted)
                                  setState(() {
                                    _speakersIsClick.value =
                                        !_speakersIsClick.value;
                                  });
                              },
                            ),
                            Space(height: 23.px),
                            StatefulBuilder(
                              builder: (_, refresh) {
                                return DetectionVoiceWidget(
                                  value: _detectionBloc.speakerValue,
                                  onChanged: (v) {
                                    _detectionBloc.speakerValue = v;
                                    refresh(() {});
                                  },
                                  onChangeEnd: (v) {
                                    _webcamAudioElement.volume = v / 100;
                                  },
                                );
                              },
                            ),
                            Space(
                              height: 10.px,
                            ),
                            Obx(
                              () => Text(
                                _isTestSpeakerFail.value
                                    ? '请重新插拔扬声器，或选择新设备重新检测'
                                    : "",
                                style: TextStyle(
                                    color: const Color(0xFF1F2125),
                                    fontSize: 14.px),
                              ),
                            ) //   ],
                            // ),
                            // _deviceListView(
                            //   _speakersIsClick,
                            //   _detectionBloc.speakersList,
                            //   _detectionBloc.speakerC,
                            // ),
                            //   ],
                            // ),
                          ],
                        ),
                        Obx(() => _deviceListView(
                              _microphoneIsClick.value,
                              _detectionBloc.microphoneList!,
                              _detectionBloc.microphoneC,
                            )),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Space(width: 48.px),
            Expanded(
              child: Column(
                children: [
                  DetectionItem(
                    isFail: _isCamera,
                    title: "摄像头",
                    controller: _detectionBloc.cameraC,
                    onTap: () {
                      // FocusManager.instance.primaryFocus.unfocus();

                      if (mounted)
                        setState(() {
                          _cameraIsClick.value = !_cameraIsClick.value;
                        });
                    },
                    isArrow: _detectionBloc.cameraList!.isNotEmpty,
                  ),
                  Container(
                    margin: const EdgeInsets.only(left: 24),
                    child: Stack(
                      children: [
                        Column(
                          children: [
                            Space(height: 10.px),
                            StatefulBuilder(builder: (_, refresh) {
                              return Column(
                                children: [
                                  Container(
                                    color: const Color(0xff000000),
                                    height: _detectionBloc.viewHeight,
                                    width: _detectionBloc.viewWidth,
                                    child: Transform(
                                      alignment: Alignment.center,
                                      transform: Matrix4.rotationY(
                                          _detectionBloc.isFlip ? math.pi : 0),
                                      child: AbsorbPointer(
                                        child: _detectionBloc.videoView ??
                                            Container(),
                                      ),
                                    ),
                                  ),
                                  Space(height: 10.px),
                                  GestureDetector(
                                    onTap: () {
                                      _detectionBloc.isFlip =
                                          !_detectionBloc.isFlip;
                                      refresh(() {});
                                    },
                                    child: Padding(
                                      padding:
                                          EdgeInsets.symmetric(vertical: 5.px),
                                      child: Row(
                                        children: [
                                          // Space(width: 10.px),
                                          Text(
                                            '翻转镜头',
                                            style: TextStyle(
                                              color: const Color(0xff1F2125),
                                              fontSize: 14.px,
                                            ),
                                          ),
                                          const Spacer(),
                                          CupertinoSwitch(
                                            activeColor: MyTheme.themeColor,
                                            value: _detectionBloc.isFlip,
                                            onChanged: (value) {
                                              _detectionBloc.isFlip = value;
                                              refresh(() {});
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            })
                          ],
                        ),
                        Obx(
                          () => _deviceListView(
                            _cameraIsClick.value,
                            _detectionBloc.cameraList!,
                            _detectionBloc.cameraC,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
        Space(height: 50.px),
        ButtonBar(
          children: [
            const ThemeButtonWeb(
              text: '上一步',
              onPressed: RouteUtil.pop,
            ),
            ThemeButtonWeb(
              text: '开始直播',
              btColor: MyTheme.themeColor,
              onPressed: () {
                if (!isTestedSpeaker) {
                  showToast('请先测试下扬声器');
                  return;
                }
                _detectionBloc.interLive(context);
              },
            ),
            // ThemeButtonWeb(
            //   text: '开启声浪监听',
            //   btColor: MyTheme.themeColor,
            //   onPressed: () {
            //     _detectionBloc.setSoundLevelDelegate();
            //   },
            // ),
            // ThemeButtonWeb(
            //   text: '屏幕共享',
            //   btColor: MyTheme.themeColor,
            //   onPressed: () {
            //     _detectionBloc.createStream();
            //   },
            // ),
          ],
        ),
      ],
    );
    return BlocBuilder<DetectionBloc, int>(
      builder: (context, value) {
        return Scaffold(
          backgroundColor: Colors.white,
          body: Center(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Container(
                margin: const EdgeInsets.only(top: 70),
                width: 672,
                child: body,
              ),
            ),
          ),
        );
      },
      bloc: _detectionBloc,
    );
  }

  Widget _deviceListView(
      bool offstage, List deviceList, TextEditingController textC) {
    return Offstage(
        offstage: offstage,
        child: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: const Color(0xffDEE0E3),
              ),
            ),
            padding: const EdgeInsets.only(top: 16, bottom: 16),
            child: ListView.builder(
                shrinkWrap: true,
                itemCount: deviceList.length,
                itemBuilder: (context, index) {
                  return InkWell(
                    onTap: () {
                      textC.text = deviceList[index].deviceName;
                      final String? _id = deviceList[index].deviceID;
                      if (deviceList == _detectionBloc.microphoneList) {
                        _microphoneIsClick.value = true;
                        _detectionBloc.useAudioDevice(_id!);
                      } else if (deviceList == _detectionBloc.cameraList) {
                        _cameraIsClick.value = true;
                        _detectionBloc.useVideoDevice(_id!);
                      } else {
                        _speakersIsClick.value = true;
                        audioSetSink(_id!);
                      }
                    },
                    child: Container(
                      color: deviceList[index].deviceName == textC.text
                          ? const Color(0xffDEE0E3)
                          : Colors.white,
                      padding: const EdgeInsets.only(left: 12),
                      height: 32,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        deviceList[index].deviceName,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  );
                }),
          ),
        ));
  }

  @override
  void dispose() {
    _webcamAudioElement.pause();
    _detectionBloc.close();
    super.dispose();
  }
}
