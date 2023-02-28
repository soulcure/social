import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' hide Text;
import 'package:get/get.dart';
import 'package:im/api/data_model/user_info.dart';
import 'package:im/api/entity/remark_bean.dart';
import 'package:im/api/entity/role_bean.dart';
import 'package:im/api/entity/user_config.dart';
import 'package:im/api/user_api.dart';
import 'package:im/app/modules/direct_message/controllers/direct_message_controller.dart';
import 'package:im/app/modules/friend_apply_page/controllers/friend_apply_page_controller.dart';
import 'package:im/app/modules/friend_list_page/controllers/friend_list_page_controller.dart';
import 'package:im/app/modules/task/task_util.dart';
import 'package:im/app/modules/task/task_ws_util.dart';
import 'package:im/common/extension/list_extension.dart';
import 'package:im/common/extension/operation_extension.dart';
import 'package:im/common/extension/string_extension.dart';
import 'package:im/common/permission/permission_model.dart';
import 'package:im/common/permission/permission_utils.dart';
import 'package:im/db/bean/dm_last_message_desc.dart';
import 'package:im/db/chat_db.dart';
import 'package:im/db/cicle_news_table.dart';
import 'package:im/db/db.dart';
import 'package:im/global.dart';
import 'package:im/hybrid/jpush_util.dart';
import 'package:im/pages/friend/relation.dart';
import 'package:im/pages/home/json/add_friend_tips_entity.dart';
import 'package:im/pages/home/json/text_chat_json.dart';
import 'package:im/pages/home/model/chat_index_model.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/pages/home/model/in_memory_db.dart';
import 'package:im/pages/home/model/text_channel_controller.dart';
import 'package:im/pages/home/model/text_channel_isolate.dart';
import 'package:im/pages/home/view/text_chat/items/components/reaction_util.dart';
import 'package:im/pages/home/view/text_chat/rich_editor/utils.dart';
import 'package:im/pages/personal/personal_page.dart';
import 'package:im/services/sp_service.dart';
import 'package:im/utils/im_utils/channel_util.dart';
import 'package:im/utils/im_utils/last_id_util.dart';
import 'package:im/utils/message_util.dart';
import 'package:im/utils/universal_platform.dart';
import 'package:im/widgets/top_status_bar.dart';
import 'package:im/ws/ws.dart';
import 'package:pedantic/pedantic.dart';
import 'package:rxdart/rxdart.dart';
import 'package:tuple/tuple.dart';

import '../../../app.dart';
import '../../../core/http_middleware/http.dart';
import '../../../loggers.dart';
import '../../../routes.dart';
import 'stick_message_controller.dart';

///频道消息公共类
class TextChannelUtil {
  static TextChannelUtil instance;

  ///所有频道消息的事件流
  final PublishSubject stream = PublishSubject();

  final PublishSubject isolateStream = PublishSubject();

  Timer statusDelayTimer;

  /// 弱网时，连接服务器，还没收到 connected 消息
  /// 然后别人发了文字，就收到了 push，也就是 push 比 notRead 更早收到
  /// 然后 push 完了，lastMessageId 就变了，于是请求 notRead 时就错过了收到 push 前的消息
  Tuple2<Map<String, String>, Map<String, String>> _lastMessageIds;

  Tuple2<Map<String, String>, Map<String, String>> get lastMessageIds =>
      _lastMessageIds;

  ///发送notPoll接口的频道参数集合：包括私信、群聊、服务器频道
  static Map<String, List<ChatChannel>> channelMap = {};

  ///2种类型的所有频道集合
  static Map<String, List<ChatChannel>> allChannelMap = {};
  static final dmType = ChatChannelType.dm.index.toString();
  static final guildTextType = ChatChannelType.guildText.index.toString();

  TextChannelUtil() {
    Ws.instance.on<WsMessage>().listen(_onWsMessage);
    if (!kIsWeb) TextChannelIsolate.init();
    isolateStream.listen((e) {
      if (e is UnReadIsolateResult) {
        onUnReadComplete(e);
      }
    });
  }

  ///获取notPull接口的参数：频道ID和对应的lastId
  Future<void> assignLastMessageIds() async {
    channelMap.clear();
    allChannelMap.clear();

    channelMap[dmType] = DirectMessageController.to.updatedChannels.toList();
    channelMap[guildTextType] = LastIdUtil.getSortGuildChannels();

    allChannelMap[dmType] = DirectMessageController.to.channels;
    allChannelMap[guildTextType] = [...channelMap[guildTextType]];

    _lastMessageIds = Tuple2(
        await LastIdUtil.getLastMessageIds(channelMap[dmType]),
        await LastIdUtil.getLastMessageIds(channelMap[guildTextType]));
  }

