import 'package:get/get.dart';
import 'package:im/app/modules/document_online/controllers/online_document_controller.dart';
import 'package:im/app/modules/document_online/document_api.dart';
import 'package:im/app/modules/document_online/document_enum_defined.dart';
import 'package:im/app/modules/document_online/entity/doc_info_item.dart';
import 'package:im/app/modules/document_online/entity/doc_item.dart';
import 'package:im/app/modules/document_online/entity/doc_list_item.dart';
import 'package:im/app/modules/tc_doc_page/controllers/tc_doc_page_controller.dart';
import 'package:im/common/extension/string_extension.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:tuple/tuple.dart';

class DocListController extends GetxController {
  // my:我的文档,view:最近查看,collect:我的收藏
  final EntryType entryType;
  String _guildId;

  int curPage = 1; //默认第1页开始

  final List<DocItem> docList = [];

  final List<DocItem> docToday = [];
  final List<DocItem> docThisWeek = [];
  final List<DocItem> docEarlier = [];

  LoadingStatus loadingStatus;

  final RefreshController refreshController = RefreshController();

  DocListController(this.entryType);

  String get guildId {
    if (_guildId.noValue) {
      _guildId = OnlineDocumentController.to().guildId;
    }
    return _guildId;
  }

  static DocListController to(EntryType entryType) {
    DocListController c;
    final String tag = EntryTypeExtension.name(entryType);
    if (Get.isRegistered<DocListController>(tag: tag)) {
      c = Get.find<DocListController>(tag: tag);
    } else {
      c = Get.put(DocListController(entryType), tag: tag);
    }
    return c;
  }

  void clear() {
    docList.clear();
    docToday.clear();
    docThisWeek.clear();
    docEarlier.clear();
  }

  void onData() {
    //curPage 默认值为1，如果大于1，代表已经有内存缓存了
    if (curPage > 1) return;
    clear();
    _reqDocList(guildId);
  }

  void reLoading() {
    update();
    _reqDocList(guildId);
  }

  void onLoading() {
    _reqDocList(guildId);
  }

  bool isEmpty() {
    if (entryType == EntryType.view) {
      return docToday.isEmpty && docThisWeek.isEmpty && docEarlier.isEmpty;
    } else {
      return docList.isEmpty;
    }
  }

  Future<void> _reqDocList(String guildId) async {
    if (guildId.noValue) return;

    loadingStatus = LoadingStatus.loading;
    final String listType = EntryTypeExtension.name(entryType);
    final DocListItem res =
        await DocumentApi.docList(guildId, listType, curPage);

    if (res != null) {
      if (entryType == EntryType.view) {
        _parserView(res);
        return;
      } else {
        _parserMyAndCollect(res);
        return;
      }
    }

    refreshController.loadFailed();
    loadingStatus = LoadingStatus.error;
    update();
  }

