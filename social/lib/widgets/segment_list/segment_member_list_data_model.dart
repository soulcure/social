import 'dart:async';
import 'dart:convert';

import 'package:get/get.dart';
import 'package:im/api/data_model/user_info.dart';
import 'package:im/api/entity/credits_bean.dart';
import 'package:im/common/extension/string_extension.dart';
import 'package:im/db/db.dart';
import 'package:im/pages/home/json/text_chat_json.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/widgets/segment_list/segment_member_list_service.dart';
import 'package:im/ws/ws.dart';
import 'package:rxdart/rxdart.dart';
import 'package:tuple/tuple.dart';

import '../../loggers.dart';

typedef UpdateCallback = void Function();

class SegmentMemberListDataModel {
  final String guildId;

  String get channelId => _channelId;
  String _channelId;

  ChatChannelType get channelType => _channelType;
  ChatChannelType _channelType;

  // 数据是否为最新的，如果不是最新，在使用时，需要更新
  bool isUpToDate = false;
  RxInt notify = RxInt(0);

  // UpdateCallback updateCallback;

  // 是否第一次拉取数据
  bool _isFirstReq = true;
  final Completer<void> _initialized = Completer();

  Future<void> get initialized => _initialized.future;

  int _itemCount = 0;

  int get itemCount => _itemCount;

  int _memberCount = 0;

  int get memberCount => _memberCount;

  int _guildCount = 0;

  int get guildCount => _guildCount;

  // 列表数据
  final List _itemList = [];

  List get itemList => _itemList;

  // 分组数据
  List _groups = [];
  Map _groupMap = {};

  Map get groupMap => _groupMap;

  // final Map _listenerMap = {};
  // void addListener(obj, UpdateCallback callback){
  //   _listenerMap[obj] = callback;
  // }
  // void removeListener(obj){
  //   _listenerMap.remove(obj);
  // }

  BehaviorSubject<List<int>> _sendSubject;

  void changeToPublic() {
    _channelId = "0";
  }

  Future refresh({List<int> pages}) async {
    if (pages == null) {
      _sendSubject.add(_sendSubject.value);
    } else {
      _sendSubject.add(pages);
    }
  }

  bool onlyFirstSegment() {
    if (_itemList.length < SegmentMemberListService.segmentSize) {
      return true;
    } else {
      return false;
    }
  }

  void sendNotify() {
    notify.value = notify.value + 1;
    // if(updateCallback != null) {
    //   updateCallback();
    // }
  }

  Future requestRemoteData(List<int> pages) async {
    final resp = await SegmentMemberListService.to
        .reqSegmentData(guildId, channelId, pages, channelType: channelType);
    _updateFromHttpData(resp);
    if (_isFirstReq) {
      _initialized.complete();
      _isFirstReq = false; // 在处理完服务器端数据之后，设置这个标志。阻止多次调用请求接口
    }
  }

  void updateFromWsMessage(WsMessage message) {
    if (message == null) return;
    final Map data = message.data;
    final guildId = "${data['guild_id']}";
    // if (guildId == null || guildId != this.guildId) return;
    final channelId = "${data['channel_id']}"; //使用服务器端的 channel_id
    if (channelId == null) return;
    if (channelId == "0") {
      if (!SegmentMemberListService.to
          .isChannelActuallyPublic(guildId, this.channelId)) return;
    } else {
      if (channelId != this.channelId) return;
    }

    switch (message.action) {
      case MessageAction.memberList:
        {
          _itemCount = data['item_count'] ?? 0;
          // _itemList.length = _itemCount;
          _memberCount = data['member_count'] ?? 0;
          _guildCount = data['guild_count'] ?? 0;
          _groups = data['groups'] as List;
          _groupMap = Map.fromEntries(
              _groups.map((e) => MapEntry(e["id"], e)).toList());

          final List ops = data['ops'];
          final String guildId = data['guild_id'];

          _applyOpt(guildId, ops);
          _persistenceData();
          isUpToDate = true;
        }
        break;
      case MessageAction.roleUp:
        {
          // 角色变更，本地搜索角色数据，更新
          final roles = data["roles"];
          _updateRolesMemCacheInfo(roles);
        }
        break;
    }
    isUpToDate = true;
    sendNotify();
  }

