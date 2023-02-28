import 'dart:async';

import 'package:get/get.dart';
import 'package:im/api/guild_api.dart';
import 'package:im/pages/home/json/text_chat_json.dart';
import 'package:im/pages/home/model/chat_index_model.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/widgets/segment_list/segment_member_list_data_model.dart';
import 'package:im/ws/ws.dart';
import 'package:tuple/tuple.dart';

import '../../global.dart';

class SegmentMemberListNotice {
  final String guildId;
  final String channelId;

  SegmentMemberListNotice(this.guildId, this.channelId);
}

class ChangeToPrivateNotice extends SegmentMemberListNotice {
  ChangeToPrivateNotice(String guildId, String channelId)
      : super(guildId, channelId);
}

class ChangeToPublicNotice extends SegmentMemberListNotice {
  ChangeToPublicNotice(String guildId, String channelId)
      : super(guildId, channelId);
}

class DeleteNotice extends SegmentMemberListNotice {
  DeleteNotice(String guildId, String channelId) : super(guildId, channelId);
}

// 处理成员列表数据逻辑，包括缓存，网路更新等业务
// 数据的处理需要区分服务器，在本层处理
// 本Service只处理服务器层级的公共数据，不处理每个频道的数据
class SegmentMemberListService extends GetxService {
  static SegmentMemberListService get to {
    SegmentMemberListService s;
    try {
      s = Get.find<SegmentMemberListService>();
    } catch (_) {}
    return s ??= Get.put(SegmentMemberListService());
  }

  static double listHeight = 50;

  // 分段大小
  static int segmentSize = 100;

  // 分段请求最大段数
  static int maxSegmentCount = 2;

  StreamSubscription _wsSubscription;

  final Map<String, dynamic> _publicGuildChannels = {};
  final Map<String, int> _guildCountMap = {};

  Rx<SegmentMemberListNotice> memberListEvent =
      Rx<SegmentMemberListNotice>(null);

  // 最近更新的频道id。最后一次发请求的，这个和服务器无关，和最后一次http请求相关
  String _latestUpdateChannelId;

  String get latestUpdateChannelId => _latestUpdateChannelId;

  // 列表模型缓存
  final Map<String, SegmentMemberListDataModel> cacheMap = {};

  @override
  void onInit() {
    _wsSubscription = Ws.instance.on().listen(_onWsEvent);
    GlobalState.selectedChannel.addListener(_onSelectedChannelChanged);

    super.onInit();
  }

  @override
  void onClose() {
    _wsSubscription.cancel();
    GlobalState.selectedChannel.removeListener(_onSelectedChannelChanged);

    super.onClose();
  }

  int guildCount(String guildId) {
    if (guildId == null) return 0;
    int gc = _guildCountMap[guildId];
    if (gc == null) {
      _guildCountMap[guildId] = gc = 0;
      getDataModel(guildId, "0",
          ChatChannelType.guildText); //没有任何频道的服务器，要取成员列表的话，先拉下公开频道数据
    }
    return gc;
  }

  void setGuildCount(String guildId, int value) {
    if (guildId == null) return;
    _guildCountMap[guildId] = value;
  }

  void _onSelectedChannelChanged() {
    // 如果选中了当前频道，并且数据过期了，需要重新刷新数据
    cacheMap.forEach((key, value) {
      if (GlobalState.selectedChannel.value?.id == value.channelId) {
        // 切回本频道，如果数据过期了，则需要重新发起请求
        if (value.isUpToDate == false) {
          value.refresh();
        }
      } else {
        // 如果频道内请求了非首段的数据，切走频道后，数据将过期。因为非首段的变更，只有最后一次请求的段才会更新
        if (!(_latestUpdateChannelId == value.channelId ||
            value.onlyFirstSegment())) {
          value.isUpToDate = false;
        }
      }
    });
  }

  // 比较新来频道数据和上次频道数据，告知哪些频道公转私，哪些频道私转公
  void _diffPublicChannels(String guildId, List originals, List currents) {
    if (originals == null || currents == null) return;
    final oSet = originals.toSet();
    final cSet = currents.toSet();
    final toPrivateSet = oSet.difference(cSet);
    toPrivateSet.forEach((element) {
      //公转私，告知外部
      memberListEvent.value = ChangeToPrivateNotice(guildId, element);
    });

    final toPublicSet = cSet.difference(oSet);
    toPublicSet.forEach((element) {
      // 私转公，如果缓存中没有公开频道的对象，则把当前缓存数据做修改作为公开频道对象，否则外部会再次请求公开频道对象
      // 如果有公开频道对象，释放私有数据，通知外部，重新获取
      // 私转公的逻辑包括首次发送，当做私有频道处理。回来之后，才知道是公开频道
      final String pubKey = "$guildId-0";
      final SegmentMemberListDataModel pubData = cacheMap[pubKey];
      final String key = "$guildId-$element";
      final SegmentMemberListDataModel elementData = cacheMap[key];
      if (pubData == null) {
        if (elementData != null) {
          // 公开频道无数据，私密频道有数据：开始请求都是私密频道，有一个转成了公开，或首次请求
          elementData.changeToPublic();
          cacheMap.remove(key);
          cacheMap[pubKey] = elementData;
        } else {
          // 公开频道无对象，转私密的频道无对象，被动转的情况。新造一个公开数据
          cacheMap[pubKey] = SegmentMemberListDataModel(guildId, "0");
        }
      }
      memberListEvent.value = ChangeToPublicNotice(guildId, element);
    });
  }

