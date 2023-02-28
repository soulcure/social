import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:im/app/theme/app_theme.dart';
import 'package:im/global.dart';
import 'package:im/icon_font.dart';
import 'package:im/pages/home/json/text_chat_json.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/pages/home/model/text_channel_controller.dart';
import 'package:im/pages/home/view/record_view/sound_play_manager.dart';
import 'package:im/themes/custom_color.dart';
import 'package:im/themes/default_theme.dart';
import 'package:im/utils/orientation_util.dart';
import 'package:im/widgets/animation/icons_animation.dart';
import 'package:tuple/tuple.dart';

class VoiceItem extends StatelessWidget {
  final MessageEntity message;
  final int index;
  final String quoteL1;
  final bool showReadStatus;

  const VoiceItem(this.message,
      {this.index = -1, this.quoteL1, this.showReadStatus = true});

  // 判断指定位置消息是否是同个人5分钟内发出来的语音文件
  bool _messageIsVoice(List<MessageEntity> messages, int index) {
    // 越界判断
    if (index < 0 || index >= messages.length) return false;
    // 时间判断
    final currentTime = message.time.millisecondsSinceEpoch;
    final destTime = messages[index].time.millisecondsSinceEpoch;
    if ((currentTime - destTime).abs() > 5 * 60 * 1000) return false;
    // 人判断
    if (messages[index].userId != message.userId) return false;
    // 类型判断
    return messages[index].content.runtimeType == VoiceEntity;
  }

  @override
  Widget build(BuildContext context) {
    final data = message.content as VoiceEntity;
    int widthLevel = 1; // 0 1 2   语音长度
    if (data.second > 20 && data.second <= 40) {
      widthLevel = 2;
    } else if (data.second > 40) {
      widthLevel = 3;
    }
    final maxWidth =
        OrientationUtil.landscape ? 500 : MediaQuery.of(context).size.width;
    final width = (maxWidth - 111) * widthLevel / 3;
    final send = Global.user.id == message.userId;
    final isRead = data.isRead ?? true;
    final messages =
        TextChannelController.to(channelId: message.channelId).messageList;

    // 上面下面的数据是否是语音
    final recall = message.quoteL1 == null;
    final preMessageIsVoice = recall && _messageIsVoice(messages, index - 1);
    final nextMessageIsVoice = recall && _messageIsVoice(messages, index + 1);

    final usePrimaryBg =
        send && GlobalState.selectedChannel.value?.type == ChatChannelType.dm;
    final color = usePrimaryBg
        ? Colors.white
        : Theme.of(context).textTheme.bodyText2.color;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () =>
          SoundPlayManager().playVoice(context, message, quoteL1: quoteL1),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
              width: width,
              height: 40,
              decoration: BoxDecoration(
                  color:
                      usePrimaryBg ? primaryColor : appThemeData.dividerColor,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(preMessageIsVoice ? 4 : 6),
                    bottomLeft: Radius.circular(nextMessageIsVoice ? 4 : 6),
                    topRight: const Radius.circular(6),
                    bottomRight: const Radius.circular(6),
                  )),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  ValueListenableBuilder(
                    valueListenable: SoundPlayManager().state,
                    builder: (context, state, _) {
                      final Tuple2<String, int> currentState =
                          state ?? const Tuple2(null, 0);
                      final data = message.content as VoiceEntity;
                      final selected = currentState.item1 == data.url ||
                          currentState.item1 == data.path;

                      if (state.item2 == 2 && selected) {
                        return Container(
                          margin: const EdgeInsets.only(left: 12),
                          child: IconsAnimation(
                            color: color,
                            icons: const [
                              IconFont.buffAnimaitonSendVoice1,
                              IconFont.buffAnimaitonSendVoice2,
                              IconFont.buffAnimaitonSendVoice3,
                            ],
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      } else if (state.item2 == 1 && selected) {
                        return Container(
                          margin: const EdgeInsets.only(left: 12),
                          child: Icon(
                            IconFont.buffAnimaitonSendVoice3,
                            color: color.withOpacity(0.5),
                            size: 18,
                          ),
                        );
                      } else {
                        return Container(
                          margin: const EdgeInsets.only(left: 12),
                          child: Icon(
                            IconFont.buffAnimaitonSendVoice3,
                            color: color,
                            size: 18,
                          ),
                        );
                      }
                    },
                  ),
                  Container(
                    margin: const EdgeInsets.only(right: 12),
                    child: Text(
                      '${data.second > 9 ? '' : '0'}${data.second}”',
                      style: TextStyle(fontSize: 12, color: color),
                    ),
                  )
                ],
              )),
          if (isRead || send || !showReadStatus)
            Container()
          else
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(left: 8),
              decoration: BoxDecoration(
                  color: CustomColor.red,
                  borderRadius: BorderRadius.circular(4)),
            )
        ],
      ),
    );
  }
}
