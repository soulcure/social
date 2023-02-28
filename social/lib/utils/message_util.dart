import 'package:im/api/data_model/user_info.dart';
import 'package:im/api/text_chat_api.dart';
import 'package:im/common/extension/future_extension.dart';
import 'package:im/common/extension/string_extension.dart';
import 'package:im/common/permission/permission_model.dart';
import 'package:im/db/chat_db.dart';
import 'package:im/db/db.dart';
import 'package:im/db/quote_message_db.dart';
import 'package:im/pages/home/json/du_entity.dart';
import 'package:im/pages/home/json/text_chat_json.dart';
import 'package:im/pages/home/model/in_memory_db.dart';

import '../global.dart';

enum AtMeType {
  none,
  role,
  user,
}

class MessageUtil {
  ///检查消息是否有艾特自己的
  static AtMeType atMe(MessageEntity message, {bool checkRecall = true}) {
    if (checkRecall && message.recall.hasValue) return AtMeType.none;
    if (message.deleted == 1) return AtMeType.none;
    if (message.content is! TextEntity && message.content is! RichTextEntity)
      return AtMeType.none;

    final myRoles = PermissionModel.getPermission(message.guildId).userRoles;

    String content = '';
    if (message.content is TextEntity) {
      content = (message.content as TextEntity).text;
    } else {
      content = (message.content as RichTextEntity).toSearchTextString();
    }
    for (final match in TextEntity.atPattern.allMatches(content)) {
      final type = match.group(1);
      final id = match.group(2);
      if (type == "!" && id == Global.user.id) {
        return AtMeType.user;
      }

      // TODO 是否存在更好的方式判断私信，不需要判断角色
      if (type == "&") {
        if (id == message.guildId) return AtMeType.role;
        if (myRoles.indexWhere((e) => e == id) != -1) {
          return AtMeType.role;
        }
      }
    }
    return AtMeType.none;
  }

  ///检查消息的 mentions 和  mentionRoles 中 是否有艾特自己的
  static AtMeType atMeInMentions(MessageEntity message,
      {String userId, bool useParam = false, List<String> userRoles}) {
    if (message == null) return AtMeType.none;
    if (message.mentions == null && message.mentionRoles == null)
      return AtMeType.none;

    if (message.mentions != null && message.mentions.isNotEmpty) {
      userId ??= Global.user.id;
      for (var i = 0; i < message.mentions.length; i++) {
        if (message.mentions[i] == userId) {
          return AtMeType.user;
        }
      }
    }
    if (message.mentionRoles != null && message.mentionRoles.isNotEmpty) {
      String item;
      if (!useParam) {
        userRoles = PermissionModel.getPermission(message.guildId).userRoles;
      }
      for (var i = 0; i < message.mentionRoles.length; i++) {
        item = message.mentionRoles[i];
        if (userRoles?.indexWhere((e) => e == item) != -1) {
          return AtMeType.role;
        }
      }
    }
    return AtMeType.none;
  }

  ///设置消息的 mentions 和 mentionRoles
  static void setMessageMentions(MessageEntity message,
      {String atContent, RegExp pattern}) {
    String content;
    if (atContent == null) {
      if (message.content is! TextEntity && message.content is! RichTextEntity)
        return;
      if (message.content is TextEntity) {
        content = (message.content as TextEntity).text;
      } else {
        content = (message.content as RichTextEntity).toSearchTextString();
      }
    } else {
      content = atContent;
    }
    if (content.noValue) return;
    final List<String> list1 = [];
    final List<String> list2 = [];
    String type, id;
    final RegExp regExp = pattern ?? TextEntity.atPattern;
    for (final match in regExp.allMatches(content)) {
      type = match.group(1);
      id = match.group(2);
      if (type == "!") {
        list1.add(id);
      } else if (type == "&") {
        list2.add(id);
      }
    }
    if (list1.isNotEmpty) message.mentions = list1;
    if (list2.isNotEmpty) message.mentionRoles = list2;
  }

