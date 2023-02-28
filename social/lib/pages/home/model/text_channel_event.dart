import 'package:im/pages/home/json/text_chat_json.dart';

class CustomKeyboardEvent {
  final String channelId;
  final bool visible;
  final MessageEntity message;
  CustomKeyboardEvent(this.channelId, this.visible, {this.message});
}

enum MessageStatus {
  normal,
  noMutualGuilds,
  noMutualFriends,
}

class NewMessageEvent {
  final MessageEntity message;
  final bool force;
  final bool jump;

  NewMessageEvent(this.message, {this.force = false, this.jump = true});
}

class ReactMessageEvent {
  final MessageEntity message;

  ReactMessageEvent(this.message);
}

// class NewMessageEventAfterSent {
//   final MessageEntity message;
//
//   NewMessageEventAfterSent(this.message);
// }

class RecallMessageEvent {
  final String id;
  final String recallBy;
  final String channelId;

  RecallMessageEvent(this.id, this.recallBy, this.channelId);
}

class DeleteMessageEvent {
  final String id;
  final MessageEntity message;

  DeleteMessageEvent(this.id, this.message);
}

class UpdateMessageEvent {
  final MessageEntity message;

  UpdateMessageEvent(this.message);
}

class UpdateTopicMessageEvent {
  final MessageEntity message;

  UpdateTopicMessageEvent(this.message);
}

class WebCircleUnreadEvent {
  final int unread;

  WebCircleUnreadEvent(this.unread);
}

class WebCircleClearUnreadEvent {
  WebCircleClearUnreadEvent();
}

class NotPullEvent {
  final String messageId;
  final String emojiName;
  final int count;
  final bool me;

  NotPullEvent(this.messageId, this.emojiName, this.count, this.me);
}

class OffLineReactionEvent {
  final String messageId;
  final String emojiName;
  final String action;

  OffLineReactionEvent(this.messageId, this.emojiName, this.action);
}

class UserRemoveEvent {
  final String guildId;
  final String userId;

  UserRemoveEvent(this.guildId, this.userId);
}

class UserJoinEvent {
  final String guildId;
  final String userId;

  UserJoinEvent(this.guildId, this.userId);
}
