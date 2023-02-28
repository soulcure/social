import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:im/pages/home/model/chat_target_model.dart';

class GuildTemplate {
  int templateId;
  String guildTeam;
  String serverIcon;
  String teamName;
  String background;
  Color themeColor;
  GuildTemplateInfo guildTemplateInfo;

  GuildTemplate.fromJson(Map<String, dynamic> json) {
    templateId = json['template_id'];
    guildTeam = json['guild_team'];
    serverIcon = json['server_icon'];
    teamName = json['team_name'];
    background = json['background'];
    themeColor = Color(json['theme_color']);
    if (json['template_config'] != null) {
      guildTemplateInfo =
          GuildTemplateInfo.fromJson(jsonDecode(json['template_config']));
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['template_id'] = templateId;
    data['guild_temp'] = guildTeam;
    data['server_icon'] = serverIcon;
    data['team_name'] = teamName;
    data['background'] = background;
    data['theme_color'] = themeColor.value;
    if (guildTemplateInfo != null) {
      data['template_config'] = jsonEncode(guildTemplateInfo.toJson());
    }
    return data;
  }
}

class GuildTemplateInfo {
  List<GuildTemplateRole> roles;
  List<GuildTemplateChannel> channels;

  GuildTemplateInfo({
    this.roles,
    this.channels,
  });

  GuildTemplateInfo.fromJson(Map<String, dynamic> json) {
    if (json['roles'] != null) {
      roles = <GuildTemplateRole>[];
      json['roles'].forEach((v) {
        roles.add(GuildTemplateRole.fromJson(v));
      });
    }
    if (json['channels'] != null) {
      channels = <GuildTemplateChannel>[];
      json['channels'].forEach((v) {
        channels.add(GuildTemplateChannel.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (roles != null) {
      data['roles'] = roles.map((v) => v.toJson()).toList();
    }
    if (channels != null) {
      data['channels'] = channels.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class GuildTemplateRole {
  String name;
  Color color;
  String desc;

  GuildTemplateRole({
    this.name,
    this.color,
  });

  GuildTemplateRole.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    color = Color(json['color']);
    desc = json['desc'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['name'] = name;
    data['color'] = color.value;
    data['desc'] = desc;
    return data;
  }
}

class GuildTemplateChannel {
  String name;
  ChatChannelType type;
  String topic;
  bool private;

  GuildTemplateChannel({
    this.name,
    this.type,
    this.topic,
  });

  GuildTemplateChannel.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    type = chatChannelTypeFromJson(json['type']);
    topic = json['topic'];
    private = json['is_private'] == 1;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['name'] = name;
    data['type'] = type.index;
    data['topic'] = topic;
    return data;
  }
}
