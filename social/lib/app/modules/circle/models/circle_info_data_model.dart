class CircleInfoDataModel {
  String guildId;
  String channelId;
  String ownerId;
  String memberCount;
  String postsCount;
  String description;
  String circleName;
  String circleBanner;
  String circleIcon;
  String sortType;

  CircleInfoDataModel({
    this.guildId = '',
    this.channelId = '',
    this.ownerId = '',
    this.memberCount = '',
    this.postsCount = '',
    this.description = '',
    this.circleName = '',
    this.circleBanner = '',
    this.circleIcon = '',
    this.sortType = '',
  });

  factory CircleInfoDataModel.fromJson(Map<String, dynamic> json) =>
      CircleInfoDataModel(
        guildId: (json['guild_id'] ?? '').toString(),
        channelId: (json['channel_id'] ?? '').toString(),
        ownerId: (json['owner_id'] ?? '').toString(),
        memberCount: (json['members'] ?? '').toString(),
        postsCount: (json['posts_total'] ?? '').toString(),
        description: (json['description'] ?? '').toString(),
        circleName: (json['name'] ?? '').toString(),
        circleBanner: (json['banner'] ?? '').toString(),
        circleIcon: (json['icon'] ?? '').toString(),
        sortType: (json['sort_type'] ?? '').toString(),
      );

  ///ws: 同步圈子的设置信息
  void updateCircleInfoDataModel(Map data) {
    if (data.containsKey('name')) circleName = data['name'];
    if (data.containsKey('description')) description = data['description'];
    if (data.containsKey('icon')) circleIcon = data['icon'];
    if (data.containsKey('banner')) circleBanner = data['banner'];
    if (data.containsKey('sort_type')) sortType = data['sort_type'];
  }
}
