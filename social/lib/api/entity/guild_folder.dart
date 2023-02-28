import 'dart:convert';

class GuildFolder {
  List<String> guildIds;
  String folderId;

  GuildFolder({this.guildIds, this.folderId});

  Map<String, dynamic> toJson() {
    if (folderId == null || folderId.isEmpty) {
      return {"guild_ids": guildIds};
    } else {
      return {"guild_ids": guildIds, "id": folderId};
    }
  }

  @override
  String toString() {
    return json.encode(toJson());
  }

  // factory GuildFolder.fromJson(Map<String, dynamic> json) =>
  //     GuildFolder(guildIds: json['guild_ids'], folderId: json['id']);
}