  ///发送WS请求，获取未读消息
  Future<void> fetchData() async {
    await assignLastMessageIds();

    final LinkedHashMap<String, String> orderMap1 =
        LinkedHashMap<String, String>();
    final LinkedHashMap<String, String> orderMap2 =
        LinkedHashMap<String, String>();

    final selectChannelId = GlobalState?.selectedChannel?.value?.id;
    if (selectChannelId.hasValue &&
        _lastMessageIds.item2.containsKey(selectChannelId)) {
      orderMap2[selectChannelId] = _lastMessageIds.item2[selectChannelId];
    }
    orderMap1.addAll(_lastMessageIds.item1);
    orderMap2.addAll(_lastMessageIds.item2);

    if (!kIsWeb) TopStatusController.to().startLoadingMessage();
    // debugPrint('getChat delay 5');
    // await Future.delayed(const Duration(seconds: 5));

    unawaited(getReadList());

    final int pullTime = SpService.to.getInt2("${Global.user.id}_pullTime");

    /// 获取未读消息 改为 notPull，send后无需wait，去ws处获取未读消息
    /// 先发私信和群聊频道(t=3)，再发服务器频道(t=0)
    Ws.instance.sendNotRead({
      "action": "notPull",
      "channels": orderMap1,
      "t": dmType,
      "pull_time": pullTime
    });
    if (!kIsWeb) {
      Ws.instance.sendNotRead({
        "action": "notPull",
        "channels": orderMap2,
        "t": guildTextType,
        "pull_time": pullTime
      });
    }

    unawaited(TaskUtil.instance.reqUndoneTask());

    debugPrint('getChat fetchData pullTime: $pullTime');
  }

  static Future<void> getReadList() async {
    final protoMap = <String, List<String>>{};
    final listGuild = ChatTargetsModel.instance.chatTargets;
    if (listGuild != null) {
      listGuild.forEach((e) {
        if (e is GuildTarget) {
          protoMap[e.id] = e.getHasPermissionChannels();
        }
      });
    }

    final List<String> dmIds = DirectMessageController.to.channels
        .map((e) => e.id)
        .toList(growable: false);
    if (dmIds.hasValue) {
      protoMap["0"] = dmIds;
    }

    try {
      final rsp = await Ws.instance.send({
        "action": MessageAction.getReadList,
        "channels": protoMap,
      });

      if (rsp != null && rsp is Map) {
        rsp.forEach((key, value) {
          if (value != null && value is Map) {
            value.forEach((key, value) async {
              if (key != null && value != null) {
                final String channelId = key;
                final String readId = value;

                final int unread =
                    Db.numUnrealOfChannelBox.get(channelId, defaultValue: 0);
                final String lastMessageId = Db.lastMessageIdBox.get(channelId);

                if (unread > 0 &&
                    lastMessageId != null &&
                    readId.compareTo(lastMessageId) >= 0) {
                  await Db.numUnrealOfChannelBox.put(channelId, 0);
                }

                await Db.readMessageIdBox.put(channelId, readId);
              }
            });
          }
        });
      }
    } catch (e, s) {
      logger.info(e.toString(), s);
    }
  }

  ///ws：未读消息列表-处理
  // ignore: type_annotate_public_apis
  static Future<void> notPullHandler(jsonData) async {
    final ack = jsonData["ack"];
    //离线消息数据
    final data = jsonData["data"];
    //upLast: 用于同步服务端的lastId
    //notPull参数中频道的lastId为空时，服务端才会返回
    final upLast = jsonData["upLast"];
    //区分：私信或服务器频道
    final t = jsonData["t"] as String;
    //不提示未读数的频道ID(新加入服务器的频道)
    Set noDisplaySet;
    final noDisplayList = jsonData["noDisplay"];
    if (noDisplayList != null && noDisplayList is List) {
      noDisplaySet = noDisplayList.toSet();
    }

    ///是否服务器文字频道
    final bool isGuildText = guildTextType == t;

    //notPull接口成功返回时间: int, 精确到秒
    final pullTime = jsonData["pull_time"];
    //时间同步
    Ws.serverTime = pullTime ?? -1;
    Ws.differenceTime = Ws.serverTime == -1
        ? 0
        : Ws.serverTime - DateTime.now().millisecondsSinceEpoch ~/ 1000;

    ///消息列表的最后一条消息描述
    final Map desc = jsonData["descs"];
    final Map reactions = jsonData["reactions"];
    if (desc != null && desc.isNotEmpty) {
      desc.forEach((key, value) {
        if (key != null && value != null) {
          // debugPrint('getChat dm desc: $key - $value');
          try {
            final strings = value.split('\t');
            if (strings != null && strings.length == 2) {
              final String messageId = strings[0];
              String desc = strings[1];
              String senderId;
              String senderNiceName;

              ///群聊的desc格式
              final strArr = desc.split('::');
              if (strArr != null && strArr.length == 3) {
                desc = strArr[2];
                senderId = strArr[0];
                senderNiceName = strArr[1];
              }

              InMemoryDb.getMessageList(key).setLastMessageDesc(
                  descMap: DmLastMessageDesc.fromNotPull(
                BigInt.parse(messageId),
                desc,
                key,
                reactions == null ? null : reactions[key],
                senderId: senderId,
                senderNiceName: senderNiceName,
              ));
            } else {
              ///新版本使用新的格式json
              final Map tempMap = jsonDecode(value);
              InMemoryDb.getMessageList(key)
                  .setLastMessageDesc(jsonMap: tempMap);
            }
          } catch (_) {}
        }
      });

      ///消息列表的描述处理完毕，再排序
      if (!isGuildText) DirectMessageController.to.sortList();
    }

    if (isGuildText) {
      debugPrint('getChat notPullHandler - isGuildText');
      TopStatusController.to().endLoadingMessage();
      if (pullTime != null && pullTime is int) updatePullTime(pullTime);
    }
    debugPrint(
        "getChat notPullHandler - start ack: $ack, t:$t, pullTime:$pullTime");

    //当前类型的频道map
    final curChannelMap = channelMap[t].toMapWithKey((e) => e.id);

    ///有未读消息的频道集合
    final Set<String> unReadChannels = {};
    if (data != null && data is Map) {
      data.forEach((channelId, value) async {
        if (value == null) return;
        final data = value as List;
        if (data.isEmpty) return;
        final len = data.length;
        debugPrint('getChat notPullHandler $channelId len: $len');

        //如果消息不属于本地频道，不添加进来
        if (!curChannelMap.containsKey(channelId)) {
          return;
        }
        final tcController = TextChannelController.to(channelId: channelId);
        if (tcController == null) return;

        final isUpdateUnRead =
            !(noDisplaySet != null && noDisplaySet.contains(channelId));
        unReadChannels.add(channelId);

        final lastReadId = Db.readMessageIdBox.get(channelId, defaultValue: "");

        ///调用isolate 处理频道离线消息
        final UnReadIsolateParam unread = UnReadIsolateParam(
            !isGuildText,
            channelId,
            tcController.guildId,
            data,
            isUpdateUnRead,
            Global.user.id,
            PermissionModel.getPermission(tcController.guildId).userRoles,
            lastReadId);

        if (kIsWeb) {
          final UnReadIsolateResult result =
              await TextChannelIsolate.onPullUnReadMessages(unread);
          await onUnReadComplete(result);
        } else {
          ///调用isolate 处理频道离线消息
          TextChannelIsolate.run(unread);
        }
      });
    }
    if (ack == -1) {
      setChannelsRemoteSynchronized(allChannelMap[t], unReadChannels);
      if (upLast != null && upLast is Map) onPullUpLast(upLast);

      if (t == guildTextType &&
          (data == null || (data is Map && data.isEmpty))) {
        ReactionUtil().asyncOffLineReaction();
      }
    }
    debugPrint("getChat notPullHandler - end");
  }

