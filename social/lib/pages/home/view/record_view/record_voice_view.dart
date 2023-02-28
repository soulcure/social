import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_audio_recorder/flutter_audio_recorder.dart';
import 'package:get/get.dart';
import 'package:im/icon_font.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/pages/home/view/bottom_bar/text_chat_bottom_bar.dart';
import 'package:im/pages/home/view/model/home_page_model.dart';
import 'package:im/pages/home/view/record_view/record_sound_state.dart';
import 'package:im/pages/home/view/record_view/sound_play_manager.dart';
import 'package:im/themes/custom_color.dart';
import 'package:im/widgets/animation/icons_animation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pedantic/pedantic.dart';
import 'package:provider/provider.dart';

class RecordVoiceView extends StatefulWidget {
  // 返回语音
  final Function(String, int) callback;
  final ValueNotifier<FocusIndex> focusIndex;

  const RecordVoiceView({@required this.callback, this.focusIndex});

  @override
  _RecordVoiceViewState createState() => _RecordVoiceViewState();
}

class _RecordVoiceViewState extends State<RecordVoiceView>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final _countDownWidth = 168.0;
  final _deleteIconOffset = 130;

  // 动画
  AnimationController controller;
  Animation<double> animation;

  // 录音
  FlutterAudioRecorder _recorder;
  Timer _recordTimer;
  String _voiceName;

  double opacity = 0;

  bool _recordEnable = true;

  @override
  void initState() {
    super.initState();

    widget.focusIndex.addListener(focusIndexDidChange);

    controller =
        AnimationController(duration: const Duration(seconds: 1), vsync: this);
    animation = CurvedAnimation(parent: controller, curve: Curves.easeIn);
    WidgetsBinding.instance.addObserver(this);
  }

  /// 初始化录制
  Future<void> _initRecorder() async {
    _voiceName = '${DateTime.now().millisecondsSinceEpoch}';
    final tmpDirectory = await getTemporaryDirectory();
    final directory = Directory('${tmpDirectory.path}/voice');
    if (!directory.existsSync()) {
      directory.createSync();
    }
    _recorder = FlutterAudioRecorder(
        "${tmpDirectory.path}/voice/$_voiceName.aac",
        audioFormat: AudioFormat.AAC,
        callback: handleRecordCallBack); // or AudioFormat.WAV
    await _recorder.initialized;
  }

  Future handleRecordCallBack(MethodCall methodCall) {
    switch (methodCall.method) {
      case FlutterAudioRecorder.methodcallback_audioRecorderBeginInterruption:
        final model = context.read<RecordSoundState>();
        _stopRecord(model.second);
        break;
      case FlutterAudioRecorder.methodcallback_audioRecorderEndInterruption:
        break;
      case FlutterAudioRecorder.methodcallback_audioRecorderEncodeErrorDidOccur:
        _stopRecord(0);
        break;
      case FlutterAudioRecorder.methodcallback_audioRecorderDidFinishRecording:
        break;
      default:
    }
    return Future.value(true);
  }

  /// 开始录制
  Future<void> _startRecord(BuildContext context) async {
    unawaited(SoundPlayManager().forceStop());
    final model = context.read<RecordSoundState>();
    try {
      ///修复话题页无法发送语音
      if (!GlobalState.isDmChannel)
        context.read<HomePageModel>().setScrollEnable(false);
    } catch (_) {}

    try {
      await _initRecorder();
      model.updateSecond(60);
      model.updateStopRecord(stopRecord: false);
      unawaited(_recorder.start());
      unawaited(controller.forward());
      _recordTimer?.cancel();
      _recordTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (model.second <= 0) {
          _stopRecord(0);
        }
        model.reduceSecond();
        controller.reset();
        controller.forward();
      });
    } catch (_) {
      _recorder?.dispose();
      _recorder = null;
      _recordTimer?.cancel();
      model.updateStopRecord(stopRecord: true);
      model.updateSecond(0);
    }
  }

  /// 停止录制
  Future<void> _stopRecord(int second) async {
    if (_recorder == null ||
        _recorder.recording.status == RecordingStatus.Unset) return;
    try {
      if (!GlobalState.isDmChannel)
        Provider.of<HomePageModel>(context, listen: false)
            .setScrollEnable(true);
    } catch (_) {}
    final model = Provider.of<RecordSoundState>(context, listen: false);
    model.updateTopOffset(0);
    if (_recordTimer == null || !_recordTimer.isActive) return; // 避免传2次消息
    // 停止动画
    _recordTimer.cancel();
    controller.reset();
    // 停止录制
    final result = await _recorder.stop();
    // 过滤不到1秒的语音
    if (second > 59 && !model.stopRecord) {
      unawaited(File(result.path)?.delete()); // 文件删除
      model.updateRecordShortError(error: true);
      unawaited(Future.delayed(const Duration(seconds: 2)).then((value) {
        model.updateRecordShortError(error: false);
      }));
    } else if (!model.stopRecord) {
      // 发送语音
      final path = result.path ?? '';
      if (File(path).existsSync()) {
        widget.callback(result.path, 60 - second);
      }
    } else {
      // 取消，删除语音
      unawaited(File(result.path)?.delete()); // 文件删除
    }
    // 删除状态改回去
    model.updateStopRecord(stopRecord: false);
    model.updateSecond(0);

    // 重置
//    await _initRecorder();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _stopRecord(Provider.of<RecordSoundState>(context, listen: false).second);
    }
    if (state == AppLifecycleState.inactive) {
      //App 进入控制中心，如果在发送音频，则断开并自动发送
      if (_recorder.recording.status != RecordingStatus.Stopped) {
        _stopRecord(
            Provider.of<RecordSoundState>(context, listen: false).second);
      }
    }
  }

  @override
  void dispose() {
    widget.focusIndex.removeListener(focusIndexDidChange);
    _recordTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void focusIndexDidChange() {
    if (widget.focusIndex.value != FocusIndex.voice) {
      final model = Provider.of<RecordSoundState>(context, listen: false);
      final second = model?.second ?? 0;
      _stopRecord(second);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RecordSoundState>(
      builder: (context, recordSoundState, child) {
        return GestureDetector(
          onTap: () {},
          onHorizontalDragStart: (_) {},
          onHorizontalDragEnd: (_) {},
          onHorizontalDragUpdate: (_) {},
          child: Stack(
            alignment: Alignment.topCenter,
            // ignore: deprecated_member_use
            overflow: Overflow.visible,
            children: <Widget>[
              Visibility(
                visible: recordSoundState.second > 0,
                child: Positioned(
                  top: -40,
                  child: _getCountDownUI(recordSoundState.second,
                      isStop: recordSoundState.stopRecord,
                      topOffset: recordSoundState.topOffset),
                ),
              ),
              _buildMainColumn(context, recordSoundState),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMainColumn(
      BuildContext context, RecordSoundState recordSoundState) {
    final color = (recordSoundState.stopRecord && recordSoundState.second != 0)
        ? Colors.red
        : Theme.of(context).primaryColor;
    return ListView(
        padding: EdgeInsets.zero,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          Container(
            height: 40,
            alignment: Alignment.bottomCenter,
            child: Offstage(
              offstage: recordSoundState.recordShortError ||
                  (recordSoundState.second != 0 &&
                      recordSoundState.second > 10),
              child: Text(
                  recordSoundState.second == 0
                      ? '按住录音'.tr
                      : '%ss后停止录音'.trArgs([recordSoundState.second.toString()]),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: recordSoundState.second == 0
                          ? Theme.of(context).textTheme.bodyText1.color
                          : Colors.red,
                      fontSize: 12)),
            ),
          ),
          const SizedBox(height: 25),
          GestureDetector(
            onLongPressStart: _recordEnable
                ? (detail) async {
                    unawaited(HapticFeedback.lightImpact());
                    unawaited(_startRecord(context));
                    setState(() => _recordEnable = false);
                    unawaited(Future.delayed(const Duration(milliseconds: 800))
                        .then((value) {
                      setState(() => _recordEnable = true);
                    }));
                  }
                : null,
            onLongPressMoveUpdate: (detail) =>
                Provider.of<RecordSoundState>(context, listen: false)
                    .updateTopOffset(detail.localPosition.dy),
//                    .updateStopRecord(
//                        stopRecord: detail.localPosition.dy < -100),
            onLongPressEnd: (detail) => _stopRecord(recordSoundState.second),
//            onPanCancel: () => _stopRecord(recordSoundState.second),
            child: Container(
              height: 110,
              alignment: Alignment.center,
              child: Stack(
                alignment: Alignment.center,
                // ignore: deprecated_member_use
                overflow: Overflow.visible,
                fit: StackFit.expand,
                children: <Widget>[
                  Positioned(
                    /// top 和 bottom 的设置仅为脱离父容器尺寸限制
                    /// 值随意，需要大于动画的最大延伸距离
                    top: -100,
                    bottom: -100,
                    child: RippleAnimatedWidget(
                        animation: animation, rippleColor: color),
                  ),
                  AnimatedContainer(
                    duration: kThemeAnimationDuration,
                    decoration:
                        BoxDecoration(shape: BoxShape.circle, color: color),
                    child: const Icon(
                      IconFont.buffAudioVisualMic,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Visibility(
            visible: recordSoundState.second != 0,
            child: SizedBox(
                width: MediaQuery.of(context).size.width,
                child: Text(
                  recordSoundState.stopRecord ? '松开取消发送'.tr : '松开发送，上滑取消'.tr,
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .bodyText1
                      .copyWith(fontSize: 12),
                )),
          )
        ]);
  }

  @protected
  Widget _getCountDownUI(int second, {bool isStop, double topOffset}) {
    const h = 48.0;

    /// 录音的倒计时UI
    return SizedBox(
      width: _countDownWidth,
      height: h,
      child: Consumer<RecordSoundState>(builder: (context, state, child) {
        return Stack(
          // ignore: deprecated_member_use
          overflow: Overflow.visible,
          alignment: Alignment.topCenter,
          children: <Widget>[
            Positioned(
              top: state.topOffset,
              child: AnimatedContainer(
                duration: kThemeAnimationDuration,
                width: _countDownWidth,
                height: h,
                decoration: ShapeDecoration(
                  shape: const StadiumBorder(),
                  color: isStop ? Colors.red : Theme.of(context).primaryColor,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Container(
                      width: 32,
                      height: 32,
                      margin: const EdgeInsets.only(left: 8),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16)),
                      child: Icon(
                        IconFont.buffModuleMic,
                        color: isStop
                            ? Colors.red
                            : Theme.of(context).primaryColor,
                      ),
                    ),
                    Container(
                      width: 68,
                      margin: const EdgeInsets.only(right: 4),
                      child: const IconsAnimation(
                        icons: [
                          IconFont.buffAnimaitonRecordSound1,
                          IconFont.buffAnimaitonRecordSound2,
                          IconFont.buffAnimaitonRecordSound3,
                          IconFont.buffAnimaitonRecordSound4,
                          IconFont.buffAnimaitonRecordSound5,
                        ],
                        duration: Duration(milliseconds: 700),
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      child: Text(
                        '${60 - second}”',
                        style:
                            const TextStyle(color: Colors.white, fontSize: 18),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
                top: -state.topOffset - _deleteIconOffset,
                child: _abandonBtn(state)),
          ],
        );
      }),
    );
  }

  Widget _abandonBtn(RecordSoundState state) {
    double w;
    double offset;
    if (state.stopRecord) {
      w = _countDownWidth;
      offset = _deleteIconOffset + state.cancelOffset * 2;
      opacity = 0;
    } else {
      w = 48;
      offset = 0;
      opacity = 1;
    }
    // 删除按钮
    // (-0.4 * state.topOffset) > 20 ? 20 : (-0.4 * state.topOffset)
    return Visibility(
        visible: state.second != 0,
        child: AnimatedOpacity(
          duration: kThemeAnimationDuration,
          opacity: opacity,
          child: AnimatedContainer(
            transform: Matrix4.translationValues(0, offset, 0),
            duration: kThemeAnimationDuration,
            height: 48,
            width: w,
            decoration: const ShapeDecoration(
                shape: StadiumBorder(), color: CustomColor.fontGrey),
            child: const Icon(
              IconFont.buffChatDelete,
              color: Colors.white,
            ),
          ),
        ));
  }
}

class RippleAnimatedWidget extends AnimatedWidget {
  static final _opacityTween = Tween<double>(begin: 1, end: 0);
  static final _sizeTween = Tween<double>(begin: 110, end: 130);
  final Color rippleColor;

  const RippleAnimatedWidget(
      {Key key, Animation<double> animation, Color rippleColor})
      // ignore: prefer_initializing_formals
      : rippleColor = rippleColor,
        super(key: key, listenable: animation);

  @override
  Widget build(BuildContext context) {
    final Animation<double> animation = listenable;
    return Opacity(
        opacity: _opacityTween.evaluate(animation),
        child: SizedBox(
          height: _sizeTween.evaluate(animation),
          width: _sizeTween.evaluate(animation),
          child: AnimatedContainer(
            duration: kThemeAnimationDuration,
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: rippleColor ?? Colors.greenAccent, width: 2)),
          ),
        ));
  }
}
