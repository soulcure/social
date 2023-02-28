class CreateTemplate {
  int id;
  String teamName;
  String guildTeam;
  String channelName;
  int parentId;
  int channelType;
  String channelDesc;
  String serverIcon;
  String channelIcon;

  CreateTemplate(
      {this.id,
      this.teamName,
      this.guildTeam,
      this.channelName,
      this.parentId,
      this.channelType,
      this.channelDesc,
      this.serverIcon,
      this.channelIcon});

  CreateTemplate.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    teamName = json['team_name'];
    guildTeam = json['guild_team'];
    channelName = json['channel_name'];
    parentId = json['parent_id'];
    channelType = json['channel_type'];
    channelDesc = json['channel_desc'];
    serverIcon = json['server_icon'];
    channelIcon = json['channel_icon'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['team_name'] = teamName;
    data['guild_team'] = guildTeam;
    data['channel_name'] = channelName;
    data['parent_id'] = parentId;
    data['channel_type'] = channelType;
    data['channel_desc'] = channelDesc;
    data['server_icon'] = serverIcon;
    data['channel_icon'] = channelIcon;
    return data;
  }
}