  ///收到isolate处理完成的结果
  static Future onUnReadComplete(UnReadIsolateResult result) async {
    final tcController = TextChannelController.to(channelId: result.channelId);
    if (tcController != null) {
      await tcController.onReceiveUnReadComplete(result);
    }
    if (result.isDm) {
      //私信群聊和圈子频道：如果有消息(不管是不是自己发的)，列表顺序要顶上去
      if (result.circleNews.hasValue) {
        final last = result.circleNews.last;
        await DirectMessageController.to
            .notifyDirectMessage(last, addUnread: result.realNumUnread > 0);
      } else if (result.realMessageLength > 0) {
        await DirectMessageController.to.notifyDirectMessage(
            result.lastRealMessage,
            addUnread: result.realNumUnread > 0);
      }
      if (result.realNumUnread > 0) DirectMessageController.to.updateUnread();
    }

    if (result.isDm && result.recalls != null && result.recalls.isNotEmpty) {
      result.recalls.forEach((e) {
        final String channelId = e.channelId;
        final String messageId = (e.content as RecallEntity).id;
        final BigInt msgId = BigInt.parse(messageId);
        final DmLastMessageDesc lastDmDesc = Db.dmLastDesc.get(channelId);
        ChannelUtil.instance.removeUnreadBeforeMessageId(channelId, messageId);
        if (lastDmDesc != null && lastDmDesc.messageId == msgId) {
          String desc;
          if (e.userId != Global.user.id) {
            desc = "对方已撤回该消息".tr;
          } else {
            desc = "你已撤回该消息".tr;
          }
          unawaited(Db.dmLastDesc.put(
            channelId,
            DmLastMessageDesc.normal(msgId, desc),
          ));
        }
      });
    }

    if (!result.isDm) {
      ReactionUtil().asyncOffLineReaction();
    }
  }

  ///如果ack为-1时(表示未读消息接收完毕)，设置 没有未读消息的频道的 remoteSynchronized 为 true
  static void setChannelsRemoteSynchronized(
      List<ChatChannel> channelList, Set<String> unReadChannels) {
    if (channelList == null) return;
    channelList?.forEach((c) async {
      if (!unReadChannels.contains(c.id)) {
        unawaited(InMemoryDb.getMessageList(c.id).setRemoteSynchronized(true));
      }
    });
    debugPrint('getChat -- setChannelsRemoteSynchronized:'
        ' unReadChannels:${unReadChannels?.length}');
  }

  ///upLast 是服务端返回的频道lastId (多端同步)，需要更新
  static void onPullUpLast(Map map) {
    if (map.isEmpty) return;
    map.forEach((key, value) {
      // debugPrint('getChatHistory onPullUpLast key:$key, value:$value');
      ChannelUtil.instance.updateLastMessageIdBoxById(
          key as String, value as String,
          forceUpdate: true);
    });
  }