  void _updateFromHttpData(Map resp) {
    if (resp == null) return;

    _itemCount = resp['item_count'] ?? 0;
    _itemList.length = _itemCount;
    _memberCount = resp['member_count'] ?? 0;
    _guildCount = resp['guild_count'] ?? 0;
    _groups = resp['groups'] as List;
    _groupMap =
        Map.fromEntries(_groups.map((e) => MapEntry(e["id"], e)).toList());

    final opts = resp['ops'];
    final String guildId = resp['guild_id'];
    _applyOpt(guildId, opts);
    _persistenceData();
    isUpToDate = true;
    sendNotify();
  }

  void _updateRolesMemCacheInfo(Map roles) {
    final roleId = roles["role_id"];
    final name = roles["name"];
    _itemList.forEach((item) {
      if (item['Group'] != null && item['Group']['id'] == roleId) {
        if (name != null) item['Group']['name'] = name;
      }
    });
    _groups.forEach((g) {
      if (g["id"] == roleId) {
        if (name != null) g['name'] = name;
      }
    });
  }

  void _applyOpt(String guildId, List opts) {
    opts.forEach((element) {
      final String opt = element["op"];
      switch (opt) {
        case 'SYNC':
          {
            // 同步数据，直接记录情况
            final Tuple2<int, int> range =
                Tuple2(element['range'][0], element['range'][1]);
            if ((range.item2 - range.item1) >
                SegmentMemberListService.segmentSize) return; //范围超过页大小，异常
            // 因为服务器给过来的列表大小，是操作完成之后的，因此旧的数组可能越界。所以先给扩容，操作完成之后，设置回服务器端返回的值
            if (range.item2 >= _itemList.length) {
              _itemList.length =
                  _itemList.length + SegmentMemberListService.segmentSize;
            }
            //  关于为什么end的值要加1，请查看replaceRange的描述
            _itemList.replaceRange(
                range.item1, range.item2 + 1, element['items']);
          }
          break;
        case 'INSERT':
          {
            final index = element['index'];
            final items = element['items'];

            //插入数据
            // 因为服务器给过来的列表大小，是操作完成之后的，因此旧的数组可能越界。所以先给扩容，操作完成之后，设置回服务器端返回的值
            if (index >= _itemList.length) {
              _itemList.length = index + SegmentMemberListService.segmentSize;
            }
            _itemList.insertAll(index, items);

            if (items is List) insertNewUserInfo(guildId, items);
          }
          break;
        case 'REMOVE':
          {
            final index = element['index'];
            // 因为服务器给过来的列表大小，是操作完成之后的，因此旧的数组可能越界。所以先给扩容，操作完成之后，设置回服务器端返回的值
            if (index >= _itemList.length) {
              _itemList.length = index + SegmentMemberListService.segmentSize;
            }
            _itemList.removeAt(index);
          }
          break;
      }
    });
    _itemList.length = _itemCount;
  }

  ///如果有推送服务器新的用户信息，存储到userInfoBox
  void insertNewUserInfo(String guildId, List list) {
    if (list == null || list.isEmpty) return;

    for (final item in list) {
      final Map map = item['User'];
      if (map == null) continue;

      final String userId = map['user_id'];
      final String avatar = map['avatar'];
      final String avatarNft = map['avatar_nft'] ?? '';
      final String avatarNftId = map['avatar_nft_id'] ?? '';

      //gnick 是服务器昵称
      //nickname可能是服务器昵称，也可能是用户昵称,如果服务器昵称 和用户昵称都有 nickname是服务器昵称 否则用户昵称
      //nickname_v2用户昵称

      /// 目前服务器是使用 nickname_v2 字段代替 nickname，理论上 nickname 是没用的
      /// 不过未来使用 nickname 替换会 nickname_v2 是合理的，所以这里处理了这种情况
      final String nickname = map['nickname_v2'] ?? map['nickname'];
      final String gNickName = map['gnick'];

      if (userId.noValue) continue;

      /// 本地没有此用户数据，说明除了成员列表，其他地方都没用到，不保存用户信息
      if (!Db.userInfoBox.containsKey(userId)) continue;

      UserInfo.updateIfChanged(
        userId: userId,
        avatar: avatar,
        nickname: nickname,
        gNick: gNickName,
        guildId: guildId,
        avatarNft: avatarNft,
        avatarNftId: avatarNftId,
      );
    }
  }

