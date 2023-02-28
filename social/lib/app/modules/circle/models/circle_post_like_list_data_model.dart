import 'package:im/api/circle_api.dart';

import 'circle_post_like_detail_data_model.dart';

class CirclePostLikeListDataModel {
  String listId;
  String hasNext;
  String size;
  String postId;
  List records = [];
  bool initFinish = false;
  List<CirclePostLikeDetailDataModel> recordsDataModelList = [];

  CirclePostLikeListDataModel({
    this.listId = '0',
    this.postId = '',
    this.hasNext = '',
    this.size = '60',
    this.recordsDataModelList = const [],
  });

  Future initFromNet({bool isDesc = true}) async {
    final result = await CircleApi.circleReactionList(postId, listId, size,
        isDesc: isDesc);
    size = result['size'].toString() ?? '60';
    listId = result['list_id'].toString() ?? '-1';
    hasNext = result['next'].toString() ?? '0';
    records = result['records'] ?? [];
    recordsDataModelList.clear();
    for (final item in records) {
      recordsDataModelList.add(CirclePostLikeDetailDataModel.fromJson(item));
    }
    initFinish = true;
  }

  /// * 点赞列表下一页
  Future needMorePost({bool isDesc = true}) async {
    if ("1" == hasNext) {
      final result = await CircleApi.circleReactionList(postId, listId, size,
          isDesc: isDesc);
      size = result['size'].toString() ?? '60';
      listId = result['list_id'].toString() ?? '-1';
      hasNext = result['next'].toString() ?? '0';
      final records = result['records'] ?? [];
      for (final item in records) {
        recordsDataModelList.add(CirclePostLikeDetailDataModel.fromJson(item));
      }
    } else {
      return;
    }
  }

  /// * 获取点赞列表下一页
  static Future<List<CirclePostLikeDetailDataModel>> getNextList(
      {String postId, String listId, String size, bool isDesc = false}) async {
    final result = await CircleApi.circleReactionList(postId, listId, size,
        isDesc: isDesc);
    final records = (result['records'] ?? []) as List;
    return records
        .map((e) => CirclePostLikeDetailDataModel.fromJson(e))
        .toList();
  }

  int get postLikeListCount => recordsDataModelList.length;

  CirclePostLikeDetailDataModel postListDetailDataModelAtIndex(int index) {
    return recordsDataModelList[index];
  }
}
