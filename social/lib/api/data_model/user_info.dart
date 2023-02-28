import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:im/api/entity/role_bean.dart';
import 'package:im/api/user_api.dart';
import 'package:im/common/extension/string_extension.dart';
import 'package:im/common/permission/permission.dart';
import 'package:im/db/db.dart';
import 'package:im/loggers.dart';
import 'package:im/pages/guild_setting/role/role.dart';
import 'package:im/pages/home/model/chat_index_model.dart';
import 'package:im/pages/home/model/chat_target_model.dart';

import '../../global.dart';

part 'user_info.g.dart';

enum PresenceStatus {
  offline,
  online,
  free,
  notDisturb,
  unknown,
}

@HiveType(typeId: 0)
class UserInfo extends HiveObject {
  @HiveField(0)
  String userId;
  @HiveField(1)
  String avatar;
  @HiveField(2)
  String nickname;

  /// 服务器昵称，并不是所有 UserInfo 结构体都有
  String gnick;
  @HiveField(3)
  String username;
  @HiveField(4)
  int gender;
  @HiveField(5)
  String phoneNumber;
  @HiveField(6)
  List<String> roles;
  @HiveField(7)
  bool isBot;
  @HiveField(8)
  Map guildNickNames;

  // 数字藏品头像和id
  @HiveField(9)
  String avatarNft;
  @HiveField(10)
  String avatarNftId;

  UserInfo({
    this.userId,
    this.avatar = '',
    this.nickname = '',
    this.gnick = '',
    this.gender = 0,
    this.username = '',
    this.phoneNumber = '',
    this.roles = const [],
    isBot = false,
    this.guildNickNames,
    this.avatarNft = '',
    this.avatarNftId = '',
  }) : isBot = isBot ?? false;

  // 成员列表和用户信息接口返回字段不一致，fromMemberList：是否来自成员列表返回的数据
  // 成员列表 , 无角色：不包含roles字段，有角色：roles:[{'role_id':'111','name':'管理员'}]
  // 用户信息 , 无角色：role_ids:[]，有角色：role_ids:['111']，不在服务器：不包含role_ids字段
  factory UserInfo.fromJson(Map<String, dynamic> json,
          {bool fromMemberList = false}) =>
      UserInfo(
        userId: json['user_id'] as String,
        avatar: json['avatar'] as String,
        nickname: json['nickname_v2'] ?? json['nickname'],
        gnick: json['gnick'] as String,
        roles: () {
          // 成员列表
          if (fromMemberList) {
            if (json['roles'] == null) return <String>[];
            return ((json['roles'] ?? []) as List)
                .map((e) {
                  if (e is Map) {
                    return '${e['role_id']}';
                  } else {
                    return e;
                  }
                })
                .toList()
                .cast<String>();
          } else {
            // 用户信息
            if (!json.containsKey('role_ids') || json['role_ids'] == null)
              return null;
            return ((json['role_ids']) as List).cast<String>();
          }
        }(),
        gender: (json['gender'] ?? 0) as int,
        username: json['username'] as String,
        phoneNumber: (json['mobile'] == "null" ? 0 : json["mobile"]) as String,
        isBot: json["bot"] == true || json["bot"] == 1 || json["bot"] == "1",
        avatarNft: json["avatar_nft"] as String,
        avatarNftId: json["avatar_nft_id"] as String,
      );

  String showName(
      {bool hideGuildNickname = false,
      bool hideRemarkName = false,
      String guildId}) {
    final recordBean = hideRemarkName ? null : Db.remarkBox.get(userId);
    final remarkName = recordBean?.name;
    if (remarkName.hasValue) return remarkName;
    final gId = guildId ?? ChatTargetsModel.instance?.selectedChatTarget?.id;
    final gNickName = hideGuildNickname ? '' : guildNickname(gId);
    return gNickName.isEmpty ? nickname : gNickName;
  }

  String showNameRule(String channelId, {String guildId}) {
    bool hideGuildNickname = false;
    final ChatChannel channel = Db.channelBox.get(channelId);
    if (channel != null) {
      final ChatChannelType type = channel.type;

      ///私信和群聊 长按用户头像 @使用账号昵称
      if (type == ChatChannelType.dm || type == ChatChannelType.group_dm) {
        hideGuildNickname = true;
      }
    }

    return showName(guildId: guildId, hideGuildNickname: hideGuildNickname);
  }

  String guildNickname(String guildId) {
    ///gnick 未存储hive db,服务器实时获取或下发的本服务器昵称
    if (gnick.hasValue) return gnick;
    if (guildNickNames == null || guildNickNames.isEmpty) return '';
    return guildNickNames[guildId] ?? '';
  }

  String get markName => Db.remarkBox.get(userId)?.name ?? "";

