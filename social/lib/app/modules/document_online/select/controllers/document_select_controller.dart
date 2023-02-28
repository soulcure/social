import 'dart:collection';

import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:im/app/modules/document_online/controllers/online_document_controller.dart';
import 'package:im/app/modules/document_online/document_enum_defined.dart';
import 'package:im/app/modules/document_online/entity/doc_info_item.dart';
import 'package:im/app/modules/document_online/entity/doc_item.dart';
import 'package:im/app/modules/document_online/entity/doc_list_item.dart';
import 'package:im/app/modules/tc_doc_page/controllers/tc_doc_page_controller.dart';
import 'package:im/common/extension/string_extension.dart';
import 'package:im/pages/search/model/search_model.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:tuple/tuple.dart';

import '../../document_api.dart';

class DocumentSelectController extends GetxController {
  // my:我的文档,view:最近查看,collect:我的收藏
  final EntryType entryType = EntryType.my;
  String guildId;

  int curPage = 1; //默认第1页开始
  int searchPage = 1; //默认第1页开始

  LoadingStatus loadingNormalStatus;
  LoadingStatus loadingSearchStatus;

  final RefreshController refreshController = RefreshController();

  final List<DocItem> _docNormalList = [];
  final List<DocItem> _docSearchList = [];

  bool isSearch = false;
  String keyword = '';

  final TextEditingController textEditingController = TextEditingController();
  final SearchInputModel searchInputModel = SearchInputModel();
  final ScrollController scrollController = ScrollController();
  final FocusNode focusNode = FocusNode();

  UnmodifiableListView<DocItem> get docList {
    if (isSearch) {
      return UnmodifiableListView(_docSearchList);
    }
    return UnmodifiableListView(_docNormalList);
  }

  static DocumentSelectController to() {
    DocumentSelectController c;
    if (Get.isRegistered<DocumentSelectController>()) {
      c = Get.find<DocumentSelectController>();
    } else {
      c = Get.put(DocumentSelectController());
    }
    return c;
  }

  @override
  void onInit() {
    super.onInit();
    guildId = Get.arguments;
    listen();
    onData();
  }

  @override
  void onClose() {
    searchInputModel.dispose();
    textEditingController.dispose();
    scrollController.dispose();
  }

  void onData() {
    //curPage 默认值为1，如果大于1，代表已经有内存缓存了
    if (curPage > 1) return;

    _reqDocList(guildId);
  }

  void onLoading() {
    if (isSearch) {
      ///搜索模式
      if (keyword.hasValue) {
        _reqSearchData(keyword, isLoading: true);
      }
    } else {
      _reqDocList(guildId);
    }
  }

  bool isEmpty() {
    return docList.isEmpty;
  }

  void reLoading() {
    update();
    _reqDocList(guildId);
  }

  void listen() {
    searchInputModel.searchStream.listen((input) {
      if (input.hasValue) {
        keyword = input;
        curPage = 1;
        isSearch = true;
        refreshController.loadComplete();
        _reqSearchData(input);
      } else {
        isSearch = false;
        _docSearchList.clear();
        if (loadingNormalStatus == LoadingStatus.noData) {
          refreshController.loadNoData();
        } else {
          refreshController.loadComplete();
        }

        update();
      }
    });
    scrollController.addListener(focusNode.unfocus);
  }

  LoadingStatus loadingStatus() {
    if (isSearch) {
      return loadingSearchStatus;
    }
    return loadingNormalStatus;
  }

  Future<void> _reqDocList(String guildId) async {
    loadingNormalStatus = LoadingStatus.loading;
    final String listType = EntryTypeExtension.name(entryType);
    final DocListItem res =
        await DocumentApi.docList(guildId, listType, curPage);

    if (res != null) {
      _parserDocList(res);
      return;
    }

    refreshController.loadFailed();
    loadingNormalStatus = LoadingStatus.error;
    update();
  }

  void _parserDocList(DocListItem res) {
    final List<DocItem> list = res.docList;
    if (list == null || list.isEmpty) {
      if (isEmpty()) {
        loadingNormalStatus = LoadingStatus.noData;
      } else {
        loadingNormalStatus = LoadingStatus.complete;
      }
      refreshController.loadNoData();
      update();
      return;
    }
    _docNormalList.addAll(list);

    if (list.length < res.size) {
      refreshController.loadNoData();
    } else {
      refreshController.loadComplete();
      curPage++;
    }
    loadingNormalStatus = LoadingStatus.complete;

    checkEmpty();
    update();
  }

  Future<void> _reqSearchData(String keyword, {bool isLoading = false}) async {
    loadingSearchStatus = LoadingStatus.loading;
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
        _docSearchList.clear();
      }
      if (list != null && list.isNotEmpty) {
        _docSearchList.addAll(list);
      }

      if (list.length < res.size) {
        refreshController.loadNoData();
      } else {
        refreshController.loadComplete();
        curPage++;
      }
      loadingSearchStatus = LoadingStatus.complete;

      checkEmpty();
      update();
      return;
    }

    refreshController.loadFailed();
    update();
  }

  void checkEmpty() {
    if (isSearch) {
      if (isEmpty()) {
        loadingSearchStatus = LoadingStatus.noData;
      } else {
        loadingSearchStatus = LoadingStatus.complete;
      }
    } else {
      if (isEmpty()) {
        loadingNormalStatus = LoadingStatus.noData;
      } else {
        loadingNormalStatus = LoadingStatus.complete;
      }
    }
  }

  void createItem(DocItem item) {
    isSearch = false;
    _docNormalList.insert(0, item);
    checkEmpty();
    update();
  }

  ///dest目标，src源
  void updateData(DocItem dest, DocItem src) {
    if (dest == null || src == null) return;

    if (src.collectedAt != null) {
      dest.collectedAt = src.collectedAt;
    }
    if (src.updatedAt != null) {
      dest.updatedAt = src.updatedAt;
    }
    if (src.viewedAt != null) {
      dest.viewedAt = src.viewedAt;
    }
    if (src.title != null) {
      dest.title = src.title;
    }
    if (src.canCopy != null) {
      dest.canCopy = src.canCopy;
    }
    if (src.canReaderComment != null) {
      dest.canReaderComment = src.canReaderComment;
    }
  }

  void updateItem(DocItem item) {
    final String fileId = item.fileId;
    final int indexList = _docNormalList.indexWhere((e) => e.fileId == fileId);
    if (indexList >= 0) {
      updateData(_docNormalList[indexList], item);
      update();
      return;
    }
  }

  void removeItem(DocItem item) {
    return removeItemById(item.fileId);
  }

  void removeItemById(String fileId) {
    final int indexList = _docNormalList.indexWhere((e) => e.fileId == fileId);
    if (indexList >= 0) {
      _docNormalList.removeAt(indexList);
      update();
      return;
    }
  }

  void handleResult(
    List<Tuple2<TcDocPageReturnType, DocInfoItem>> list,
  ) {
    if (list == null || list.isEmpty) return;

    list.forEach((res) {
      final TcDocPageReturnType type = res.item1;
      final DocItem item = DocItem.fromInfo(res.item2);

      switch (type) {
        case TcDocPageReturnType.add:
          createItem(item);
          break;
        case TcDocPageReturnType.delete:
          final String fileId = item.fileId;
          removeItemById(fileId);
          break;
        case TcDocPageReturnType.update:
          updateItem(item);
          break;
        default:
          break;
      }
    });
  }
}
