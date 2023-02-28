import 'dart:convert';
import 'dart:developer';

import 'package:im/api/bot_api.dart';
import 'package:im/api/text_chat_api.dart';
import 'package:im/global.dart';
import 'package:im/pages/home/json/message_card_entity.dart';
import 'package:im/pages/home/json/text_chat_json.dart';
import 'package:im/pages/home/view/text_chat/items/components/parsed_text_extension.dart';
import 'package:im/pages/tool/url_handler/link_handler.dart';
import 'package:pedantic/pedantic.dart';
import 'package:url_launcher/url_launcher.dart';

enum _KeyOperation {
  set,
  clear,
  toggle,
}

_KeyOperation _keyOpFromString(String op) {
  switch (op) {
    case "set":
      return _KeyOperation.set;
    case "clear":
      return _KeyOperation.clear;
    case "toggle":
  }
  return _KeyOperation.toggle;
}

class BotLinkHandler extends LinkHandler {
  /// 当前 bot 交互对应的消息，在每次调用 [handle] 前必须设置
  static MessageEntity currentMessage;

  @override
  bool match(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;

    return uri.scheme == 'fanbook';
  }

  @override
  Future handle(String url, {RefererChannelSource refererChannelSource}) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (uri.host == "key") {
      _processKey(_keyOpFromString(uri.pathSegments[0]), uri.pathSegments[1],
          uri.queryParameters);
      return;
    }
    // example: fanbook://bot/callback?data=confirm
    switch (uri.host + uri.path) {
      case 'bot/callback':
        unawaited(BotApi.invokeRemoteCallback(
          userId: Global.user.id,
          data: uri.queryParameters['data'],
          message: currentMessage,
        ));
        break;

      case 'external/open':
        var url = Uri.tryParse(uri.queryParameters['url']);
        if (url == null) break;

        url = url.replace(
            query: url.query.replaceAllMapped(RegExp(r"\$(\w+)"), (match) {
          final field = match.group(1);
          switch (field) {
            case 'user_id':
              return Global.user.id;
            case 'message':
              if (currentMessage == null) return field;
              return jsonEncode({
                "sender_id": currentMessage.userId,
                "message_id": currentMessage.messageId,
                "channel_id": currentMessage.channelId,
                if (currentMessage.guildId != null)
                  "guild_id": currentMessage.guildId,
              });
            default:
              return field;
          }
        }));

        await launch(url.toString());
        break;
    }
  }

  void _processKey(
      _KeyOperation op, String key, Map<String, String> queryParameters) {
    final messageContent = currentMessage.content as MessageCardEntity;
    if (key == "auto") {
      key = messageContent.hasAnyKeyMySelf();
      // 将操作从 toggle 转成具体的 set/clear
      if (op == _KeyOperation.toggle) {
        op = key != null ? _KeyOperation.clear : _KeyOperation.set;
      }

      if (op == _KeyOperation.set) {
        final max = int.tryParse(queryParameters['max']) ?? 5;
        if (key != null) {
          // 已经有 key 了，就不能再设置了
          return;
        } else {
          // 寻找一个合适的 key
          key = messageContent.getEmptyKey(max);
          if (key == null) {
            log("无法自动设置合适的 key", name: "消息卡片");
            return;
          }
        }

        /// 为了防止数据竞争，服务端提供了自动设置的接口。自动清除暂时没有服务端接口，如果有必要再说。
        MessageCardApi.autoSetKey(
          currentMessage.channelId,
          currentMessage.messageId,
          max,
        ).catchError(
            (e) => log("failed to set key due to $e", name: "MessageCard"));

        /// 由于自动设置的特殊性（特殊接口），不走后面的逻辑
        return;
      }
      //  此时 op == _KeyOperation.clear
      else if (key == null) {
        // 本就没有 key，不需要清除了
        return;
      }
    } else {
      /// 把 toggle 转换成其他两种状态，后续就只需要处理两种情况
      if (op == _KeyOperation.toggle) {
        if (messageContent.hasKeyMyself(key)) {
          op = _KeyOperation.clear;
        } else {
          op = _KeyOperation.set;
        }
      }
    }

    /// 用户操作只需要发起 http 请求，UI 更新将由 ws 通知触发
    switch (op) {
      case _KeyOperation.set:
        MessageCardApi.setKey(
          currentMessage.channelId,
          currentMessage.messageId,
          key,
        ).catchError(
            (e) => log("failed to set key due to $e", name: "MessageCard"));
        break;
      case _KeyOperation.clear:
        MessageCardApi.clearKey(
          currentMessage.channelId,
          currentMessage.messageId,
          key,
        ).catchError(
            (e) => log("failed to clear key due to $e", name: "MessageCard"));
        break;

      case _KeyOperation.toggle:
        assert(false,
            "this is impossible, the code above should convert `toggle` to `set` or `clear`");
    }
  }
}