  bool isEqual(UserInfo userInfo) {
    return userInfo.username == username &&
        userInfo.gender == gender &&
        userInfo.nickname == nickname &&
        userInfo.avatar == avatar &&
        userInfo.phoneNumber == phoneNumber;
  }

  /// - clone方法，新增属性，也需要在这里新增
  void extend(UserInfo v) {
    if (v.username != null) username = v.username;
    if (v.gender != null) gender = v.gender;
    if (v.nickname != null) nickname = v.nickname;
    if (v.avatar != null) avatar = v.avatar;
    if (v.roles != null) roles = v.roles;
    if (v.phoneNumber != null) phoneNumber = v.phoneNumber;
    if (v.isBot != null) isBot = v.isBot;
    if (v.guildNickNames != null && v.guildNickNames.isNotEmpty) {
      if (guildNickNames == null) {
        guildNickNames = <String, String>{};
      }
      guildNickNames.addAll(v.guildNickNames);
    }
    if (v.avatarNft != null) avatarNft = v.avatarNft;
    if (v.avatarNftId != null) avatarNftId = v.avatarNftId;
  }

  void updateGuildNickNames(Map<String, String> names, {bool needSave = true}) {
    try {
      if (names == null || names.isEmpty) return;
      if (guildNickNames == null) {
        guildNickNames = <String, String>{};
        guildNickNames.addAll(names);
      } else
        guildNickNames.addAll(names);
    } catch (e) {
      logger.finer('服务器昵称更新失败:$e');
    }
    if (needSave) save();
  }

  void removeGuildNickName(String guildId) {
    if (guildNickNames == null || guildNickNames.isEmpty) return;
    if (guildNickNames[guildId] == null) return;
    guildNickNames.remove(guildId);
    save();
  }

  static void set(UserInfo v) {
    final userId = v.userId;
    var userInfo = Db.userInfoBox.get(userId);
    if (userInfo != null)
      userInfo.extend(v);
    else
      userInfo = v;
    if (_futures.containsKey(v.userId)) {
      _futures[v.userId].complete(v);
      _futures.remove(v.userId);
    }

    if (userInfo.isInBox)
      userInfo.save();
    else
      Db.userInfoBox.put(v.userId, userInfo);
  }

  static final Set<String> _fetchQueue = {};
  static Future _fetchFuture;

  static final Map<String, Completer<UserInfo>> _futures = {};

  /// [get] 会优先获取本地缓存的用户信息，如果本地没有数据，才会请求网络，如果 [forceFromNet]
  /// 为 true，则总是去网络获取数据。同时调用[get] 多次，并且本地无缓存的情况下，并不会立即发出
  /// 网络请求。在 100ms 内如果没有更多的调用，才会组合所有的请求 id，调用一次网络请求。因此严
  /// 禁在代码中使用类似下面的代码:
  /// ```
  /// for id in ids {
  ///   final userInfo = await UserInfo.get(id);
  /// }
  /// ```
  /// 因为这会导致自动组合的并行能力丢失，变成串行，不仅大大增加等待时间，更会发起大量的网络请求。
  ///
  /// 如果获取用户信息是用来显示头像或者昵称，应该优先使用 [RealtimeNickname] 和
  /// [RealtimeAvatar] 组件
  static Future<UserInfo> get(String userId, {bool forceFromNet = false}) {
    assert(userId != null, "It's impossible to occur here.");

    // TODO: 4/2/21 处理空数据
    if ((Db.userInfoBox?.containsKey(userId) ?? false) && !forceFromNet) {
      return Future.value(Db.userInfoBox.get(userId));
    }
    if (_futures.containsKey(userId)) {
      return _futures[userId].future;
    }
    final c = _futures[userId] = Completer<UserInfo>();
    _fetchQueue.add(userId);
    _fetchFuture ??= Future.delayed(const Duration(milliseconds: 100), () {
      final tmpIds = Set.from(_fetchQueue);
      UserApi.getUserInfo(_fetchQueue.toList(),
              autoRetryIfNetworkUnavailable: true)
          .then((info) {
        info.forEach((v) {
          tmpIds.remove(v.userId);
          set(v);
        });
        tmpIds.forEach((v) {
          _futures[v].complete(null);
          _futures.remove(v);

          /// 获取失败说明用户不存在，依然需要在 db 中保存空值，防止下次重复请求
          Db.userInfoBox.put(v, null);
        });
      }).catchError((e) {
        tmpIds.forEach(_futures.remove);
        return null;
      });
      _fetchQueue.clear();
      _fetchFuture = null;
    });

    return c.future;
  }

