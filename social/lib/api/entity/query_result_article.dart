class EntityQueryResultArticle {
  String type;
  String id;
  String title;
  String description;
  dynamic replyMarkup;
  dynamic inputMessageContent;
  String url;
  bool hideUrl;
  String thumbUrl;
  int thumbWidth;
  int thumbHeight;

  EntityQueryResultArticle.fromJson(Map<String, dynamic> json) {
    type = json["type"];
    id = json["id"];
    title = json["title"];
    description = json["description"];
    replyMarkup = json["reply_markup"];
    inputMessageContent = json["input_message_content"];
    url = json["url"];
    hideUrl = json["hide_url"];
    thumbUrl = json["thumb_url"];
    thumbWidth = json["thumb_width"];
    thumbHeight = json["thumb_height"];
  }
}
