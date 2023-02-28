import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:im/app/theme/app_theme.dart';
import 'package:im/db/db.dart';
import 'package:im/global.dart';
import 'package:im/pages/guild_setting/guild/container_image.dart';
import 'package:im/pages/home/json/text_chat_json.dart';
import 'package:im/pages/home/model/input_model.dart';
import 'package:im/pages/home/model/text_channel_controller.dart';
import 'package:im/pages/home/view/text_chat/items/components/message_reaction.dart';
import 'package:im/pages/home/view/text_chat/items/sticker_item.dart';
import 'package:im/themes/const.dart';
import 'package:im/utils/sticker_util.dart';
import 'package:im/utils/universal_platform.dart';
import 'package:im/widgets/texture_image.dart';
import 'package:path/path.dart' as p;
import 'package:pedantic/pedantic.dart';
import 'package:super_tooltip/super_tooltip.dart';

Future<Map<String, dynamic>> readAllEmo() async {
  final allEmoJson =
      await rootBundle.loadString(p.join(getEmoDir(), allEmoFile));
  return jsonDecode(allEmoJson);
}

Future<Map<String, dynamic>> readEmoList({String emoType = 'emoji_zh'}) async {
  final emoData = await readAllEmo();
  final emoAssetPath = emoData[emoType];
  if (emoAssetPath == null) return null;
  final emoList = await rootBundle.loadString(emoAssetPath);
  return jsonDecode(emoList);
}

List<ReactionEntity> fromEmoMapToList(Map<String, dynamic> map) {
  final List<ReactionEntity> list = [];
  map.forEach((key, value) {
    list.add(ReactionEntity(key, id: '[$key]'));
  });
  return list;
}

String getEmoDir() => p.join('assets', 'emojis');

const allEmoFile = 'all_emoji.json';

bool isAllEmo(Characters input) {
  for (final String c in input) {
    final isLengthOk = c.runes.length == c.length && c.length < 2 && c != ' ';
    final emoRegPass = isEmoRegPass(c);
    if (isLengthOk && !emoRegPass) return false;
  }
  return true;
}

bool isEmoRegPass(String input) =>
    (!input.contains(chineseChar)) &&
    (input.replaceAll(emoRegExp, '') != input);

final RegExp emoRegExp = RegExp(
    r'(\u00a9|\u00ae|[\u2000-\u2E79]|[\u3040-\u3300]|\ud83c[\ud000-\udfff]|\ud83d[\ud000-\udfff]|\ud83e[\ud000-\udfff])');

final RegExp chineseChar = RegExp(
    r'(\u3002|\uff1f|\uff01|\uff0c|\u3001|\uff1b|\uff1a|\u201c|\u201d|\u2018|\u2019|\uff08|\uff09|\u300a|\u300b|\u3008|\u3009|\u3010|\u3011|\u300e|\u300f|\u300c|\u300d|\ufe43|\ufe44|\u3014|\u3015|\u2026|\u2014|\uff5e|\ufe4f|\uffe5)');

class EmoUtil {
  static final EmoUtil _singleton = EmoUtil._internal();

  static EmoUtil get instance => _singleton;

  factory EmoUtil() {
    return _singleton;
  }

  EmoUtil._internal();

  final Map<String, dynamic> allEmoMap = {};
  final List<ReactionEntity> curEmoList = [];
  final List<ReactionEntity> curReaEmoList = [];
  bool hasInitial = false;
  bool hasPreload = false;

  Future doInitial(
      {String emoType = 'emoji_zh',
      String reactionEmoType = 'emoji_reaction_zh'}) async {
    if (hasInitial) return;
    hasInitial = true;
    final emoData = await readAllEmo();
    emoData.forEach((key, value) async {
      final emoAssetPath = emoData[key];
      if (emoAssetPath == null) return;
      final emoReaAssetPath = emoData[reactionEmoType];
      final emoList = await rootBundle.loadString(emoAssetPath);
      final emoReaList = await rootBundle.loadString(emoReaAssetPath);
      final curEmoMap = jsonDecode(emoList);
      final reaEmoMap = jsonDecode(emoReaList);
      if (emoType == key && curEmoList.isEmpty) {
        curEmoList.addAll(fromEmoMapToList(curEmoMap));
      }
      if (reactionEmoType == key && curReaEmoList.isEmpty) {
        curReaEmoList.addAll(
            await _getReactionEmojiFromCache(fromEmoMapToList(reaEmoMap)));
        preloadImage(Get.context);
      }
      allEmoMap.addAll(curEmoMap);
    });
  }

  void preloadImage(BuildContext context) {
    if (!hasPreload) {
      hasPreload = true;
      curReaEmoList.forEach((element) {
        final asset = allEmoMap[element.name];
        if (asset != null && asset.toString().isNotEmpty)
          precacheImage(AssetImage(asset), context);
      });
    }
  }

  Widget getEmoIcon(String name, {double size = 26}) {
    final asset = allEmoMap[name];
    return asset == null
        ? Text(name)
        : Image.asset(
            asset,
            width: size,
            height: size,
          );
  }

  List<Widget> buildTabs(String guildId, IndexBuilder builder) {
    final hasStickers = StickerUtil.instance.hasStickers(guildId);
    if (!hasStickers) return [];
    return List.generate(1, (index) {
      final value = StickerUtil.instance.getStickerById(guildId);
      return value.isEmpty
          ? const SizedBox()
          : builder.call(
              _imageWidgetWithUrl(value.first.avatar, BoxFit.cover, 28, 28),
              index);
    });
  }

  SuperTooltip curTooltip;