  void dispose() {
    stream?.close();
    isolateStream?.close();
  }

  Future<void> _onWsMessage(WsMessage message) async {
    final data = message.data;

    if (message.action == MessageAction.unStick ||
        message.action == MessageAction.stick) {
      final cid = data['channel_id'].toString();
      final stickController = StickMessageController.to(channelId: cid);
      stickController?.onWsMessage(message);
      return;
    }
    if (message.action == MessageAction.push) {
      unawaited(handleIncomingImMessage(
        MessageEntity.fromJson(data),
        member: data['member'],
        author: data['author'],
      ));
      return;
    }

    switch (message.action) {
      case MessageAction.connect:
        Ws.instance.fire(Connected());
        logger.info("Web socket connected.");
        if (!kIsWeb) // 这个header 参数会引起树美接口的问题
          Http.dio.options.headers['Client-id'] = data['client_id'];
        break;
      case MessageAction.userNotice:
        _onUserNotice(data);
        break;
      case MessageAction.relation:
        await _onRelationAction(data);
        break;
      case MessageAction.roleUp:
        unawaited(PermissionModel.onGuildChange(message.action, data));
        break;
      case MessageAction.rolesUpdate:
        unawaited(PermissionModel.onGuildChange(message.action, data));

        break;
      // 用户角色被修改
      case MessageAction.userRolesUpdate:
        final String guildId = data['guild_id'];
        final String userId = data['user_id'];
        final userInfo = await UserInfo.get(userId);
        userInfo.roles = (data['roles'] as List)
            .map((e) => e['role_id'] as String)
            .cast<String>()
            .toList();
        UserInfo.set(userInfo);
        RoleBean.update(userId, guildId, userInfo.roles);
        unawaited(PermissionModel.onGuildChange(message.action, data));
        break;

      case MessageAction.overwriteUpdate:
        unawaited(PermissionModel.onGuildChange(message.action, data));

        /// TODO: 私密频道无权限红点改造后需要去掉此逻辑
        updateUnreadNum();
        break;
      case MessageAction.overwriteDel:
        unawaited(PermissionModel.onGuildChange(message.action, data));

        /// TODO: 私密频道无权限红点改造后需要去掉此逻辑
        updateUnreadNum();
        break;
      case MessageAction.userSetting:
        _onUserSetting(data);
        break;
      case MessageAction.blackAdd:
        FriendListPageController.to.onAddBlackId(data);
        break;
      case MessageAction.blackDel:
        FriendListPageController.to.onRemoveFromBlackList(data['black_id']);
        break;
      case MessageAction.circlePush:
        // debugPrint('getChat ws circlePush: $data');
        _onCirclePush(data);
        break;
      case MessageAction.userBan:
        _popToMain(data ?? {});
        break;
      case MessageAction.overwriteCircleUpdate:
        unawaited(PermissionModel.onGuildChange(message.action, data));
        break;
    }
  }

  Future<void> handleIncomingImMessage(
    MessageEntity message, {
    @required Map author,
    @required Map member,
  }) async {
    TextChannelController tcController;

    try {
      tcController = TextChannelController.to(channelId: message.channelId);
    } catch (_) {
      // 私信可能会在没有此频道的时候收到消息，所以需要先创建私信频道
      if (message.channelType == ChatChannelType.dm) {
        tcController = await getDmChannelController(message);
      } else {
        /// 暂不处理本地无频道时收到此频道的推送
        return;
      }
    }
    await tcController.onNewMessage(message, author: author, member: member);
  }

  Future getDmChannelController(MessageEntity message) async {
    String recipientId = message.userId;

    if (message.content.type == MessageType.friend) {
      /// 如果是一条添加好友成功后自动发送的：你和对方已经成为好友，现在可以开始聊天了
      /// 那么可能是添加好友时刚创建的私信频道，在这种情况下，确认添加好友时就会调用创建私信频道的接口，
      /// 但是 ws 推送极有可能比 http 更快到达，也就是收到此推送时，频道创建还未完成
      /// 所以这里需要轮询内存中的频道，等待频道创建完成，虽然应避免使用等待，但是为了代码复杂度，
      /// 以及遵循各个行为的语义，权衡之下还是使用这种方式。

      final content = message.content as AddFriendTipsEntity;
      recipientId = Global.user.id == content.content["agree"]
          ? content.content["apply"]
          : content.content["agree"];
      bool hasDmChannel() {
        return DirectMessageController.to.channels
            .any((v) => v.recipientId == recipientId);
      }

      // 轮询等待频道创建完成，间隔 100ms
      while (!hasDmChannel()) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }

    final channel = await DirectMessageController.to.createChannel(recipientId);
    return Get.put(TextChannelController(channel));
  }

  void updateUnreadNum() {
    final target = ChatTargetsModel.instance.selectedChatTarget;
    if (target is GuildTarget) {
      target.traverseChannelsTask();
    }
  }

