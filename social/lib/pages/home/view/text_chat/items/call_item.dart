import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/core/widgets/button/fade_button.dart';
import 'package:im/global.dart';
import 'package:im/pages/home/json/text_chat_json.dart';
import 'package:im/routes.dart';
import 'package:im/themes/const.dart';

import '../../../../../icon_font.dart';

class CallItem extends StatelessWidget {
  static Map<int, String> statusString = {
    CallEntity.statusCallingPartyCanceled: "已取消语音通话",
    CallEntity.statusCalledPartyDenied: "对方已拒绝",
    CallEntity.statusCalledPartyNoResponse: "对方无人应答",
  };
  final MessageEntity message;

  const CallItem(this.message);

  @override
  Widget build(BuildContext context) {
    final data = message.content as CallEntity;
    Widget child;
    var style = Theme.of(context).textTheme.bodyText2;
    style = style.copyWith(color: style.color.withOpacity(0.8));
    if (data.status == CallEntity.statusFinished) {
      child = Text(
        "通话时长 %s".trArgs([data.duration.toString()]),
        style: style,
      );
    } else {
      child = FadeButton(
        onTap: () => _redial(context),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).iconTheme.color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                decoration: const ShapeDecoration(
                    shape: CircleBorder(), color: Color(0xFFFF4433)),
                width: 24,
                height: 24,
                alignment: Alignment.center,
                child: const Icon(IconFont.buffAudioVisualCallMiss,
                    size: 16, color: Colors.white),
              ),
              sizeWidth8,
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text("已取消视频通话".tr, style: style),
                  Text(
                    "轻触即可回拨".tr,
                    style:
                        const TextStyle(color: Color(0xFF8F959E), fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }
    return UnconstrainedBox(child: child);
  }

  void _redial(BuildContext context) {
    final data = message.content as CallEntity;
    // final channel = GlobalState.selectedChannel.value;
    if (message.userId == Global.user.id) {
      Routes.pushVideoPage(context, data.objectId.toString());
    } else {
      Routes.pushVideoPage(context, message.userId);
    }
  }
}