  // 收到WS消息之后，分发相应的变更数据给对应的数据model处理
  void _onWsEvent(event) {
    // 只处理列表更新相关的数据消息
    if (event is Connected) {
      // WS 重连后，移除不在ui可视范围内的model，重新发起请求，
      cacheMap.removeWhere((key, model) {
        // 保留当前选中的文本频道
        if (model.channelId == GlobalState.selectedChannel?.value?.id)
          return false;
        // 保留当前选中的语音频道
        if (model.channelId == GlobalState.mediaChannel?.value?.item2?.id)
          return false;
        // 保留当前选中服务器下的语音频道
        if (model.guildId == ChatTargetsModel.instance.selectedChatTarget?.id &&
            model.channelType == ChatChannelType.guildVoice) return false;

        return true;
      });
      cacheMap.forEach((key, value) {
        if (!value.isUpToDate) value.refresh();
      });
    } else if (event is Disconnected) {
      // 断开连接后，内存中的数据已经无法和服务器保持同步，因此需要设置成过期标志，在下次连接成功时，重新拉取
      cacheMap.forEach((key, value) {
        value.isUpToDate = false;
      });
    } else if (event is WsMessage) {
      if (event == null) return;
      if (event.action != MessageAction.roleUp &&
          event.action != MessageAction.memberList) return;

      final Map data = event.data;
      final guildId = "${data['guild_id']}";
      // if (guildId == null) return;
      final channelId = "${data['channel_id']}"; //使用服务器端的 channel_id
      if (channelId == null) return;

      // memberList信息中的公共数据，放在servie中处理，其他信息，放入具体dataModel中处理
      if (event.action == MessageAction.memberList) {
        final pcs = data['channel_pub_ids'] as List;

        if (guildId != null && guildId.isNotEmpty && guildId != "0") {
          setGuildCount(guildId, data['guild_count'] ?? 0);
          final oldPcs = _publicGuildChannels[guildId];
          _publicGuildChannels[guildId] = pcs;
          _diffPublicChannels(guildId, oldPcs, pcs);
        }
      }

      // dataModel数据分发给具体model
      cacheMap.forEach((key, value) {
        value.updateFromWsMessage(event);
      });
    }
  }

  // 获取频道列表model
  // autoCreate: 如果没有缓存，则造一个
  SegmentMemberListDataModel getDataModel(
      String guildId, String channelId, ChatChannelType channelType,
      {bool autoCreate = true, bool initWithPersistenceData = true}) {
    // 计算频道是否为"真.公开"频道，是的话，使用公共的model，否则使用原始的
    String key = "$guildId-$channelId";
    if (isChannelActuallyPublic(guildId, channelId)) {
      key = "$guildId-0";
    }
    SegmentMemberListDataModel model = cacheMap[key];
    if (model == null && autoCreate) {
      model = SegmentMemberListDataModel(guildId, channelId,
          initWithPersistenceData: initWithPersistenceData,
          channelType: channelType);
      cacheMap[key] = model;
    }
    return model;
  }

  List<Tuple2<String, String>> cleanDataModelCache({String guildId}) {
    final List<Tuple2<String, String>> toDelete = [];
    if (guildId != null) {
      cacheMap.removeWhere((key, value) {
        if (key.startsWith(guildId)) {
          value.isUpToDate = false;
          toDelete.add(Tuple2(value.guildId, value.channelId));
          return true;
        } else {
          return false;
        }
      });
    } else {
      cacheMap.forEach((key, value) {
        toDelete.add(Tuple2(value.guildId, value.channelId));
      });
      cacheMap.clear();
    }
    return toDelete;
  }

  // 频道是否为真.公开频道
  bool isChannelActuallyPublic(String guildId, String channelId) {
    if (guildId == null || channelId == null) return false;
    final List publicChannels = _publicGuildChannels[guildId];
    if (publicChannels != null && publicChannels.contains(channelId)) {
      return true;
    }
    return false;
  }

  Future<dynamic> reqSegmentData(
      String guildId, String channelId, List<int> segs,
      {ChatChannelType channelType}) async {
    /// todo 根据上面说的，不使用流的方式，这里的 page 计算也能去掉
    if (segs == null || segs.isEmpty) return null;

    try {
      final String userId = Global.user.id;
      final segments = [0, ...segs];
      final tempPages = segments.toSet().toList()..sort();
      final pages = tempPages
          .map((page) =>
              Tuple2(page * segmentSize, (page + 1) * segmentSize - 1))
          .toList();

      int type = 0;
      if (channelType != null) {
        type = chatChannelTypeToJson(channelType);
      }
      final resp = await GuildApi.getSegmentMemberList(
          guildId, channelId, userId, pages,
          channelType: type);

      // 公共数据
      _latestUpdateChannelId = channelId;

      if (guildId != null && guildId.isNotEmpty && guildId != "0") {
        setGuildCount(guildId, resp['guild_count'] ?? 0);
        final pcs = resp['channel_pub_ids'] as List;
        final oldPcs = _publicGuildChannels[guildId];
        _publicGuildChannels[guildId] = pcs;
        _diffPublicChannels(guildId, oldPcs, pcs);
      }

      // 剩下的事情，交给请求方（dataModel）
      return resp;
    } catch (e) {
      return null;
    }
  }
}
