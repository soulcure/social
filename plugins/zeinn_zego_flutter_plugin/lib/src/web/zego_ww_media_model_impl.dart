import 'dart:html';
import 'package:zego_ww/src/web/player_interop.dart';

import '../interface/zego_ww_media_model.dart';
import 'dart:js_util' as js_util;

class ZegoWwMediaModelImpl extends ZegoWwMediaModel {
  VideoElement? videoElement;

  ZegoWwMediaModelImpl(this.videoElement);

  MediaStream? _stream;

  bool isLeavePipHandling = false;

  @override
  set src(_src) {
    // TODO: implement src
    _stream = _src;
    videoElement?.srcObject = _src;
    // 退出画中画模式时候执行
    videoElement!.removeEventListener('leavepictureinpicture', (_) {
      print("videoElement => leavePictureInPicture => removeEventListener");
    });
    videoElement!.addEventListener('leavepictureinpicture', (_) {
      ///  保证500毫秒内只会处理一次，拦截同时多次请求处理
      if (isLeavePipHandling) {
        return;
      }
      isLeavePipHandling = true;
      Future.delayed(Duration(milliseconds: 100)).then((value) {
        // 已退出画中画模式
        isPip = false;
        print("videoElement => leavePictureInPicture => active:$active");
        if (active!) {
          play();
        }

        if (onLeavePip != null) {
          onLeavePip!();
        }
      });
      Future.delayed(Duration(milliseconds: 500)).then((value) {
        isLeavePipHandling = false;
      });
    });
  }

  @override
  // TODO: implement src
  get src => _stream;

  @override
  bool? get active {
    if (src == null) {
      return false;
    }
    return src.active;
  }

  void pause() {
    videoElement?.pause();
  }

/*
* 画中画
* */
  dynamic requestPIP() {
    js_util.callMethod(videoElement!, 'requestPictureInPicture', <Object>[]);
    isPip = true;
  }

/*
* 退出画中画
* */
  dynamic exitPIP() {
    // js_util.callMethod(Document(), 'exitPictureInPicture', <Object>[]);
    exitPictureInPicture();
    isPip = false;
  }

/*
* 是否可以开启画中画
* */
  dynamic pictureInPictureEnabled() {
    return js_util
        .callMethod(videoElement!, 'pictureInPictureEnabled', <Object>[]);
  }

  @override
  void play() {
    videoElement?.play();
  }

  @override
  set muted(bool _muted) {
    // TODO: implement muted
    videoElement?.muted = _muted;
  }

  @override
  set autoplay(bool? _autoplay) {
    // TODO: implement autoplay
    super.autoplay = _autoplay;
  }

  @override
  // TODO: implement autoplay
  bool? get autoplay => super.autoplay;
}
