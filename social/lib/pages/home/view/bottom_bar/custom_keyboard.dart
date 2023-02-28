import 'package:flutter/material.dart';
import 'package:flutter_parsed_text/flutter_parsed_text.dart';
import 'package:im/api/entity/reply_markup.dart';
import 'package:im/core/widgets/button/fade_button.dart';
import 'package:im/pages/home/json/text_chat_json.dart';
import 'package:im/pages/home/model/text_channel_controller.dart';
import 'package:im/pages/home/view/text_chat/items/components/parsed_text_extension.dart';
import 'package:im/themes/custom_color.dart';

class CustomKeyboard extends StatelessWidget {
  final MessageEntity message;

  const CustomKeyboard(this.message);

  @override
  Widget build(BuildContext context) {
    return Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          separatorBuilder: (context, index) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final List<Widget> children = [];
            final array = message.replyMarkup.keyboard[index];
            for (final cell in array) {
              children.add(Expanded(
                  child: FadeButton(
                onTap: () {
                  TextChannelController.to(channelId: message.channelId)
                      .sendContent(TextEntity.fromString(cell.text));
                },
                child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: ShapeDecoration(
                      color: CustomColor(context).backgroundColor2,
                      shape: const StadiumBorder(),
                      shadows: const [
                        BoxShadow(
                            color: Color(0xFFE0E2E6),
                            offset: Offset(0, 0.5),
                            blurRadius: 4)
                      ],
                    ),
                    height: 42,
                    alignment: Alignment.center,
                    child: _buildText(context, cell)),
              )));
              if (cell != array.last) children.add(const SizedBox(width: 10));
            }
            return Row(children: children);
          },
          itemCount: message.replyMarkup.keyboard.length,
        ));
  }

  Widget _buildText(BuildContext context, Keyboard cell) {
    final style = Theme.of(context).textTheme.bodyText2;
    return ParsedText(
      style: style,
      overflow: TextOverflow.ellipsis,
      text: cell.text,
      parse: [
        ParsedTextExtension.matchCusEmoText(context, style.fontSize),
        ParsedTextExtension.matchChannelLink(context),
        ParsedTextExtension.matchAtText(
          context,
          tapToShowUserInfo: false,
          fetchFromNetIfNotExistLocally: true,
        ),
      ],
    );
  }
}