  // 机器人隐身消息指令，只有自己和被@用户可见
  static bool canISeeThisMessage(MessageEntity message,
      {String userId, bool useParam = false, List<String> userRoles}) {
    if (message.content is TextEntity &&
        (message.content as TextEntity).isHideCommand()) {
      userId ??= Global.user.id;
      bool isAtMe;
      if (message.isIncomplete) {
        isAtMe = MessageUtil.atMeInMentions(message,
                userId: userId, useParam: useParam, userRoles: userRoles) !=
            AtMeType.none;
      } else {
        isAtMe = atMe(message) != AtMeType.none;
      }
      final isISend = message.userId == Global.user.id;
      // 机器人隐身消息指令，只有自己和被@用户可见
      if (!isAtMe && !isISend) {
        return false;
      }
    }
    if (message.content is DuEntity) {
      return false;
    }

    return true;
  }

  static Future<MessageEntity> getMessage(
      String messageId, String channelId) async {
    MessageEntity res;
    final ml = InMemoryDb.getMessageList(channelId);

    ///第一步，从内存中读取
    res = ml.get(BigInt.parse(messageId));
    if (res != null) return res;

    res = ml.getFromCache(messageId);
    if (res != null) return res;

    ///第二步，如果从内存中找不到则从数据库拿
    res = await ChatTable.getMessage(messageId);
    res ??= await QuoteMessageTable.getMessage(messageId);
    if (res != null) {
      ml.addCache(res);
      return res;
    }

    ///第三步，如果从数据库找不到，则从服务器拿,此时还需进行权限判断
    res = await TextChatApi.getMessage(channelId, messageId,
        autoRetryIfNetworkUnavailable: true);
    if (res != null) {
      QuoteMessageTable.append(res).unawaited;
      ml.addCache(res);
      return res;
    }

    return res;
  }

  ///艾特用户ID的表达式
  static final RegExp atUserPattern = RegExp(r"\$\{@!(\d+)\}");

  ///获取圈子消息频道的副标题 - 在线push使用
  static Future<String> toDescString(String text, String guildId,
      {String atPre = ''}) async {
    if (text.noValue) return '';
    String result = text;
    if (atUserPattern.hasMatch(text)) {
      result = await result.replaceAllMappedAsync(atUserPattern, (m) async {
        final user = await UserInfo.getUserInfoForGuild(m.group(1), guildId);
        final showName = user?.showName(guildId: guildId) ?? "";
        return '$atPre$showName';
      });
    }
    return result;
  }

  ///转换文本中的用户ID - 消息列表圈子频道使用
  static String getDescString(String text,
      {String guildId, String atPre = ''}) {
    if (text.noValue) return text;
    final StringBuffer replaced = StringBuffer();
    int currentIndex = 0;
    for (final match in atUserPattern.allMatches(text)) {
      final prefix = match.input.substring(currentIndex, match.start);
      currentIndex = match.end;
      final userId = match.group(1);
      final user = Db.userInfoBox.get(userId);
      final showName = user?.showName(guildId: guildId);
      replaced
        ..write(prefix)
        ..write(showName.hasValue ? '$atPre$showName ' : '');
    }
    replaced.write(text.substring(currentIndex));
    return replaced.toString();
  }

  ///转换文本中的用户ID - 私信和群聊频道使用
  static String getDescStringForDm(
    String text, {
    String atPre = '',
    String guildId,
    bool hideGuildNickname = true,
  }) {
    if (text.noValue) return text;
    final StringBuffer replaced = StringBuffer();
    int currentIndex = 0;
    for (final match in atUserPattern.allMatches(text)) {
      final prefix = match.input.substring(currentIndex, match.start);
      currentIndex = match.end;
      final userId = match.group(1);
      final user = Db.userInfoBox.get(userId);
      final showName = user?.showName(
          guildId: guildId, hideGuildNickname: hideGuildNickname);
      replaced
        ..write(prefix)
        ..write(showName.hasValue ? '$atPre$showName ' : '');
    }
    replaced.write(text.substring(currentIndex));
    return replaced.toString();
  }

  ///解析出文本中的用户ID
  static List<String> getUserIdListInText(String text) {
    if (text.noValue) return null;
    final List<String> list = [];
    final matches = atUserPattern.allMatches(text);
    if (matches.isNotEmpty) {
      final Set<String> set = {};
      matches.forEach((m) {
        set.add(m.group(1));
      });
      list.addAll(set.toList(growable: false));
    }
    return list;
  }

  ///去掉换行符
  static String trimEmptyEnd(String value) {
    return value?.replaceAll('\n', '');
  }
}
