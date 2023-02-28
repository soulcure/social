import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:im/api/api.dart';
import 'package:im/api/data_model/user_info.dart';
import 'package:im/api/entity/create_template.dart';
import 'package:im/api/entity/credits_bean.dart';
import 'package:im/api/entity/guild_template.dart';
import 'package:im/api/entity/sticker_bean.dart';
import 'package:im/api/entity/user_config.dart';
import 'package:im/app/modules/mute/controllers/mute_listener_controller.dart';
import 'package:im/common/extension/string_extension.dart';
import 'package:im/common/permission/permission_model.dart';
import 'package:im/core/config.dart';
import 'package:im/core/http_middleware/http.dart';
import 'package:im/db/db.dart';
import 'package:im/loggers.dart';
import 'package:im/pages/home/json/text_chat_json.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/utils/sticker_util.dart';
import 'package:im/ws/ws.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:oktoast/oktoast.dart';
import 'package:tuple/tuple.dart';

import '../global.dart';
import '../loggers.dart';

part 'guild_api.g.dart';

@JsonSerializable()
class DmGroupRecipientIcon {
  DmGroupRecipientIcon({
    this.userId,
    this.avatar,
  });

  @JsonKey(name: "user_id")
  String userId;
  String avatar;

  factory DmGroupRecipientIcon.fromJson(Map<String, dynamic> json) =>
      DmGroupRecipientIcon(
        userId: json["user_id"],
        avatar: json["avatar"],
      );

  Map<String, dynamic> toJson() => {
        "user_id": userId,
        "avatar": avatar,
      };
}

class DmGroupRecipientIconAdapter extends TypeAdapter<DmGroupRecipientIcon> {
  @override
  final int typeId = 18;

  @override
  DmGroupRecipientIcon read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DmGroupRecipientIcon(
      userId: fields[0] as String,
      avatar: fields[1] as String,
    );
  }

  @override
  void write(BinaryWriter writer, DmGroupRecipientIcon obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.userId)
      ..writeByte(1)
      ..write(obj.avatar);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DmGroupRecipientIconAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// todo 继承 chatchannel
@JsonSerializable()
class DirectMessageStruct {
  @JsonKey(name: 'guild_id')
  String guildId;
  @JsonKey(name: 'channel_id')
  String channelId;
  @JsonKey(name: 'recipient_id')
  String recipientId;
  @JsonKey(name: 'offline')
  int numUnread;
  int top;

  ///部落群聊新增字段
  String icon; //图标
  String name; //名称
  // todo 使用枚举
  @JsonKey(defaultValue: 3)
  int type; //类型
  @JsonKey(name: 'user_icon')
  List<DmGroupRecipientIcon> userIcons;

  ///状态：0 打开; 1 关闭
  int status;

  DirectMessageStruct({
    this.guildId,
    this.channelId,
    this.recipientId,
    this.numUnread,
    this.top,
    this.icon,
    this.name,
    this.type,
    this.userIcons,
    this.status,
  });

  factory DirectMessageStruct.fromJson(Map<String, dynamic> srcJson) =>
      _$DirectMessageStructFromJson(srcJson);

  Map<String, dynamic> toJson() => _$DirectMessageStructToJson(this);
}

class GuildApi {
  /// 返回欢迎消息，加入服务器的欢迎由此接口返回，不能依赖于 ws 获取，因为此时去获取，服务器可能还没把欢迎消息存入到数据库，但是也可能存入了
  static Future<MessageEntity> join(
      {String guildId, String userId, String c, String postId}) async {
    final res = await Http.request(
      '/api/guild/join',
      data: {
        'guild_id': guildId,
        'user_id': userId,
        'c': c,
        'post_id': postId,
      },
    );
    return MessageEntity.fromJson(res);
  }

  ///获取服务端的消息频道列表(增量)
  static Future<Tuple2<List<DirectMessageStruct>, int>> getDmList(
      {String userId}) async {
    Tuple2<List<DirectMessageStruct>, int> returnTuple2;

    ///参数last_time: 服务端只返回last_time之后有更新的私信和群聊频道,为空则返回所有
    final dmList2Time = Db.userConfigBox.get(UserConfig.dmList2Time);
    logger.info('dmList2 - param dmList2Time:$dmList2Time');
    final result = await Http.request('/api/dm/dmList2',
        data: {'user_id': userId, 'last_time': dmList2Time},
        autoRetryIfNetworkUnavailable: true,
        cancelToken: AutoCancelToken.get(AutoCancelType.dmList));
    final List<DirectMessageStruct> dmList = [];
    int time;
    if (result is Map) {
      time = result['time'];
      final List data = result['lists'];
      if (data != null && data.isNotEmpty) {
        for (final e in data) {
          try {
            // print('getChat struct-item: $e');
            dmList.add(DirectMessageStruct.fromJson(e));
          } catch (e, s) {
            // print('dmList2 error: $e');
            logger.severe('dmList2解析报错', e, s);
          }
        }
      }
    }
    returnTuple2 = Tuple2(dmList, time);
    logger.info('getChat dmList2 - length:${dmList.length}');
    return returnTuple2;
  }

