import 'package:get/get.dart';
import 'package:im/app/modules/document_online/controllers/online_document_controller.dart';
import 'package:im/app/modules/document_online/document_api.dart';
import 'package:im/app/modules/document_online/document_enum_defined.dart';
import 'package:im/app/modules/document_online/entity/doc_info_item.dart';
import 'package:im/app/modules/document_online/entity/doc_item.dart';
import 'package:im/app/modules/document_online/entity/doc_list_item.dart';
import 'package:im/app/modules/document_online/search/controllers/document_search_controller.dart';
import 'package:im/app/modules/tc_doc_page/controllers/tc_doc_page_controller.dart';
import 'package:im/common/extension/string_extension.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:tuple/tuple.dart';

class DocSearchListController extends GetxController {
  // my:我的文档,view:最近查看,collect:我的收藏
  final EntryType entryType;
  String guildId;

  int curPage = 1; //默认第1页开始

  final List<DocItem> docList = [];

  LoadingStatus loadingStatus;

  final RefreshController refreshController = RefreshController();

  DocSearchListController(this.entryType);

  static DocSearchListController to(EntryType entryType) {
    DocSearchListController c;
    final String tag = EntryTypeExtension.name(entryType);
    if (Get.isRegistered<DocSearchListController>(tag: tag)) {
      c = Get.find<DocSearchListController>(tag: tag);
    } else {
      c = Get.put(DocSearchListController(entryType), tag: tag);
    }
    return c;
  }

  @override
  void onInit() {
    super.onInit();
    final SearchParams params = Get.arguments;
    guildId = params.guildId;
    onData();
  }

  void onData() {
    //curPage 默认值为1，如果大于1，代表已经有内存缓存了
    if (curPage > 1) return;

    DocumentSearchController.to().curCallBack = _reqSearchData;

    final String keyword = DocumentSearchController.to().keyword;
    if (keyword.hasValue) {
      _reqSearchData(keyword);
    }
  }

  Future<void> _reqSearchData(String keyword) async {
    if (keyword.noValue) {
      docList.clear();
      update();
      return;
    }

    curPage = 1;
    final String listType = EntryTypeExtension.name(entryType);
    final DocListItem res = await DocumentApi.docSearch(
      guildId,
      listType,
      keyword,
      curPage,
    );
    if (res != null) {
      final List<DocItem> list = res.docList;
      if (list == null || list.isEmpty) {
        loadingStatus = LoadingStatus.noData;
        refreshController.loadNoData();
        docList.clear();
        update();
        return;
      }

      docList.clear();
      docList.addAll(list);

      if (list.length < res.size) {
        refreshController.loadNoData();
      } else {
        refreshController.loadComplete();
      }

      loadingStatus = LoadingStatus.complete;
      update();
      return;
    }

    refreshController.loadFailed();
    update();
  }

  void reLoading() {
    final String keyword = DocumentSearchController.to().keyword;
    if (keyword.hasValue) {
      update();
      _reqDocList(guildId);
    }
  }

  void onLoading() {
    final String keyword = DocumentSearchController.to().keyword;
    if (keyword.hasValue) {
      _reqDocList(guildId);
    }
  }

  bool isEmpty() {
    return docList.isEmpty;
  }

  Future<void> _reqDocList(String guildId) async {
    loadingStatus = LoadingStatus.loading;
    final String listType = EntryTypeExtension.name(entryType);
    final DocListItem res =
        await DocumentApi.docList(guildId, listType, curPage);

    if (res != null) {
      _parserMyAndCollect(res);
      return;
    }

    refreshController.loadFailed();
    loadingStatus = LoadingStatus.error;
    update();
  }

  void _parserMyAndCollect(DocListItem res) {
    final list = res.docList;
    if (list == null || list.isEmpty) {
      if (isEmpty()) {
        loadingStatus = LoadingStatus.noData;
      } else {
        loadingStatus = LoadingStatus.complete;
      }
      refreshController.loadNoData();
      update();
      return;
    }

    docList.addAll(list);

    if (list.length < res.size) {
      refreshController.loadNoData();
    } else {
      refreshController.loadComplete();
      curPage++;
    }

    if (isEmpty()) {
      loadingStatus = LoadingStatus.noData;
    } else {
      loadingStatus = LoadingStatus.complete;
    }

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
    if (src.title != null) {
      dest.title = src.title;
    }
  }

  void updateItem(DocItem item) {
    final String fileId = item.fileId;
    final int indexList = docList.indexWhere((e) => e.fileId == fileId);
    if (indexList >= 0) {
      updateData(docList[indexList], item);
      update();
      return;
    }
  }

  void removeItem(DocItem item) {
    return removeItemById(item.fileId);
  }

  void removeItemById(String fileId) {
    final int indexList = docList.indexWhere((e) => e.fileId == fileId);
    if (indexList >= 0) {
      docList.removeAt(indexList);
      update();
      return;
    }
  }

  void createItem(DocItem item) {
    docList.insert(0, item);
    update();
  }

  void renameItemTitle(String fileId, String title) {
    final int indexList = docList.indexWhere((e) => e.fileId == fileId);
    if (indexList >= 0) {
      docList[indexList].title = title;
      update();
      return;
    }
  }

  void changeCollect(String fileId, bool status) {
    final int indexList = docList.indexWhere((e) => e.fileId == fileId);
    if (indexList >= 0) {
      docList[indexList].setCollect(status);
      update();
      return;
    }
  }

  static void handleResult(
    List<Tuple2<TcDocPageReturnType, DocInfoItem>> list,
  ) {
    if (list == null || list.isEmpty) return;

    list.forEach((res) {
      final TcDocPageReturnType type = res.item1;
      final DocItem item = DocItem.fromInfo(res.item2);

      switch (type) {
        case TcDocPageReturnType.add:
          if (OnlineDocumentController.to().entryType == EntryType.view) {
            DocSearchListController.to(EntryType.view).createItem(item);
          } else if (OnlineDocumentController.to().entryType == EntryType.my) {
            DocSearchListController.to(EntryType.my).createItem(item);
          }
          break;
        case TcDocPageReturnType.delete:
          final String fileId = item.fileId;
          if (OnlineDocumentController.to().entryType == EntryType.view) {
            DocSearchListController.to(EntryType.view).removeItemById(fileId);
          } else if (OnlineDocumentController.to().entryType == EntryType.my) {
            DocSearchListController.to(EntryType.my).removeItemById(fileId);
          }
          break;
        case TcDocPageReturnType.update:
          if (OnlineDocumentController.to().entryType == EntryType.view) {
            DocSearchListController.to(EntryType.view).updateItem(item);
          } else if (OnlineDocumentController.to().entryType == EntryType.my) {
            DocSearchListController.to(EntryType.my).updateItem(item);
          } else {
            DocSearchListController.to(EntryType.collect).updateItem(item);
          }
          break;
        default:
          break;
      }
    });
  }
}
