import 'package:date_format/date_format.dart';
import 'package:get/get.dart';
import 'package:im/locale/message_keys.dart';
import 'package:im/pages/home/json/text_chat_json.dart';
import 'package:im/utils/message_util.dart';
import 'package:intl/intl.dart';

mixin MessageEntityExtension on MessageEntity {
  static String buildTimeSeparator(MessageEntity item, bool crossYear) {
    final List<String> timeFormat = crossYear
        ? [yyyy, "年".tr, m, "月".tr, d, "日".tr]
        : [m, "月".tr, d, "日".tr];

    var timeString = formatDate(item.messageTime(), timeFormat);
    if (Get.locale.languageCode != MessageKeys.zh) {
      if (crossYear) {
        timeString = DateFormat.yMMMd().format(item.time);
      } else {
        timeString = DateFormat.MMMd().add_Hm().format(item.time);
      }
    }
    return timeString;
  }

  // 公屏的逻辑抽取，需要讨论抽取后放置的位置
  static bool shouldShowUserInfo(
      MessageEntity previous, MessageEntity current, MessageEntity next,
      {bool underNewMessageSeparator}) {
    /// return false 优先
    if (current.isRecalled) return false;

    if (underNewMessageSeparator) return true;
    if (previous == null) return true;
    if (previous.content.type == MessageType.friend) return true;

    /// 满足了显示时间戳条件
    if (shouldShowTimeStamp(previous, current)) return true;

    /// 本条消息和上一条消息不是同一个人发的时候
    if (previous.userId != current.userId) return true;

    /// 一些不需要显示用户信息的消息
    if (previous.content is StartEntity || previous.content is WelcomeEntity)
      return true;

    // 判断消息是不是一个卡片展示
    bool isCard(MessageEntity m) {
      if (m.quoteL1 != null) return true;

      switch (m.content.type) {
        // 第一部分：非实体消息类型
        case MessageType.del:
        case MessageType.empty:
        case MessageType.upMsg:
        case MessageType.recall:
        case MessageType.pinned:
        case MessageType.reaction:
        case MessageType.du:
        case MessageType.messageCardKey:
          assert(false, "这些非实体消息不可能触发");
          return false;

        // 第二部分：不会展示成卡片的消息类型
        case MessageType.unSupport:
        case MessageType.start:
        case MessageType.image:
        case MessageType.video:
        case MessageType.voice:
        case MessageType.newJoin:
        case MessageType.redPack:
        case MessageType.call:
        case MessageType.richText:
        case MessageType.stickerEntity:
        case MessageType.circle:
        case MessageType.file:
        case MessageType.circleShareEntity:
        case MessageType.goodsShareEntity:
        case MessageType.externalShareEntity:
        case MessageType.friend:
        case MessageType.document:
          return false;

        // 第三部分：会展示成卡片的消息类型
        case MessageType.topicShare:
        case MessageType.messageCard:
        case MessageType.task:
        case MessageType.vote:
          return true;

        // 第四部分：普通文本有些特殊，包含 URL 会显示为卡片样式
        case MessageType.text:
          return (m.content as TextEntity).numUrls > 0;
      }

      assert(true, "所有判断均已在 switch-case 完成，此处不应该触发");
      return false;
    }

    /// 当前消息包含了卡片时
    if (isCard(current)) return true;

    /// 上一条消息包含卡片时
    // if (isCard(previous)) return true;

    if (previous.isRecalled) return true;

    /// 下一条消息包含卡片时
//    if (next != null && isCard(next)) return true;

    ///上一条是隐藏消息
    if (!MessageUtil.canISeeThisMessage(previous)) return true;

    return false;
  }

  /// 如果下一条消息和上一条消息时间差了 5 分钟，显示时间戳
  static bool shouldShowTimeStamp(MessageEntity current, MessageEntity next) {
    final time = current.time.add(const Duration(minutes: 5));
    final nextMessageTime = next.time;
    return time.isBefore(nextMessageTime);
  }
}
