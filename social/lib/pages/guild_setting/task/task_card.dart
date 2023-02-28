import 'package:dynamic_card/dynamic_card.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:im/icon_font.dart';
import 'package:im/pages/guild_setting/circle/circle_detail_page/show_landscape_circle_reply_popup.dart';
import 'package:im/pages/home/json/task_entity.dart';
import 'package:im/pages/home/json/text_chat_json.dart';
import 'package:im/pages/home/view/text_chat/items/components/message_card.dart';
import 'package:im/widgets/dynamic_widget/dynamic_widget.dart';

import '../../../loggers.dart';

class TaskCard extends StatelessWidget {
  final TaskEntity entity;
  final MessageEntity message;

  const TaskCard({Key key, this.entity, this.message}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constrains) {
      final bodyStyle = Theme.of(context).textTheme.bodyText2;
      return MessageCard(
        child: DynamicWidget(
          json: entity.content,
          message: message,
          config: TempWidgetConfig(
            radioConfig: RadioConfig(
              singleSelected: Icon(
                IconFont.buffSelectSingle,
                size: 20,
                color: Theme.of(context).primaryColor,
              ),
              singleUnselected: const Icon(
                IconFont.buffUnselectSingle,
                size: 20,
                color: color3,
              ),
              groupSelected: Icon(
                IconFont.buffSelectGroup,
                size: 20,
                color: Theme.of(context).primaryColor,
              ),
              groupUnselected: const Icon(
                IconFont.buffUnselectGroup,
                size: 20,
                color: color3,
              ),
            ),
            textConfig: TextConfig(
              textRep: (data) => _buildRichText(data.text, context,
                  bodyStyle.copyWith(height: 1.25, fontSize: 14)),
              contentTextRep: (data) => _buildRichText(
                  data.text,
                  context,
                  data.type == ContentTextData.h1
                      ? bodyStyle.copyWith(
                          fontSize: 14, fontWeight: FontWeight.bold)
                      : bodyStyle.copyWith(
                          fontSize: 14, fontWeight: FontWeight.bold)),
            ),
            buttonConfig: ButtonConfig(
              dropdownConfig: DropdownConfig(
                dropdownIcon: () =>
                    const Icon(IconFont.buffDownMore, color: color3),
              ),
            ),
            commonConfig: CommonConfig(
                widgetWith: kIsWeb ? 400 : constrains.maxWidth - 16),
          ),
        ),
      );
    });
  }

  Widget _buildRichText(String value, BuildContext context, TextStyle style) {
    try {
      return buildRichText(value, context,
          padding: EdgeInsets.zero, style: style);
    } catch (e) {
      logger.warning('动态卡片文本解析错误:$e       \nvalue:$value');
      return null;
    }
  }
}