  void _onUserNotice(Map data) {
//    用户信息修改不包含服务器角色，角色字段需单独处理
    final userId = data["user_id"];
    final user = Db.userInfoBox.get(userId);
    final userRoles = user?.roles;
    final guildId = data['guild_id'];
    final nickName = data['nickname'];
    final userPending = data['user_pending'];

    final isChangeGuildNick = guildId != null;
    if (isChangeGuildNick) {
      if (nickName != null)
        user?.updateGuildNickNames({guildId: nickName});
      else
        user?.removeGuildNickName(guildId);
    } else
      UserInfo.set(UserInfo.fromJson(data)..roles = userRoles);
    // 当前用户信息修改
    if (userId == Global.user.id && !isChangeGuildNick) {
      Global.user.update(
          avatar: data["avatar"],
          nickname: data["nickname"],
          avatarNft: data["avatar_nft"],
          avatarNftId: data["avatar_nft_id"]);
    }

    /// 更新用户userPending状态
    if (isChangeGuildNick && userPending != null) {
      if (TaskWsUtil.isOnTaskPage) {
        TaskWsUtil.onUserNoticeData = data;
      } else {
        TaskUtil.instance.updateGuildTargetInfoWithGuildId(data);
      }
    }

    ///修改备注名
    final friendUserId = data['friend_user_id']?.toString();
    final name = data['name']?.toString();
    if (friendUserId != null && name != null && friendUserId.isNotEmpty) {
      final remarkBean =
          Global.user.remarkListBean ?? Db.remarkListBox.get(userId);
      remarkBean.remarks[friendUserId] = RemarkBean(friendUserId, name, '');
      Global.user.remarkListBean = remarkBean;
      Db.remarkListBox.put(userId, remarkBean);
      Db.remarkBox.put(friendUserId, remarkBean.remarks[friendUserId]);
    }
  }

  ///处理:在线的圈子消息
  void _onCirclePush(Map data) {
    final message = MessageEntity.fromJson(data);
    if (message.channelType != ChatChannelType.circlePostNews) return;
    final content = message.content as CirclePostNewsEntity;
    final circleType = CircleNewsTable.getCircleType(content?.circleType);
    if (circleType == null) return;

    content.updateAtMe(message.mentions);
    final channelId = message.channelId;
    InMemoryDb.getMessageList(channelId).saveMessage(message);

    if (CirclePostNewsType.postDel == circleType) {
      ChannelUtil.instance.updateFirstMessageIdBox(message);
    }

    //圈子频道是否增加未读数
    bool addUnread = false;
    //自己发的 和 删除回复和取消动态点赞-不更新未读数
    if (message.userId != Global.user.id &&
        CircleNewsTable.isUpdateUnread(circleType)) {
      addUnread = true;
      ChannelUtil.instance.updateFirstMessageIdBox(message);
      ChannelUtil.instance.increaseUnread(message);
      if (content.atMe == 1) {
        ChannelUtil.instance.increaseAtMessageNum(channelId, message.messageId);
      }
      _pushCircleNewsNotification(message, data);
    }
    DirectMessageController.to
        .notifyDirectMessage(message, addUnread: addUnread);
    DirectMessageController.to.updateUnread();
  }

  ///本地在线推送-圈子动态消息
  Future<void> _pushCircleNewsNotification(
      MessageEntity message, Map data) async {
    if (App.appLifecycleState == AppLifecycleState.resumed && !kIsWeb) return;
    final bool isMuted = (Db.userConfigBox.get(UserConfig.mutedChannel) ?? [])
        .contains(message.channelId);
    if (isMuted) return;
    final content = message.content as CirclePostNewsEntity;
    if (content != null) {
      if (content.name.noValue && content.msg.noValue && content.desc.noValue)
        return;

      final name =
          content.name.hasValue ? MessageUtil.trimEmptyEnd(content.name) : ' ';
      if (content.desc.hasValue) {
        /// name可能包含艾特ID，需要转换成昵称
        unawaited(MessageUtil.toDescString(name, message.guildId, atPre: '@')
            .then((nameValue) {
          final desc = content.desc.hasValue
              ? MessageUtil.trimEmptyEnd(content.desc)
              : ' ';
          unawaited(
              MessageUtil.toDescString(desc, message.guildId).then((value) {
            JPushUtil.pushNotification(
                title: nameValue,
                content: value ?? ' ',
                fireTime: DateTime.now().add(const Duration(milliseconds: 100)),
                sound: UniversalPlatform.isIOS ? "ring2.caf" : "ring2.mp3",
                extra: {
                  "circleData": jsonEncode(data),
                  "type": JPushType.circleComment.toString(),
                });
          }));
        }));
      } else if (content.msg.hasValue) {
        final msg =
            content.msg.hasValue ? MessageUtil.trimEmptyEnd(content.msg) : ' ';
        unawaited(JPushUtil.pushNotification(
            title: name,
            content: msg,
            fireTime: DateTime.now().add(const Duration(milliseconds: 100)),
            sound: UniversalPlatform.isIOS ? "ring2.caf" : "ring2.mp3",
            extra: {
              "circleData": jsonEncode(data),
              "type": JPushType.circleComment.toString(),
            }));
      }
    }
  }

