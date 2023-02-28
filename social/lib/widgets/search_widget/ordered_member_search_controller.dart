import 'dart:async';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:im/api/data_model/user_info.dart';
import 'package:im/api/guild_api.dart';
import 'package:im/global.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/utils/string_filter_utils.dart';
import 'package:tuple/tuple.dart';

/// 获取服务端的分页成员列表
/// 返回值为 Tuple2<用户列表，是否有更多>
Future<Tuple2<List<UserInfo>, bool>> _fetchPagedMemberList(
    {String guildId, String channelId, int page, int pageSize}) async {
  final res = await GuildApi.getSegmentMemberList(
    guildId,
    channelId,
    Global.user.id,
    [Tuple2<int, int>(page * pageSize, (page + 1) * pageSize - 1)],
    notsync: true,
    showDefaultErrorToast: true,
  );
  final List items = res["ops"][0]["items"];
  final List<UserInfo> ret = [];
  for (final e in items) {
    if ((e as Map).containsKey("User")) {
      ret.add(UserInfo.fromJson(e["User"]));
    }
  }
  return Tuple2(ret, items.length == pageSize);
}

/// 为成员搜索提供数据源
/// 1. 允许在列表最后一项为 LoadMore
/// 2. 允许输入过滤成员
/// 3. 允许在未过滤时分页展示列表
class OrderedMemberSearchController extends GetxController {
  List<UserInfo> list = [];
  bool showLoadingWidget = true;

  final List<UserInfo> _allMembers = [];
  final Stream<String> stream;
  final String guildId;
  final String channelId;
  ChatChannelType channelType;

  final _pageSize = 100;
  var _page = 0;
  String _lastInput;

  /// 原始完整列表是否还有更多数据可以加载
  bool originListHasMore = true;

  StreamSubscription<String> subscription;

  OrderedMemberSearchController.fromDebouncedTextStream(
      {this.guildId, this.channelId, this.stream, this.channelType});

  // 是否显示服务器所有成员
  bool isGuildMember = false;

  @override
  void onInit() {
    subscription = stream.listen(_checkMentionMembers);
    if (channelId == null ||
        (channelId != null && channelType == ChatChannelType.guildCircle)) {
      isGuildMember = true;
    }

    super.onInit();
  }

  @override
  void onClose() {
    subscription.cancel();
  }

  Future<bool> fetchNextPage() async {
    ///fix 在搜索的时候不加载下一页
    if (_lastInput != null && _lastInput.isNotEmpty) return false;

    try {
      final value = await _fetchPagedMemberList(
          guildId: guildId,
          channelId: isGuildMember ? '0' : channelId,
          page: _page,
          pageSize: _pageSize);
      final items = value.item1.toList();
      items.forEach((element) {
        final isExist = _allMembers.contains(element);
        if (!isExist) {
          _allMembers.add(element);
        }
      });

      // _allMembers.addAll(value.item1);
      list = _allMembers;
      update();
      _page++;
      if (value.item2) {
        return true;
      } else {
        originListHasMore = false;
        return false;
      }
    } catch (e) {
      debugPrint("Error fetch paged member list $e");
      return true;
    }
  }

  Future<void> _checkMentionMembers(String input) async {
    _lastInput = input;

    /// 输入了搜索关键字后把状态设置为没有更多可加载
    /// 如果后期搜索内容分页需要再改
    if (input.isEmpty) {
      showLoadingWidget = true;
      list = _allMembers;
      update();
      return;
    } else {
      showLoadingWidget = false;
    }

    // 本地最多搜索 1000 人
    list = _allMembers
        .sublist(0, min(_allMembers.length, 1000))
        .where((e) => StringFilterUtils.checkMatch(e.nickname, input))
        .toList(growable: false);
    update();

    try {
      if (channelType == ChatChannelType.group_dm) {
        ///群聊：需要传 channelId
        list = (await GuildApi.searchMembers('0', input, channelId: channelId))
            .toList(growable: false);
      } else {
        list = (await GuildApi.searchMembers(guildId, input))
            .toList(growable: false);
      }
      update();
    } catch (e) {
      debugPrint('searchMembers error: $e');
    }
  }
}
