class EntityUser {
  int id;
  bool isBot;
  String firstName;
  String lastName;
  String username;
  String languageCode;
  bool canJoinGroups;
  bool canReadAllGroupMessages;
  bool supportsInlineQueries;

  EntityUser.fromJson(Map<String, dynamic> json) {
    id = json["id"];
    isBot = json["is_bot"];
    firstName = json["first_name"];
    lastName = json["last_name"];
    username = json["username"];
    languageCode = json["language_code"];
    canJoinGroups = json["can_join_groups"];
    canReadAllGroupMessages = json["can_read_all_group_messages"];
    supportsInlineQueries = json["supports_inline_queries"];
  }
}
