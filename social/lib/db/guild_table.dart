import 'package:im/api/entity/user_config.dart';
import 'package:im/loggers.dart';
import 'package:im/pages/home/model/chat_index_model.dart';
import 'package:im/pages/home/model/chat_target_model.dart';

import 'db.dart';

///服务器本地缓存
class GuildTable {
  ///保存服务器列表的排序
  static Future _updateGuildOrder() {
    return Db.guildOrderBox.clear().then((_) {
      return Db.guildOrderBox
          .addAll(ChatTargetsModel.instance.chatTargets.map((e) => e.id));
    });
  }

  ///保存单个服务器的缓存
  static List<Future> add(GuildTarget target) {
    final List<Future> futureList = [];
    futureList.add(target.updateGuildBox());
    for (final c in target.channels) futureList.add(Db.channelBox.put(c.id, c));

    futureList.add(_updateGuildOrder());
    return futureList;
  }

  ///保存服务器列表, 再保存 myGuild2 接口的Hash值
  static Future appendAll(List<GuildTarget> list, {String myGuild2Hash}) async {
    final List<Future> futureList = [];
    list.forEach((t) {
      futureList.addAll(add(t));
    });
    await Future.wait(futureList);
    if (myGuild2Hash != null) {
      await Db.userConfigBox.put(UserConfig.myGuild2Hash, myGuild2Hash);
      logger.info('myGuild2 put myGuild2Hash: $myGuild2Hash');
    }
  }

  static void remove(String guildId) {
    Db.guildBox.delete(guildId);
    _updateGuildOrder();
  }

  static List<GuildTarget> getAll() {
    final guilds = Db.guildBox.values.map((e) {
      e = Map.from(e);
      e["channel_lists"] = e["channel_lists"].toString().split(",");
      return GuildTarget.fromJson(e);
    }).toList();
    final allChannels = Db.channelBox.values;
    for (final g in guilds) {
      final List<ChatChannel> channels = [];
      for (final c in allChannels) {
        if (c.guildId == g.id) channels.add(c);
      }

      g.channels
        ..clear()
        ..addAll(channels);
    }

    final Map<String, GuildTarget> map = {};
    guilds.forEach((element) {
      map[element.id] = element;
    });
    return Db.guildOrderBox.values
        .map((e) => map[e])
        .where((e) => e != null)
        .toList();
  }
}
