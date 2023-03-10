import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:math' hide log;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' hide Text;
import 'package:get/get.dart';
import 'package:im/api/data_model/user_info.dart';
import 'package:im/api/entity/credits_bean.dart';
import 'package:im/api/entity/resend_resp.dart';
import 'package:im/api/entity/role_bean.dart';
import 'package:im/api/entity/user_config.dart';
import 'package:im/api/guild_api.dart';
import 'package:im/api/text_chat_api.dart';
import 'package:im/api/user_api.dart';
import 'package:im/app/modules/direct_message/controllers/direct_message_controller.dart';
import 'package:im/app/modules/document_online/info/controllers/doc_link_preview_controller.dart';
import 'package:im/app/modules/friend_list_page/controllers/friend_list_page_controller.dart';
import 'package:im/app/modules/home/controllers/home_scaffold_controller.dart';
import 'package:im/app/routes/app_pages.dart' as get_pages;
import 'package:im/common/extension/list_extension.dart';
import 'package:im/common/extension/operation_extension.dart';
import 'package:im/common/extension/string_extension.dart';
import 'package:im/common/permission/permission.dart';
import 'package:im/common/permission/permission_mixin.dart';
import 'package:im/common/permission/permission_model.dart';
import 'package:im/common/permission/permission_utils.dart';
import 'package:im/core/http_middleware/interceptor/channel_mutex_interceptor.dart';
import 'package:im/db/bean/dm_last_message_desc.dart';
import 'package:im/db/bean/reaction_item.dart';
import 'package:im/db/chat_db.dart';
import 'package:im/db/cicle_news_table.dart';
import 'package:im/db/db.dart';
import 'package:im/db/reaction_table.dart';
import 'package:im/global.dart';
import 'package:im/hybrid/jpush_util.dart';
import 'package:im/loggers.dart';
import 'package:im/pages/home/components/bottom_right_button/bottom_right_button_controller.dart';
import 'package:im/pages/home/components/bottom_right_button/top_right_button_controller.dart';
import 'package:im/pages/home/json/add_friend_tips_entity.dart';
import 'package:im/pages/home/json/document_entity.dart';
import 'package:im/pages/home/json/du_entity.dart';
import 'package:im/pages/home/json/text_chat_json.dart';
import 'package:im/pages/home/model/chat_index_model.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/pages/home/model/in_memory_db.dart';
import 'package:im/pages/home/model/reaction_model.dart';
import 'package:im/pages/home/model/text_channel_event.dart';
import 'package:im/pages/home/model/text_channel_isolate.dart';
import 'package:im/pages/home/model/text_channel_util.dart';
import 'package:im/pages/home/view/text_chat/items/components/message_reaction.dart';
import 'package:im/pages/home/view/text_chat/items/model/message_card_helper.dart';
import 'package:im/pages/home/view/text_chat/items/text_item.dart';
import 'package:im/pages/home/view/text_chat/items/vote_item.dart';
import 'package:im/pages/home/view/text_chat_view.dart';
import 'package:im/pages/topic/controllers/topic_controller.dart';
import 'package:im/pages/topic/topic_page.dart';
import 'package:im/quest/fb_quest_config.dart';
import 'package:im/services/server_side_configuration.dart';
import 'package:im/utils/content_checker.dart';
import 'package:im/utils/im_utils/channel_util.dart';
import 'package:im/utils/message_util.dart';
import 'package:im/utils/universal_platform.dart';
import 'package:im/utils/utils.dart';
import 'package:im/widgets/list_view/index_list.dart';
import 'package:im/widgets/list_view/position_list_view/src/item_positions_listener.dart';
import 'package:im/widgets/list_view/position_list_view/src/scrollable_positioned_list.dart';
import 'package:im/widgets/list_view/proxy_index_list.dart';
import 'package:im/widgets/load_more.dart';
import 'package:im/widgets/network_video_player.dart';
import 'package:im/ws/pin_handler.dart';
import 'package:im/ws/ws.dart';
import 'package:pedantic/pedantic.dart';
import "package:quest_system/quest_system.dart";
import 'package:rxdart/rxdart.dart';
import 'package:sliding_sheet/sliding_sheet.dart';

import '../../../app.dart';

const _kBatchMsgTimeout = Duration(seconds: 3);
const _kBatchMsgRetryTimes = 100;
const _maxBatchMsgRetryTimes = 10000;
final _batchMsgMutexOption = MutexOption();
final _getListMutexOption = MutexOption();

