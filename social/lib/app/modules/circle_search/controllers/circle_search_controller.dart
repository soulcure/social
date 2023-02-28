import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:im/api/api.dart';
import 'package:im/api/circle_api.dart';
import 'package:im/app/modules/circle/models/models.dart';
import 'package:im/pages/search/model/search_model.dart';
import 'package:im/pages/search/search_util.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

///圈子搜索 Controller
class CircleSearchController extends GetxController {
  SearchInputModel searchInputModel;
  RefreshController refreshController;
  ScrollController scrollController;
  String guildId;
  String channelId;

  ///搜索结果集合
  List<CirclePostDataModel> resultList;

  final int size = 30;
  String listId = '0';
  Map<String, dynamic> topicInfo;
  int pageKey = 0;

  String searchKeyValue;

  ///请求状态
  SearchStatus searchStatus = SearchStatus.normal;

  ///是否有下一页
  bool hasNextPage = true;

  bool searched = false;

  CircleSearchController(this.guildId, this.channelId) {
    resultList = [];
    searchInputModel = SearchInputModel();
    refreshController = RefreshController();
    scrollController = ScrollController();
    searchInputModel.searchStream.where(SearchUtil.filterInput).listen(search);
  }

  ///搜索圈子动态
  Future<void> search(String searchKey) async {
    debugPrint('getChat search: $searchKey');
    resetData();
    update();
    if (searchKey == null || searchKey.trim().isEmpty) {
      return;
    }
    searchKeyValue = searchKey.trim();
    await searchMore();
    if (!searched) searched = true;
  }

  ///加载下一页
  Future<int> searchMore() async {
    searchStatus = SearchStatus.searching;
    update();
    bool isCancel = false;
    topicInfo = await CircleApi.searchCircle(
            guildId, channelId, '$size', listId, searchKeyValue,
            cancelToken: AutoCancelToken.getOnly(AutoCancelType.search))
        .catchError((e) {
      debugPrint('getChat searchCircle e: $e');

      ///主动取消请求，不是异常
      if (e is DioError && e.type == DioErrorType.cancel) {
        isCancel = true;
      } else {
        searchStatus = SearchStatus.fail;
      }
      return <String, dynamic>{};
    });
    if (isCancel) return 0;

    List<CirclePostDataModel> searchList;
    if (topicInfo != null && searchStatus != SearchStatus.fail) {
      searchStatus = SearchStatus.success;
      final List records = topicInfo['records'] ?? [];
      searchList = records.map((e) => CirclePostDataModel.fromJson(e)).toList();
      resultList.addAll(searchList);
      if (searchList.isNotEmpty)
        listId = searchList.last.postInfoDataModel.postId;
    }

    final curLoadLength = searchList != null ? searchList.length : 0;
    hasNextPage = curLoadLength >= size;
    debugPrint(
        'getChat searchMore length: ${resultList.length} - listId:$listId - hasNextPage:$hasNextPage ');
    update();
    return curLoadLength;
  }

  ///重新搜索
  void reSearch() {
    if (searchKeyValue != null && searchKeyValue.isNotEmpty)
      search(searchKeyValue);
  }

  ///重置参数
  void resetData() {
    AutoCancelToken.cancel(AutoCancelType.search);
    if (resultList.isNotEmpty) resultList.clear();
    searchStatus = SearchStatus.normal;
    listId = '0';
    refreshController.loadComplete();
    pageKey++;
    hasNextPage = true;
  }

  @override
  void onClose() {
    super.onClose();
    scrollController?.dispose();
  }
}
