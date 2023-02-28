import 'dart:async';
import 'dart:convert';

import 'package:im/api/entity/user_role_card_bean.dart';
import 'package:im/api/relation_api.dart';
import 'package:im/common/extension/string_extension.dart';
import 'package:im/db/db.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:meta/meta.dart';

const int singleCreditVersion = -999; // 单卡槽版本号

class CreditsBean {
  String userId;
  GuildCardBean relatedGuilds;
  List<CreditsModel> credits;

  CreditsBean({this.userId, this.relatedGuilds, this.credits});

  CreditsBean.fromJson(Map<String, dynamic> json) {
    if (json == null) return;
    try {
      userId = json['user_id'];
      if (json['credits'] != null) {
        final Map creditMaps = json['credits'];
        credits = creditMaps.values
            .map((e) => CreditsModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
      final Map map = json['related_guilds'];
      if (map != null && map.isNotEmpty) {
        final relatedGuildsMap = jsonDecode(map.values.first);
        relatedGuilds = GuildCardBean.fromMap(relatedGuildsMap);
      }
    } catch (e) {
      print('CreditsBean decode error');
    }
  }

  int sortCardFunc(CreditsModel l, CreditsModel r) {
    final leftIndex = l.index ?? -1;
    final rightIndex = r.index ?? -1;
    return leftIndex - rightIndex;
  }

  /// 多卡槽数据
  List<GuildCardBean> get cardBeans {
    List<GuildCardBean> beans = [];
    if (credits != null && credits.isNotEmpty) {
      // 过滤掉visible=false, 这些数据不显示在多卡槽上
      beans = (credits..sort(sortCardFunc))
          .where((e) => e.visible != false)
          .map((e) => e.content)
          .toList();
    } else if (relatedGuilds != null) {
      // 兼容老数据， 这里取的是单卡槽数据
      beans = [relatedGuilds];
    }
    return beans;
  }

  /// 徽章数据，可能为null
  String get cardUrl {
    // 从多卡槽数据中，取出第一个可视的卡槽
    final firstVisibleItem = credits != null
        ? (credits..sort(sortCardFunc))
            ?.firstWhere((e) => e.visible != false, orElse: () => null)
        : null;
    // 优先取新字段数据 >  多卡槽数据中取徽章数据  > 单卡槽徽章数据
    return firstVisibleItem?.title?.img ??
        firstVisibleItem?.content?.title?.img ??
        relatedGuilds?.title?.img;
  }

  // 保存未处理数据
  static void saveUnHandleDataToBox(String key) {
    Map unHandleData = Db.creditsBox.get('unHandleData');
    unHandleData ??= {};
    unHandleData[key] = _userCards[key];
    Db.creditsBox.put('unHandleData', unHandleData);
  }

  // 只需要读取一次即可
  static bool isRead = false;

  static void readUnHandleDataToBox() {
    if (!isRead) {
      final Map unHandleData = Db.creditsBox.get('unHandleData');
      if (unHandleData != null) {
        unHandleData.forEach((key, value) {
          if (_userIds[key] == null) {
            _userIds[key] = <String>{};
            _userCards[key] = {};
          }
          final Map<String, Map> map = Map<String, Map>.from(value);
          _userCards[key] = map;
          _userIds[key] = map.keys.toSet();
        });
      }
      isRead = true;
    }
  }

  /// 合并同个时间段的多个请求
  static final Map<String, Future> _futureMap = {};
  static final Map<String, Map<String, Map>> _userCards = {};
  static final Map<String, Set<String>> _userIds = {};

  static void updateItem(String guildId, String channelId,
      {bool isGroupDmChannel = false,
      bool requestNow = true,
      String userId,
      Map userCards}) {
    // 读取未处理的历史数据
    readUnHandleDataToBox();
    // 部落是没有guildId的，所以标志位由channelId顶替
    final key = isGroupDmChannel ? channelId : guildId;
    if (userId.hasValue) {
      if (_userIds[key] == null) {
        _userIds[key] = <String>{};
        _userCards[key] = {};
      }
      if (!_userIds[key].contains(userId)) {
        _userIds[key].add(userId);
        _userCards[key][userId] = userCards;
      }
    }
    if (!requestNow) {
      saveUnHandleDataToBox(key);
      return;
    }
    // 如果没有更新卡槽的数据就不进行更新
    if (_userCards[key] == null || _userCards[key].isEmpty) return;
    _futureMap[key] ??= Future.delayed(const Duration(milliseconds: 200), () {
      final List userIds = List.from(_userIds[key]);
      final List<Map> userCards = [];
      userIds.forEach((userId) {
        userCards.add(_userCards[key][userId]);
      });
      fetchData(guildId, channelId, userCards).whenComplete(() {
        // 移除掉加载过得数据
        userIds.forEach((userId) {
          _userCards[key].remove(userId);
          _userIds[key].remove(userId);
        });
        _futureMap.remove(key);
        saveUnHandleDataToBox(key);
      });
    });
  }

  /// 请求并保存到本地
  static Future<void> fetchData(
      String guildId, String channelId, List<Map> userCards,
      {bool isGroupDmChannel = false}) async {
    // 部落需要优化请求方式
    final List res = isGroupDmChannel
        ? await RelationApi.getCredits(guildId, userCards,
            channelId: channelId, channelType: ChatChannelType.group_dm.index)
        : await RelationApi.getCredits(guildId, userCards);
    if (res == null || res.isEmpty) return;
    final beanList = res.map((e) => CreditsBean.fromJson(e)).toList();
    final key = isGroupDmChannel ? channelId : guildId;
    beanList.forEach((e) {
      e.saveToBox(key);
    });
  }

  /// ws,之后做的更新操作
  static void updateIfCreditsItemChange(
    Map member, {
    @required String guildId,
    @required String channelId,
    @required String userId,
    ChatChannel chatChannel,
    bool requestNow = true,
  }) {
    if (channelId.noValue ||
        guildId.noValue ||
        userId.noValue ||
        member == null) return;

    // 需要channel类型来判断是否是部落还是普通频道
    final channel = chatChannel ?? Db.channelBox.get(channelId);
    if (channel == null) return;

    // 是否是部落频道
    final isGroupDmChannel = channel.type == ChatChannelType.group_dm;
    // 获取本地缓存
    final key = isGroupDmChannel ? '$channelId-$userId' : '$guildId-$userId';
    final credits = Db.creditsBox.get(key);

    final List guildCard = member['guild_card'];
    if (guildCard != null && guildCard.isNotEmpty) {
      // 比对本地hash，如果一样就不需要更新
      if (credits != null && guildCard.join('-').hashCode == credits['v']) {
        return;
      }
      updateItem(guildId, channelId,
          userId: userId,
          userCards: {
            'user_id': userId,
            'card_ids': guildCard.map((e) => e.split(';')[1]).toList()
          },
          isGroupDmChannel: isGroupDmChannel,
          requestNow: requestNow);
    } else if (credits != null) {
      Db.creditsBox.delete(key);
    }
  }

  /// 每次getList, 过滤相同用户后调用 => updateIfCreditsItemChange
  static Future<void> updateIfCreditsChange(List<dynamic> messages) async {
    if (messages == null || messages.isEmpty) return;
    final Set<String> userIds = {};
    messages.forEach((e) {
      // 过滤相同用户数据
      if (e is Map && e.containsKey('user_id')) {
        final userId = e['user_id'];
        if (userIds.contains(userId)) return;
        userIds.add(userId);
        updateIfCreditsItemChange(
          e['member'],
          guildId: e['guild_id'],
          channelId: e['channel_id'],
          userId: e['user_id'],
        );
      }
    });
  }

  /// bean => box , 这里仅仅只是缓存徽章的url，其余数据不缓存
  Future<void> saveToBox(String guildId) async {
    final key = '$guildId-$userId';
    final url = cardUrl ?? '';

    if (url.noValue) {
      await Db.creditsBox.delete(key);
      return;
    }

    if (credits != null) {
      final v =
          credits.map((e) => '$guildId;${e.cardId};${e.v}').toList().join('-');
      if (v.noValue) {
        // 数据解析错误, 机器人徽章数据设置出问题的时候会触发这里
        // fix:【聊天公屏】当成员列表100名之后的用户被删除徽章和卡槽，说话完也没法触发更新。
        await Db.creditsBox.delete(key);
      } else {
        await Db.creditsBox.put(key, {
          'url': url,
          'v': v.hashCode,
        });
      }
    } else if (relatedGuilds != null) {
      // relatedGuilds 这种旧数据覆盖，不能覆盖新数据，这块逻辑做兼容用
      final m = Db.creditsBox.get(key);
      if (m == null || m['v'] == singleCreditVersion) {
        await Db.creditsBox.put(key, {'url': url, 'v': singleCreditVersion});
      }
    } else {
      await Db.creditsBox.delete(key);
    }
  }

  /// memberList/jsonData 直接更新本地数据
  /// [credits] 是新版本的多卡槽数据，[relatedGuilds] 是旧版本的单卡槽数据
  /// 可能都有数据，优先使用多卡槽数据
  /// COMPATIBILITY 服务器全面迁移到多卡槽后，可以简化这里的逻辑
  static Future<void> saveBean(String userId, String guildId,
      {Map credits, Map relatedGuilds}) async {
    final key = '$guildId-$userId';
    if (credits != null || relatedGuilds != null) {
      // 如果接收到relatedGuilds是一个正常的map，就需要重新encode，走原本的解析流程。
      // 这里主要是兼容新旧接口解析方式不一致的问题
      // COMPATIBILITY 服务器不返回单卡槽数据时可删除
      if (relatedGuilds != null && relatedGuilds.containsKey('title')) {
        relatedGuilds = {'_': jsonEncode(relatedGuilds)};
      }
      final bean = CreditsBean.fromJson({
        'user_id': userId,
        if (credits != null) 'credits': credits,
        if (relatedGuilds != null) 'related_guilds': relatedGuilds
      });
      await bean.saveToBox(guildId);
    } else {
      await Db.creditsBox.delete(key);
    }
  }
}

/// credit item content
class CreditsModel {
  String botId;
  String cardId;
  GuildCardBean content;
  TitleBean title;
  int v;
  bool visible;
  int index;

  CreditsModel({this.botId, this.cardId, this.content});

  CreditsModel.fromJson(Map<String, dynamic> json) {
    if (json == null) return;
    if (json['bot_id'] != null) botId = '${json['bot_id']}';
    cardId = json['card_id'];
    if (json['content'] != null) {
      content = GuildCardBean.fromMap(jsonDecode(json['content']));
    }
    if (json['title'] != null) title = TitleBean.fromMap(json['title'] ?? {});
    if (json['v'] != null) v = json['v'];
    if (json['visible'] != null) visible = json['visible'];
    if (json['index'] != null) index = json['index'];
  }

  Map toJson() {
    return {
      if (botId != null) 'bot_id': botId,
      if (cardId != null) 'card_id': cardId,
      if (content != null) 'content': jsonEncode(content.toJson()),
      if (title != null) 'title': title.toJson(),
      if (v != null) "v": v,
      if (visible != null) "visible": visible,
      if (index != null) "index": index,
    };
  }
}
