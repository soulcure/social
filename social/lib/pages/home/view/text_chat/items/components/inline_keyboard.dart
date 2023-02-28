import 'package:flutter/material.dart';
import 'package:flutter_parsed_text/flutter_parsed_text.dart';
import 'package:im/api/bot_api.dart';
import 'package:im/api/entity/reply_markup.dart';
import 'package:im/common/extension/string_extension.dart';
import 'package:im/core/widgets/button/fade_button.dart';
import 'package:im/icon_font.dart';
import 'package:im/pages/home/json/text_chat_json.dart';
import 'package:im/pages/home/view/text_chat/items/components/parsed_text_extension.dart';
import 'package:im/pages/tool/url_handler/bot_callback_link_handler.dart';
import 'package:im/pages/tool/url_handler/link_handler_preset.dart';
import 'package:im/themes/default_theme.dart';
import 'package:im/utils/orientation_util.dart';

import '../../../../../../global.dart';
import '../../../../../../routes.dart';

class InlineKeyboard extends StatelessWidget {
  final MessageEntity message;

  const InlineKeyboard(this.message);

  @override
  Widget build(BuildContext context) {
    final List<Widget> rows = [];
    for (final row in message.replyMarkup.inlineKeyboard) {
      final List<Widget> children = [];
      row.forEach((cell) {
        Widget button = Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            // margin: const EdgeInsets.all(2.5),
            alignment: Alignment.center,
            decoration: ShapeDecoration(
                shape: StadiumBorder(side: BorderSide(color: primaryColor))),
            child: _buildText(context, cell.text));

        if (cell.url != null) {
          button = _buildLinkButton(button);
        }

        children.add(Expanded(
            child: FadeButton(
          onTap: () {
            if (cell.appId.hasValue) {
              Routes.pushMiniProgram(cell.appId);
            } else if (cell.url != null) {
              LinkHandlerPreset.bot.handle(cell.url);
            } else if (cell.callbackData != null) {
              BotLinkHandler.currentMessage = message;
              LinkHandlerPreset.bot.handle(
                  'fanbook://bot/callback?data=${Uri.encodeComponent(cell.callbackData)}');
            }
          },
          child: button,
        )));

        if (cell != row.last)
          children.add(SizedBox(width: OrientationUtil.landscape ? 10 : 5));
      });

      rows.add(Row(children: children));
      if (row != message.replyMarkup.inlineKeyboard.last)
        rows.add(const SizedBox(height: 12));
    }

    return Column(children: rows);
  }

  Widget _buildLinkButton(Widget child) {
    return Stack(
      alignment: Alignment.center,
      children: [
        child,
        Positioned(
            right: 15,
            width: 18,
            height: 18,
            child: Icon(IconFont.buffBotCommandLink,
                color: primaryColor, size: 18)),
      ],
    );
  }

  void invokeRemoteCallback(InlineKeyboardData data) {
    BotApi.invokeRemoteCallback(
      userId: Global.user.id,
      data: data.callbackData,
      message: message,
    );
  }

  Widget _buildText(BuildContext context, String text) {
    final style = TextStyle(
        fontSize: 14, fontWeight: FontWeight.w500, color: primaryColor);
    return ParsedText(
      style: style,
      overflow: TextOverflow.ellipsis,
      text: text,
      parse: [
        ParsedTextExtension.matchCusEmoText(context, style.fontSize),
        // ParsedTextExtension.matchURLText(context),
        ParsedTextExtension.matchChannelLink(context),
        ParsedTextExtension.matchAtText(
          context,
          textStyle: style,
          tapToShowUserInfo: false,
          fetchFromNetIfNotExistLocally: true,
        ),
      ],
    );
  }
}
