// To parse this JSON data, do
//
//     final botInfo = botInfoFromJson(jsonString);

import 'dart:convert';

class BotInfo {
  BotInfo({
    this.botId,
    this.ownerId,
    this.botName,
    this.botDescription,
    this.botAbout,
    this.botAvatar,
    this.webhook,
    this.enableInlineMode,
    this.enableInlineGeo,
    this.joinGroupAllowed,
    this.enableGroupPrivacyMode,
    this.confirmedUpdateId,
    this.commands,
    this.permissions,
    this.username,
  });

  final String botId;
  final String ownerId;
  final String botName;
  final String botDescription;
  final String botAbout;
  final String botAvatar;
  final String webhook;
  final bool enableInlineMode;
  final bool enableInlineGeo;
  final bool joinGroupAllowed;
  final bool enableGroupPrivacyMode;
  final int confirmedUpdateId;
  final List<BotCommandItem> commands;
  final int permissions;
  final String username;

  factory BotInfo.fromRawJson(String str) => BotInfo.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory BotInfo.fromJson(Map<String, dynamic> json) => BotInfo(
        botId: json["bot_id"].toString(),
        ownerId: json["owner_id"].toString(),
        botName: json["bot_name"],
        botDescription: json["bot_description"],
        botAbout: json["bot_about"],
        botAvatar: json["bot_avatar"],
        webhook: json["webhook"],
        enableInlineMode: json["enable_inline_mode"],
        enableInlineGeo: json["enable_inline_geo"],
        joinGroupAllowed: json["join_group_allowed"],
        enableGroupPrivacyMode: json["enable_group_privacy_mode"],
        confirmedUpdateId: json["confirmed_update_id"],
        commands: _parseCommands(
            json["commands"], json["bot_id"], json['bot_avatar']),
        permissions: json["bot_permissions"] ?? 0,
        username: json["username"],
      );

  Map<String, dynamic> toJson() => {
        "bot_id": botId,
        "owner_id": ownerId,
        "bot_name": botName,
        "bot_description": botDescription,
        "bot_about": botAbout,
        "bot_avatar": botAvatar,
        "webhook": webhook,
        "enable_inline_mode": enableInlineMode,
        "enable_inline_geo": enableInlineGeo,
        "join_group_allowed": joinGroupAllowed,
        "enable_group_privacy_mode": enableGroupPrivacyMode,
        "confirmed_update_id": confirmedUpdateId,
        "commands": commands ?? commands.map((v) => v.toJson()),
        "bot_permissions": permissions,
        "username": username,
      };

  static List<BotCommandItem> _parseCommands(
      List<dynamic> data, String botId, String botAvatar) {
    if (data == null) return [];
    return List<Map<String, dynamic>>.from(data)
        .map<BotCommandItem>(
          (v) => BotCommandItem.fromJson(
            v..addAll({'bot_id': botId, 'bot_avatar': botAvatar}),
          ),
        )
        .toList();
  }
}

class BotCommandParameter {
  BotCommandParameter({
    this.icon,
    this.k,
    this.v,
  });

  final String icon;
  final String k;
  final String v;

  factory BotCommandParameter.fromRawJson(String str) =>
      BotCommandParameter.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory BotCommandParameter.fromJson(Map<String, dynamic> json) =>
      BotCommandParameter(
        icon: json["icon"],
        k: json["k"],
        v: json["v"],
      );

  Map<String, dynamic> toJson() => {
        "icon": icon,
        "k": k,
        "v": v,
      };
}

class BotCommandItem {
  String appId;
  String botId;
  String botAvatar;
  String command;
  String description;
  int visibleLevel;
  String url;
  bool hide;
  bool clickable;
  bool isValid;

  List<List<BotCommandParameter>> selectParameters;
  List<List<BotCommandParameter>> formParameters;

  bool get isAdminVisible => visibleLevel == 2;

  BotCommandItem({
    this.appId,
    this.botId,
    this.botAvatar,
    this.command,
    this.description,
    this.visibleLevel,
    this.url,
    this.hide,
    this.clickable,
    this.isValid = true,
  });

  BotCommandItem.fromJson(Map<String, dynamic> json) {
    command = json['command'];
    description = json['description'];
    appId = json['app_id'];
    botId = json['bot_id'];
    botAvatar = json['bot_avatar'];
    url = json['url'];
    visibleLevel = json['visible_level'];
    selectParameters = json['select_parameters'] == null
        ? null
        : List<List<BotCommandParameter>>.from(json['select_parameters'].map(
            (e) => List<BotCommandParameter>.from(
                e.map((e) => BotCommandParameter.fromJson(e)))));
    formParameters = json['form_parameters'] == null
        ? null
        : List<List<BotCommandParameter>>.from(json['form_parameters'].map(
            (e) => List<BotCommandParameter>.from(
                e.map((e) => BotCommandParameter.fromJson(e)))));
    hide = json['hide'] ?? false;
    clickable = json['clickable'] ?? false;
    isValid = true;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['command'] = command;
    data['description'] = description;
    data['visible_level'] = visibleLevel;
    data['app_id'] = appId;
    data['bot_id'] = botId;
    data['bot_avatar'] = botAvatar;
    data['url'] = url;
    data['select_parameters'] = selectParameters
        ?.map((e) => e.map((e) => e.toJson()).toList(growable: false))
        ?.toList(growable: false);
    data['form_parameters'] = formParameters
        ?.map((e) => e.map((e) => e.toJson()).toList(growable: false))
        ?.toList(growable: false);
    data['hide'] = hide;
    data['clickable'] = clickable;
    return data;
  }

  @override
  // ignore: avoid_equals_and_hash_code_on_mutable_classes
  bool operator ==(Object other) {
    return other is BotCommandItem &&
        botId == other.botId &&
        command == other.command &&
        visibleLevel == other.visibleLevel;
  }

  @override
  // ignore: avoid_equals_and_hash_code_on_mutable_classes
  int get hashCode => super.hashCode;
}
