class CloseAudienceRoomModel {
  String? nickName;
  String? avatarUrl;
  int? audienceCount;
  String? roomLogo;
  String? userId;
  String? serverId;

  CloseAudienceRoomModel({
    this.nickName,
    this.avatarUrl,
    this.audienceCount,
    this.roomLogo,
    required this.userId,
    required this.serverId,
  });
}