  static Future<int> getGuildMemberCount(String guildId) async {
    final cnt = await Http.request(
        '${Config.memberListUri}/api/guild/memberCount',
        data: {
          'guild_id': guildId,
        });
    if (cnt is int) {
      return cnt;
    } else {
      throw Exception("数据类型错误".tr);
    }
  }

  // static Future<dynamic> getGroupMemberList(
  //     String channelId, String userId, List<Map<String, int>> paramRanges,
  //     {bool notsync, bool showDefaultErrorToast = false}) async {
  //   ///兼容部落群聊
  //   final data = {
  //     'guild_id': channelId,
  //     'channel_id': channelId,
  //     'user_id': userId,
  //     'ranges': paramRanges,
  //     'notsync': notsync,
  //     'ctype': 9,
  //   };
  //
  //   final result = await Http.request(
  //     '${Config.memberListUri}/api/dm/members',
  //     data: data,
  //     showDefaultErrorToast: showDefaultErrorToast,
  //   );
  //
  //   return result;
  // }

  static Future<ChatChannel> getGroupInfo(String channelId) async {
    ///兼容部落群聊
    final data = {'channel_id': channelId};

    final result = await Http.request('/api/channel/info', data: data);

    return ChatChannel.fromJson(result);
  }

  static Future<dynamic> getSegmentMemberList(String guildId, String channelId,
      String userId, List<Tuple2<int, int>> ranges,
      {int channelType,
      bool notsync,
      bool showDefaultErrorToast = false}) async {
    final List<Map<String, int>> paramRanges =
        ranges.map((e) => {'start': e.item1, 'end': e.item2}).toList();

    final data = {
      'guild_id': guildId,
      'channel_id': channelId,
      'user_id': userId,
      'ranges': paramRanges,
    };

    if (notsync != null) {
      data["notsync"] = notsync;
    }

    if (channelType != null) {
      data["channel_type"] = channelType;
    }

    // // ///兼容部落群聊
    // if (guildId == "0") {
    //   // data['ctype'] = ChatChannelType.group_dm.index;
    //   // data['guild_id'] = channelId;
    //   data['channel_type'] = ChatChannelType.group_dm.index;
    // }

    final result = await Http.request(
      '${Config.memberListUri}/api/guild/getMember/v2',
      data: data,
      showDefaultErrorToast: showDefaultErrorToast,
    );

    return result;
  }

  static Future<List<UserInfo>> getMemberList(
      {String guildId, String userId}) async {
    final List result = await Http.request(
      '/api/guild/getMember',
      data: {
        'guild_id': guildId,
        'user_id': userId,
      },
    );

    final List<UserInfo> memberList = result?.map<UserInfo>((e) {
          if (e != null && (e['relate_guild'] != null || e['credits'] != null))
            CreditsBean.saveBean(e['user_id'], guildId,
                credits: e['credits'], relatedGuilds: e['relate_guild']);
          return e == null
              ? null
              : UserInfo.fromJson(e as Map<String, dynamic>);
        })?.toList() ??
        const [];

    /// 刷新本地缓存
    memberList.forEach(UserInfo.set);

    await Db.memberListBox
        .put(guildId, memberList.map((e) => e.userId).toList());

    return memberList;
  }

  static Future createGuild(
      {String name,
      String icon,
      String userId,
      String batchGuidType = '',
      String banner = '',
      String templateId = '',
      bool showDefaultErrorToast = true}) async {
    final res = await Http.request('/api/guild/create',
        showDefaultErrorToast: showDefaultErrorToast,
        data: {
          'name': name,
          'icon': icon,
          'user_id': userId,
          'batch_guild_type': batchGuidType,
          'banner': banner,
          'template_id': templateId,
        });
    return res;
  }

