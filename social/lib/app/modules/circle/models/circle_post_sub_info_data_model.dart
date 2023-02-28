import 'package:im/global.dart';

import 'circle_post_like_detail_data_model.dart';

class CirclePostSubInfoDataModel {
  Map<String, dynamic> data;
  String commentTotal;
  List commentList;
  String likeTotal;

  /// 喜欢用户ID列表
  List<CirclePostLikeDetailDataModel> likeList;
  String iLiked;
  String likeId;

  ///是否关注
  bool isFollow;

  ///从消息列表打开动态详情时，增加的点赞数，用于动画显示
  int increaseLike;

  int get totalLikeNum {
    try {
      return int.parse(likeTotal);
    } catch (e) {
      return 0;
    }
  }

  CirclePostSubInfoDataModel({
    this.data = const {},
    this.commentTotal = '',
    this.commentList = const [],
    this.likeTotal = '',
    this.likeList = const [],
    this.iLiked = '',
    this.likeId = '',
    this.isFollow = false,
    this.increaseLike,
  });

  factory CirclePostSubInfoDataModel.fromJson(Map<String, dynamic> json) =>
      CirclePostSubInfoDataModel(
          data: json,
          commentTotal: (json['comment_total'] ?? '').toString(),
          commentList: (json['comment_detail'] ?? []) as List,
          likeTotal: (json['like_total'] ?? '').toString(),
          likeList: ((json['like_detail'] ?? []) as List)
              .map((e) => CirclePostLikeDetailDataModel.fromJson(e))
              .toList(),
          iLiked: (json['liked'] ?? '').toString(),
          likeId: (json['like_id'] ?? '').toString(),
          isFollow: (json['is_follow'] ?? false) as bool);

  Map<String, dynamic> toJson() => {
        'comment_total': commentTotal,
        'comment_detail': commentList,
        'like_total': likeTotal,
        //圈子分享消息保存时，需要去掉likeList，否则会报错
        // 'like_detail': likeList,
        'liked': iLiked,
        'like_id': likeId,
      };

  /// todo 还是要对外暴露 likeDetailDataModelList, 这个接口直接用下面的 get likeDetailDataModelList 替代
  int likeListCount() {
    return likeList.length;
  }

  /// todo 还是要对外暴露 likeDetailDataModelList, 这个接口直接用下面的 get likeDetailDataModelList 替代
  CirclePostLikeDetailDataModel likeDetailDataModelAtIndex(int index) {
    return likeList[index];
  }

  // 将当前用户加入点赞列表
  void _iLikeIt(String likeId) {
    if (totalLikeNum > likeList.length + 1) return;
    final me = CirclePostLikeDetailDataModel(
      userId: Global.user.id,
      reactionId: likeId,
    );

    final i = likeList.indexWhere(
      (m) => m.userId == me.userId,
    );
    if (i == -1) {
      // 当前用户未点赞
      likeList.add(me);
    }
  }

  // 将当前用户移除点赞列表
  void _iCancelLike() {
    final i = likeList.indexWhere(
      (m) => m.userId == Global.user.id,
    );
    if (i != -1) {
      likeList.removeAt(i);
    }
  }

  /// * 修改自己的点赞状态
  void modifyLikeState(String iLiked, String likeId) {
    this.iLiked = iLiked;
    this.likeId = likeId;
    if (iLiked == '1') {
      likeTotal = '${totalLikeNum + 1}';
      _iLikeIt(likeId);
    } else {
      likeTotal = '${totalLikeNum - 1}';
      _iCancelLike();
    }
    data['liked'] = iLiked;
    data['like_id'] = likeId;
    data['like_total'] = likeTotal;
  }

  void modifyILiked(String iLiked) {
    this.iLiked = iLiked;
    data['liked'] = iLiked;
  }
}
