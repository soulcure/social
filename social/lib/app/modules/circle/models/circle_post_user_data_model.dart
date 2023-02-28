class CirclePostUserDataModel {
  String userId;
  String avatar;
  String userName;
  String nickName;

  CirclePostUserDataModel(
      {this.userId = '',
      this.avatar = '',
      this.userName = '',
      this.nickName = ''});

  factory CirclePostUserDataModel.fromJson(Map<String, dynamic> json) =>
      CirclePostUserDataModel(
        userId: (json['user_id'] ?? '').toString(),
        avatar: (json['avatar'] ?? '').toString(),
        userName: (json['username'] ?? '').toString(),
        nickName: (json['nickname'] ?? '').toString(),
      );

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'avatar': avatar,
        'username': userName,
        'nickname': nickName,
      };
}
