import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oktoast/oktoast.dart';

class RecordSoundState with ChangeNotifier {
  static RecordSoundState instance = RecordSoundState();

  final double cancelOffset = -30;
  int _second = 0;
  bool _recording = false;
  bool _stopRecord = false; // 是否停止录音
  bool _recordShortError = false; // 录制时间太短
  double _topOffset = 0;

  double get topOffset => _topOffset;

  int get second => _second;

  bool get recording => _recording;

  bool get stopRecord => _stopRecord;

  bool get recordShortError => _recordShortError;

  // 接口方法
  void updateSecond(int second) {
    if (second != _second) {
      _topOffset = 0;
      _second = second;
      notifyListeners();
    }
  }

  void reduceSecond() {
    if (_second > 0) {
      _second -= 1;
    }
    notifyListeners();
  }

  void updateRecording({bool recording}) {
    assert(recording != null);
    _recording = recording;
    notifyListeners();
  }

  void updateStopRecord({bool stopRecord}) {
    assert(stopRecord != null);
    if (_stopRecord != stopRecord) {
      _stopRecord = stopRecord;
      notifyListeners();
    }
  }

  void updateRecordShortError({bool error}) {
    assert(error != null);
    _recordShortError = error;
    showToast("说话时间过短".tr);
  }

  void updateTopOffset(double offset) {
    _topOffset += offset;
    _topOffset = min(0, max(_topOffset, cancelOffset));
    final stopRecord = _topOffset <= cancelOffset;
    if (_stopRecord != stopRecord) {
      _stopRecord = stopRecord;
    }
    notifyListeners();
  }
}