  static Widget consume(
    String userId, {
    String guildId,
    ValueWidgetBuilder<UserInfo> builder,
    Widget child,
    // 高度设置为1，空的SizedBox会导致用户信息弹窗内容为空没法收起
    Widget placeHolder = const SizedBox(
      height: 1,
    ),
  }) {
    // TODO: 4/2/21 处理空数据
    if (guildId?.hasValue ??
        true || !Db.userInfoBox?.containsKey(userId) ??
        true) getUserInfoRoles(userId, guildId: guildId);

    return ValueListenableBuilder<Box<UserInfo>>(
      valueListenable: Db.userInfoBox.listenable(keys: [userId]),
      builder: (c, box, child) {
        final userInfo = box.get(userId);
        if (userInfo == null) return placeHolder;
        return builder(c, userInfo, child);
      },
      child: child,
    );
  }

  static Future<UserInfo> getUserInfoRoles(String userId, {String guildId}) {
    if (guildId == null) {
      return get(userId);
    }
    if (guildId == null || guildId.isEmpty) return Future.value();

    final futureKey = 'key_$userId${guildId ?? ''}';
    if (_futures.containsKey(futureKey)) {
      return _futures[futureKey].future;
    }
    final c = _futures[futureKey] = Completer<UserInfo>();
    _fetchQueue.add(userId);
    _fetchFuture ??= Future.delayed(const Duration(milliseconds: 100), () {
      final tmpIds = Set.from(_fetchQueue);
      UserApi.getUserInfo(_fetchQueue.toList(),
              guildId: guildId, autoRetryIfNetworkUnavailable: true)
          .then((info) {
        info.forEach((v) {
          tmpIds.remove(v.userId);
          set(v);
          if (guildId.hasValue) {
            RoleBean.update(v.userId, guildId, v.roles);
          }
        });
        tmpIds.forEach((v) {
          _futures[v].complete(null);
          _futures.remove(v);
        });
      }).catchError((e) {
        tmpIds.forEach(_futures.remove);
        return null;
      });
      _fetchQueue.clear();
      _fetchFuture = null;
    });

    return c.future;
  }

  ///监听多个userId，来构建Widget
  static Widget getUserIdListWidget(
    List<String> userIdList, {
    String guildId,
    ValueWidgetBuilder<Map<String, UserInfo>> builder,
    Widget placeHolder = const SizedBox(
      height: 1,
    ),
  }) {
    if (userIdList == null || userIdList.isEmpty) return placeHolder;
    userIdList.forEach((id) {
      getUserInfoForGuild(id, guildId);
    });
    return ValueListenableBuilder<Box<UserInfo>>(
      valueListenable: Db.userInfoBox.listenable(keys: userIdList),
      builder: (c, box, child) {
        Map<String, UserInfo> map = {};
        bool allGet = true;
        userIdList.forEach((id) {
          if (box.get(id) == null) {
            allGet = false;
          } else {
            map[id] = box.get(id);
          }
        });
        if (!allGet) return placeHolder;
        return builder(c, map, child);
      },
    );
  }

  static Future _guildUserFuture;
  static final Map<int, Map<String, Set<String>>> _guildUserInfoQueue = {};
  static int _queueIndex = 0;

  ///获取用户的UserInfo 和 服务器昵称
  static Future<UserInfo> getUserInfoForGuild(String userId, String guildId) {
    if (guildId.noValue) {
      return get(userId);
    }
    if (Db.userInfoBox?.containsKey(userId) ?? false) {
      return Future.value(Db.userInfoBox.get(userId));
    }

    final futureKey = '$guildId-$userId';
    if (_futures.containsKey(futureKey)) {
      return _futures[futureKey].future;
    }

    final c = _futures[futureKey] = Completer<UserInfo>();
    Map<String, Set<String>> idSetMap = _guildUserInfoQueue[_queueIndex];
    if (idSetMap == null) {
      idSetMap = _guildUserInfoQueue[_queueIndex] = {};
    }
    Set<String> idSet = idSetMap[guildId];
    if (idSet == null) {
      idSet = idSetMap[guildId] = {};
    }
    idSet.add(userId);

    _guildUserFuture ??= Future.delayed(const Duration(milliseconds: 100), () {
      final tmpQueueIndex = _queueIndex;
      final tmpIdSetMap = _guildUserInfoQueue[_queueIndex];
      _queueIndex++;
      _guildUserFuture = null;

      //清理 _futures
      void _futuresRemove() {
        tmpIdSetMap?.forEach((gId, set) {
          set?.forEach((uId) {
            final _futureKey = '$gId-$uId';
            _futures[_futureKey].complete(null);
            _futures.remove(_futureKey);
          });
        });
      }

      UserApi.getUserInfoForGuild(tmpIdSetMap,
              autoRetryIfNetworkUnavailable: true)
          .then((data) {
        data.forEach((gId, list) {
          list.forEach((user) {
            _setUserInfoForGuild(user, gId);
            tmpIdSetMap[gId].remove(user.userId);
          });
        });
        _futuresRemove();
      }).catchError((e) {
        _futuresRemove();
        return null;
      });
      _guildUserInfoQueue.remove(tmpQueueIndex);
      // debugPrint('getChat gu _guildUserInfoQueue.length: ${_guildUserInfoQueue.length}');
    });

    return c.future;
  }

