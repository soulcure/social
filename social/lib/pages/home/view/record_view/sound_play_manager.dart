import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:get/get.dart' as get_x;
import 'package:im/global.dart';
import 'package:im/pages/home/json/text_chat_json.dart';
import 'package:im/pages/home/model/text_channel_controller.dart';
import 'package:im/pages/home/model/text_channel_event.dart';
import 'package:im/pages/home/model/text_channel_util.dart';
import 'package:im/utils/custom_cache_manager.dart';
import 'package:im/utils/show_confirm_dialog.dart';
import 'package:im/widgets/audio_player_manager.dart';
import 'package:oktoast/oktoast.dart';
import 'package:pedantic/pedantic.dart';
import 'package:tuple/tuple.dart';
import 'package:wakelock/wakelock.dart';

class SoundPlayManager {
  static SoundPlayManager _instance;

  AudioPlayer audioPlayer = AudioPlayer();

  /// url, playing (0 normal / 1 pre / 2 playing)
  ValueNotifier<Tuple2<String, int>> state =
      ValueNotifier(const Tuple2(null, 0));

  // current
  BuildContext context;

//  int messageId;
  MessageEntity message;
  String quoteL1;

  factory SoundPlayManager() {
    // ignore: join_return_with_assignment
    _instance ??= SoundPlayManager._();
    return _instance;
  }

  SoundPlayManager._() {
    /// 异常监听
    audioPlayer.onPlayerError.listen((event) {
      state.value = const Tuple2(null, 0);
      message = null;
      // 播放语音关闭屏幕常亮
      Wakelock.disable();
    });

    /// 播放结束监听
    audioPlayer.onPlayerCompletion.listen((event) {
      // 播放语音关闭屏幕常亮
      Wakelock.disable();
      if (this.message == null) return;

      state.value = const Tuple2(null, 0);
      final message = this.message;
      this.message = null;

      /// 如果播放的是自己的声音，则不考虑继续播放
      final list =
          TextChannelController.to(channelId: message.channelId).messageList;
      final index =
          list.indexWhere((element) => element.messageId == message.messageId);
      if (list[index].userId == Global.user.id) return;

      /// 获取之后的未读消息，继续播放
      if (index < list.length - 1) {
        for (int i = index + 1; i < list.length; i++) {
          final item = list[i];
          if (item.userId != Global.user.id &&
              item.content.runtimeType == VoiceEntity) {
            final voice = item.content as VoiceEntity;
            final isRead = voice.isRead ?? false;
            if (quoteL1 != null && item.quoteL1 != quoteL1) continue;
            if (!isRead && !item.isRecalled) {
              playVoice(context, item);
              break;
            }
          }
        }
      }
    });

    // 监听消息
    TextChannelUtil.instance.stream
        .where((e) => e is RecallMessageEvent)
        .listen((e) async {
      final messageId = (e as RecallMessageEvent).id;
      if ((messageId ?? "") == message?.messageId ?? "-1") {
        unawaited(showConfirmDialog(
          title: '该消息已经被撤回'.tr,
          confirmText: '知道了'.tr,
          showCancelButton: false,
        ));
        unawaited(forceStop());
      }
    });
  }

  Future<void> playVoice(BuildContext context, MessageEntity message,
      {String quoteL1}) async {
    // 是否在话题中
    this.quoteL1 = quoteL1;

    // 1. 重复点击，停止播放
    if (this.message != null &&
        this.message.messageId == message.messageId &&
        state.value.item2 == 2) {
      await audioPlayer.stop();
      state.value = const Tuple2(null, 0);
      return;
    }

    // 2. 停止当前播放语音
    this.message = message;
    await audioPlayer.stop();
    if (AudioPlayerManager.instance.isPlaying)
      unawaited(AudioPlayerManager.instance.stop());

    int result = -1;

    if (kIsWeb) {
      final voice = message.content as VoiceEntity;
      state.value = Tuple2(voice.url, 1); // 预播放
      state.value = Tuple2(voice.url, 2);
      // 4. 开始播放
      result = await audioPlayer.play(voice.url, isLocal: false);

      unawaited(Future.delayed(Duration(seconds: voice.second)).then((value) {
        state.value = const Tuple2(null, 0);
      }));
    } else {
      // 3. 下载/加载语音
      final voice = message.content as VoiceEntity;
      state.value = Tuple2(voice.path ?? voice.url, 1); // 预播放

      String voicePath;

      if (voice.path != null &&
          voice.path.isNotEmpty &&
          File(voice.path).existsSync()) {
        voicePath = voice.path;
      } else {
        // 拉去缓存
        File cacheFile;
        try {
          cacheFile =
              await CustomCacheManager.instance.getSingleFile(voice.url);
        } catch (e) {
          if (e is ArgumentError ||
              (e is HttpExceptionWithStatus &&
                  (e.statusCode == HttpStatus.forbidden ||
                      e.statusCode == HttpStatus.notFound))) {
            state.value = const Tuple2(null, 0);
            await setReadStatus(context, message);
            showToast('语音内容不存在'.tr);
          }
          return;
        }

        if (cacheFile != null) {
          voicePath = cacheFile.path;
        }
      }

      print('拿到文件 :$voicePath');
      if (voicePath == null ||
          voicePath.isEmpty ||
          !File(voicePath).existsSync() ||
          (message.messageId != this.message?.messageId)) return;
      state.value = Tuple2(voice.path ?? voice.url, 2);
//    print('开始播放');
      // 4. 开始播放
      result = await audioPlayer.play(voicePath, isLocal: true);
      // 播放语音保持屏幕常亮
      unawaited(Wakelock.enable());
    }

//    print('result:${result}');
    // 5.设置已读
    if (result == 1) {
      await setReadStatus(context, message);
    } else {
      state.value = const Tuple2(null, 0);
    }
  }

  Future<void> setReadStatus(
      BuildContext context, MessageEntity message) async {
    final voice = message.content as VoiceEntity;
    voice.isRead = true;
    await TextChannelController.to(channelId: message.channelId)
        .setVoiceRead(message);
    this.context = context;
    this.message = message;
  }

  Future<void> stop() async {
    state.value = const Tuple2(null, 0);
    await audioPlayer.stop();
  }

  /// 强制退出
  Future<void> forceStop() async {
    state.value = const Tuple2(null, 0);
    message = null;
    await audioPlayer.stop();
  }
}