  List<Widget> buildTabViews(BuildContext context, InputModel inputModel) {
    final theme = Theme.of(context);
    final guildId = inputModel.guildId;
    final hasStickers = StickerUtil.instance.hasStickers(guildId);
    if (!hasStickers) return [];
    return List.generate(1, (index) {
      final beans = StickerUtil.instance.getStickerById(guildId);
      const rowCount = 5;
      final rows = buildGrid(beans.length, rowCount);
      return ListView.builder(
        padding: const EdgeInsets.only(top: 16),
        itemBuilder: (ctx, index) {
          final curLength = rows[index];
          return Row(
            children: List.generate(rowCount, (i) {
              final cur = i + index * rowCount;
              final isEmpty = curLength < rowCount && i >= curLength;
              final hasSticker = cur < beans.length;
              if (isEmpty || !hasSticker)
                return const Expanded(
                  child: SizedBox(),
                );
              final curSticker = beans[cur];
              final url = spliceGif(curSticker.avatar);
              return Expanded(
                child: Builder(
                  builder: (ctx) => Column(
                    children: [
                      GestureDetector(
                        onLongPress: () {
                          curTooltip = SuperTooltip(
                              arrowTipDistance: 50,
                              arrowBaseWidth: 10,
                              arrowLength: 4,
                              borderColor:
                                  const Color(0xff919499).withOpacity(0.3),
                              borderWidth: 0.5,
                              content: Container(
                                width: 120,
                                height: 120,
                                padding: const EdgeInsets.all(6),
                                decoration:
                                    const BoxDecoration(color: Colors.white),
                                alignment: Alignment.center,
                                child: _imageWidgetWithUrl(
                                    url, BoxFit.contain, 120, 120,
                                    radius: 8),
                              ),
                              borderRadius: 8,
                              shadowColor: Colors.transparent,
                              popupDirection: TooltipDirection.up,
                              outsideBackgroundColor: Colors.transparent);
                          curTooltip.show(ctx);
                        },
                        onTap: () {
                          TextChannelController.to(
                                  channelId: inputModel.reply?.channelId ??
                                      inputModel.channelId)
                              .sendContents(
                            [
                              StickerEntity('', curSticker.name, url,
                                  width: curSticker.width,
                                  height: curSticker.height)
                            ],
                            relay: inputModel.reply,
                          );
                        },
                        onLongPressEnd: (detail) {
                          curTooltip?.close();
                        },
                        child: Container(
                          width: 60,
                          height: 60,
                          alignment: Alignment.center,
                          child: _imageWidgetWithUrl(url, BoxFit.cover, 60, 60),
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        curSticker.name ?? '',
                        style: TextStyle(
                            fontSize: 12,
                            color: theme.textTheme.bodyText1.color,
                            height: 1),
                      ),
                      sizeHeight10
                    ],
                  ),
                ),
              );
            }),
          );
        },
        itemCount: rows.length,
      );
    });
  }

  List<int> buildGrid(int total, int row) {
    final divRes = total ~/ row;
    final rest = total % row;
    return rest == 0
        ? List.generate(divRes, (index) => row)
        : List.generate(divRes + 1, (index) => index == divRes ? rest : row);
  }

  Widget _imageWidgetWithUrl(
      String url, BoxFit fit, double width, double height,
      {double radius = 0}) {
    if (UniversalPlatform.isMobileDevice && TextureImage.useTexture) {
      final devicePixelRatio =
          MediaQuery.of(Global.navigatorKey.currentContext).devicePixelRatio;
      return SizedBox(
          height: width,
          width: height,
          child: TextureImage(
            url,
            width: width * devicePixelRatio,
            height: height * devicePixelRatio,
            radius: radius * devicePixelRatio,
          ));
    } else {
      return ContainerImage(
        url,
        fit: fit,
        width: width,
        height: height,
        placeHolder: (context, url) => Center(
          child: SizedBox(
            width: 15,
            height: 15,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(
                  appThemeData.disabledColor.withOpacity(0.5)),
            ),
          ),
        ),
      );
    }
  }

  // 缓存反序
  Future<List<ReactionEntity>> _getReactionEmojiFromCache(
      List<ReactionEntity> list) async {
    final reversedList = list.reversed;
    final box = Db.reactionEmojiOrderBox;
    final orderMap = box?.values?.toList();
    if (orderMap?.isEmpty ?? true) {
      for (int i = 0; i < reversedList.length; i++) {
        await box?.add(reversedList.elementAt(i).name);
      }
      return list;
    } else {
      await box.clear();
      final List<ReactionEntity> newList = [];
      final Map<String, ReactionEntity> tempMap = {};
      reversedList.forEach((element) {
        tempMap[element.name] = element;
      });
      for (int i = 0; i < orderMap.length; i++) {
        final cur = orderMap.elementAt(i);
        final emo = tempMap[cur];
        if (emo != null) newList.add(emo);
      }
      final restList =
          reversedList.where((element) => !newList.contains(element)).toList();
      newList.addAll(restList);
      for (int i = 0; i < newList.length; i++) {
        unawaited(box.add(newList[i].name));
      }
      return newList.reversed.toList();
    }
  }

  void updateReactionEmojiOrder(String emojiName) {
    final box = Db.reactionEmojiOrderBox;
    final emojiIdx =
        curReaEmoList.indexWhere((element) => element.name == emojiName);
    if (emojiIdx >= 0) {
      curReaEmoList
        ..removeAt(emojiIdx)
        ..insert(0, ReactionEntity(emojiName));
    }

    try {
      final cacheEmojiIdx =
          box.values.toList().indexWhere((element) => element == emojiName);
      if (cacheEmojiIdx >= 0) {
        box.deleteAt(cacheEmojiIdx);
      }
      box.add(emojiName);
    } catch (e) {
      print(e);
    }
  }
}

typedef IndexBuilder = Widget Function(Widget child, int index);
