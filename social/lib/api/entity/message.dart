import "../entity/chat.dart";
import "../entity/user.dart";

class EntityMessage {
  int messageId;
  EntityUser from;
  int date;
  EntityChat chat;
  EntityUser forwardFrom;
  EntityChat forwardFromChat;
  int forwardFromMessageId;
  String forwardSignature;
  String forwardSenderName;
  int forwardDate;
  EntityMessage replyToMessage;
  int editDate;
  String mediaGroupId;
  String authorSignature;
  String text;
  List<dynamic> entities;

  EntityMessage.fromJson(Map<String, dynamic> json) {
    messageId = json["message_id"];
    from = EntityUser.fromJson(json["from"]);
    date = json["date"];
    chat = EntityChat.fromJson(json["chat"]);
    forwardFrom = EntityUser.fromJson(json["forward_from"]);
    forwardFromChat = EntityChat.fromJson(json["forward_from_chat"]);
    forwardFromMessageId = json["forward_from_message_id"];
    forwardSignature = json["forward_signature"];
    forwardSenderName = json["forward_sender_name"];
    forwardDate = json["forward_date"];
    replyToMessage = EntityMessage.fromJson(json["reply_to_message"]);
    editDate = json["edit_date"];
    mediaGroupId = json["media_group_id"];
    authorSignature = json["author_signature"];
    text = json["text"];
    if (json["entities"] != null) {
      entities = List.from(
        json["entities"].map(
          (v) => v,
        ),
      );
    }
  }
}