  void _persistenceData() {
    // 首页数据
    final String saveKey = "$guildId-$channelId-0";
    final Map archiveData = {};
    archiveData['segment_0_items'] =
        //  关于为什么end的值要加1，请查看sublist的描述
        _itemList.length > 99 ? _itemList.sublist(0, 100) : _itemList;

    // Info数据
    archiveData['guild_id'] = guildId;
    archiveData['channel_id'] = channelId;
    archiveData['item_count'] = _itemCount;
    archiveData['member_count'] = _memberCount;
    // groups数据
    archiveData['groups'] = _groups;

    try {
      final valueStr = jsonEncode(archiveData);
      Db.segmentMemberListBox.put(saveKey, valueStr);
    } catch (e, s) {
      // 忽略异常
      logger.severe("_persistenceData", e, s);
    }

    // 存储用户数据
    try {
      _itemList.forEach((item) {
        if (item != null && item["User"] != null) {
          ///处理游戏卡片绑定数据
          final user = item['User'];
          final userId = user['user_id'];
          final Map credits = user['credits'];
          final Map relatedGuilds = user['related_guilds'];

          // TODO 更新数据
          // if (credits != null || relatedGuilds != null)
          CreditsBean.saveBean(userId, guildId,
              credits: credits, relatedGuilds: relatedGuilds);
        }
      });
    } catch (e) {
      logger.warning("archive error:$e");
    }
  }

  SegmentMemberListDataModel(this.guildId, this._channelId,
      {bool initWithPersistenceData = true, ChatChannelType channelType}) {
    _itemCount = 0;
    _memberCount = 0;

    if (channelType != null) {
      _channelType = channelType;
    }

    if (initWithPersistenceData) {
      _loadPersistenceData();
    }
    _sendSubject = BehaviorSubject<List<int>>();
    _sendSubject.add([0]);

    _sendSubject
        .distinct((v1, v2) {
          // 去重，带0计算
          if (v1 == null || v2 == null) return false;
          final v1Set = v1.toSet();
          final v2Set = v2.toSet();
          v1Set.add(0);
          v2Set.add(0);
          // 请求页数相同并且是最新的，则认为是相同的。
          // 如果过期了，即使请求页号相同，也要发送
          // 如果是首次情况时的过期，认为是初始化情况，即使过期也认为是相同的（首次时，因为初始化对象和socket连接后都会刷新，容易重复请求）
          if (v1Set.every(v2Set.contains) &&
              v2Set.every(v1Set.contains) &&
              (isUpToDate == true || _isFirstReq == true)) {
            return true;
          }
          return false;
        })
        .debounceTime(const Duration(milliseconds: 200)) // 防抖
        .listen(requestRemoteData);
  }

  // 本地加载出缓存的数据
  void _loadPersistenceData() {
    final String saveKey = "$guildId-$channelId-0";
    final valueStr = Db.segmentMemberListBox.get(saveKey);
    try {
      final Map archiveData = jsonDecode(valueStr);
      if (archiveData != null) {
        _itemCount = archiveData['item_count'];
        _itemList.addAll(archiveData['segment_0_items']);
        _itemList.length = _itemCount;
        _memberCount = archiveData['member_count'];
        _groups = archiveData['groups'];
      }
    } catch (e, s) {
      logger.severe("_loadPersistenceData", e, s);
    }
  }

  List<UserInfo> memberSnapshot() {
    return _itemList
            .where((e) => e != null && e["User"] != null)
            .map((e) => UserInfo.fromJson(e["User"] as Map<String, dynamic>,
                fromMemberList: true))
            .toList() ??
        [];
  }

  List<UserInfo> memberSnapshotNotBot() {
    return _itemList.where((e) => e != null && e["User"] != null).map((e) {
          final user = UserInfo.fromJson(e["User"] as Map<String, dynamic>,
              fromMemberList: true);
          if (!user.isBot) return user;
        }).toList() ??
        [];
  }
}