  // ignore: unused_element
  Future _pushCircleNotification(Map data, MessageEntity message) async {
    if (App.appLifecycleState == AppLifecycleState.resumed && !kIsWeb) return;
    // final content = message.content as CirclePostNewsEntity;

    debugPrint('getChat circle - Notification 1 ');
    final receiveId = data['receive_id'].toString();
    final sendId = data['send_id'].toString();
    final ownerId = data['owner_id'].toString();
    final isPush = data['is_push']?.toString() ?? '';
    final method = data['method'].toString();
    var mentions = <String>[];
    if (data['mentions'] != null && data['mentions'] is List) {
      mentions =
          (data['mentions'] as List).map<String>((e) => e['user_id']).toList();
    }

    if (isPush == 'false') return;
    if (sendId == Global.user.id) return;
    if (!mentions.contains(Global.user.id) &&
        receiveId != Global.user.id &&
        ownerId != Global.user.id) return;

    if (method == "reaction" || method == "comment" || method == "post") {
      final userId = data['user_id'];
      final type = data['circle_type'];
      final content = data['content'];
      final guildId = data['guild_id'];

      final userInfo = (await UserApi.getUserInfo([userId])).single;
      String nickName = _fetchUserSenderName(userInfo);
      nickName = nickName.takeCharacter(8);
      var notificationTitle = "";
      var notificationContent = ' ';
      switch (type) {
        case "post_like":
          notificationTitle = "[$nickName]点赞了你的动态！";
          break;
        case "post_comment":
          if (receiveId == Global.user.id && ownerId == Global.user.id) {
            notificationTitle = "[$nickName]回复了你的动态！";
          } else if (mentions.hasValue && mentions.contains(Global.user.id)) {
            notificationTitle = "[$nickName]在回复中@你！";
          }

          // final document = NotusDocument.fromJson(jsonDecode(content));
          // notificationContent = document.toPlainText().replaceAll('\n', '');

          notificationContent =
              await _toNotificationString(content, guildId, userId);
          break;
        case "comment_comment":
          if (receiveId == Global.user.id) {
            notificationTitle = "[$nickName]回复了你！";
          } else if (mentions.hasValue && mentions.contains(Global.user.id)) {
            notificationTitle = "[$nickName]在回复中@你！";
          }

          // final document = NotusDocument.fromJson(jsonDecode(content));
          // notificationContent = document.toPlainText().replaceAll('\n', '');
          notificationContent =
              await _toNotificationString(content, guildId, userId);
          break;
        case "comment_like":
          notificationTitle = "[$nickName]点赞了你的回复！";
          break;
        case "post_at":
          notificationTitle = "[$nickName]在动态中@你！";
          // final document = NotusDocument.fromJson(jsonDecode(content));
          // notificationContent = document.toPlainText().replaceAll('\n', '');
          notificationContent =
              await _toNotificationString(content, guildId, userId);
          break;

        default:
          break;
      }
      if (notificationTitle.isNotEmpty) {
        unawaited(JPushUtil.pushNotification(
            title: notificationTitle,
            content: notificationContent,
            fireTime: DateTime.now().add(const Duration(milliseconds: 100)),
            sound: UniversalPlatform.isIOS ? "ring2.caf" : "ring2.mp3",
            extra: {
              "channel_id": data['channel_id'].toString(),
              "post_id": data['post_id'].toString(),
              "comment_id": data['comment_id'].toString(),
              "guild_id": data['guild_id'].toString(),
              "user_id": data['user_id'].toString(),
              "circle_type": data['circle_type'].toString(),
              "topic_id": data['topic_id'].toString(),
              "type": JPushType.circleComment.toString(),
            }));
      }
    }
  }

  Future<String> _toNotificationString(
      String content, String guildId, String userId) async {
    final document = Document.fromJson(jsonDecode(content ?? ''));

    String value = '';

    final operationList =
        RichEditorUtils.formatDelta(document.toDelta()).toList();
    for (final o in operationList) {
      if (o.isImage) {
        value += '[图片]'.tr;
      } else if (o.isVideo) {
        value += '[视频]'.tr;
      } else {
        final String res = await TextEntity.fromString(o.value)
            .toNotificationString(guildId, userId);
        value += res;
      }
    }
    return value.replaceAll('\n', '');
  }

  void _popToMain(Map data) {
    final userId = data['user_id'] ?? '';
    if (userId != Global.user.id) return;
    clearData(onSuccess: (mobile, country) {
      TextChannelController.dmChannel = null; //静态变量重置
      Routes.popAndPushLoginPage(mobile, country);
    });
  }