  void _parserView(DocListItem res) {
    final List<DocItem> list = res.docList;
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

    final now = DateTime.now();
    for (final DocItem item in list) {
      final DateTime lastTime =
          DateTime.fromMillisecondsSinceEpoch(item.viewedAt);
      final int inDays = now.difference(lastTime).inDays;

      if (inDays <= 1) {
        //今天
        docToday.add(item);
      } else if (inDays <= 7) {
        //本周
        docThisWeek.add(item);
      } else {
        //较早
        docEarlier.add(item);
      }
    }

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

  void _parserMyAndCollect(DocListItem res) {
    final List<DocItem> list = res.docList;
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
    docList.addAll(res.docList);

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

  void addCollect(DocItem item) {
    if (entryType == EntryType.collect) {
      final int index = docList.indexWhere((e) => e.fileId == item.fileId);
      if (index >= 0) {
        docList[index].setCollect(true);
      } else {
        docList.insert(0, item);
        checkEmpty();
      }
      DocListController.to(EntryType.collect).update();
    }
  }

  void removeCollect(DocItem item) {
    if (entryType == EntryType.collect) {
      final int index = docList.indexWhere((e) => e.fileId == item.fileId);
      if (index >= 0) {
        docList[index].setCollect(false);
        docList.removeAt(index);
        checkEmpty();
      }
      DocListController.to(EntryType.collect).update();
    }
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

  void updateItem(DocItem item, {bool sort = false}) {
    final String fileId = item.fileId;
    if (entryType == EntryType.view) {
      final int indexToday = docToday.indexWhere((e) => e.fileId == fileId);
      if (indexToday >= 0) {
        updateData(docToday[indexToday], item);

        if (sort) {
          final cur = docToday.removeAt(indexToday);
          docToday.insert(0, cur);
        }

        DocListController.to(EntryType.view).update();
        return;
      }

      final int indexWeek = docThisWeek.indexWhere((e) => e.fileId == fileId);
      if (indexWeek >= 0) {
        updateData(docThisWeek[indexWeek], item);

        if (sort) {
          final cur = docThisWeek.removeAt(indexWeek);
          docToday.insert(0, cur);
        }

        DocListController.to(EntryType.view).update();
        return;
      }

      final int indexEarlier = docEarlier.indexWhere((e) => e.fileId == fileId);
      if (indexEarlier >= 0) {
        updateData(docEarlier[indexEarlier], item);

        if (sort) {
          final cur = docEarlier.removeAt(indexEarlier);
          docToday.insert(0, cur);
        }

        DocListController.to(EntryType.view).update();
        return;
      }

      ///如果没有找到 则添加
      docToday.insert(0, item);
      DocListController.to(EntryType.view).update();
      return;
    } else if (entryType == EntryType.my) {
      final int indexList = docList.indexWhere((e) => e.fileId == fileId);
      if (indexList >= 0) {
        updateData(docList[indexList], item);
        DocListController.to(EntryType.my).update();
        return;
      }
    } else if (entryType == EntryType.collect) {
      ///添加收藏
      if (item.isCollect()) {
        final int indexList = docList.indexWhere((e) => e.fileId == fileId);
        if (indexList >= 0) {
          updateData(docList[indexList], item);
          DocListController.to(EntryType.collect).update();
          return;
        } else {
          docList.insert(0, item);
          DocListController.to(EntryType.collect).update();
          return;
        }
      } else {
        ///移除收藏
        final int indexList = docList.indexWhere((e) => e.fileId == fileId);
        if (indexList >= 0) {
          docList[indexList].setCollect(false);
          docList.removeAt(indexList);
          DocListController.to(EntryType.collect).update();
          return;
        }
      }
    }
  }

  void removeItem(DocItem item) {
    return removeItemById(item.fileId);
  }

  void removeItemById(String fileId) {
    if (entryType == EntryType.view) {
      final int indexToday = docToday.indexWhere((e) => e.fileId == fileId);
      if (indexToday >= 0) {
        docToday.removeAt(indexToday);
        checkEmpty();
        DocListController.to(EntryType.view).update();
        return;
      }

      final int indexWeek = docThisWeek.indexWhere((e) => e.fileId == fileId);
      if (indexWeek >= 0) {
        docThisWeek.removeAt(indexWeek);
        checkEmpty();
        DocListController.to(EntryType.view).update();
        return;
      }

      final int indexEarlier = docEarlier.indexWhere((e) => e.fileId == fileId);
      if (indexEarlier >= 0) {
        docEarlier.removeAt(indexEarlier);
        checkEmpty();
        DocListController.to(EntryType.view).update();
        return;
      }
    } else if (entryType == EntryType.my) {
      final int indexList = docList.indexWhere((e) => e.fileId == fileId);
      if (indexList >= 0) {
        docList.removeAt(indexList);
        checkEmpty();
        DocListController.to(EntryType.my).update();
        return;
      }
    } else if (entryType == EntryType.collect) {
      final int indexList = docList.indexWhere((e) => e.fileId == fileId);
      if (indexList >= 0) {
        docList.removeAt(indexList);
        checkEmpty();
        DocListController.to(EntryType.collect).update();
        return;
      }
    }
  }

  void createItem(DocItem item) {
    if (entryType == EntryType.view) {
      docToday.insert(0, item);
      checkEmpty();
      DocListController.to(EntryType.view).update();
    } else if (entryType == EntryType.my) {
      docList.insert(0, item);
      checkEmpty();
      DocListController.to(EntryType.my).update();
    } else if (entryType == EntryType.collect && item.isCollect()) {
      docList.insert(0, item);
      checkEmpty();
      DocListController.to(EntryType.collect).update();
    }
  }

  void renameItemTitle(String fileId, String title) {
    if (entryType == EntryType.view) {
      final int indexToday = docToday.indexWhere((e) => e.fileId == fileId);
      if (indexToday >= 0) {
        docToday[indexToday].title = title;
        DocListController.to(EntryType.view).update();
        return;
      }

      final int indexWeek = docThisWeek.indexWhere((e) => e.fileId == fileId);
      if (indexWeek >= 0) {
        docThisWeek[indexWeek].title = title;
        DocListController.to(EntryType.view).update();
        return;
      }

      final int indexEarlier = docEarlier.indexWhere((e) => e.fileId == fileId);
      if (indexEarlier >= 0) {
        docEarlier[indexEarlier].title = title;
        DocListController.to(EntryType.view).update();
        return;
      }
    } else if (entryType == EntryType.my) {
      final int indexList = docList.indexWhere((e) => e.fileId == fileId);
      if (indexList >= 0) {
        docList[indexList].title = title;
        DocListController.to(EntryType.my).update();
        return;
      }
    } else if (entryType == EntryType.collect) {
      final int indexList = docList.indexWhere((e) => e.fileId == fileId);
      if (indexList >= 0) {
        docList[indexList].title = title;
        DocListController.to(EntryType.collect).update();
        return;
      }
    }
  }

  void checkEmpty() {
    if (isEmpty()) {
      loadingStatus = LoadingStatus.noData;
    } else {
      loadingStatus = LoadingStatus.complete;
    }
  }

  static void handleItemAdd(DocItem item, {bool addView = false}) {
    ///是否需要添加到我的查看，生成副本不自动打开不需要添加，创建文档自动打开需要添加
    if (addView) DocListController.to(EntryType.view).createItem(item);
    DocListController.to(EntryType.my).createItem(item);
    DocListController.to(EntryType.collect).createItem(item);
  }

  static void handleItemDel(String fileId, {bool isRecord = false}) {
    DocListController.to(EntryType.view).removeItemById(fileId);
    if (!isRecord) {
      DocListController.to(EntryType.my).removeItemById(fileId);
      DocListController.to(EntryType.collect).removeItemById(fileId);
    }
  }

  static void handleItemUpdate(DocItem item, {bool sort = false}) {
    DocListController.to(EntryType.view).updateItem(item, sort: sort);
    DocListController.to(EntryType.my).updateItem(item);
    DocListController.to(EntryType.collect).updateItem(item);
  }

  static void handleItemAddCollect(DocItem item) {
    DocListController.to(EntryType.view).updateItem(item);
    DocListController.to(EntryType.my).updateItem(item);
    DocListController.to(EntryType.collect).addCollect(item);
  }

  static void handleItemRemoveCollect(DocItem item) {
    DocListController.to(EntryType.view).updateItem(item);
    DocListController.to(EntryType.my).updateItem(item);
    DocListController.to(EntryType.collect).removeCollect(item);
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
          handleItemAdd(item, addView: true);
          break;
        case TcDocPageReturnType.delete:
          final String fileId = item.fileId;
          handleItemDel(fileId);
          break;
        case TcDocPageReturnType.update:
          handleItemUpdate(item, sort: true);
          break;
        default:
          break;
      }
    });
  }
}