  static Future checkCreateGuild({
    String userId,
    bool showDefaultErrorToast,
    bool isOriginDataReturn,
  }) async {
    final res = await Http.request(
      '/api/guild/CheckCreateGuild',
      showDefaultErrorToast: showDefaultErrorToast,
      data: {'user_id': userId},
      isOriginDataReturn: isOriginDataReturn,
    );
    return res;
  }

  /// 获取服务器默认频道接口
  static Future<List<CreateTemplate>> getGuildChannelTemplate(
      {String guildType = '', String version = ''}) async {
    final List result = await Http.request('/api/guild/GetChannelTemplate',
        showDefaultErrorToast: true,
        data: {'guild_type': guildType, 'version': version});
    return result.map((e) => CreateTemplate.fromJson(e)).toList();
  }

  ///60版本创建服务器获取模版接口
  static Future<List<GuildTemplate>> getGuildTemplate(
      {String version = ''}) async {
    final List result = await Http.request(
      '/api/guild/getGuildTemplate',
      data: {'version': version},
    );
    return result.map((e) => GuildTemplate.fromJson(e)).toList();
  }

  static Future dissolveGuild(
    String userId,
    String guildId,
  ) {
    return Http.request("/api/guild/del", showDefaultErrorToast: true, data: {
      "user_id": userId,
      "guild_id": guildId,
    });
  }

  static Future quitGuild(
    String userId,
    String guildId,
  ) {
    return Http.request("/api/guild/quitGuild",
        showDefaultErrorToast: true,
        data: {
          "user_id": userId,
          "guild_id": guildId,
        });
  }

  static Future<GuildTarget> getFullGuildInfo(
      {String guildId, String userId}) async {
    final res = await Http.request("/api/guild/getGuild",
        data: {'user_id': userId, 'guild_id': guildId});

    // TODO 这个不能放这儿
    PermissionModel.initGuildPermission(
      guildId: res["guild_id"],
      ownerId: res["owner_id"],
      permissions: res['permissions'],
      userRoles: res['userRoles'],
      channels: res['channels'],
      roles: res['roles'],
    );

    return GuildTarget.fromJson(res);
  }

  static Future<Tuple2<List<GuildTarget>, String>> getGuildList(
      {String userId}) async {
    ///myGuild2接口增加参数hash：服务端通过判断hash，决定是否返回空(204)
    final myGuild2Hash = Db.userConfigBox.get(UserConfig.myGuild2Hash);
    logger.info('myGuild2 - param myGuild2Hash:$myGuild2Hash');
    final res = await Http.request('/api/guild/myGuild2',
        data: {'user_id': userId, 'hash': myGuild2Hash},
        autoRetryIfNetworkUnavailable: true,
        cancelToken: AutoCancelToken.get(AutoCancelType.myGuild2));
    if (res == null) return null;

    ///兼容：旧版本格式List
    List list;
    String hash;
    if (res is List) {
      if (res.isEmpty) return null;
      list = res;
    } else {
      final map = res as Map;

      ///容错：防止map为空
      if (map.isEmpty) return null;
      hash = map['hash'];
      list = map['lists'];
    }

    // print('getChat myGuild2 2 hash: $hash');
    return Tuple2<List<GuildTarget>, String>(
        list.whereType<Map>().toList().map<GuildTarget>((v) {
          PermissionModel.initGuildPermission(
            guildId: v["guild_id"],
            ownerId: v["owner_id"],
            permissions: v['permissions'],
            userRoles: v['userRoles'],
            channels: v['channels'],
            roles: v['roles'],
          );
          final guildId = v["guild_id"];
          final emojis = v['emojis'];
          final gnick = v['gnick'];
          if (gnick != null) {
            final user = Db.userInfoBox.get(Global.user.id);
            user?.updateGuildNickNames({guildId: gnick});
          } else {
            final user = Db.userInfoBox.get(Global.user.id);
            user?.removeGuildNickName(guildId);
          }
          final emoList = StickerBean.fromMapList(emojis);
          if (emoList.isEmpty) {
            StickerUtil.instance.addGuildToSet(guildId);
          } else
            StickerUtil.instance.setStickerById(v["guild_id"], emoList);

          // 将禁言时间缓存到内存
          MuteListenerController.myMuteTimeMap[guildId] = v["no_say"] ?? 0;

          return GuildTarget.fromJson(v)..sortChannels();
        }).toList(),
        hash);
  }

