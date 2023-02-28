import 'package:im/db/db.dart';
import 'package:pedantic/pedantic.dart';

class UserConfig {
  static String defaultGuildsRestricted = 'default_guilds_restricted';
  static String restrictedGuilds = 'restricted_guilds';
  static String friendSourceFlags = 'friend_source_flags';
  static String friendSourceFlagsAll = 'all';
  static String friendSourceFlagsMutualGuilds = 'mutual_guilds';
  static String friendSourceFlagsMutualFriends = 'mutual_friends';
  static String mute = "mute";
  static String channel = "channel";
  static String mutedChannel = "muted_channel";
  static String notificationMuteKey = "notificationMute";
  static String channelViewPermissionKey = "channelViewPermission"; //查看频道权限
  static String myGuild2Hash = "myGuild2Hash"; //myGuild2接口参数hash
  static String dmList2Time = "dmList2Time"; //dmList2接口参数lastTime
  static String dmList2ChannelIds = "dmList2ChannelIds"; //dmList2接口返回的频道ID

  // 退出服务器需要移除被限制私聊的服务器
  static Future<void> removeRestrictedGuilds(String guildId) async {
    final List<String> restrictedGuilds =
        await Db.userConfigBox.get(UserConfig.restrictedGuilds);
    restrictedGuilds.remove(guildId);
    unawaited(
        Db.userConfigBox.put(UserConfig.restrictedGuilds, restrictedGuilds));
  }

  // ignore: type_annotate_public_apis
  static List<String> getMutedChannel(res) {
    if (res[UserConfig.mute] != null) {
      final List<dynamic> rawChannels =
          res[UserConfig.mute][UserConfig.channel];
      return rawChannels.cast<String>();
    }
    return null;
  }

  static Future<void> update({
    bool defaultGuildsRestricted,
    List<String> restrictedGuilds,
    Map<String, dynamic> friendSourceFlags,
    List<String> mutedChannels,
    bool notificationMute,
  }) async {
    if (defaultGuildsRestricted != null)
      await Db.userConfigBox
          .put(UserConfig.defaultGuildsRestricted, defaultGuildsRestricted);
    if (restrictedGuilds != null)
      await Db.userConfigBox.put(UserConfig.restrictedGuilds, restrictedGuilds);
    if (friendSourceFlags != null)
      await Db.userConfigBox
          .put(UserConfig.friendSourceFlags, friendSourceFlags);
    if (mutedChannels != null)
      await Db.userConfigBox.put(mutedChannel, mutedChannels);
    if (notificationMute != null)
      await Db.userConfigBox.put(notificationMuteKey, notificationMute);
  }

  static Future<bool> notificationMute() async {
    return Db.userConfigBox.get(notificationMuteKey);
  }

  static Future<bool> isChannelMuted(String channelId) async {
    final List<String> mutedChannels = await Db.userConfigBox.get(mutedChannel);
    return mutedChannels?.contains(channelId) == true;
  }

  /// 更新本地配置，使指定的channel恢复消息通知
  static Future<void> unMuteChannel(String channelId) async {
    final List<String> mutedChannels = await Db.userConfigBox.get(mutedChannel);

    /// 没有频道消息屏蔽的配置
    if (mutedChannels == null) return;

    /// 从配置中删除此channelId
    final bool isSuccess = mutedChannels.remove(channelId);
    if (isSuccess) {
      await Db.userConfigBox.put(mutedChannel, mutedChannels);
    }
  }

  /// 更新本地配置，屏蔽指定频道的消息通知
  static Future<void> muteChannel(String channelId) async {
    List<String> mutedChannels = await Db.userConfigBox.get(mutedChannel);
    mutedChannels ??= [];

    /// 改频道已被设置为屏蔽消息通知
    if (mutedChannels.contains(channelId)) return;

    /// 将改频道加入消息屏蔽列表，并更新本地配置
    mutedChannels.add(channelId);
    await Db.userConfigBox.put(mutedChannel, mutedChannels);
  }
}