  Future<void> _onRelationAction(Map data) async {
    // 1=收到申请好友；2=好友建立完成；3=好友被删除；4=被人拒绝添加好友;5=申请者取消
    final type = RelationActionExtension.fromInt(data["type"]);
    final relationId = data['relation_id'];
    final requestId = data['request_id'];
    final timestamp = data['timestamp'];
    switch (type) {
      case RelationAction.apply:
        final user = (await UserApi.getUserInfo([requestId])).single;
        FriendApplyPageController.to.onApply(
            requestId: requestId, relationId: relationId, timestamp: timestamp);
        if ((App.appLifecycleState != AppLifecycleState.resumed || kIsWeb) &&
            relationId == Global.user.id) {
          String nickname = _fetchUserSenderName(user);
          nickname = nickname.takeCharacter(8);

          unawaited(JPushUtil.pushNotification(
              title: '$nickname 请求添加你为好友，快去通过吧！',
              content: ' ',
              fireTime: DateTime.now().add(const Duration(milliseconds: 100)),
              sound: UniversalPlatform.isIOS ? "ring2.caf" : "ring2.mp3",
              extra: {
                "user_id": requestId.toString(),
                "type": JPushType.relationAdd.toString()
              }));
        }
        break;
      case RelationAction.friend:
        //  接受添加好友请求后，如果未创建dm频道,则创建
        if (requestId == Global.user.id) {
          await DirectMessageController.to.createChannel(relationId);
        }

        FriendApplyPageController.to
            .onFriend(requestId: requestId, relationId: relationId);
        final user = (await UserApi.getUserInfo([requestId])).single;
        if ((App.appLifecycleState != AppLifecycleState.resumed || kIsWeb) &&
            relationId == Global.user.id) {
          String nickname = _fetchUserSenderName(user);
          nickname = nickname.takeCharacter(8);

          unawaited(JPushUtil.pushNotification(
              title: '$nickname 同意你的好友请求了，快去看看吧！',
              content: ' ',
              fireTime: DateTime.now().add(const Duration(milliseconds: 100)),
              sound: UniversalPlatform.isIOS ? "ring2.caf" : "ring2.mp3",
              extra: {
                "user_id": requestId.toString(),
                "type": JPushType.relationFriend.toString()
              }));
        }
        break;
      case RelationAction.delete:
        unawaited(FriendListPageController.to
            .delete(requestId: requestId, relationId: relationId));
        break;
      case RelationAction.refuse:
        FriendApplyPageController.to
            .onCancel(requestId: relationId, relationId: requestId);
        break;
      case RelationAction.cancel:
        FriendApplyPageController.to
            .onCancel(requestId: requestId, relationId: relationId);
        final user = (await UserApi.getUserInfo([requestId])).single;
        if ((App.appLifecycleState != AppLifecycleState.resumed || kIsWeb) &&
            relationId == Global.user.id) {
          String nickname = _fetchUserSenderName(user);
          nickname = nickname.takeCharacter(8);
          unawaited(JPushUtil.pushNotification(
              title: '$nickname 已撤回添加你为好友的申请',
              content: ' ',
              fireTime: DateTime.now().add(const Duration(milliseconds: 100)),
              sound: UniversalPlatform.isIOS ? "ring2.caf" : "ring2.mp3",
              extra: {
                "user_id": requestId.toString(),
                "type": JPushType.relationAdd.toString()
              }));
        }
        break;
      default:
    }
  }

  String _fetchUserSenderName(UserInfo userInfo, {String guildId = ""}) {
    String senderName = "";
    if (userInfo?.markName?.isNotEmpty ?? false) {
      senderName = userInfo?.markName;
    } else if ((guildId?.isNotEmpty ?? false) &&
        (userInfo.guildNickname(guildId)?.isNotEmpty ?? false)) {
      senderName = userInfo.guildNickname(guildId);
    } else if (userInfo.nickname?.isNotEmpty ?? false) {
      senderName = userInfo.nickname;
    }
    return senderName;
  }

  void _onUserSetting(Map data) {
    List<String> muteChannels;
    final rawMuteChannels = data[UserConfig.mute];
    if (rawMuteChannels != null) {
      final res = json.decode(rawMuteChannels);
      muteChannels = res[UserConfig.channel]
          ?.map<String>((channel) => channel.toString())
          ?.toList();
    }

    List restrictedGuildsRet;
    final rGuilds = data[UserConfig.restrictedGuilds];
    if (rGuilds != null && rGuilds != 'null') {
      if (rGuilds is String) {
        restrictedGuildsRet = json.decode(data[UserConfig.restrictedGuilds]);
      } else {
        restrictedGuildsRet = rGuilds as List;
      }
    }
    restrictedGuildsRet ??= [];

    try {
      UserConfig.update(
        defaultGuildsRestricted: data[UserConfig.defaultGuildsRestricted],
        restrictedGuilds: restrictedGuildsRet.cast<String>(),
        mutedChannels: muteChannels,
      );
    } catch (_) {}

    // 多端同步服务器列表排序
    final guildFoldersString = data['guild_folders'];
    if (guildFoldersString is String && guildFoldersString != 'null') {
      try {
        ///TODO: 加入服务器清除残留服务器聊天数据
        final List<dynamic> guildFolders =
            json.decode(data['guild_folders']) ?? [];
        ChatTargetsModel.instance.syncGuildsDataMaybeFromServer(guildFolders);
      } catch (e) {
        logger.warning('更新服务器列表数据格式错误:$guildFoldersString');
      }
    }
  }

