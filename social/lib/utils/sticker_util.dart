import 'dart:ui';

import 'package:im/api/entity/sticker_bean.dart';
import 'package:im/api/sticker_api.dart';
import 'package:im/db/db.dart';

import '../loggers.dart';

class StickerUtil {
  static final StickerUtil _singleton = StickerUtil._internal();

  static StickerUtil get instance => _singleton;

  factory StickerUtil() {
    return _singleton;
  }

  StickerUtil._internal();

  ///key为guildId, value是表情列表
  final Map<String, List<StickerBean>> _stickers = {};

  ///用于判断服务器是否请求过
  final Set<String> _guildIds = {};

  List<StickerBean> getStickerById(String guildId) {
    if (guildId == null) return [];
    if (_stickers[guildId] == null) _stickers[guildId] = [];
    return _stickers[guildId];
  }

  void addStickers(String guildId, List<StickerBean> stickers) {
    if (guildId == null) return;
    if (_stickers[guildId] == null) _stickers[guildId] = [];
    final tem = _stickers[guildId];
    tem.addAll(stickers);
    saveStickerToDB(guildId, tem);
  }

  void setStickerById(String guildId, List<StickerBean> stickers) {
    if (guildId == null) return;
    if (_stickers[guildId] == null) _stickers[guildId] = [];
    _stickers[guildId].clear();
    _stickers[guildId].addAll(stickers);
    saveStickerToDB(guildId, stickers);
  }

  bool hasStickers(String guildId) {
    final list = _stickers[guildId];
    return list?.isNotEmpty ?? false;
  }

  int get stickerLength => _stickers.length;

  Future getStickers(String guildId) async {
    if (guildId == null || guildId.isEmpty) return;
    if (_guildIds.contains(guildId)) return;
    final list = await StickerApi.getStickers(guildId);
    if (list != null && list.isNotEmpty) {
      _stickers[guildId] = list;
      _guildIds.add(guildId);
    }
  }

  void addGuildToSet(String guildId) {
    _guildIds.add(guildId);
  }

  void removeGuildId(String guildId) {
    _guildIds.remove(_guildIds);
  }

  void saveStickerToDB(String key, List<StickerBean> stickers) {
    try {
      final list = stickers.map((e) => e.toJson()).toList();
      Db.stickerBox.put(key, list);
    } catch (e) {
      logger.severe('表情包存入错误:$e');
    }
  }

  void getStickersFromDB(String key) {
    try {
      final value = Db.stickerBox.get(key);
      if (value == null || value.isEmpty) return;
      final stickers = StickerBean.fromMapList(value);
      _stickers[key] ??= [];
      _stickers[key].clear();
      _stickers[key].addAll(stickers);
    } catch (e) {
      logger.severe('表情包读取错误:$e');
    }
  }

  Future setStickers(String guildId,
      {List<StickerBean> stickers,
      VoidCallback onSuccess,
      VoidCallback onError}) {
    return StickerApi.setStickers(guildId, stickers ?? _stickers[guildId] ?? [],
        onSuccess: onSuccess, onError: onError);
  }
}
