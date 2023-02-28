class CirclePostCommentDetailDataModel {
  String userId;
  String avatar;

  CirclePostCommentDetailDataModel({this.userId = '', this.avatar = ''});

  factory CirclePostCommentDetailDataModel.fromJson(
          Map<String, dynamic> json) =>
      CirclePostCommentDetailDataModel(
          userId: (json['user_id'] ?? '').toString(),
          avatar: (json['avatar'] ?? '').toString());
}
