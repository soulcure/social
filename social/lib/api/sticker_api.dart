import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:im/api/entity/sticker_bean.dart';
import 'package:im/core/http_middleware/http.dart';
import 'package:im/global.dart';

class StickerApi {
  static const String addStickerUrl = '/api/emojis/create';
  static const String getStickersUrl = '/api/emojis/lists';

  ///获取表情列表
  static Future<List<StickerBean>> getStickers(String guildId,
      {CancelToken token}) async {
    dynamic res;
    try {
      res = await Http.request(getStickersUrl,
          data: {'guild_id': guildId}, cancelToken: token);
    } catch (e) {
      res = null;
    }
    if (res == null) return null;
    return StickerBean.fromMapList(res);
  }

  ///设置表情列表
  static Future setStickers(String guildId, List<StickerBean> stickers,
      {CancelToken token,
      ui.VoidCallback onSuccess,
      ui.VoidCallback onError}) async {
    dynamic res;
    final List<Map> list = [];
    stickers.forEach((element) {
      list.add(element.toJson());
    });
    try {
      res = await Http.request(
        addStickerUrl,
        data: {'guild_id': guildId, 'emojis': list, 'user_id': Global.user.id},
        cancelToken: token,
      );
      onSuccess?.call();
    } catch (e) {
      onError?.call();
    }
    return res;
  }
}