  ///清除所有频道消息列表的内存数据<p>
  static void clearAllTextChannelData() {
    void clearData(String tagId) {
      try {
        /// 清理内存数据
        final tcController = TextChannelController.to(channelId: tagId);
        tcController.internalList?.clear();
      } catch (_) {}
    }

    //私信频道
    final directMessageChannels = DirectMessageController.to.channels;
    //服务器文字频道
    final chatChannels = ChatTargetsModel.instance.chatTextChannels;
    directMessageChannels?.forEach((channel) async {
      clearData(channel.id);
    });
    chatChannels?.forEach((channel) async {
      /// Get.delete 无法删除，暂时不用
      // final result = await Get.delete(tag: channel.id);
      clearData(channel.id);
    });
  }

  ///更新用户的 pullTime (精确到秒)
  static void updatePullTime(int pullTime) {
    if (pullTime != null && pullTime > 0)
      SpService.to.rawSp.setInt("${Global.user.id}_pullTime", pullTime);
  }

  ///web端重连成功后，重新加载当前频道，并且清除其他频道的内存消息<p>
  Future<void> afterConnectedByWeb() async {
    debugPrint('getChat web -- afterConnectedByWeb ');
    await Db.cleanUserChatData();

    /// 清理内存数据并且设置缓存标记为true
    void clearAndReset(String tagId) {
      try {
        if (InMemoryDb.isExist(tagId)) {
          InMemoryDb.getMessageList(tagId).setRemoteSynchronized(true);
          InMemoryDb.getMessageList(tagId).clear();
          final tcController = TextChannelController.to(channelId: tagId);
          tcController.internalList?.clear();
        }
      } catch (_) {}
    }

    //私信频道
    final directMessageChannels = DirectMessageController.to.channels;
    //服务器文字频道
    final chatChannels = ChatTargetsModel.instance.chatTextChannels;
    directMessageChannels?.forEach((channel) async {
      clearAndReset(channel.id);
    });
    chatChannels?.forEach((channel) async {
      clearAndReset(channel.id);
    });

    try {
      final selectChannelId = GlobalState?.selectedChannel?.value?.id;
      if (selectChannelId != null) {
        final tcController =
            TextChannelController.to(channelId: selectChannelId);
        unawaited(tcController.joinChannel());
      }
    } catch (_) {}

    final LinkedHashMap<String, String> orderMap1 =
        LinkedHashMap<String, String>();
    orderMap1.addAll(_lastMessageIds.item1);
    print('orderMap1 : $orderMap1');
    final int pullTime = SpService.to.getInt2("${Global.user.id}_pullTime");
    Ws.instance.sendNotRead({
      "action": "notPull",
      "channels": orderMap1,
      "t": "3",
      "pull_time": pullTime
    });
  }

  static Map _channelViewPermissionMap = {};

  static void setChannelViwePermission(String channelId, bool visibility) {
    _channelViewPermissionMap[channelId] = visibility;
  }

  ///初始化所有服务器频道的查看频道权限map,并且监听频道权限变化
  Future<void> initChannelViewPermission() async {
    if (Db.userConfigBox.containsKey(UserConfig.channelViewPermissionKey)) {
      ///先从缓存中获取权限map
      _channelViewPermissionMap =
          Db.userConfigBox.get(UserConfig.channelViewPermissionKey) ?? {};
    }
    debugPrint('getChat view start：${_channelViewPermissionMap.length}');
    //所有服务器文字频道
    final chatChannels = ChatTargetsModel.instance.chatTextChannels;

    ///清理单个频道数据
    void clearChannelData(String cid) {
      ChatTable.clearChatHistory(cid);
      Db.deleteChannelImBox(cid);
      if (InMemoryDb.isExist(cid)) {
        InMemoryDb.getMessageList(cid).clear();
        TextChannelController.to(channelId: cid).internalList?.clear();
      }
    }

    bool visible;
    String channelId;
    chatChannels.forEach((channel) {
      channelId = channel.id;
      visible = PermissionUtils.isChannelVisible(
          PermissionModel.getPermission(channel.guildId), channelId);
      if (_channelViewPermissionMap.containsKey(channelId)) {
        if (_channelViewPermissionMap[channelId] != visible) {
          ///查看频道权限有变化，需要清理消息数据
          clearChannelData(channelId);
        }
      }
      _channelViewPermissionMap[channelId] = visible;
    });
    unawaited(Db.userConfigBox
        .put(UserConfig.channelViewPermissionKey, _channelViewPermissionMap));

    ///监听全局的查看权限
    PermissionModel.selfChangeStream.listen((value) {
      // debugPrint(
      //     'getChat view listen: ${value.item1}, ${value.item2}, ${value.item3}');
      if (value.item1 == null) return;
      final guildId = value.item1;
      final channelId = value.item2;
      if (channelId != null) {
        final visible = PermissionUtils.isChannelVisible(
            PermissionModel.getPermission(guildId), channelId);
        if (_channelViewPermissionMap[channelId] != visible) {
          ///有变化时，清除该频道的消息数据
          clearChannelData(channelId);

          ///更新缓存
          _channelViewPermissionMap[channelId] = visible;
          unawaited(Db.userConfigBox.put(
              UserConfig.channelViewPermissionKey, _channelViewPermissionMap));
        }
      }
    });
  }
}
