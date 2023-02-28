import 'package:get/get.dart';
import 'package:im/app/modules/circle/controllers/circle_controller.dart';
import 'package:im/db/db.dart';

enum CircleSortType {
  updated,
  publish,
}

extension CircleSortTypeExtension on CircleSortType {
  String get keyName {
    switch (this) {
      case CircleSortType.updated:
        return 'updated';
      case CircleSortType.publish:
        return 'publish';
      default:
        return '';
    }
  }

  String get typeName {
    switch (this) {
      case CircleSortType.updated:
        return '最新回复'.tr;
      case CircleSortType.publish:
        return '最新发布'.tr;
      default:
        return '';
    }
  }

  static String key2Name(String key) {
    for (final value in CircleSortType.values) {
      if (key == value.keyName) return value.typeName;
    }
    return '';
  }

  static CircleSortType key2Value(String key) {
    for (final value in CircleSortType.values) {
      if (key == value.keyName) return value;
    }
    return CircleSortType.updated;
  }
}

class GuildTopicSortModel {
  final String guildId;
  Map<String, int> topicSort = {};

  GuildTopicSortModel({this.guildId}) {
    final topicSort = Db.guildTopicSortCategoryBox.get(guildId);
    this.topicSort = Map<String, int>.from(topicSort ?? {});
  }

  String getSortName(String topicId) {
    final int sortIdx = getSortIdx(topicId);
    return CircleSortType.values[sortIdx].typeName;
  }

  String getTopicSortApiKeyName(String topicId) {
    final int sortIdx = getSortIdx(topicId);
    return CircleSortType.values[sortIdx].keyName;
  }

  int getSortIdx(String topicId) {
    // 如果已经有本地存储的默认值，则使用本地存储的。
    // 默认使用服务器端的默认值
    // 服务器端没有，则取0 最新回复
    if (topicId.isEmpty) topicId = "_all";
    final int sortType = topicSort[topicId];
    int sortRtn = 0;
    if (sortType != null) {
      sortRtn = sortType;
    } else {
      // 圈子配置中服务器端的值
      final serverSortType =
          CircleController.to.circleInfoDataModel?.sortType ?? '';
      sortRtn = CircleSortTypeExtension.key2Value(serverSortType).index;
    }

    return sortRtn;
  }

  void saveSort(String topicId, int sortType) {
    if (topicId.isEmpty) topicId = "_all";
    topicSort[topicId] = sortType;
    Db.guildTopicSortCategoryBox?.put(guildId, topicSort);
  }
}
