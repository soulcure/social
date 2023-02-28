import 'dart:async';
import 'dart:collection';
import 'dart:math';

import 'package:azlistview/azlistview.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:im/api/black_list_api.dart';
import 'package:im/api/data_model/user_info.dart';
import 'package:im/api/relation_api.dart';
import 'package:im/common/extension/string_extension.dart';
import 'package:im/db/db.dart';
import 'package:im/global.dart';
import 'package:im/pages/friend/relation.dart';
import 'package:im/pages/friend/widgets/relation_utils.dart';
import 'package:im/utils/show_confirm_dialog.dart';
import 'package:lpinyin/lpinyin.dart';
import 'package:pedantic/pedantic.dart';
import 'package:rxdart/rxdart.dart';

class UserInfoBean with ISuspensionBean {
  final UserInfo user;
  String tagIndex = '';

  UserInfoBean(this.user);

  @override
  String getSuspensionTag() => tagIndex;
}

class FriendListPageController extends GetxController {
  static FriendListPageController get to => Get.find();
  ValueListenable<Box<String>> _friendBox;
  BehaviorSubject friendStream;
  StreamSubscription _streamSubscription;

  UnmodifiableListView<UserInfoBean> get list => UnmodifiableListView(_list);
  List<UserInfoBean> _list = [];
  List<String> _idList = [];

  /// 黑名单
  final List<Map<String, dynamic>> _blackList = [];

  UnmodifiableListView<Map<String, dynamic>> get blackList =>
      UnmodifiableListView(_blackList);

  List<UserInfoBean> get friendList => list
      .where((element) => !blackListIsContain(element.user.userId))
      .toList();

  @override
  void onInit() {
    super.onInit();
  }

  @override
  void onClose() {
    _friendBox.removeListener(_addSink);
    _friendBox = null;
    _streamSubscription.cancel();
    friendStream = null;
  }

  Future<void> init() async {
    await initFriendList();
    await fetchBlackList();
  }

  Future<void> initFriendList() async {
    if (_friendBox == null || !_friendBox.value.isOpen) {
      _friendBox = Db.friendListBox.listenable();
      _friendBox.addListener(_addSink);
      friendStream = BehaviorSubject();
      _streamSubscription = friendStream
          .debounceTime(const Duration(milliseconds: 500))
          .listen((queryString) async {
        await getFriendList();
      });
    }
    final res1 = await getFriendList();
    if (res1.isEmpty)
      try {
        return await fetchData();
      } catch (e) {
        rethrow;
      }
    else {
      unawaited(fetchData());
      return res1;
    }
  }

  void _addSink() {
    friendStream.add('');
  }

  Future<List<UserInfoBean>> getFriendList() async {
    final ids = Db.friendListBox.values;
    _idList = ids.toList();
    List<UserInfo> users = [];
    final length = (_idList.length / 500).ceil().toInt();
    for (int i = 0; i < length; i++) {
      final start = 500 * i;
      final end = min(start + 500, _idList.length);
      final ids = _idList.sublist(start, end);
      final _list = await Future.wait(ids.map(UserInfo.get));
      users += _list;
    }
    _list = users.map((v) => UserInfoBean(v)).toList();
    _handleList();
    update();
    return _list;
  }

  Future<List<String>> fetchData() async {
    if (Global.user.id == null)
      await Future.delayed(const Duration(seconds: 1));

    final res = await RelationApi.getFriendList(Global.user.id, null, 1000);
    res.forEach((v) {
      RelationUtils.update(v, RelationType.friend);
    });
    _idList = res;
    await Db.friendListBox.clear();
    await Db.friendListBox.addAll(res);
    return res;
  }

  //是否为机器人
  bool isBot(String userId) {
    final userInfo = Db.userInfoBox.get(userId);
    return userInfo?.isBot == true;
  }

  bool isMyFriend(String userId) {
    return _idList?.any((element) => element == userId) ?? false;
  }

  // 好友排序
  void _handleList() {
    if (_list.isEmpty) return;
    final length = _list.length;
    for (var i = 0; i < length; i++) {
      final remarkName = Db.remarkBox.get(_list[i].user.userId)?.name;
      final nickName =
          remarkName.hasValue ? remarkName : _list[i].user.nickname;
      final String pinyin = PinyinHelper.getPinyinE(nickName);
      final String tag =
          pinyin.hasValue ? pinyin.substring(0, 1).toUpperCase() : '#';
      // _list[i].namePinyin = pinyin;
      if (RegExp("[A-Z]").hasMatch(tag)) {
        _list[i].tagIndex = tag;
      } else {
        _list[i].tagIndex = "#";
      }
    }
    //根据A-Z排序
    SuspensionUtil.sortListBySuspensionTag(_list);
  }

  Future<void> add(String userId) async {
    if (!_friendBox.value.values.contains(userId)) {
      await _friendBox.value.add(userId);
    }
    update();
  }

  Future<void> delete({String requestId, String relationId}) async {
    final String userId = requestId == Global.user.id ? relationId : requestId;
    RelationUtils.update(requestId, RelationType.none);
    final index =
        _friendBox.value.values.toList().indexWhere((e) => e == userId);
    if (index >= 0) {
      await _friendBox.value.deleteAt(index);
    }
    update();
  }

  Future<bool> remove(String userId) async {
    final res = await showConfirmDialog(
      title: '删除好友'.tr,
      content: '删除后，将从彼此的好友列表中移除。'.tr,
    );
    if (res != true) return false;
    await RelationApi.remove(Global.user.id, userId);
    RelationUtils.update(userId, RelationType.none);
    _list.removeWhere((element) => element.user.userId == userId);
    final index =
        _friendBox.value.values.toList().indexWhere((e) => e == userId);
    if (index >= 0) {
      await _friendBox.value.deleteAt(index);
    }
    update();
    return true;
  }

  //////////// ---黑名单逻辑--- //////////

  Future<bool> addBlackId(String blackId) async {
    try {
      final localUserId = Global.user.id.toString();
      final result = await BlackListApi.addToBlackList(localUserId, blackId);
      if (result['black_id'] == blackId) {
        onAddBlackId(result);
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  void onAddBlackId(Map blackInfo) {
    try {
      if (!blackListIsContain(blackInfo['black_id'])) {
        _blackList.add(blackInfo);
        update();
      }
    } catch (e) {
      print(e);
    }
  }

  Future<bool> removeFromBlackList(String blackId) async {
    try {
      final localUserId = Global.user.id.toString();
      await BlackListApi.removeFromBlackList(localUserId, blackId);
      onRemoveFromBlackList(blackId);
      return true;
    } catch (e) {
      return false;
    }
  }

  void onRemoveFromBlackList(String blackId) {
    _blackList.removeWhere((element) => element['black_id'] == blackId);
    update();
  }

  Future fetchBlackList() async {
    try {
      final localUserId = Global.user.id.toString();
      final temp = await BlackListApi.getBlackList(localUserId);
      _blackList.clear();
      for (final item in temp) {
        _blackList.add(item as Map);
      }
      update();
    } catch (e) {
      print(e);
    }
  }

  bool blackListIsContain(String userId) {
    return _blackList.firstWhere((element) => element['black_id'] == userId,
            orElse: () => null) !=
        null;
  }
}
