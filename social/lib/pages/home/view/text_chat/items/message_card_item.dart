import 'dart:async';
import 'dart:convert';

import 'package:dynamic_view/dynamic_view.dart';
import 'package:dynamic_view/widgets/models/widgets.dart';
import 'package:fb_live_flutter/live/utils/func/utils_class.dart';
import 'package:flutter/material.dart';
import 'package:im/app/theme/app_theme.dart';
import 'package:im/pages/home/json/message_card_entity.dart';
import 'package:im/pages/home/json/text_chat_json.dart';
import 'package:im/pages/home/view/text_chat/items/model/dynamic_view_config.dart';
import 'package:im/pages/tool/url_handler/bot_callback_link_handler.dart';
import 'package:im/pages/tool/url_handler/link_handler_preset.dart';
import 'package:im/utils/image_operator_collection/image_builder.dart';
import 'package:im/utils/image_operator_collection/image_widget.dart';

import 'components/message_card.dart';
import 'components/parsed_text_extension.dart';

class DynamicViewWidgetDataInjector extends InheritedWidget {
  final MessageCardEntity data;
  final String guildId;

  const DynamicViewWidgetDataInjector({this.data, this.guildId, Widget child})
      : super(child: child);

  static DynamicViewWidgetDataInjector of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<DynamicViewWidgetDataInjector>();
  }

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) {
    return false;
  }
}

class MessageCardItem extends StatefulWidget {
  final MessageEntity message;

  const MessageCardItem(this.message);

  @override
  State<MessageCardItem> createState() => _MessageCardItemState();
}

class _MessageCardItemState extends State<MessageCardItem> {
  WidgetData _widgetData;
  Object _parseError;
  MessageCardEntity _entity;

  StreamSubscription _streamSubscription;

  @override
  void initState() {
    _entity = widget.message.content;
    _entity.loadKeysFromLocal(widget.message.messageId);

    try {
      _widgetData = WidgetData.fromJson(jsonDecode(_entity.data));
    } catch (e) {
      _parseError = e;
    }
    _streamSubscription = _entity.listen((_) => setState(() {}));

    super.initState();
  }

  @override
  void dispose() {
    _streamSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_parseError != null) {
      return Text(_parseError.toString());
    }

    Widget child = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: DynamicViewWidgetDataInjector(
            data: _entity,
            guildId: widget.message.guildId,
            child: DynamicView.fromData(_widgetData),
          ),
        ),
        //  展示信息来源:不单独展示来源图标，所以只判断来源名称是否为空
        if (strNoEmpty(_entity.comeFromName)) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Divider(
              color: appThemeData.dividerColor,
            ),
          ),
          Container(
            width: double.infinity,
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                if (strNoEmpty(_entity.comeFromIcon))
                  Container(
                    width: 16,
                    height: 16,
                    margin: const EdgeInsets.only(right: 4),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: appThemeData.dividerColor.withOpacity(0.2),
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: ImageWidget.fromCachedNet(
                      CachedImageBuilder(imageUrl: _entity.comeFromIcon),
                    ),
                  ),
                Text(
                  _entity.comeFromName,
                  style: appThemeData.textTheme.headline2
                      .copyWith(fontSize: 12, height: 1.25),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ]
      ],
    );

    if (_entity.edition != "base") {
      child = MessageCard(
        constraints: const BoxConstraints(maxHeight: 1000),
        child: child,
      );
    }

    return NotificationListener<DynamicViewHrefNotification>(
      onNotification: (notification) {
        _handleInteract(notification.href);
        return true;
      },
      child: child,
    );
  }

  void _handleInteract(String href) {
    BotLinkHandler.currentMessage = widget.message;

    LinkHandlerPreset.bot.handle(
      href,
      refererChannelSource: RefererChannelSource.ChatMainPage,
    );
  }
}
