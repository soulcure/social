import 'dart:collection';

import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:im/app/modules/document_online/controllers/online_document_controller.dart';
import 'package:im/app/modules/document_online/document_enum_defined.dart';
import 'package:im/app/modules/document_online/entity/doc_item.dart';
import 'package:im/app/modules/document_online/entity/doc_list_item.dart';
import 'package:im/common/extension/string_extension.dart';
import 'package:im/pages/search/model/search_model.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

import '../../document_api.dart';

typedef SearchCallBack = void Function(String value);

class SearchParams {
  String guildId;
  int initialIndex;

  SearchParams(this.guildId, this.initialIndex);
}

class DocumentSearchController extends GetxController {
  final List<DocItem> _docList = [];

  String guildId;
  int initialIndex;
  bool isSearch = false;
  String keyword = '';

  int curPage = 1; //默认第1页开始

  UnmodifiableListView<DocItem> get docList => UnmodifiableListView(_docList);

  final RefreshController refreshController = RefreshController();
  final TextEditingController textEditingController = TextEditingController();
  final SearchInputModel searchInputModel = SearchInputModel();
  final ScrollController scrollController = ScrollController();
  final FocusNode focusNode = FocusNode();

  SearchCallBack curCallBack;

  static DocumentSearchController to() {
    DocumentSearchController c;
    if (Get.isRegistered<DocumentSearchController>()) {
      c = Get.find<DocumentSearchController>();
    } else {
      c = Get.put(DocumentSearchController());
    }
    return c;
  }

  @override
  void onInit() {
    super.onInit();
    final SearchParams params = Get.arguments;
    guildId = params.guildId;
    initialIndex = params.initialIndex;
    listen();
  }

  @override
  void onClose() {
    searchInputModel.dispose();
    textEditingController.dispose();
    scrollController.dispose();
  }

  void onLoading() {
    if (keyword.hasValue) {
      _reqSearchData(keyword, isLoading: true);
    }
  }

  void listen() {
    searchInputModel.searchStream.listen((input) {
      keyword = input;
      if (curCallBack != null) {
        curCallBack(input);
      }
    });
    scrollController.addListener(focusNode.unfocus);
  }

  Future<void> _reqSearchData(String keyword, {bool isLoading = false}) async {
    final entryType = OnlineDocumentController.to().entryType;
    final String listType = EntryTypeExtension.name(entryType);
    final DocListItem res = await DocumentApi.docSearch(
      guildId,
      listType,
      keyword,
      curPage,
    );
    if (res != null) {
      final List<DocItem> list = res.docList;
      if (!isLoading) {
        _docList.clear();
      }
      if (list != null && list.isNotEmpty) {
        _docList.addAll(list);
      }

      if (list.length < res.size) {
        refreshController.loadNoData();
      } else {
        refreshController.loadComplete();
        curPage++;
      }
      update();
      return;
    }

    refreshController.loadFailed();
    update();
  }
}
