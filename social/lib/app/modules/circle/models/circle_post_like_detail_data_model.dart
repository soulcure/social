class CirclePostLikeDetailDataModel {
  String userId;
  String avatar;
  String userName;
  String nickName;
  String reactionId;

  CirclePostLikeDetailDataModel(
      {this.userId = '',
      this.avatar = '',
      this.userName = '',
      this.nickName = '',
      this.reactionId = ''});

  factory CirclePostLikeDetailDataModel.fromJson(Map<String, dynamic> json) =>
      CirclePostLikeDetailDataModel(
          userId: (json['user_id'] ?? '').toString(),
          avatar: (json['avatar'] ?? '').toString(),
          userName: (json['username'] ?? '').toString(),
          nickName: (json['nickname'] ?? '').toString(),
          reactionId: (json['reaction_id'] ?? '').toString());
}