  static Future getGuildInfo(
      {String guildId,
      String userId,
      bool showDefaultErrorToast = false}) async {
    final res = await Http.request('/api/guild/getInfo',
        showDefaultErrorToast: showDefaultErrorToast,
        data: {
          'guild_id': guildId,
          "user_id": userId,
        });
    return res;
  }

  static Future<void> removeUser({
    String guildId,
    String userId,
    String userName = "",
    String memberId,
    bool showDefaultErrorToast = true,
    bool isOriginDataReturn = false,
    bool ban = false,
    String blackReason,
  }) async {
    final res = await Http.request("/api/guild/removeUser",
        showDefaultErrorToast: showDefaultErrorToast,
        isOriginDataReturn: isOriginDataReturn,
        data: {
          "guild_id": guildId,
          "user_id": userId,
          "member_id": memberId,
          "ban": ban ? 1 : 0,
          if (ban && blackReason.hasValue) "black_reason": blackReason,
        });
    if (res is Map && res.isEmpty) return;
    final errorCode = res["code"];
    if (errorCode == 1007) {
      showToast("%s已不存在当前服务器，请退出重试".trArgs([userName]));
      throw RequestArgumentError(1007,
          message: errorCode2Message['1007'] ?? '');
    } else {
      final errMsg = errorCode2Message['$errorCode'] ?? res["desc"] ?? '';
      showToast(errMsg);
      throw RequestArgumentError(errorCode, message: errMsg);
    }
  }

  static Future updateGuildConfig(
      {String guildId,
      String userId,
      String systemChannelId,
      int systemChannelFlags}) async {
    final res = await Http.request("/api/guildManage/guildJoinSet",
        showDefaultErrorToast: true,
        data: {
          "guild_id": guildId,
          "user_id": userId,
          "system_channel_id": systemChannelId,
          "system_channel_flags": systemChannelFlags,
        });
    return res;
  }

  static Future updateGuildInfo(String guildId, String userId,
      {String icon,
      String banner,
      String name,
      String description,
      bool isWelcomeOn,
      List<String> welcome,
      bool showDefaultErrorToast = false}) async {
    final res = await Http.request("/api/guild/up",
        showDefaultErrorToast: showDefaultErrorToast,
        data: {
          "guild_id": guildId,
          "user_id": userId,
          if (icon != null) 'icon': icon,
          if (banner != null) 'banner': banner,
          if (description != null) 'description': description,
          if (name != null) 'name': name,
          if (isWelcomeOn != null) "welcome_switch": isWelcomeOn,
          if (welcome != null) "welcome": welcome,
        });
    return res;
  }

  static Future<List<UserInfo>> searchMembers(
    String guildId,
    String key, {
    bool isNeedRoles = false,
    String channelId,
  }) async {
    final Map params = {
      "q": key,
      "guild_id": guildId,
      "action": "q",
    };
    if (isNeedRoles) {
      params["r"] = "1";
    }
    if (channelId != null) {
      params['channel_id'] = channelId;
      params["r"] = "0";
    }
    try {
      final res = await Ws.instance.send(params);
      return res?.map<UserInfo>((json) {
        final String guildNickName = json["gnick"];
        final Map<String, String> guildNickNames = {};
        if (guildNickName != null && guildNickName.isNotEmpty) {
          guildNickNames[guildId] = guildNickName;
        }
        return UserInfo.fromJson(json)..guildNickNames = guildNickNames;
      })?.toList();
    } catch (e, s) {
      logger.severe(e.toString(), s);
    }
    return const [];
  }

  static Future setGuildNickname(String guildId, {String nick = ''}) async {
    final res = await Http.request("/api/guild/nick", data: {
      "guild_id": guildId,
      "nick": nick,
    });
    return res;
  }

  static Future setGuildFeatures(String guildId,
      {List featureList = const ["GUEST"], int status = 0}) async {
    return Http.request("/api/guildManage/guildFeatures",
        showDefaultErrorToast: true,
        data: {
          "guild_id": guildId,
          "feature_list": featureList,
          "status": status,
        });
  }

  ///检查成员是否还在服务器中
  static Future<Map> checkGuildMembers(
      {String guildId,
      List<String> userIds,
      bool showErrorToast = false}) async {
    final res = await Http.request(
        "${Config.memberListUri}/api/guild/participants",
        showDefaultErrorToast: showErrorToast,
        data: {
          "guild_id": guildId,
          "channel_type": ChatChannelType.guildText.index,
          "user_ids": userIds,
        });
    return res;
  }
}