///???????????? Controller
class TextChannelController extends GetxController
    with GuildPermissionListener {
  /// ????????????channelId?????????????????????????????????????????????
  static ChatChannel dmChannel;

  ///??????????????????????????????Controller<p>
  ///????????????????????????channelId
  // ignore: prefer_constructors_over_static_methods
  static TextChannelController to({String channelId}) {
    // debugPrint('getChat to 2 tagId: $tagId');
    assert(channelId != null);
    if (channelId == null) {
      logger.severe('TextChannelController: channelId is null');
      return null;
    }
    TextChannelController c;
    try {
      /// Get.find???????????????????????????
      c = Get.find<TextChannelController>(tag: channelId);
    } catch (_) {}
    if (c == null) {
      //todo ?????????channel????????????guildId,????????????,???????????????guildId,?????????????????????????????????
      final ChatChannel channel = Db.channelBox.get(channelId);
      assert(channel != null);
      if (channel == null) {
        throw Exception(
            "Please ensure you have put a corresponding TextChannelController");
      }
      c = Get.put(TextChannelController(channel), tag: channelId);
    }
    return c;
  }

  TextChannelController(this.channel) {
    richInputController = SheetController();
    _connectStream = BehaviorSubject()
      ..throttleTime(const Duration(seconds: 3)).listen((e) {
        Ws.instance.connect();
      });
  }

  ///??????
  ChatChannel channel;

  ///(??????????????????)???????????????stream
  BehaviorSubject<int> _connectStream;

  bool canReadHistory = true;
  DateTime permissionChangeTime;

  /// ??????????????????????????????0 ???????????????1 ???????????????????????????????????????????????????
  int newMessagePosition = 0;

  /// ?????? [forceInitialIndex] ???????????? UI ???????????????
  bool useForceIndex;

  /// loadmore ????????????????????????????????????????????????,??????????????????????????????????????????,??????????????????????????????,??????????????????????????????
  bool loadMoreForceUpdate = false;
  int forceInitialIndex;
  ValueKey<int> listKey = const ValueKey(0);

  ///???true???, ??????[TextChatView]?????????????????????chatViewOffset???????????????
  bool isJumpBottom;

  /// ????????????????????????????????????
  MessageEntity customKeyboardMessage;

  LoadMoreStatus _loadHistoryState = LoadMoreStatus.ready;

  // LoadMoreStatus _loadMoreState = LoadMoreStatus.ready;

  // ignore: unnecessary_getters_setters
  set loadHistoryState(LoadMoreStatus value) => _loadHistoryState = value;

  // ignore: unnecessary_getters_setters
  LoadMoreStatus get loadHistoryState => _loadHistoryState;

  ///??????????????? Controller
  BottomRightButtonController brController;

  // ignore: unnecessary_getters_setters
  set loadMoreState(LoadMoreStatus value) =>
      brController?.loadMoreState?.value = value;

  // ignore: unnecessary_getters_setters
  LoadMoreStatus get loadMoreState => brController?.loadMoreState?.value;

  String get channelId => channel?.id;

  String get guildId => channel?.guildId;

  String get channelName => channel.name;

  /// ?????????????????????
  MessageList internalList;

  ProxyController proxyController;
  ProxyIndexListener proxyListener;

  /// ???????????????????????????
  int numBottomInvisible = 0;

  /// ????????????????????????????????????????????????????????????????????????????????????
  int topIndex;

  /// ????????????????????????????????????????????????????????????????????????????????????
  int bottomIndex;

  UnmodifiableListView<MessageEntity> get messageList =>
      UnmodifiableListView(internalList?.list ?? const []);

  ///???????????????????????????
  Completer _hasInitialized;

  Future get hasInitialized => _hasInitialized?.future;

  ///????????????????????????????????????????????????????????????????????????????????????
  bool showLoading = false;

  ///????????????????????????
  bool isLoadingHistory = false;

  ///????????????????????????
  bool isLoadingMore = false;

  /// ????????????????????????
  SheetController richInputController;

  /// ?????????????????????????????????
  bool richInputVisible = false;

  void initialScrollPositionList() {
    proxyController ??=
        ProxyController.fromItemController(ItemScrollController());
    proxyListener ??=
        ProxyIndexListener.fromItemListener(ItemPositionsListener.create());
  }

  void initialIndexList() {
    proxyController = ProxyController.fromIndexController(IndexController());
    proxyListener = ProxyIndexListener.fromIndexListener((start, end) {});
  }

  Future<void> setVoiceRead(MessageEntity message) async {
    if (canReadHistory) {
      final m = await ChatTable.getMessage(message.messageId);

      ///????????????????????????????????????
      if (m != null) unawaited(ChatTable.append(message));
    }

    /// ???????????????
    TextChannelUtil.instance.stream.add(UpdateMessageEvent(message));
    final voiceMessage = internalList.get(message.messageIdBigInt);
    if (voiceMessage != null) {
      (voiceMessage.content as VoiceEntity).isRead = true;
      update();
    }
  }

  ///???????????????????????????
  void jumpToBottom(
      {Duration delay = const Duration(milliseconds: 100),
      double offset = TextChatViewBottomPadding}) {
    loadHistoryState = LoadMoreStatus.ready;
    debugPrint('getChat jumpToBottom --> start ');
    if (!listIsIdentical()) {
      internalList = InMemoryDb.getMessageList(channelId);
      brController.resetLoadMoreState();
      listKey = ValueKey(listKey.value + 1);
      //???????????????,chatView ??? chatViewOffset ???????????????,???????????????????????????
      isJumpBottom = true;
      debugPrint('getChat jumpToBottom --> offset:$offset');
      update();
      return;
    }

    void func() {
      if (proxyController != null && !proxyController.isAttached) return;

      /// +100 ?????????????????????????????????????????????????????????????????????
      proxyController?.jumpToIndex(internalList.length + 100,
          alignment: 1, offset: offset);
      brController.resetLoadMoreState();
    }

    if (delay == Duration.zero)
      func();
    else
      Future.delayed(delay, func);
  }

  void topicPageJumpToBottom() {
    final TopicController tc = TopicController.to();
    final len = tc.messages.length + 3;
    TopicPage.proxyController?.jumpToIndex(len, alignment: 1);
  }

  void jumpToIndex(int index, {double alignment = 1}) {
    if (index < 0) index = 0;
    if (proxyController != null && !proxyController.isAttached) return;

    /// ???????????????????????? 2 ???
    index += 2;
    proxyController?.jumpToIndex(index - 1, alignment: alignment);
  }

  Future<void> animationToMessageId(
      String guildId, String channelId, String messageId) async {
    final id = GlobalState.selectedChannel?.value?.id;

    bool isJumpGuild = false;
    if (id != channelId) {
      await ChatTargetsModel.instance.selectChatTargetById(guildId,
          channelId: channelId, gotoChatView: true);
      isJumpGuild = true;
    }

    ///fix ??????????????????????????????
    internalList.list.forEach((e) => e.extra = null);

    if (isJumpGuild) {
      await Future.delayed(const Duration(milliseconds: 200)).then((_) {
        jumpToMessage(messageId);
      });
    } else {
      await jumpToMessage(messageId);
    }
  }

  Future<void> jumpToMessage(String messageId) async {
    await gotoMessage(messageId, showDefaultErrorToast: true);

    final MessageEntity curMsg = internalList.list
        .firstWhere((e) => e.messageId == messageId, orElse: () => null);

    if (curMsg == null) return;

    curMsg.extra = TopicController.NEW_BACK;
    await Future.delayed(const Duration(milliseconds: 1000)).then((_) {
      proxyListener?.itemPositionsListener?.itemPositions?.addListener(() {
        if (curMsg.extra != null) {
          curMsg.extra = null;
          update();
        }
      });
    });
  }

  final Map<String, Future<MessageEntity>> _loadQuoteListFuture = {};

  Future<MessageEntity> getQuoteMessage(String messageId) async {
    if (!_loadQuoteListFuture.containsKey(messageId)) {
      _loadQuoteListFuture[messageId] =
          MessageUtil.getMessage(messageId, channelId);
    }

    return _loadQuoteListFuture[messageId];
  }

  @override
  String get guildPermissionMixinId => channel.guildId;

  @override
  void onClose() {
    _connectStream?.close();
    // _segmentMemberListModel = null;
    // _segmentMemberListViewModel = null;
    disposePermissionListener();
  }

  @override
  Future<void> onPermissionChange() async {
    // TODO: ?????????????????????????????????????????????
    if (GlobalState.isDmChannel) return;
    if (PermissionUtils.oneOf(
      guildPermission,
      [Permission.READ_MESSAGE_HISTORY],
      channelId: channel?.id,
    )) {
      if (!ServerSideConfiguration.to.readHistoryPermissionEnabled) return;

      if (!canReadHistory) {
        canReadHistory = true;
        permissionChangeTime = DateTime.now();

        /// todo ???????????????????????????????????????????????????????????? id ??????????????????
        if (internalList.isNotEmpty) {
          await ChatTable.appendAll(internalList.list);
          final res = await TextChatApi.getMessages(
              Global.user.id, channelId, internalList.first.messageId);
          internalList.addAll(res);
          listKey = ValueKey(listKey.value + 1);
          update();
          await ChatTable.appendAll(res);
        } else {
          await _loadLocalRemoteData();
        }
      }
    } else {
      void reset() {
        loadHistoryState = LoadMoreStatus.ready;
        // ???????????????????????????????????????????????????????????? messageState ?????? ValueNotifier?????????????????????
        internalList.forEach((e) {
          Future.delayed(const Duration(milliseconds: 50), () {
            if (e.content?.messageState != null) {
              e.content.messageState.close();
              e.content.messageState = null;
            }
          });
        });

        final MessageEntity item = internalList.lastMessage;
        ChannelUtil.instance.setUnreadAndSync(item);
        internalList.clear();

        listKey = ValueKey(listKey.value + 1);
        update();
      }

      if (canReadHistory) {
        canReadHistory = false;
        permissionChangeTime = DateTime.now();
        newMessagePosition = 0;
        InMemoryDb.cleanChannel(channel.id);
        reset();
        update();
      }
    }
  }

  Future<void> joinChannel() async {
    logger.info("Join channel. guildId: $guildId channelId: $channelId");
    brController ??= BottomRightButtonController.to(channelId);

    /// ??????web ????????????????????????????????????
    if (kIsWeb) forceInitialIndex = null;

    clearNetVideoPlayerAfterChangeChannel();
    clearChatCardsHttpCache();

    _hasInitialized ??= Completer();

    ///??????bugly???????????? proxyController = null
    initialScrollPositionList();

    ///???????????????????????????????????????
    DocLinkPreviewController.removeAll();

    ///?????????????????????
    if (!_hasInitialized.isCompleted) {
      // initialScrollPositionList();
      // if (channel.type != ChatChannelType.dm) {
      //   // _segmentMemberListModel = SegmentMemberListModel(guildId, channelId);
      //   // _segmentMemberListModel =
      //   //     SegmentMemberListModel.getModel(guildId, channelId);
      //   _segmentMemberListViewModel = SegmentMemberListViewModel(guildId, channelId);
      // }
      addPermissionListener();
    }

    ///?????????????????????????????????????????????????????????????????????????????????
    loadHistoryState = LoadMoreStatus.ready;
    isLoadingHistory = false;
    isLoadingMore = false;

    if (ServerSideConfiguration.to.readHistoryPermissionEnabled) {
      try {
        canReadHistory = channel.type == ChatChannelType.dm ||
            channel.type == ChatChannelType.group_dm ||
            PermissionUtils.oneOf(
                guildPermission, [Permission.READ_MESSAGE_HISTORY],
                channelId: channelId);
      } catch (_) {
        canReadHistory = true;
      }
    } else {
      canReadHistory = true;
    }

    /// [DEBUG] ??????????????????????????????????????????????????????
    // numUnread.value = 10;
    /// [DEBUG] ???????????????????????????????????????????????????
    // newMessagePosition = 10;

    if (kIsWeb) {
      internalList = InMemoryDb.getMessageList(channelId);
      await loadHistory();
      brController.joinChannel();
      if (channel.type == ChatChannelType.dm && internalList.isNotEmpty) {
        internalList.setLastMessageDesc(message: internalList.lastMessage);
      }
    } else {
      await _loadLocalRemoteData();
    }

    CreditsBean.updateItem(guildId, channelId);

    ///??????????????????readId
    ChannelUtil.instance.upLastReadSend();
  }

  ///??????????????????
  Future<void> _loadLocalRemoteData() async {
    internalList = InMemoryDb.getMessageList(channelId);

    ///fix ??????????????????????????????
    internalList.list.forEach((e) => e.extra = null);

    //?????????????????????????????????
    bool readHistoryError = false;

    if (canReadHistory) {
      /// ?????????????????????,??????????????????????????????????????????
      if (internalList.isNotEmpty &&
          ChannelUtil.instance.getUnread(channelId) > 0) {
        internalList.clear();
      }
      if (internalList.isEmpty) {
        showMessageListLoading(true, true);
        final completer = Completer();

        ///????????????????????????
        Future<void> afterFailOrTimeout() async {
          if (completer.isCompleted) return;
          completer.complete(0);
          await internalList.readCompleteHistory();
          unawaited(_readLastPageToMemory());
          readHistoryError = true;
          // debugPrint('getChat firstRead - afterFailOrTimeout');
        }

        try {
          ///???????????????batchMsg,??????????????????3???????????????????????????????????????
          await internalList
              .readHistory(
                  throwError: true,
                  completer: completer,
                  mutexOption: _batchMsgMutexOption)
              .timeout(_kBatchMsgTimeout, onTimeout: () async {
            // debugPrint('getChat firstRead ---------> timeout');
            await afterFailOrTimeout();
            return 0;
          });
        } catch (e) {
          // debugPrint('getChat firstRead -------> catchError???$e');
          await afterFailOrTimeout();
        }
      }
    } else {
      newMessagePosition = 0;
    }

    if (!_hasInitialized.isCompleted) _hasInitialized.complete();

    ///?????? internalList ???????????????????????????notPull??????
    ///????????????????????????????????????????????????
    if (canReadHistory && internalList.isEmpty) {
      await loadHistory(firstLoad: true);
    }

    ///????????????????????????????????????????????????????????????????????????????????????
    ///??????latestMessageDesc??????????????????????????????????????????????????????LastMessageDesc
    if (internalList.isNotEmpty &&
        internalList.latestMessageDesc == null &&
        dmTypeSet.contains(channel?.type)) {
      internalList.setLastMessageDesc(message: internalList.lastMessage);
      DirectMessageController.to.bringChannelToTop(channel);
    }

    if (canReadHistory) {
      showMessageListLoading(internalList.isEmpty, false);
    } else {
      //??????????????????????????????????????????????????????????????????????????????
      if (ChannelUtil.instance.getUnread(channelId) > 0) {
        ChannelUtil.instance.setUnread(channelId, 0);
      }
    }

    newMessagePosition = ChannelUtil.instance.getUnread(channel.id);
    final trController = TopRightButtonController.to(channelId);
    trController.joinChannel(Db.firstMessageIdBox.get(channelId));
    _findCustomKeyboardMessage(internalList.list);
    listKey = ValueKey(listKey.value + 1);

    update();

    await ChannelUtil.instance.initLastVisibleMessageIdBox(channelId);
    brController.joinChannel(isClearUnread: !readHistoryError);
  }

  ///????????????????????????????????????
  void showMessageListLoading(bool show, bool isNotify) {
    showLoading = show;
    if (isNotify) update();
  }

  ///?????????isolate?????????????????????
  Future<void> onReceiveUnReadComplete(UnReadIsolateResult result) async {
    final start = DateTime.now();

    if (result.circleNews.hasValue) {
      ///?????????????????????????????????
      await CircleNewsTable.appendList(result.circleNews);
    }

    logger.info("notpull??????????????????????????????");

    ///????????????
    await ChatTable.appendAllBySql(result.sqlList).catchError((e) async {
      logger.info("notpull??????????????????????????????");
      //?????????notpull?????????????????????1????????????
      await Future.delayed(const Duration(milliseconds: 1000));
      return onReceiveUnReadComplete(result);
    });
    final isUpdateUnRead = result.isUpdateUnRead;
    final lastMessage = result.lastMessage;
    final firstMessage = result.firstMessage;
    final realNumUnread = result.realNumUnread;
    logger.info("notpull??????????????????");

    ///?????????????????? lastId
    if (lastMessage != null) {
      ChannelUtil.instance.updateLastMessageIdBoxById(
          lastMessage.channelId, lastMessage.messageId,
          forceUpdate: true);
    }

    /// ??????lastId????????????????????????
    unawaited(InMemoryDb.getMessageList(channelId).setRemoteSynchronized(true));

    ///???????????????????????????
    bool isIncreaseUnread = true;
    if (isUpdateUnRead && firstMessage != null) {
      /// ???????????????
      isIncreaseUnread = ChannelUtil.instance
          .increaseUnread(firstMessage, value: realNumUnread);

      /// ??????firstId ??? ?????????????????????
      if (isIncreaseUnread) {
        ChannelUtil.instance.updateFirstMessageIdBox(firstMessage);
        result.atList.forEach((mId) {
          ChannelUtil.instance.increaseAtMessageNum(channelId, mId);
        });
      }
    }

    if (result.realMessageLength > 0) {
      ChannelUtil.instance.updateLastVisibleMessageIdBox(
          channelId, result.lastRealMessage.messageIdBigInt);
    }

    ///???????????????pin????????????????????????
    result.messageModifications?.forEach(onPullModifyMessage);
    result.recalls?.forEach((e) {
      onMessageRecalled((e.content as RecallEntity).id, e.userId);
    });
    result.pins?.forEach((e) {
      pinHandler(e, updateLastId: false);
    });
    if (result.reactions.hasValue) mergeReactions(result.reactions);
    if (result.messageCardKeys.hasValue)
      MessageCardHelper.bulkSetKeys(result.messageCardKeys);

    /// ????????????????????????
    ChatTargetsModel.instance.notify();

    /// ???????????????????????????
    if (isSelectedChannel()) {
      // /// ????????????????????????????????????????????????????????????????????????????????? Controller??????????????????????????????
      // trController.joinChannel(Db.firstMessageIdBox.get(channel.id));

      if (result.realMessageLength > 0) {
        ///?????????????????????????????????????????????????????????
        loadMoreState = LoadMoreStatus.ready;

        // _processUnreadMessages(messages, realNumUnread);
        // _findCustomKeyboardMessage(internalList.list);
        if (canReadHistory) {
          /// ????????????????????????
          newMessagePosition += realNumUnread;
          // trController.unreadNum += realNumUnread;
          if (messageList.length == 1) newMessagePosition = 1;
        }
        //unawaited(_readLastPageToMemory());
        await _readLastPageToMemory();
        //?????????????????????
        listKey = ValueKey(listKey.value + 1);
      }
      update();
    } else {
      ///??????????????????????????????InMemoryDb????????????
      InMemoryDb.cleanChannel(channelId);
    }

    ///??????????????????????????????????????????????????????????????????
    if (!isIncreaseUnread && result.isDm) {
      result.realNumUnread = 0;
    }

    debugPrint(
        "getChat ??????????????????:$channelId, ??????:${DateTime.now().difference(start).inMilliseconds} ms, numUnread: $realNumUnread");
    logger.finest(
        "${DateTime.now()} ???????????????????????????????????????????????? $channelId, ${result.realMessageLength} ?????????");
  }

  ///?????????????????? (????????????????????? ??? ????????????)
  bool isSelectedChannel() {
    return GlobalState.selectedChannel.value?.id == channelId ||
        dmChannel?.id == channelId;
  }

  ///awaitDatabaseFinish: ?????????????????????????????????
  Future sendMessage(MessageEntity message,
      {MessageEntity reply, bool awaitDatabaseFinish}) async {
    /// ??????????????????
    CustomTrigger.instance.dispatch(QuestTriggerData(
      condition: QuestCondition([
        QIDSegQuest.sendFirstMessage,
        "-",
        message.guildId,
        "-",
        message.channelId,
      ]),
    ));

    final dbMessageList = InMemoryDb.getMessageList(message.channelId);
    final String nonce =
        ChatTable.generateLocalMessageId(dbMessageList?.lastMessageId);

    message
      ..localStatus = MessageLocalStatus.local
      ..time = Ws.nowDateTime
      ..messageId = nonce
      ..nonce = nonce;

    message.messageIdBigInt = BigInt.parse(nonce);
    dbMessageList.add(message);

    if (reply != null) {
      if (reply.quoteL1.noValue && reply.quoteL2.noValue) {
        message.quoteL1 = reply.messageId;
      } else {
        message.quoteL1 = reply.quoteL1;
        message.quoteL2 = reply.messageId;
      }
    }

    if (newMessagePosition > 0) newMessagePosition++;

    TextChannelUtil.instance.stream.add(NewMessageEvent(message, force: true));
    update();

    final _awaitDatabaseFinish = awaitDatabaseFinish ?? false;
    final hasQuote = message.quoteL1 != null;
    try {
      if (canReadHistory) await dbMessageList.saveMessage(message);
      await message.content
          .startUpload(channelId: message.channelId)
          .timeout(const Duration(seconds: 120));

      message.mentionRoles = message.content.mentions.item1;
      message.mentions = message.content.mentions.item2;

      ///?????????????????????????????????mentionRoles????????????
      if (message.mentionRoles != null &&
          message.mentionRoles.isNotEmpty &&
          !PermissionUtils.oneOf(PermissionModel.getPermission(message.guildId),
              [Permission.MENTION_EVERYONE],
              channelId: message.channelId)) {
        message.mentionRoles = null;
      }

      final jsonObj = {
        ...message.toWsJson(),
        "nonce": nonce,
        if (message.mentionRoles != null) "mention_roles": message.mentionRoles,
        if (message.mentions != null) "mentions": message.mentions,
      };

      await InMemoryDb.addSendFailMessageId(message);
      final res = await Ws.instance.send(jsonObj);
      await InMemoryDb.deleteSendFailMessageId(message);

      // todo ??????/?????? ws ?????????
      final String messageId = res['message_id'];
      int status = -1;
      if (messageId != null) {
        status = res['status'];

        InMemoryDb.updateMessageId(BigInt.parse(messageId), message);

        // todo ????????????????????????????????????????????????????????????????????????
        CreditsBean.updateIfCreditsItemChange(
          res['member'],
          guildId: message.guildId,
          channelId: message.channelId,
          userId: message.userId,
          chatChannel: channel,
        );

        message
          ..messageId = messageId
          ..status = status
          ..time = DateTime.fromMillisecondsSinceEpoch(res['time']);
        message.reactionModel.messageId = messageId.toString();
      }

      if (status == 0) {
        message.content.messageState.value = MessageState.sent;
        // ?????????????????????????????????
        if (message.type == ChatChannelType.dm ||
            message.type == ChatChannelType.group_dm) {
          final String desc = jsonObj['desc'];
          final String channelId = message.channelId;

          /// ?????????desc????????????????????????????????????????????????????????????????????????????????????hive
          InMemoryDb.getMessageList(channelId).setLastMessageDesc(
              descMap: DmLastMessageDesc.normal(
            BigInt.parse(messageId),
            desc,
          ));
          //????????????
          DirectMessageController.to.bringChannelToTop(channel);
        }
      } else {
        message.content.messageState.value = MessageState.shield;
        jumpToBottom();
      }

      update();

      if (_awaitDatabaseFinish) {
        await ChatTable.deletePermanently(nonce, hasQuote: hasQuote);
      } else {
        unawaited(ChatTable.deletePermanently(nonce, hasQuote: hasQuote));
      }

      message.localStatus = MessageLocalStatus.normal;
      if (canReadHistory) {
        if (_awaitDatabaseFinish) {
          await InMemoryDb.getMessageList(message.channelId)
              .saveMessage(message);
        } else {
          unawaited(InMemoryDb.getMessageList(message.channelId)
              .saveMessage(message));
        }
      }
    } on CheckRejectException catch (_) {
      logger.finest("???????????????????????? ${await message.toNotificationString()}");

      ///fix: ???????????????????????????????????????????????????????????????
      bringChannelToTop(channel);

      if (message.content is ImageEntity) {
        final content = message.content as ImageEntity;
        content.url = content.asset.name;
      }
      message.content.messageState.value = MessageState.sent;
      if (_awaitDatabaseFinish) {
        await ChatTable.deletePermanently(nonce, hasQuote: hasQuote);
      } else {
        unawaited(ChatTable.deletePermanently(nonce, hasQuote: hasQuote));
      }
      await InMemoryDb.deleteSendFailMessageId(message);
      message.localStatus = MessageLocalStatus.illegal;
      if (canReadHistory)
        unawaited(
            InMemoryDb.getMessageList(message.channelId).saveMessage(message));
    } on WsUnestablishedException catch (e) {
      bringChannelToTop(channel);
      message.content.messageState.value = MessageState.timeout;

      ///????????????????????????????????????
      _connectStream.add(0);
      logger.severe("Send Message Error", e);
    } catch (e) {
      bringChannelToTop(channel);
      message.content.messageState.value = MessageState.timeout;
      logger.severe("Send Message Error", e);
    }

    try {
      saveSendAtUser(message);
    } catch (e, s) {
      logger.severe("saveSendAtUser", e, s);
    }
  }

  Future sendMessages(List<MessageEntity> messages,
      {MessageEntity reply}) async {
    if (messages.isNotEmpty) {
      /// ??????????????????
      CustomTrigger.instance.dispatch(QuestTriggerData(
        condition: QuestCondition([
          QIDSegQuest.sendFirstMessage,
          "-",
          messages[0].guildId,
          "-",
          messages[0].channelId,
        ]),
      ));
    }

    final List<String> nonceList = [];
    final dbMessageList = InMemoryDb.getMessageList(channelId);
    for (var i = 0; i < messages.length; i++) {
      final message = messages[i];
      final String nonce =
          ChatTable.generateLocalMessageId(dbMessageList?.lastMessageId);
      message
        ..localStatus = MessageLocalStatus.local
        ..messageId = nonce
        ..nonce = nonce;
      message.messageIdBigInt = BigInt.parse(nonce);
      dbMessageList.add(message);

      if (reply != null) {
        if (reply.quoteL1.noValue && reply.quoteL2.noValue) {
          message.quoteL1 = reply.messageId;
        } else {
          message.quoteL1 = reply.quoteL1;
          message.quoteL2 = reply.messageId;
        }
      }
      if (newMessagePosition > 0) newMessagePosition++;

      TextChannelUtil.instance.stream
          .add(NewMessageEvent(message, jump: false));
      update();

      nonceList.add(nonce);
    }
    jumpToBottom();

    for (var i = 0; i < messages.length; i++) {
      final message = messages[i];
      try {
        if (canReadHistory) await dbMessageList.saveMessage(message);
      } catch (e) {
        bringChannelToTop(channel);
        message.content.messageState.value = MessageState.timeout;
        logger.severe("Send Messages Error", e);
      }
    }

    for (var i = 0; i < messages.length; i++) {
      final message = messages[i];
      final nonce = nonceList[i];
      final hasQuote = message.quoteL1 != null;
      if (message.content.messageState.value == MessageState.timeout) continue;

      try {
        if (message.content is VideoEntity) {
          await (message.content as VideoEntity).compressAsset();
        } else if (message.content is ImageEntity) {
          await (message.content as ImageEntity).compressAsset();
        }
        if (canReadHistory)
          await InMemoryDb.getMessageList(message.channelId)
              .saveMessage(message);

        await message.content
            .startUpload(channelId: message.channelId)
            .timeout(const Duration(seconds: 120));
        final jsonObj = message.toJson();
        jsonObj["action"] = "send";
        jsonObj.remove("time");

        await InMemoryDb.addSendFailMessageId(message);
        final res = await Ws.instance.send(jsonObj);
        await InMemoryDb.deleteSendFailMessageId(message);
        final String messageId = res['message_id'];
        final status = res['status'];

        InMemoryDb.updateMessageId(BigInt.parse(messageId), message);
        message.status = status;
        message.reactionModel.messageId = messageId.toString();
        message.time = DateTime.fromMillisecondsSinceEpoch(res['time']);
        if (status == 0) {
          message.content.messageState.value = MessageState.sent;

          // ?????????????????????????????????
          if (message.type == ChatChannelType.dm ||
              message.type == ChatChannelType.group_dm) {
            final String desc = jsonObj['desc'];
            final String channelId = message.channelId;
            InMemoryDb.getMessageList(channelId).setLastMessageDesc(
                descMap: DmLastMessageDesc.normal(
              BigInt.parse(messageId),
              desc,
            ));
            //????????????
            DirectMessageController.to.bringChannelToTop(channel);
          }
        } else {
          message.content.messageState.value = MessageState.shield;
          jumpToBottom();
        }
        //TextChannelUtil.instance.stream.add(NewMessageEventAfterSent(message));

        unawaited(ChatTable.deletePermanently(nonce, hasQuote: hasQuote));
        message.localStatus = MessageLocalStatus.normal;
        if (canReadHistory)
          unawaited(InMemoryDb.getMessageList(message.channelId)
              .saveMessage(message));
      } on CheckRejectException catch (_) {
        logger.finest("???????????????????????? ${await message.toNotificationString()}");

        ///fix: ???????????????????????????????????????????????????????????????
        bringChannelToTop(channel);

        if (message.content is ImageEntity) {
          final content = message.content as ImageEntity;
          content.url = content.asset.name;
        }
        message.content.messageState.value = MessageState.sent;
        unawaited(ChatTable.deletePermanently(nonce, hasQuote: hasQuote));
        await InMemoryDb.deleteSendFailMessageId(message);
        message.localStatus = MessageLocalStatus.illegal;
        if (canReadHistory)
          unawaited(InMemoryDb.getMessageList(message.channelId)
              .saveMessage(message));
      } on WsUnestablishedException catch (e) {
        bringChannelToTop(channel);
        message.content.messageState.value = MessageState.timeout;

        ///????????????????????????????????????
        _connectStream.add(0);
        logger.severe("Send Messages Error", e);
      } catch (e) {
        bringChannelToTop(channel);
        message.content.messageState.value = MessageState.timeout;
        logger.severe("Send Messages Error", e);
      }
    }
    //????????????????????????????????????update?????????????????????????????????
    update();
  }

  Future<void> sendContents(
    List<MessageContentEntity> contents, {
    String guildId,
    MessageEntity relay,
    ChatChannelType channelType,
  }) async {
    final List<MessageEntity<MessageContentEntity>> messageList = [];
    final nowTime = DateTime.now();
    for (int i = 0; i < contents.length; i++) {
      final content = contents[i];
      content.messageState ??= MessageState.waiting.obs;
      final message = _wrapMessage(content,
          guildId: guildId,
          channelType: channelType,
          time: nowTime.add(Duration(milliseconds: i)));
      messageList.add(message);
    }

    await sendMessages(messageList, reply: relay);
  }

  Future<void> sendContent(
    MessageContentEntity content, {
    String guildId,
    MessageEntity reply,
    ChatChannelType channelType,
    bool awaitDatabaseFinish,
  }) async {
    final message =
        _wrapMessage(content, guildId: guildId, channelType: channelType);

    await sendMessage(message,
        reply: reply, awaitDatabaseFinish: awaitDatabaseFinish);
  }

  Future<void> resend(MessageEntity<MessageContentEntity> message) async {
    message.content.messageState.value = MessageState.waiting;
    update();

    final bool hasQuote = message.quoteL1 != null || message.quoteL2 != null;

    final String channelId = message.channelId;
    final int sendTime = message.time.millisecondsSinceEpoch ~/ 1000;
    final String nonce = message.nonce;

    final ResendResp res =
        await TextChatApi.checkReSend(channelId, sendTime, nonce);

    unawaited(
        ChatTable.deletePermanently(message.messageId, hasQuote: hasQuote));
    InMemoryDb.removeMessage(message);
    if (res != null) {
      final String messageId = res.messageId;
      final int time = res.timestamp;
      message
        ..messageId = messageId
        ..status = 0
        ..time = DateTime.fromMillisecondsSinceEpoch(time);
      message.reactionModel.messageId = messageId.toString();
      message.localStatus = MessageLocalStatus.normal;
      message.content.messageState.value = MessageState.sent;

      InMemoryDb.updateMessageId(BigInt.parse(messageId), message);
      update();
    } else {
      //???????????????
      if (message.content is VideoEntity || message.content is ImageEntity) {
        await sendMessages([message]);
      } else {
        await sendMessage(message);
      }
    }
  }

  MessageEntity _wrapMessage(
    MessageContentEntity content, {
    String guildId,
    ChatChannelType channelType,
    DateTime time,
  }) {
    // todo ?????????????????????????????????????????? guildId
    var gid = guildId ?? this.guildId;
    channelType ??= channel.type;
    if (channelType == ChatChannelType.dm) gid = null;

    return MessageEntity(
      MessageAction.send,
      channelId,
      Global.user.id,
      gid,
      time ?? DateTime.now(),
      content,
      type: channelType,
    );
  }

  Future<void> onNewMessage(
    MessageEntity message, {
    @required Map author,
    @required Map member,
    bool privateMsg = false,
  }) async {
    if (message.channelType == ChatChannelType.unsupported ||
        message.channelType == ChatChannelType.circlePostNews ||
        message.channelType == ChatChannelType.circleNews) {
      ///??????????????????????????????????????????????????????
      return;
    }

    final messageList = InMemoryDb.getMessageList(message.channelId);
    if (privateMsg) message.localStatus = MessageLocalStatus.temporary;

    if (message.content is DuEntity) {
      final DuEntity duEntity = message.content as DuEntity;

      final String voteId = duEntity.voteId;
      final String url = duEntity.url;
      final duIsVoted = duEntity.isVoted; //0???????????????????????????1???????????????????????????null?????????????????????????????????
      final Map map = Db.voteCardBox.get(voteId);
      final isVoted = map != null ? map['isVoted'] ?? 0 : 0;

      if (duEntity.userId == Global.user.id || map == null) {
        await VoteItemBuilder.updateFormNet(
            voteId, url, message.guildId, message.channelId);
        return;
      }

      /// ??????????????????????????????????????????????????????
      final theSameStatus = duIsVoted != null && duIsVoted == isVoted;
      if (theSameStatus || duIsVoted == null) {
        VoteItemBuilder.updateFromXPath(voteId, duEntity.xpath);
      }

      return;
    }

    final requestNow =
        message.channelId == GlobalState.selectedChannel.value?.id ||
            message.channelId == TextChannelController.dmChannel?.id;
    CreditsBean.updateIfCreditsItemChange(
      member,
      guildId: message.guildId,
      channelId: message.channelId,
      userId: message.userId,
      requestNow: requestNow,
    );

    await messageList.saveMessage(message,
        author: author, privateMsg: privateMsg);

    final content = message.content;
    switch (content.runtimeType) {
      case MessageModificationEntity:
        onModifyMessage(message);
        return;
      case RecallEntity:
        final String channelId = message.channelId;
        final String messageId = (content as RecallEntity).id;
        ChannelUtil.instance.removeUnreadBeforeMessageId(channelId, messageId);

        onMessageRecalled((content as RecallEntity).id, message.userId);
        if (message.userId != Global.user.id)
          unawaited(_pushLocalNotification(message));
        return;
      case ReactionEntity2:
        TextChannelUtil.instance.stream.add(ReactMessageEvent(message));
        final entity = content as ReactionEntity2;

        final String channelId = message.channelId;
        final String messageId = entity.id;
        final String emojiName = entity.emoji.name;
        final bool me = message.userId == Global.user.id;
        final int count = entity.emoji.count;

        if (entity.action == "add") {
          //_reactionStream.add(message);
          await _onAddReaction(channelId, messageId, emojiName, me, messageList,
              count: count);
          if (!me) unawaited(_pushLocalNotification(message));
        } else if (entity.action == "del") {
          //_reactionStream.add(message);
          await _onDelReaction(channelId, messageId, emojiName, me, messageList,
              count: count);
        } else if (entity.action == "delAll") {
          //_reactionStream.add(message);
          await _onDelAllReaction(
              channelId, messageId, emojiName, me, messageList);
        }
        return;
      case AddFriendTipsEntity:
        //?????????????????????UI?????????????????????
        messageList.add(message);
        update();
        TextChannelUtil.instance.stream.add(NewMessageEvent(message));
        return;
    }

    final bool isShield = (message.type == ChatChannelType.dm ||
            message.type == ChatChannelType.group_dm) &&
        message.userId != Global.user.id &&
        message.status != 0;
    if (isShield) return;

    messageList.add(message);

    if (message.roleIds != null) {
      RoleBean.update(message.userId, message.guildId, message.roleIds);
    }

    final atMe = MessageUtil.atMeInMentions(message) != AtMeType.none;
    bool shouldCheckPopupCustomKeyboard = false;

    if (isSelectedChannel()) {
      final focusOutChatWindow =

          /// app ?????????????????????????????????????????????
          HomeScaffoldController.to.windowIndex.value != 1 ||

              /// app ???????????????????????????????????????
              WidgetsBinding.instance.lifecycleState ==
                  AppLifecycleState.paused;
      if ((focusOutChatWindow ||
              newMessagePosition > 0 ||
              numBottomInvisible > 1) &&

          /// ?????????????????????????????????????????????????????????????????????????????????
          listIsIdentical()) {
        newMessagePosition++;
      }

      if (kIsWeb) forceInitialIndex = null;

      bool isSameTopic() {
        if (message.quoteL2 == null || message.quoteL1 == null) return false;
        return InMemoryDb.getMessage(message.channelId,
                    BigInt.parse(message.quoteL2 ?? message.quoteL1))
                ?.userId ==
            Global.user.id;
      }

      if (message.channelType == ChatChannelType.dm || atMe || isSameTopic()) {
        shouldCheckPopupCustomKeyboard = true;
      }
    }

    update();

    if (shouldCheckPopupCustomKeyboard) {
      _checkPopupCustomKeyboard(message);
    }

    /// ????????????????????????????????????
    if (message.userId != Global.user.id) {
      if (MessageUtil.canISeeThisMessage(message)) {
        /// ????????????????????????
        if (message.channelType != ChatChannelType.guildCircleTopic)
          unawaited(_pushLocalNotification(message));

        ChannelUtil.instance.updateFirstMessageIdBox(message);

        //?????????????????????????????????????????????
        if (messageList.remoteSynchronized) {
          ChannelUtil.instance.increaseUnread(message);
        }

        if (FriendListPageController.to.isMyFriend(message.userId)) {
          ChannelUtil.increaseHotChatFriend(
              message.channelId,
              message.userId,
              message.time
                  .add(const Duration(minutes: 15))
                  .millisecondsSinceEpoch);
        }

        //????????????????????????????????????
        if (atMe) {
          ChannelUtil.instance
              .increaseAtMessageNum(message.channelId, message.messageId);
        }
      }
    }

    if (message.channelType == ChatChannelType.dm ||
        message.channelType == ChatChannelType.group_dm) {
      await DirectMessageController.to.notifyDirectMessage(message);
      GlobalState.updateBadge();
    }

    TextChannelUtil.instance.stream.add(NewMessageEvent(message));
    //TextChannelUtil.instance.stream.add(NewMessageEventAfterSent(message));
  }

  ///?????????internalList ??? InMemoryDb??????MessageList ????????????
  ///???????????????????????????????????????????????????????????????????????????????????????????????????????????????
  bool listIsIdentical() {
    return internalList == InMemoryDb.getMessageList(channelId);
  }

  ///??????????????????
  Future<void> loadHistory({bool firstLoad = false}) async {
    if (isLoadingHistory) return;
    // ?????????????????????????????????????????????????????????????????????????????????????????????
    if (loadHistoryState == LoadMoreStatus.noMore) return;
    if (internalList != null &&
        internalList.isNotEmpty &&
        internalList.first.content is StartEntity) return;

    isLoadingHistory = true;

    debugPrint('start load history');

    int numNewMessages = 0;
    if (!firstLoad) {
      try {
        numNewMessages =
            await internalList.readHistory(retryTimes: _kBatchMsgRetryTimes);
        if (numNewMessages == -1) {
          isLoadingHistory = false;
          return;
        }
      } catch (e) {
        isLoadingHistory = false;
        logger.warning("error in [readHistory] $e");
        return;
      }
    }
    if (numNewMessages == 0) {
      final firstValidMessageId = internalList?.firstValidMessage?.messageId;
      debugPrint('getChat loadHistory channelId:$channelId '
          'firstMessageId:$firstValidMessageId firstLoad:$firstLoad');

      final guildId = channel.guildId;
      List<MessageEntity> messages = await TextChatApi.getMessages(
              Global.user.id, channelId, firstValidMessageId,
              retryTimes: _kBatchMsgRetryTimes,
              mutexOption: _getListMutexOption)
          .catchError((e) {
        logger.warning("error in [TextChatApi.getMessages] $e");
        isLoadingHistory = false;
      });

      if (messages == null) {
        isLoadingHistory = false;
        return;
      }

      if (messages.isEmpty || messages.first.content is StartEntity) {
        loadHistoryState = LoadMoreStatus.noMore;
        showLoading = false;
      }

      messages = messages.map((e) {
        //todo ?????????channel????????????guildId,????????????,???????????????guildId,?????????????????????????????????
        if (channel.type != ChatChannelType.dm &&
            channel.type != ChatChannelType.group_dm) e.guildId = guildId;
        final element = e;
        if (element.content.runtimeType == VoiceEntity)
          (element.content as VoiceEntity).isRead = true;
        return element;
      }).toList();

      ///?????????????????????????????????
      if (listIsIdentical()) {
        debugPrint('getChat loadHistory channelId:$channelId - save');
        await _saveMessagesToDbAndRefreshList(messages);
      } else {
        debugPrint('getChat loadHistory channelId:$channelId - not save');
        internalList.addAll(messages);
      }

      if (messages.isNotEmpty) {
        if (internalList.isNotEmpty &&
            firstLoad &&
            !Db.lastMessageIdBox.containsKey(channelId)) {
          ChannelUtil.instance.updateLastMessageIdBoxById(
              channelId, internalList.lastMessage.messageId);
        }
      }
      numNewMessages = messages.length;
    }

    ///????????????????????????????????????forceInitialIndex?????????chat_view????????????
    if (!firstLoad) forceInitialIndex = numNewMessages + 1;

    ///???????????????(???????????????????????????????????????????????????)???listKey???chatView???????????????
    listKey = ValueKey(listKey.value + 1);
    update();

    ///update????????????????????????????????????????????????????????????????????????
    isLoadingHistory = false;
    debugPrint('load history finish');
  }

  Future<void> _saveMessagesToDbAndRefreshList(
      List<MessageEntity> messages) async {
    await ChatTable.appendAll(messages, isUpdate: true);
    InMemoryDb.getMessageList(channelId).addAll(messages);
  }

  ///?????????????????????????????????InMemoryDb
  Future<void> _readLastPageToMemory() async {
    debugPrint('getChat readLastPage: $channelId start');
    final messageList = MessageList(channelId,
        notSyncMessageId: internalList?.notSyncMessageId,
        remoteSynchronized: internalList?.remoteSynchronized);
    final readNum = await messageList.readHistory(
        retryTimes: _maxBatchMsgRetryTimes, mutexOption: _batchMsgMutexOption);
    if (readNum <= 0) return;
    InMemoryDb.map[channelId] = messageList;
    debugPrint('getChat readLastPage: $channelId readNum:$readNum');
    if (internalList.isNotEmpty &&
        messageList.firstMessageId <= internalList.lastMessageId) {
      debugPrint('getChat readLastPage: $channelId update');
      InMemoryDb.map[channelId].addAll(internalList.list);
      internalList = InMemoryDb.map[channelId];
      update();
    }
  }

  ///??????????????????
  Future<void> loadMore() async {
    if (isLoadingMore) return;
    internalList ??= InMemoryDb.getMessageList(channelId);
    if (loadMoreState == LoadMoreStatus.noMore ||
        (internalList?.isEmpty ?? true)) return;
    isLoadingMore = true;
    debugPrint('start load more');
    final lastValidMessageId = internalList.lastMessageId;
    List<MessageEntity> history;
    int localLoadNum = 0;
    final lengthBeforeLoadMore = messageList.length;

    ///???????????????????????????????????????
    final lastMessage =
        await ChatTable.getMessage(lastValidMessageId.toString());
    if (lastMessage != null) {
      try {
        localLoadNum = await internalList.readHistory(
            retryTimes: _kBatchMsgRetryTimes, before: false);
        debugPrint("getChat loadMore 1 localLoadNum???$localLoadNum");
        if (localLoadNum == -1) {
          isLoadingMore = false;
          return;
        }

        ///???????????????????????????????????????????????????????????????
        if (localLoadNum == 0 &&
            lastValidMessageId <
                Db.lastVisibleMessageIdBox
                    .get(channelId, defaultValue: BigInt.from(0))) {
          isLoadingMore = false;
          loadMoreState = LoadMoreStatus.noMore;
          return;
        }
      } catch (e) {
        isLoadingMore = false;
        return;
      }
      if (newMessagePosition > 0) newMessagePosition += localLoadNum;
    }

    ///??????????????????????????????0?????????????????????
    if (localLoadNum == 0) {
      try {
        history = await TextChatApi.getMessages(
            Global.user.id, channelId, lastValidMessageId.toString(),
            before: false);
      } catch (e) {
        isLoadingMore = false;
        return;
      }
      debugPrint("getChat loadMore 2 length???${history?.length}");
      if (history.isNotEmpty) {
        history = history.map((e) {
          e.guildId = guildId;
          final element = e;
          if (element.content.runtimeType == VoiceEntity)
            (element.content as VoiceEntity).isRead = true;
          return element;
        }).toList();
        internalList.addAll(history);
        if (newMessagePosition > 0) newMessagePosition += history.length;
      }
    }

    ///?????????????????????InMemoryDb???MessageList
    if (!listIsIdentical()) {
      final dbMessageList = InMemoryDb.getMessageList(channelId);
      if (localLoadNum > 0) {
        if (internalList.lastMessageId >= dbMessageList.firstMessageId) {
          dbMessageList.addAll(internalList.list);
          internalList = dbMessageList;
          debugPrint("getChat loadMore 6?????? InMemoryDB ???????????????");
        }
      } else {
        if (history.isNotEmpty) {
          if (internalList.lastMessageId >= dbMessageList.firstMessageId) {
            debugPrint("getChat loadMore 7?????? InMemoryDB ???????????????");
            await _saveMessagesToDbAndRefreshList(internalList.list);
            internalList = dbMessageList;
          }
        } else {
          debugPrint("getChat loadMore 8");
          internalList = dbMessageList;
        }
      }
    }
    if (localLoadNum > 0 || history.isNotEmpty) {
      forceInitialIndex = lengthBeforeLoadMore + 1;
      useForceIndex = false;
      loadMoreForceUpdate = true;
    }
    brController.resetLoadMoreState();
    update();

    ///update????????????????????????????????????????????????????????????
    isLoadingMore = false;
    debugPrint('load more finish');
  }

  // ignore: unused_element
  Future _pushCircleNotification(Map data) async {
    if (App.appLifecycleState == AppLifecycleState.resumed && !kIsWeb) return;
    final receiveId = data['receive_id'].toString();
    final sendId = data['send_id'].toString();
    final ownerId = data['owner_id'].toString();
    final isPush = data['is_push'].toString();
    final method = data['method'].toString();
    if (isPush == 'false') return;
    if (sendId == Global.user.id) return;
    if ((receiveId == Global.user.id || ownerId == Global.user.id) &&
        (method == "reaction" || method == "comment")) {
      final userId = data['user_id'];
      final type = data['circle_type'];
      final content = data['content'];
      final userInfo = (await UserApi.getUserInfo([userId])).single;
      String nickName = _fetchUserSenderName(userInfo);
      nickName = nickName.takeCharacter(8);
      var notificationTitle = "";
      var notificationContent = ' ';
      switch (type) {
        case "post_like":
          notificationTitle = "[$nickName]????????????????????????";
          break;
        case "post_comment":
          notificationTitle = "[$nickName]????????????????????????";
          final document = Document.fromJson(jsonDecode(content));
          notificationContent = document.toContent().replaceAll('\n', '');
          break;
        case "comment_comment":
          notificationTitle = receiveId == Global.user.id
              ? "[$nickName]???????????????"
              : "[$nickName]????????????????????????";
          final document = Document.fromJson(jsonDecode(content));
          notificationContent = document.toContent().replaceAll('\n', '');
          break;
        case "comment_like":
          notificationTitle = "[$nickName]????????????????????????";
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

  Future<void> _pushLocalNotification(MessageEntity message) async {
    if (App.appLifecycleState == AppLifecycleState.resumed &&
        !kIsWeb &&
        (Platform.isIOS || Platform.isAndroid)) return;

    if (message.channelType == ChatChannelType.dm ||
        message.channelType == ChatChannelType.group_dm) {
      final bool isMuted = (Db.userConfigBox.get(UserConfig.mutedChannel) ?? [])
          .contains(message.channelId);
      final isAtMe = (message?.mentions?.hasValue ?? false) &&
          message.mentions.contains(Global.user.id);
      if (message.channelType == ChatChannelType.group_dm && isMuted && !isAtMe)
        return;

      final userInfo = await UserInfo.get(message.userId);
      final String sendName = _fetchUserSenderName(userInfo);

      String title;
      String content = await message.toNotificationString();
      bool isAddBadge = true;

      if (message.content is DocumentEntity) {
        final List<String> idList = MessageUtil.getUserIdListInText(content);
        if (idList.hasValue) {
          idList.forEach(UserInfo.get);
          content = MessageUtil.getDescStringForDm(
            content,
            atPre: '@',
            guildId: message.guildId,
          );
        }
      }

      if (message.channelType == ChatChannelType.group_dm &&
          message.content is! ReactionEntity2) {
        ChatChannel c = Db.channelBox.get(message.channelId);
        if (c == null || c.name == null) {
          c = await GuildApi.getGroupInfo(message.channelId);
          await Db.channelBox.put(c.id, c);
        }
        if (c != null && c.name != null) {
          title = c.name;
          content = "$sendName: $content";
        }

        if (title == null || title.isEmpty) {
          return;
        }
      } else {
        title = sendName;
      }

      /// ?????????????????????????????????
      if (message.content is RecallEntity) content = "?????????????????????".tr;
      //  ????????????
      if (message.content is ReactionEntity2) {
        final ReactionEntity2 reactionEntity = message.content;

        ///???????????????notify
        if (TopicController.isSurrounding(reactionEntity.emoji.name)) return;

        final originMessageId = (message.content as ReactionEntity2).id;
        final originMessage =
            await MessageUtil.getMessage(originMessageId, channelId);
        if (Global.user.id == originMessage.userId) {
          title = await originMessage.toNotificationString();
          content = "$sendName ??????:$content";
        } else {
          return;
        }
        isAddBadge = false;
      } else if (message.content is RecallEntity) {
        isAddBadge = false;
      } else if (message.content is CallEntity) {
        return;
      }
      unawaited(JPushUtil.pushNotification(
          title: title,
          content: content,
          fireTime: DateTime.now().add(const Duration(milliseconds: 100)),
          addBadge: isAddBadge,
          sound: UniversalPlatform.isIOS ? "ring2.caf" : "ring2.mp3",
          extra: {
            "channel_id": message.channelId.toString(),
            "message_id": message.messageId.toString(),
            'type': JPushType.channel.toString()
          }));
    } else {
      await _pushLocalNotificationForChannel(message);
    }
  }

  void onMessageRecalled(String messageId, String recalledBy) {
    changeMemoryMessage(
        callback: (message, map) {
          message.recall = recalledBy;
          message.content?.messageState?.value = MessageState.sent;
        },
        messageId: BigInt.parse(messageId));

    TextChannelUtil.instance.stream
        .add(RecallMessageEvent(messageId, recalledBy, channelId));
    unawaited(ChatTable.markRecalled(messageId, recalledBy));
    ChannelUtil.instance.recallAtMessage(channelId, messageId);
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

  // ????????????
  void mergeReactions(List<MessageEntity> reactions) {
    final Map<String, ReactionItem> rcMap = {};

    for (final MessageEntity r in reactions) {
      final rc = r.content as ReactionEntity2;

      final BigInt msgId = BigInt.parse(rc.id);
      final String name = rc.emoji.name;
      final int me = r.userId == Global.user.id ? 1 : 0;
      final String ac = rc.action;
      final int count = ac == 'add' ? 1 : -1;

      final String key = '$msgId@$name';
      if (rcMap[key] == null) {
        rcMap[key] =
            ReactionItem(msgId: msgId, name: name, count: count, me: me);
      } else {
        final ReactionItem temp = rcMap[key];
        temp.count = temp.count + count;
        temp.me = (temp.me == 1 || me == 1) ? 1 : 0;
      }
    }
    rcMap.forEach((key, value) async {
      final message = InMemoryDb.getMessage(channelId, value.msgId);
      if (message != null && message.reactionModel != null) {
        final ReactionModel model = message.reactionModel;
        final ReactionEntity entity =
            ReactionEntity(value.name, count: value.count, me: value.me == 1);

        await model.appendByNotPull(entity);

        //todo ???????????????ws?????????????????????????????????????????????
        ///????????????????????????????????????????????????????????????????????????UI
        if (Get.currentRoute == get_pages.Routes.TOPIC_PAGE) {
          final NotPullEvent notPullEvent = NotPullEvent(
              message.messageId, value.name, value.count, value.me == 1);
          TextChannelUtil.instance.stream.add(notPullEvent);
        }
      } else {
        await ReactionTable.appendByNotPullDbCount(
            value.msgId.toString(), value.name, value.me == 1,
            count: value.count);
      }
    });
  }

  Future<void> _onAddReaction(String channelId, String messageId,
      String emojiName, bool me, MessageList messageList,
      {int count = 1}) async {
    final message = InMemoryDb.getMessage(channelId, BigInt.parse(messageId));
    if (message != null && message.reactionModel != null) {
      final ReactionModel model = message.reactionModel;
      await model.append(emojiName, me, count: count);
    } else {
      await ReactionTable.appendByDbCount(messageId, emojiName, count, me);
    }
  }

  Future<void> _onDelReaction(String channelId, String messageId,
      String emojiName, bool me, MessageList messageList,
      {int count = 1}) async {
    final message = InMemoryDb.getMessage(channelId, BigInt.parse(messageId));
    if (message != null && message.reactionModel != null) {
      final ReactionModel model = message.reactionModel;
      await model.remove(emojiName, me, count: count);
    } else {
      await ReactionTable.removeByDbCount(messageId, emojiName, count, me);
    }
  }

  Future<void> _onDelAllReaction(String channelId, String messageId,
      String emojiName, bool me, MessageList messageList) async {
    final message = InMemoryDb.getMessage(channelId, BigInt.parse(messageId));
    if (message != null && message.reactionModel != null) {
      final model = message.reactionModel;
      await model.removeAll(emojiName, me);
    } else {
      await ReactionTable.removeByDbCount(messageId, emojiName, 0, me);
    }
  }

  /// ?????????????????????????????????
  void deleteMessage(String messageId) {
    MessageEntity message2;
    changeMemoryMessage(
        messageId: BigInt.parse(messageId),
        callback: (message, map) {
          message.deleted = 1;
          map.remove(message.messageIdBigInt);

          /// ???????????????????????????????????????????????????????????????????????????
          InMemoryDb.getMessageList(channelId).addCache(message);
          message2 = message;
        });

    ChatTable.markDeleted(messageId);

    TextChannelUtil.instance.stream
        .add(DeleteMessageEvent(messageId, message2));

    internalList.setLastMessageDesc(
        message: internalList.getFromCache(messageId));
    update();
  }

  Future<void> _pushLocalNotificationForChannel(MessageEntity message) async {
    String getAtString(MessageEntity message) {
      ///  @???????????? @???????????? @???
      if ((message?.mentions?.hasValue ?? false) &&
          message.mentions.contains(Global.user.id)) {
        return "@???".tr;
      }
      if (message?.mentionRoles?.hasValue ?? false) {
        if (message.mentionRoles.contains(message.guildId)) {
          return "@????????????".tr;
        } else {
          final roleId = PermissionModel.getPermission(message.guildId)
              .userRoles
              .firstWhere((element) => message.mentionRoles.contains(element),
                  orElse: () => null);
          if (roleId != null) {
            final role = PermissionModel.getPermission(message.guildId)
                .roles
                .firstWhere((element) => roleId == element.id);
            return (role?.name?.hasValue ?? false)
                ? "@${role.name}"
                : "@??????????????????".tr;
          }
        }
      }
      return "";
    }

    // ???????????????????????? @???????????? @???????????? @??? ???????????? ?????????????????????????????????
    final userInfo = await UserInfo.get(message.userId);
    String senderName =
        _fetchUserSenderName(userInfo, guildId: message.guildId);

    senderName = senderName.length > 16
        ? "${subRichString(senderName, 16)}..."
        : senderName;
    String subString = "";
    final chatTargetAndChannel = ChatTargetsModel.instance
        .getChatTargetAndChannelByChannelId(message.channelId);
    String reactionOriginContent = '';
    if (chatTargetAndChannel == null) return;

    // ???????????????????????????????????????
    final isChannelMuted = await UserConfig.isChannelMuted(message.channelId);
    // ?????????????????????????????????@??????????????????
    final atString = getAtString(message);

    if (isChannelMuted && atString.isEmpty) return;

    // ???????????????????????????,??????@???????????????
    final guildTarget =
        ChatTargetsModel.instance.getChatTarget(message.guildId) as GuildTarget;
    if (guildTarget.memberCount > guildTarget.guildPushThreshold &&
        atString.isEmpty) return;
    // ???????????????????????????APP???????????????????????????????????????maxNotiCountInBg??????at??????????????????????????????????????????
    if (atString.isEmpty && ServerSideConfiguration.to.serverEnableNotiInBg) {
      final userEnableNofitifactionMute =
          Db.userConfigBox.get(UserConfig.notificationMuteKey) ?? false;
      if (userEnableNofitifactionMute) {
        if (ServerSideConfiguration.to.currentNotiCountInBg >=
            ServerSideConfiguration.to.maxNotiCountInBg) {
          return;
        } else {
          ServerSideConfiguration.to.currentNotiCountInBg++;
        }
      }
    }

    // ??????????????????????????????????????????
    // if (chatTargetAndChannel.item1.unreadMark == UnreadMark.redDot) {
    final quoteL1MessageEntity = await ChatTable.getMessage(message.quoteL1);
    final quoteL2MessageEntity = await ChatTable.getMessage(message.quoteL2);
    if (quoteL1MessageEntity != null &&
        quoteL1MessageEntity.userId == Global.user.id) {
      // ????????????
      subString = "?????????".tr;
    } else if (quoteL2MessageEntity != null &&
        quoteL2MessageEntity.userId == Global.user.id) {
      // ????????????
      subString = "?????????".tr;
    } else if (message.content is WelcomeEntity) {
      // ????????????
      subString = "";
    } else if (message.content is ReactionEntity2) {
      final originMessageId = (message.content as ReactionEntity2).id;
      final originMessage =
          await MessageUtil.getMessage(originMessageId, channelId);
      if (Global.user.id == originMessage.userId) {
        reactionOriginContent = await originMessage.toNotificationString();
        subString += "??????".tr;
      } else {
        return;
      }
    }
    // } else {
    //   // ?????????????????????????????????
    //   if (message.content is TextEntity) {
    //     subString = getAtString(message);

    //     /// ??????????????????@?????????????????????
    //     if (subString.isEmpty) return;
    //   } else if (message.content is RecallEntity) {
    //     final m = InMemoryDb.getMessage(
    //         message.channelId, (message.content as RecallEntity).id);
    //     if (m == null) return;

    //     /// ???????????????????????????@?????????????????????
    //     if (getAtString(m).isEmpty) return;
    //   } else if (message.content is RichTextEntity) {
    //     subString = getAtString(message);

    //     /// ??????????????????@?????????????????????
    //     if (subString.isEmpty) return;
    //   } else if (message.content is ReactionEntity2) {
    //     final originMessageId = (message.content as ReactionEntity2).id;
    //     final originMessage =
    //         await MessageUtil.getMessage(originMessageId, channelId);
    //     if (Global.user.id == originMessage.userId) {
    //       reactionOriginContent = await originMessage.toNotificationString();
    //       subString += "??????:".tr;
    //     } else {
    //       return;
    //     }
    //   } else {
    //     return;
    //   }
    // }

    String title = "${chatTargetAndChannel.item1.name}???";
    switch (chatTargetAndChannel.item2.type) {
      case ChatChannelType.dm:
      case ChatChannelType.guildText:
        title += "#";
        break;
      case ChatChannelType.guildVoice:
        title += "????".tr;
        break;
      case ChatChannelType.guildVideo:
        title += "????".tr;
        break;
      case ChatChannelType.guildCategory:
        break;
      default:
        break;
    }
    title += chatTargetAndChannel.item2.name;

    String content = await message.toNotificationString();

    if (message.content is ReactionEntity2) {
      ///???????????????notify
      if (TopicController.isSurrounding(
          (message.content as ReactionEntity2).emoji.name)) return;

      content = "$reactionOriginContent\n$senderName$subString???$content";
    } else if (message.content is DocumentEntity) {
      final List<String> idList = MessageUtil.getUserIdListInText(content);
      if (idList.hasValue) {
        idList.forEach(UserInfo.get);
        content = MessageUtil.getDescStringForDm(
          content,
          atPre: '@',
          guildId: message.guildId,
          hideGuildNickname: false,
        );
      }

      ///???case???????????????????????????case???????????????
    } else if (message.content is! WelcomeEntity &&
        message.content is! CircleShareEntity) {
      content = "$senderName$subString???$content";
    }

    await JPushUtil.pushNotification(
        title: title,
        content: content,
        fireTime: DateTime.now().add(const Duration(milliseconds: 100)),
        addBadge: false,
        sound: UniversalPlatform.isIOS ? "ring2.caf" : "ring2.mp3",
        extra: {
          "channel_id": message.channelId.toString(),
          "message_id": message.messageId.toString(),
          'type': JPushType.channel.toString()
        });
  }

  ///?????????????????????????????????
  ///before: ??????????????????
  Future<void> gotoMessage(String messageId,
      {bool showDefaultErrorToast = false, bool before = true}) async {
    ///??????internalList??????
    int index = internalList.list.indexWhere(
        (e) => e.messageId == messageId && e.deleted == 0 && e.recall.noValue);
    debugPrint('getChat ??????: index:$index, id:$messageId???before:$before');

    ///??????InMemoryDb?????????
    if (!listIsIdentical() && index < 0) {
      index = InMemoryDb.map[channelId].list.indexWhere((e) =>
          e.messageId == messageId && e.deleted == 0 && e.recall.noValue);
      if (index > -1) {
        debugPrint('getChat ??????, InMemoryDb?????????, index:$index');
        internalList = InMemoryDb.map[channelId];
        brController.resetLoadMoreState();
        forceInitialIndex = index + 2;
        useForceIndex = before;
        update();
        return;
      }
    }

    if (index > -1) {
      debugPrint("getChat ?????????internalList?????????");
      if (!before) index++;
      jumpToIndex(max(0, index), alignment: before ? 0 : 1);
      brController.resetLoadMoreState();
    } else {
      final MessageEntity jumpMessage = await ChatTable.getMessage(messageId);
      //????????????????????????????????????????????????????????????????????????
      if (jumpMessage != null && !jumpMessage.displayable) return;
      final messageList = MessageList(channelId,
          notSyncMessageId: internalList?.notSyncMessageId,
          remoteSynchronized: internalList?.remoteSynchronized);

      bool isInLocal = false;
      if (jumpMessage != null) {
        debugPrint("getChat ????????????????????????");
        messageList.addAll(await messageList.getMessageNearHistory(messageId,
            showDefaultErrorToast: showDefaultErrorToast, before: before));
        isInLocal = true;
      } else {
        debugPrint("getChat ????????????????????????");
        //???????????? addAll ????????? .. ???????????????????????????????????????????????????
        messageList.addAll(await TextChatApi.getMessagesNear(
            channelId, messageId,
            showDefaultErrorToast: showDefaultErrorToast));
      }
      internalList = messageList;
      final jumpMessageIndex =
          internalList.list.indexWhere((e) => e.messageId == messageId);
      if (isInLocal)
        newMessagePosition = internalList.length - jumpMessageIndex;

      brController.resetLoadMoreState();
      forceInitialIndex = jumpMessageIndex + (before ? 1 : 2);
      useForceIndex = before;
      debugPrint(
          'getChat ?????? forceInitialIndex:$forceInitialIndex useForceIndex:$useForceIndex');
      update();
    }
  }

  void onModifyMessage(MessageEntity message) {
    final content = message.content as MessageModificationEntity;
    final messageToModify = InMemoryDb.getMessageList(message.channelId)
        .get(BigInt.parse(content.messageId));
    messageToModify?.content = content.content;
    messageToModify?.replyMarkup = content.replyMarkup;

    listKey = ValueKey(listKey.value + 1);
    update();
    ChatTable.modifyMessage(
      content.messageId,
      content: content.content,
      replyMarkup: content.replyMarkup,
    );
  }

  Future<void> onPullModifyMessage(MessageEntity message) async {
    if (message?.channelId == GlobalState.selectedChannel.value?.id &&
        message?.content is MessageModificationEntity) {
      final content = message.content as MessageModificationEntity;

      final List<MessageEntity> list = await TextChatApi.getBatchMessages(
          message.channelId, [content.messageId]);

      list.forEach((e) {
        final messageToModify = InMemoryDb.getMessageList(e.channelId)
            .get(BigInt.parse(e.messageId));
        messageToModify?.content = e.content;
        messageToModify?.replyMarkup = e.replyMarkup;
        update();
        ChatTable.modifyMessage(
          e.messageId,
          content: e.content,
          replyMarkup: e.replyMarkup,
        );
      });
      return;
    }

    final String modifyMessageId =
        (message.content as MessageModificationEntity)?.messageId;
    if (modifyMessageId.noValue) return;
    ChatTable.modifyMessageLocalStatus(
        modifyMessageId, MessageLocalStatus.incomplete);
  }

  void _checkPopupCustomKeyboard(MessageEntity message) {
    final replyMarkup = message.replyMarkup;
    if (replyMarkup == null) return;

    if (replyMarkup.keyboard != null) {
      customKeyboardMessage = message;
      TextChannelUtil.instance.stream.add(CustomKeyboardEvent(channelId, true));
    }

    if (replyMarkup.removeKeyboard == true) {
      customKeyboardMessage = null;
      TextChannelUtil.instance.stream
          .add(CustomKeyboardEvent(channelId, false));
    }
  }

  /// ??????????????????????????????????????????
  void _findCustomKeyboardMessage(
      List<MessageEntity<MessageContentEntity>> list) {
    for (int i = list.length - 1; i >= 0; i--) {
      final replyMarkup = list[i].replyMarkup;
      if (replyMarkup == null) continue;

      if (replyMarkup.keyboard != null) {
        customKeyboardMessage = list[i];
        break;
      }

      if (replyMarkup.removeKeyboard == true) {
        break;
      }
    }
  }

  /// ?????????????????????????????????????????????????????????????????????????????? messageList ??????????????????
  /// ??????????????????????????????????????????????????????????????????????????????????????????????????????
  /// ?????????https://idreamsky.feishu.cn/wiki/wikcnuLlWcVRi3GXIfKs2oNju0Y
  void changeMemoryMessage({
    @required BigInt messageId,
    @required
        void Function(
                MessageEntity message, SplayTreeMap<BigInt, MessageEntity> list)
            callback,
  }) {
    if (internalList != null) {
      /// ???????????????????????????????????????????????????????????? internalList ??????
      final message = internalList.get(messageId);
      if (message != null) {
        callback(message, internalList.getSplayTreeMap());
        update();
      }
    }
    if (listIsIdentical()) return;

    /// ??????????????????????????????????????????????????????????????????
    /// internalList ??????????????????????????? InMemoryDb ?????????????????????????????????????????????????????????
    /// ???????????????????????????????????????????????????????????? InMemoryDb ??????
    final ml = InMemoryDb.getMessageList(channelId);
    final message = ml.get(messageId);
    if (message != null) {
      callback(message, ml.getSplayTreeMap());
    }
  }

  ///????????????????????????
  void saveSendAtUser(MessageEntity message) {
    final tempMentions = message.content?.mentions?.item2;
    if (tempMentions.hasValue &&
        (message.type == ChatChannelType.guildText ||
            message.type == ChatChannelType.group_dm)) {
      //?????????guildId???0,??????channelId
      final gId = message.type == ChatChannelType.group_dm
          ? message.channelId
          : message.guildId;
      ChannelUtil.instance.addGuildAtUserId(gId, tempMentions);
    }
  }

  ///?????????????????????????????????
  void bringChannelToTop(ChatChannel channel) {
    if (channel.type == ChatChannelType.dm ||
        channel.type == ChatChannelType.group_dm) {
      DirectMessageController.to.bringChannelToTop(channel);
    }
  }
}
