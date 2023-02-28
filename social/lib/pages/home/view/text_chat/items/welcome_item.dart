import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:im/api/data_model/user_info.dart';
import 'package:im/common/extension/string_extension.dart';
import 'package:im/icon_font.dart';
import 'package:im/pages/home/json/text_chat_json.dart';
import 'package:im/themes/const.dart';
import 'package:im/themes/default_theme.dart';
import 'package:im/utils/utils.dart';
import 'package:im/widgets/realtime_user_info.dart';

class WelcomeItem extends StatelessWidget {
  final MessageEntity message;

  const WelcomeItem(this.message);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 4, left: 8, right: 12),
              child: Icon(
                IconFont.buffChatWelcome,
                color: Color(0xFF3EB382),
                size: 16,
              ),
            ),
            sizeWidth8,
            Expanded(
              child: UserInfo.consume(message.userId,
                  builder: (context, userInfo, child) {
                return _buildText(context, userInfo);
              }),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(left: 44),
          child: Text(
            formatDate2Str(message.time, showToday: true),
            style: Theme.of(context).textTheme.bodyText1.copyWith(fontSize: 13),
          ),
        ),
      ],
    );
  }

  Widget _buildText(BuildContext context, UserInfo userInfo) {
    final strings = (message.content as WelcomeEntity).text.split("%%");
    return Text.rich(
      TextSpan(
          style: TextStyle(color: Theme.of(context).textTheme.bodyText2.color),
          children: [
            // TODO(临时方案)：解决TextSpan在web垂直方向不对齐问题
            if (kIsWeb) const TextSpan(text: nullChar),
            if (strings[0].isNotEmpty) TextSpan(text: strings[0]),
            WidgetSpan(
                child: RealtimeNickname(
              userId: userInfo.userId,
              tapToShowUserInfo: true,
              style: TextStyle(color: primaryColor),
            )),
            if (strings[1].isNotEmpty) TextSpan(text: strings[1]),
            // TODO(临时方案)：解决TextSpan在web垂直方向不对齐问题
            if (kIsWeb) const TextSpan(text: nullChar),
          ]),
    );
  }
}