  static void _setUserInfoForGuild(UserInfo v, String guildId) {
    final userId = v.userId;
    var userInfo = Db.userInfoBox.get(userId);
    if (userInfo != null)
      userInfo.extend(v);
    else
      userInfo = v;

    final futureKey = '$guildId-$userId';
    if (_futures.containsKey(futureKey)) {
      _futures[futureKey].complete(userInfo);
      _futures.remove(futureKey);
    }

    if (userInfo.isInBox)
      userInfo.save();
    else
      Db.userInfoBox.put(v.userId, userInfo);
  }

  static Widget withRoles(
    String userId, {
    ValueWidgetBuilder<List<Role>> builder,
    Widget child,
    Widget placeHolder = const SizedBox(),
  }) {
    final chatTargetId = ChatTargetsModel.instance.selectedChatTarget?.id;
    return ValueListenableBuilder<Box<GuildPermission>>(
      valueListenable: Db.guildPermissionBox.listenable(keys: [chatTargetId]),
      builder: (c, box, widget) {
        return consume(userId, guildId: chatTargetId, builder: (c, user, w) {
          final roles = (box.get(chatTargetId)?.roles ?? [])
              .where((element) => (user?.roles ?? []).contains(element.id))
              .toList();
          return builder(c, roles, widget);
        });
      },
    );
  }

  static Widget withUserRoles(
    UserInfo user, {
    ValueWidgetBuilder<List<Role>> builder,
    Widget child,
    Widget placeHolder = const SizedBox(),
  }) {
    final chatTargetId = ChatTargetsModel.instance.selectedChatTarget?.id;
    return ValueListenableBuilder<Box<GuildPermission>>(
      valueListenable: Db.guildPermissionBox.listenable(keys: [chatTargetId]),
      builder: (c, box, widget) {
        final roles = (box.get(chatTargetId)?.roles ?? [])
            .where((element) => (user?.roles ?? []).contains(element.id))
            .toList();
        return builder(c, roles, widget);
      },
    );
  }

  /// - user新增属性是否也需要在这里新增，别人写的有待研究。最好测试一下
  /// - 有如下场景：
  /// - 1、聊天列表发送变化的ws通知
  /// - 2、获取聊天列表
  /// - 3、圈子详情更新用户头像
  static void updateIfChanged({
    @required String userId,
    String nickname,
    String username,
    String avatar,
    String gNick,
    String guildId,
    String avatarNft,
    String avatarNftId,
    bool isBot,
  }) {
    try {
      final Map<String, String> guildNicknameMap = {};
      if (gNick.hasValue && guildId.hasValue) guildNicknameMap[guildId] = gNick;
      if (Db.userInfoBox.containsKey(userId)) {
        final userInfo = Db.userInfoBox.get(userId);
        bool needSave = false;
        if (nickname != null && userInfo.nickname != nickname) {
          needSave = true;
          userInfo.nickname = nickname;
        }
        if (username != null && userInfo.username != username) {
          needSave = true;
          userInfo.username = username;
        }
        if (avatar != null && userInfo.avatar != avatar) {
          needSave = true;
          userInfo.avatar = avatar;
        }
        //nft头像取消的时候是null
        if (avatarNft != null && userInfo.avatarNft != avatarNft) {
          needSave = true;
          userInfo.avatarNft = avatarNft;
        }
        if (avatarNftId != null && userInfo.avatarNftId != avatarNftId) {
          needSave = true;
          userInfo.avatarNftId = avatarNftId;
        }

        if (guildId.hasValue) {
          final tempGuildNick = gNick ?? '';
          final localGuildNick = userInfo.guildNickname(guildId ?? '');
          if (tempGuildNick != localGuildNick) needSave = true;
          if (tempGuildNick.isNotEmpty)
            userInfo.updateGuildNickNames(guildNicknameMap, needSave: false);

          ///之前的版本中，离线进入app会出现调用[updateIfChanged]并且[gNick]为空，导致服务器昵称被删除的情况
          ///当前版本未复现，所以重新加上下面的逻辑
          else if (tempGuildNick.isEmpty && userId != Global.user.id)
            userInfo.removeGuildNickName(guildId);
        }
        if (needSave) userInfo.save();
      } else {
        Db.userInfoBox.put(
            userId,
            UserInfo(
              userId: userId,
              nickname: nickname,
              username: username,
              avatar: avatar,
              guildNickNames: guildNicknameMap,
              isBot: isBot,
              avatarNft: avatarNft,
              avatarNftId: avatarNftId,
            ));
      }
    } catch (_) {}
  }
}
