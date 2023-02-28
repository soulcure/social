import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:im/hybrid/webrtc/tools/audio_help.dart';
import 'package:im/pages/video_call/model/video_model.dart';
import 'package:im/routes.dart';
import 'package:im/widgets/sound_meter.dart';

class VideoToolBar extends StatefulWidget {
  final VideoModel model;
  const VideoToolBar(this.model);

  @override
  __ToolBarState createState() => __ToolBarState();
}

class __ToolBarState extends State<VideoToolBar> {
  bool enableCamera = false;
  bool muted = false;
  bool _isClosed = false;

  @override
  void initState() {
    widget.model.onComplete = _close;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final iconColor = Theme.of(context).textTheme.bodyText2.color;
    enableCamera = widget.model.enableVideo.value;
    return Center(
      child: Container(
        width: 220,
        height: 56,
        decoration: BoxDecoration(
          color: Theme.of(context).backgroundColor,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            // 摄像头开关
            IconButton(
              onPressed: () {
                enableCamera = widget.model.toggleCamera();
                setState(() {});
              },
              icon: Icon(
                enableCamera ? Icons.videocam : Icons.videocam_off,
                size: 24,
                color: iconColor,
              ),
            ),
            // 麦克风
            InkWell(
              onTap: () {
                muted = widget.model.toggleMuted();
                setState(() {});
              },
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: muted
                    ? Icon(
                        Icons.mic_off,
                        color: iconColor,
                      )
                    : SoundMic(iconColor),
              ),
            ),
            // 外放
            AudioHelp.getAudioIcon(
              context,
              color: iconColor,
              padding: const EdgeInsets.all(8),
            ),
            // 挂断
            IconButton(
              onPressed: _close,
              icon: const Icon(
                Icons.call_end,
                size: 24,
                color: Color(0xFFF2494A),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _close() {
    if (!_isClosed) {
      _isClosed = true;
      widget.model.close("通话已结束".tr);
      Routes.pop(context);
    }
  }
}
