import 'dart:convert';

import 'package:dynamic_card/dynamic_card.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:im/common/extension/string_extension.dart';
import 'package:im/core/http_middleware/http.dart';
import 'package:im/db/db.dart';
import 'package:im/global.dart';
import 'package:im/icon_font.dart';
import 'package:im/loggers.dart';
import 'package:im/pages/home/json/text_chat_json.dart';
import 'package:im/pages/home/json/vote_entity.dart';
import 'package:im/pages/home/view/text_chat/text_chat_ui_creator.dart';
import 'package:im/themes/default_theme.dart';
import 'package:im/widgets/dynamic_widget/dynamic_widget.dart';
import 'package:im/ws/ws.dart';
import 'package:pedantic/pedantic.dart';

import '../../../../../icon_font.dart';
import 'components/message_card.dart';

const color3 = Color(0xff8F959E);

class VoteItemBuilder extends StatefulWidget {
  final String voteId;
  final String url;
  final MessageEntity message;
  final Function(Map json) builder;

  const VoteItemBuilder({
    @required this.voteId,
    @required this.url,
    @required this.message,
    @required this.builder,
  });

  static Future<bool> updateFormNet(
      String voteId, String url, String guildId, String channelId) async {
    try {
      final res = await Http.dio.get(url, queryParameters: {
        'vote_id': voteId,
        'guild_id': guildId,
        'channel_id': channelId,
        'user_id': Global.user.id,
      });
      if (res.data != null) {
        final Map data = res.data;
        if (data['data'] != null && data['code'] == 200) {
          unawaited(Db.voteCardBox.put(voteId, data['data']));
          return true;
        }
      }
    } catch (e) {
      logger.info(e.toString());
    }
    return false;
  }

  static void updateFromXPath(String voteId, Map xPath) {
    final map = Db.voteCardBox.get(voteId);
    if (map == null) {
      return;
    }
    xPath.keys.toList().cast<String>().forEach((key) {
      final pathArr = key.split('->');
      try {
        dynamic tmp = map;
        for (int i = 0; i < pathArr.length; i++) {
          final _key = pathArr[i];
          final isLast = i == pathArr.length - 1;
          if (isLast) {
            tmp[_key] = xPath[key];
          } else {
            if (_key.isPureNumber()) {
              tmp = tmp[int.parse(_key)];
            } else {
              tmp = tmp[_key];
            }
          }
        }
        Db.voteCardBox.put(voteId, map);
      } catch (e) {
        logger.info(e);
      }
    });
  }

  @override
  _VoteItemBuilderState createState() => _VoteItemBuilderState();
}

class _VoteItemBuilderState extends State<VoteItemBuilder> {
  static Set<String> updatedMap = {};

  void decode(String key, String url, {bool force = false}) {
    if (url.noValue) return;
    if (!updatedMap.contains(key) || force) {
      VoteItemBuilder.updateFormNet(
              key, url, widget.message.guildId, widget.message.channelId)
          .then((res) {
        if (res) updatedMap.add(key);
      });
    }
  }

  @override
  void initState() {
    decode(widget.voteId, widget.url);
    Ws.instance.connectionStatus.addListener(_onWsStatusChange);
    super.initState();
  }

  @override
  void dispose() {
    Ws.instance.connectionStatus.removeListener(_onWsStatusChange);
    super.dispose();
  }

  void _onWsStatusChange() {
    final status = Ws.instance.connectionStatus.value;
    if (status == WsConnectionStatus.disconnected ||
        status == WsConnectionStatus.connecting) {
      updatedMap.clear();
    } else {
      decode(widget.voteId, widget.url, force: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
        valueListenable: Db.voteCardBox.listenable(keys: [widget.voteId]),
        builder: (context, box, _) {
          final data = Db.voteCardBox.get(widget.voteId);
          if (data == null)
            return Container(
                height: 113,
                width: 113,
                color: Theme.of(context).scaffoldBackgroundColor,
                child: DefaultTheme.defaultLoadingIndicator());
          final json = jsonDecode(jsonEncode(data));
          return widget.builder(json);
        });
  }
}

class VoteItem extends StatefulWidget {
  final VoteEntity entity;
  final MessageEntity message;

  const VoteItem({Key key, this.entity, this.message}) : super(key: key);

  @override
  _VoteItemState createState() => _VoteItemState();
}

class _VoteItemState extends State<VoteItem> {
  @override
  Widget build(BuildContext context) {
    if (widget.entity.voteId == null || widget.entity.url == null)
      return TextChatUICreator.unSupportWidget(context);

    return GestureDetector(
      onTap: () {}, // 禁用内部弹出回复效果
      child: VoteItemBuilder(
          voteId: widget.entity.voteId,
          url: widget.entity.url,
          message: widget.message,
          builder: (json) {
            return LayoutBuilder(builder: (context, constrains) {
              return MessageCard(
                child: DynamicWidget(
                  json: json,
                  message: widget.message,
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
                        valueChangeCallback: (arr) {
                          try {
                            final map =
                                Db.voteCardBox.get(widget.entity.voteId);
                            final List children = map['children'];
                            final index = children
                                .indexWhere((e) => e['type'] == 'radio');
                            if (index < 0) return;
                            final Map radio = children[index];
                            final Map param = radio['param'];
                            final List list = param['list'];
                            for (int i = 0; i < list.length; i++) {
                              final Map item = list[i];
                              item['value'] = arr.contains(i) ? 1 : 0;
                            }
                            Db.voteCardBox.put(widget.entity.voteId, map);
                          } catch (e) {
                            logger.info(e);
                          }
                        }),
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
          }),
    );
  }
}
