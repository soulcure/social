class EntityQueryResultPhoto {
  String type;
  String id;
  String photoUrl;
  String thumbUrl;
  int photoWidth;
  int photoHeight;
  String title;
  String description;
  String caption;
  String parseMode;
  dynamic replyMarkup;
  dynamic inputMessageContent;

  EntityQueryResultPhoto.fromJson(Map<String, dynamic> json) {
    type = json["type"];
    id = json["id"];
    photoUrl = json["photo_url"];
    thumbUrl = json["thumb_url"];
    photoWidth = json["photo_width"];
    photoHeight = json["photo_height"];
    title = json["title"];
    description = json["description"];
    caption = json["caption"];
    parseMode = json["parse_mode"];
    replyMarkup = json["reply_markup"];
    inputMessageContent = json["input_message_content"];
  }
}
