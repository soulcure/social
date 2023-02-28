/*
 * @FilePath       : /social/lib/widgets/refresh/list_model.dart
 * 
 * @Info           : 
 * 
 * @Author         : Whiskee Chan
 * @Date           : 2022-02-21 15:17:01
 * @Version        : 1.0.0
 * 
 * Copyright 2022 iDreamSky FanBook, All Rights Reserved.
 * 
 * @LastEditors    : Whiskee Chan
 * @LastEditTime   : 2022-04-20 14:59:53
 * 
 */
import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';

/// 被 Refresher 组件使用的 model
class ListModel<T> extends ChangeNotifier {
  @protected
  List<T> internalList = [];

  int pageNum = 1;
  int pageSize;
  int _clearCount = 0;

  UnmodifiableListView<T> get list => UnmodifiableListView(internalList);

  int get length => internalList.length;

  /// - 第一次加载数据
  set list(List<T> firstData) {
    internalList = firstData ?? [];
    // 由于第一次加载数据后pageNum并不会设置为第二页，所以需要特殊处理第一页时候页数
    // 此修改不随后端分页接口变化而变化，也不适合后端使用pageNum模式的分页接口的逻辑
    if (pageNum == 1 && internalList.isNotEmpty) {
      pageNum++;
    }
  }

  // Future future;

//  Future get future1 => future;

  /// 获取更多数据
  /// 如果发生错误，返回 null
  /// 否则返回新增的数据列表
  Future<List<T>> Function() fetchData;

  ListModel({this.pageSize = 10, @required this.fetchData});

  Future<int> getNextPage() async {
    final res = await fetchData();
    if (res == null) return 0;

    internalList.addAll(res);
    notifyListeners();

    pageNum++;
    return res.length;
  }

  void clear() {
    _clearCount++;
    pageNum = 1;
    internalList.clear();
  }

  void clearWithNotify() {
    clear();
    notifyListeners();
  }

  String getListKey() {
    return "$_clearCount-${internalList.length}";
  }
}
