import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/api/entity/file_send_history_bean_entity.dart';
import 'package:im/db/db.dart';
import 'package:im/pages/search/model/search_model.dart';
import 'package:im/pages/search/search_util.dart';
import 'package:im/utils/file_util.dart';

import '../../../../global.dart';

class FileSelectController extends GetxController {
  static const String showTitleUpdated = "showTitleUpdated";
  static const String historyListUpdated = "historyListUpdated";

  bool isShowPopView = false;

  /// 文件收发历史列表，fileList用于展示，fileHistoryList是原始数据
  List<FileSendHistoryBeanEntity> fileList = [];
  List<FileSendHistoryBeanEntity> fileHistoryList = [];

  /// 输入框监听
  SearchInputModel searchInputModel;
  ScrollController scrollController;
  final searchInputController = TextEditingController();

  @override
  void onInit() {
    super.onInit();

    scrollController = ScrollController()..addListener(hideSoftInput);

    searchInputModel = SearchInputModel()
      ..searchStream.where(SearchUtil.filterInput).listen(search);

    // 根据用户存储历史数据
    fileHistoryList = Db.fileSendHistoryBox
            .get(Global.user.id)
            ?.map((e) => e as FileSendHistoryBeanEntity)
            ?.toList() ??
        [];
    // 初始化选中状态
    fileHistoryList.forEach((element) => element.isSelected = false);
    fileList = fileHistoryList;
  }

  @override
  void onClose() {
    scrollController?.dispose();
    super.onClose();
  }

  /// - 隐藏键盘
  void hideSoftInput() {
    if (searchInputModel.inputFocusNode.hasFocus) {
      searchInputModel.inputFocusNode.unfocus();
    }
  }

  /// - 搜索
  Future<void> search(String searchKey) async {
    fileList = searchKey.isNotEmpty
        ? fileHistoryList
            .where((element) => element.name.contains(searchKey))
            .toList()
        : fileHistoryList;
    update([historyListUpdated]);
  }

  /// - 切换文件选择popView
  void switchShowPopView() {
    isShowPopView = !isShowPopView;
    update([showTitleUpdated]);
  }

  /// - 获取文件选中的个数和大小
  String selectFileMsg() {
    final selectFiles = fileHistoryList.where((element) => element.isSelected);
    int totalSize = 0;
    selectFiles.forEach((element) {
      totalSize += element.size;
    });
    final sizeStr = FileUtil.getFileSize(totalSize);
    return '${selectFiles.length}个文件 - $sizeStr'.tr;
  }

  /// - 选中的数量
  int selectCount() {
    return fileHistoryList.where((element) => element.isSelected).length;
  }

  /// - 单个文件最大 200M，单次最多选择 9 个
  bool canSend() {
    return selectCount() > 0;
  }

  /// - 改变选中状态
  void changeCheck(FileSendHistoryBeanEntity fileItem) {
    fileItem.isSelected = !fileItem.isSelected;
    update([historyListUpdated]);
  }

  /// - 获取选中的文件
  List<FileSendHistoryBeanEntity> getSelectFiles() =>
      fileHistoryList.where((element) => element.isSelected).toList();
}
