import 'dart:async';
import 'dart:typed_data';

import 'package:disk_space/disk_space.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:im/api/data_model/user_info.dart';
import 'package:im/api/entity/at_me_bean.dart';
import 'package:im/api/entity/file_send_history_bean_entity.dart';
import 'package:im/api/entity/first_unread_message_bean.dart';
import 'package:im/api/entity/remark_bean.dart';
import 'package:im/api/entity/role_bean.dart';
import 'package:im/api/entity/task_bean.dart';
import 'package:im/api/guild_api.dart';
import 'package:im/app/modules/circle/models/models.dart';
import 'package:im/common/permission/permission.dart';
import 'package:im/db/chat_db.dart';
import 'package:im/db/cicle_news_table.dart';
import 'package:im/db/quote_message_db.dart';
import 'package:im/db/reaction_table.dart';
import 'package:im/db/topic_db.dart';
import 'package:im/dlog/model/dlog_report_model.dart';
import 'package:im/global.dart';
import 'package:im/pages/friend/relation.dart';
import 'package:im/pages/guild_setting/role/role.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/pages/home/model/input_model.dart';
import 'package:im/pages/personal/clean_cache_model.dart';
import 'package:im/services/sp_service.dart';
import 'package:im/utils/show_confirm_dialog.dart';
import 'package:im/utils/time_measurer.dart';
import 'package:im/widgets/dialog/db_error_dialog.dart';
import 'package:path/path.dart';
import 'package:pedantic/pedantic.dart';

import '../loggers.dart';
import '../routes.dart';
import 'async_db/async_db.dart';
import 'bean/dm_last_message_desc.dart';
import 'bean/last_reaction_item.dart';
import 'message_card_key_table.dart';
import 'message_search_table.dart';
import 'platform/interface.dart'
    if (dart.library.html) 'platform/web.dart'
    if (dart.library.io) 'platform/sqflite.dart';

extension SafeBox<E> on Box<E> {
  /// - hivebox.get(key) key????????????????????????
  // ignore: avoid_annotating_with_dynamic
  E safeGet(dynamic key, {E defaultValue}) {
    if (key == null || !isOpen) return null;
    return get(key, defaultValue: defaultValue);
  }
}

class Db {
  static AsyncDB db;
  static Box<InputRecord> textFieldInputRecordBox;
  static Box<UserInfo> userInfoBox;
  static Box<RemarkListBean> remarkListBox;
  static Box<RemarkBean> remarkBox;
  static Box<List<String>> memberListBox;
  static Box<String> friendListBox;
  static Box<RelationType> relationBox;
  static Box<String> guildSelectedChannelBox;
  static Box<Map> dmListBox;
  static Box<Map> videoCardBox;
  static Box userConfigBox;
  static Box<Map> guildBox;
  static Box<String> guildOrderBox;
  static Box<ChatChannel> channelBox;
  static Box<String> channelCollapseBox;
  static Box<int> numUnrealOfChannelBox;
  static Box<List> hotChatFriendOfChannelBox;
  static Box<String> reactionEmojiOrderBox;
  static Box<GuildPermission> guildPermissionBox;
  static Box<List<String>> pinMessageUnreadBox;
  static Box<Map> guildTopicSortCategoryBox;
  static Box<List> stickerBox;
  static Box<Map> circleShareBox;
  static Box<Map> redPacketBox;
  static Box<CirclePostInfoDataModel> circleDraftBox;
  static Box<int> rejectVideoBox;
  static Box<RoleBean> guildRoleBox; // ??????????????????
  static Box<bool> experimentalFeatureBox; // ??????????????????
  static Box<Map> creditsBox; //
  static Box<String> circleInfoCachedBox;
  static Box<String> circlePostCachedBox;

  /// TODO ????????? JSON ?????????
  static Box<String> stickMessageBox;

  ///?????????????????????ID (??????????????????????????????)
  static Box<String> lastMessageIdBox;

  ///?????????????????????ID
  static Box<String> readMessageIdBox;

  ///??????????????????????????????ID (?????????????????????)
  static Box<BigInt> lastCompleteMessageIdBox;

  ///?????????????????????????????????ID (?????????????????????)
  static Box<BigInt> lastVisibleMessageIdBox;

  ///????????????????????????ID??????????????????????????????????????????
  static Box<DateTime> clickGuildIdBox;

  ///??????????????????????????????ID todo ?????????????????????????????????????????????
  static Box<BigInt> firstMessageIdBox;

  ///???????????????????????????
  static Box<AtMeBean> numAtOfChannelBox;

  ///????????????????????????
  static Box<String> segmentMemberListBox;

  ///???????????????????????????ID
  static Box<Map> sendFailMessageIdBox;

  ///??????????????????????????????????????????????????????
  static Box<List<String>> mpAuthSettingBox;

  ///?????????????????????
  static Box<TaskBean> undoneTaskBox;

  ///?????????????????????
  static Box<TaskBean> doneTaskBox;

  ///??????????????????????????????
  static Box<DmLastMessageDesc> dmLastDesc;

  ///????????????????????????????????????(??????5????????????????????????????????????????????????)
  static Box<List> guildRecentAtBox;

  /// ??????????????????
  static Box<Map> voteCardBox;

  /// ????????????????????????
  static Box<List> fileSendHistoryBox;

  /// COS??????????????????????????????
  static Box<String> cosFileDirIndexBox;

  ///????????????????????????
  static Box<dynamic> guideBox;

  ///??????????????????userId
  static String lastOpenId;

  static void init() {
    Hive.registerAdapter(UserInfoAdapter());
    Hive.registerAdapter(ChatChannelTypeAdapter());
    Hive.registerAdapter(ChatChannelAdapter());
    Hive.registerAdapter(InputRecordAdapter());
    Hive.registerAdapter(GuildPermissionAdapter());
    Hive.registerAdapter(ChannelPermissionAdapter());
    Hive.registerAdapter(PermissionOverwriteAdapter());
    Hive.registerAdapter(RoleAdapter());
    Hive.registerAdapter(RemarkBeanAdapter());
    Hive.registerAdapter(RemarkListBeanAdapter());
    Hive.registerAdapter(AtMeBeanAdapter());
    Hive.registerAdapter(FirstUnreadMessageBeanAdapter());
    Hive.registerAdapter(CirclePostInfoDataModelAdapter());
    Hive.registerAdapter(RoleBeanAdapter());
    Hive.registerAdapter(TaskBeanAdapter());
    Hive.registerAdapter(DmLastMessageDescAdapter());
    Hive.registerAdapter(LastReactionItemAdapter());
    Hive.registerAdapter(DLogReportModelAdapter());
    Hive.registerAdapter(DmGroupRecipientIconAdapter());
    Hive.registerAdapter(FileSendHistoryBeanEntityAdapter());
    Hive.registerAdapter(RelationTypeAdapter());
  }

  //subDir: ??????ID
  static Future<void> open(String subDir) async {
    //??????????????????????????????????????????db????????????????????????
    if (subDir == lastOpenId) {
      return;
    }
    lastOpenId = subDir;
    try {
      //???????????????????????????
      await checkDisk();
      await Hive.close();
      await Hive.initFlutter("$subDir/v2");

      try {
        await _openBoxes();
      } catch (e) {
        await deleteAndReOpenBox();
      }

      try {
        await _openDatabase();
      } on DataBaseUpgradeException catch (e) {
        await cleanUserChatData();
        logger.severe("????????????????????? $e");
      } catch (e) {
        debugPrint('getChat openDatabase error: ${e?.toString()}');
        logger.severe("????????????????????? $e");
        uploadError("dbError", e?.toString());
        await showDialog(
            context: Global.navigatorKey.currentContext,
            builder: (ctx) => const DbErrorDialog());
      }

      final bool isCleaning =
          SpService.to.getBool(SP.isCleaningChatCache) ?? false;
      if (isCleaning == true) {
        final CleanCacheModel cleanModel = CleanCacheModel();
        await cleanModel.cleanChatCache(isForce: true);
        logger.severe("clean chat data continue finish");
      }
    } catch (_) {
      lastOpenId = null;
      rethrow;
    }
  }

  ///??????box?????????????????????
  static Future<void> deleteAndReOpenBox() async {
    await Hive.deleteFromDisk();
    await _openBoxes();
  }

  ///????????????????????????
  static int dbVersion = 11;

  ///QuoteMessageTable TopicTable ????????? ChatTable???????????????????????????
  static Future _openDatabase() async {
    debugPrint('getChat openDatabase:  dbVersion:$dbVersion');

    ///?????????????????????
    Db.db = await AsyncDB.shared.openAsDatabase(await getPath(),
        version: dbVersion, onCreate: (db, version) async {
      await ChatTable.createTable(db);
      await TopicTable.createTableTopic(db);
      await ReactionTable.createTable(db);
      await MessageSearchTable.createTable(db);
      await QuoteMessageTable.createTable(db);
      await CircleNewsTable.createTable(db);
      await MessageCardKeyTable.createTable(db);
    }, onUpgrade: (db, oldVersion, newVersion) async {
      debugPrint('getChat oldVersion:$oldVersion - newVersion:$newVersion');
      if (oldVersion < 9 && newVersion >= 9)
        throw DataBaseUpgradeException(msg: '?????????????????????,??????????????????????????????,?????????????????????.'.tr);
      if (oldVersion < 10 && newVersion >= 10)
        await CircleNewsTable.createTable(db);
      // 1.6.60 ??????
      if (oldVersion < 11 && newVersion >= 11)
        await MessageCardKeyTable.createTable(db);
    });

    final startTime = DateTime.now().millisecondsSinceEpoch;
    await ChatTable.checkTable();
    await TopicTable.checkTable();
    await ReactionTable.checkTable();
    await MessageSearchTable.checkTable();
    await QuoteMessageTable.checkTable();
    await CircleNewsTable.checkTable();
    await MessageCardKeyTable.checkTable();
    final costTime = DateTime.now().millisecondsSinceEpoch - startTime;
    logger.info("cost $costTime millisecondes to check table");
  }

  //?????????????????????????????????
  static bool isCheckDiskComplete = false;

  ///?????????????????????????????????????????????????????????????????????
  ///????????????????????????????????????????????????????????????????????????????????????????????????
  static Future<void> checkDisk() async {
    if (isCheckDiskComplete) {
      return;
    }
    isCheckDiskComplete = true;
    final diskSpace = await DiskSpace.getFreeDiskSpace.catchError((error) {
      logger.info(error.toString());
    });
    if (diskSpace < 200) {
      final bool isConfirm = await showConfirmDialog(
        title: '??????????????????????????????????????????????????????'.tr,
      );
      if (isConfirm != null && isConfirm == true) {
        unawaited(
            Routes.pushCleanCachePage(Global.navigatorKey.currentContext));
      }
    }
  }

  static Future delDatabase() async {
    //??????db????????????????????????????????????
    await Db.db?.clearAllTask();
    await Db.db?.close();
    AsyncDB.shared.dbPath = "";
    await deleteDatabase(await getPath());
    await _openDatabase();
  }

  ///?????????????????????????????????????????????sqlite????????????lastId???????????????
  static Future<void> cleanUserChatData(
      {CleanLastIdType type = CleanLastIdType.all}) async {
    try {
      await Future.wait([
        Db.delDatabase(),
        Db.numAtOfChannelBox.clear(),
        Db.numUnrealOfChannelBox.clear(),
        Db.hotChatFriendOfChannelBox.clear(),
        clearLastIdBox(type: type),
        Db.sendFailMessageIdBox.clear(),
        Db.firstMessageIdBox.clear(),
        Db.readMessageIdBox.clear(),
        Db.lastCompleteMessageIdBox.clear(),
        Db.lastVisibleMessageIdBox.clear(),
        Db.clickGuildIdBox.clear(),
        Db.guildSelectedChannelBox.clear(),
        Db.fileSendHistoryBox.clear(),
        Db.creditsBox.clear(),
        Db.circleInfoCachedBox.clear(),
        Db.circlePostCachedBox.clear(),
        SpService.to.remove(SP.defaultChatTarget),
      ]);
    } catch (e, s) {
      logger.severe("cleanUserChatData error", e, s);
      await cleanUserChatData(type: type);
    }
  }

  ///???????????????????????????box??????????????????lastId???????????????
  static void deleteChannelImBox(String channelId) {
    if (channelId == null) return;
    Db.numAtOfChannelBox.delete(channelId);
    Db.numUnrealOfChannelBox.delete(channelId);
    Db.hotChatFriendOfChannelBox.delete(channelId);
    Db.lastMessageIdBox.delete(channelId);
    Db.firstMessageIdBox.delete(channelId);
    Db.readMessageIdBox.delete(channelId);
    Db.sendFailMessageIdBox.delete(channelId);
    Db.lastCompleteMessageIdBox.delete(channelId);
    Db.lastVisibleMessageIdBox.delete(channelId);
    Db.guildRecentAtBox.delete(channelId);
  }

  ///???????????????????????????box??????????????????lastId???????????????
  static void batchDeleteChannelImBox(Iterable<String> channelIds) {
    if (channelIds == null || channelIds.isEmpty) return;
    Db.numAtOfChannelBox.deleteAll(channelIds);
    Db.numUnrealOfChannelBox.deleteAll(channelIds);
    Db.hotChatFriendOfChannelBox.deleteAll(channelIds);
    Db.lastMessageIdBox.deleteAll(channelIds);
    Db.firstMessageIdBox.deleteAll(channelIds);
    Db.readMessageIdBox.deleteAll(channelIds);
    Db.sendFailMessageIdBox.deleteAll(channelIds);
    Db.lastCompleteMessageIdBox.deleteAll(channelIds);
    Db.lastVisibleMessageIdBox.deleteAll(channelIds);
    Db.guildRecentAtBox.deleteAll(channelIds);
  }

  ///??????????????? lastMessageIdBox
  /// cleanType???0 ????????????; 1 ???????????????
  static Future<void> clearLastIdBox(
      {CleanLastIdType type = CleanLastIdType.all}) async {
    if (lastMessageIdBox.isEmpty) return;
    if (type == CleanLastIdType.excludeDm) {
      final List keys = lastMessageIdBox.keys.toList();
      ChatChannel channel;
      String key;
      for (int i = 0; i < keys.length; i++) {
        key = keys[i] as String;
        channel = channelBox.get(key);
        if (channel != null && channel.type != ChatChannelType.dm)
          await lastMessageIdBox.delete(key);
      }
    } else {
      await lastMessageIdBox.clear();
    }
  }

  static Future<void> delete() async {
    //debug???????????????
    await delDatabase();
  }

  ///????????????????????????
  /*static Future<void> openSearchDb() async {
    searchEngine = SearchEngine();
    SearchEngine.setup();
    //????????????
    const schema =
        '{"${ChatTable.columnMessageId}": "string","${ChatTable.columnUserId}": "string", '
        '"${ChatTable.columnGuildId}": "string", '
        '"${ChatTable.columnChannelId}": "string", '
        '"${ChatTable.columnTime}": "u64", "${ChatTable.columnContent}": "text"}';
    //????????????
    final dbPath = await getSearchPath();
    final tempDirectory = Directory(dbPath);
    try {
      // ignore: avoid_slow_async_io
      final bool exists = await tempDirectory.exists();
      if (!exists) {
        await tempDirectory.create();
      }
    } catch (e) {
      print('getChatHistory -- openSearchDb error: $e ');
    }
    searchEngine.openOrCreate(dbPath, schema);
    print('getChatHistory -- openSearchDb: $dbPath, schema: $schema ');
  }*/

  ///????????????????????????????????????
  /* static Future<void> deleteSearchDb() async {
    final tempDirectory = Directory(await getSearchPath());
    try {
      // ignore: avoid_slow_async_io
      final bool exists = await tempDirectory.exists();
      if (exists) {
        print('getChatHistory -- deleteSearchDb exists:$exists ');
        await tempDirectory.delete(recursive: true);
      }
    } catch (e) {
      print('getChatHistory -- deleteSearchDb error: $e ');
    }
  }

  static Future<String> getSearchPath() async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/${Global.user.id}/v3';
  }*/

  static Future<String> getPath() async {
    final databasePath = await getDatabasesPath();
    return join(databasePath, '${Global.user.id}_db__29');
  }

  static Future<void> _openBoxes() async {
    final p = TimeMeasurer.start();

    /// ?????? chatChannel ????????????????????????????????????
    /// ??? chatChannel ???????????? box ??????????????????
    /// ????????????????????? box ???????????????
    Uint8List getHiveBytes() => kIsWeb ? Uint8List(0) : null;
    channelCollapseBox = await Hive.openBox<String>("ChannelCollapseBox");

    textFieldInputRecordBox =
        await Hive.openBox<InputRecord>('TextFieldInputRecord');
    userInfoBox = await Hive.openBox<UserInfo>("UserInfo");
    remarkListBox =
        await Hive.openBox<RemarkListBean>("RemarkBean", bytes: getHiveBytes());
    remarkBox =
        await Hive.openBox<RemarkBean>("RecordBean", bytes: getHiveBytes());
    memberListBox =
        await Hive.openBox<List<String>>("MemberList", bytes: getHiveBytes());
    friendListBox =
        await Hive.openBox<String>("FriendList", bytes: getHiveBytes());
    dmListBox = await Hive.openBox<Map>("DmList");
    videoCardBox = await Hive.openBox<Map>("VideoCard", bytes: getHiveBytes());
    relationBox =
        await Hive.openBox<RelationType>("Relation", bytes: getHiveBytes());
    guildSelectedChannelBox = await Hive.openBox<String>(
      "GuildSelectedChannelBox",
    );
    userConfigBox = await Hive.openBox("UserConfig", bytes: getHiveBytes());
    channelBox = await Hive.openBox<ChatChannel>("ChannelBox");
    guildBox = await Hive.openBox<Map>("guild");
    redPacketBox = await Hive.openBox<Map>("RedPacket", bytes: getHiveBytes());
    guildOrderBox = await Hive.openBox<String>("guildOrder");
    numUnrealOfChannelBox = await Hive.openBox<int>("NumUnrealOfChannelBox");
    reactionEmojiOrderBox = await Hive.openBox<String>("ReactionEmojiOrderBox");
    guildPermissionBox = await Hive.openBox<GuildPermission>(
        "GuildPermissionBox",
        bytes: getHiveBytes());
    pinMessageUnreadBox =
        await Hive.openBox<List<String>>("PinMessageUnreadBox");
    guildTopicSortCategoryBox =
        await Hive.openBox<Map>("topicSortCategoryBox", bytes: getHiveBytes());
    stickerBox = await Hive.openBox<List>("StickerBox", bytes: getHiveBytes());
    circleShareBox =
        await Hive.openBox<Map>("circleShareBox", bytes: getHiveBytes());
    stickMessageBox = await Hive.openBox<String>("StickMessageBox");
    lastMessageIdBox = await Hive.openBox<String>("LastMessageIdBox");
    readMessageIdBox =
        await Hive.openBox<String>("ReadMessageIdBox", bytes: getHiveBytes());
    firstMessageIdBox =
        await Hive.openBox<BigInt>("firstMessageIdBox", bytes: getHiveBytes());
    lastCompleteMessageIdBox = await Hive.openBox<BigInt>(
        "lastCompleteMessageIdBox",
        bytes: getHiveBytes());
    lastVisibleMessageIdBox = await Hive.openBox<BigInt>(
        "lastVisibleMessageIdBox",
        bytes: getHiveBytes());
    clickGuildIdBox =
        await Hive.openBox<DateTime>("clickGuildIdBox", bytes: getHiveBytes());
    numAtOfChannelBox = await Hive.openBox<AtMeBean>("NumAtOfChannelBox",
        bytes: getHiveBytes());
    rejectVideoBox =
        await Hive.openBox<int>("RejectedVideoBox", bytes: getHiveBytes());
    circleDraftBox = await Hive.openBox<CirclePostInfoDataModel>(
        "CircleDraftBox",
        bytes: getHiveBytes());
    segmentMemberListBox = await Hive.openBox<String>("SegmentMemberListBox",
        bytes: getHiveBytes());
    sendFailMessageIdBox =
        await Hive.openBox<Map>("sendFailMessageIdBox", bytes: getHiveBytes());
    guildRoleBox =
        await Hive.openBox<RoleBean>("guildRoleBox", bytes: getHiveBytes());
    mpAuthSettingBox = await Hive.openBox<List<String>>("MpAuthSettingBox",
        bytes: getHiveBytes());
    experimentalFeatureBox =
        await Hive.openBox<bool>("experimentalFeature", bytes: getHiveBytes());
    hotChatFriendOfChannelBox = await Hive.openBox<List>(
        "HotChatFriendOfChannelBox",
        bytes: getHiveBytes());
    undoneTaskBox = await Hive.openBox<TaskBean>("undoneTaskBox");
    doneTaskBox = await Hive.openBox<TaskBean>("doneTaskBox");
    dmLastDesc = await Hive.openBox<DmLastMessageDesc>("dmLastDesc2");
    guildRecentAtBox = await Hive.openBox<List>("guildRecentAtBox");
    voteCardBox = await Hive.openBox<Map>("voteCardBox");
    fileSendHistoryBox = await Hive.openBox<List>("fileSendHistoryBox");
    guideBox = await Hive.openBox<dynamic>("guideBox");
    creditsBox = await Hive.openBox<Map>("CreditsBox");
    circleInfoCachedBox = await Hive.openBox<String>("circleInfoCachedBox");
    circlePostCachedBox = await Hive.openBox<String>("circlePostCachedBox");

    TimeMeasurer.end("hive boxes opened", p);
  }

  static Future<void> compactAllBox() async {
    await Future.delayed(const Duration(seconds: 20));

    final preTimeStamp = SpService.to.getInt(SP.preCompactAllBoxTime);
    if (preTimeStamp == null) {
      unawaited(SpService.to.setInt(
          SP.preCompactAllBoxTime, DateTime.now().millisecondsSinceEpoch));
      return;
    }

    final weekAgoTime = DateTime.now().subtract(const Duration(days: 7));

    final preTime = DateTime.fromMillisecondsSinceEpoch(preTimeStamp);

    if (preTime.isAfter(weekAgoTime)) {
      return;
    }

    /// ????????????
    await channelCollapseBox.compact();
    await Future.delayed(const Duration(seconds: 1));
    await textFieldInputRecordBox.compact();
    await Future.delayed(const Duration(seconds: 1));
    await userInfoBox.compact();
    await Future.delayed(const Duration(seconds: 1));
    await remarkListBox.compact();
    await Future.delayed(const Duration(seconds: 1));
    await remarkBox.compact();
    await Future.delayed(const Duration(seconds: 1));
    await memberListBox.compact();
    await Future.delayed(const Duration(seconds: 1));
    await friendListBox.compact();
    await Future.delayed(const Duration(seconds: 1));
    await dmListBox.compact();
    await Future.delayed(const Duration(seconds: 1));
    await videoCardBox.compact();
    await Future.delayed(const Duration(seconds: 1));
    await relationBox.compact();
    await Future.delayed(const Duration(seconds: 1));
    await guildSelectedChannelBox.compact();
    await Future.delayed(const Duration(seconds: 1));
    await userConfigBox.compact();
    await Future.delayed(const Duration(seconds: 1));
    await channelBox.compact();
    await Future.delayed(const Duration(seconds: 1));
    await guildBox.compact();
    await Future.delayed(const Duration(seconds: 1));
    await redPacketBox.compact();
    await Future.delayed(const Duration(seconds: 1));
    await guildOrderBox.compact();
    await Future.delayed(const Duration(seconds: 1));
    await numUnrealOfChannelBox.compact();
    await Future.delayed(const Duration(seconds: 1));
    await reactionEmojiOrderBox.compact();
    await Future.delayed(const Duration(seconds: 1));
    await guildPermissionBox.compact();
    await Future.delayed(const Duration(seconds: 1));
    await pinMessageUnreadBox.compact();
    await Future.delayed(const Duration(seconds: 1));
    await guildTopicSortCategoryBox.compact();
    await Future.delayed(const Duration(seconds: 1));
    await stickerBox.compact();
    await Future.delayed(const Duration(seconds: 1));
    await circleShareBox.compact();
    await Future.delayed(const Duration(seconds: 1));
    await stickMessageBox.compact();
    await Future.delayed(const Duration(seconds: 1));
    await lastMessageIdBox.compact();
    await Future.delayed(const Duration(seconds: 1));
    await readMessageIdBox.compact();
    await Future.delayed(const Duration(seconds: 1));
    await firstMessageIdBox.compact();
    await Future.delayed(const Duration(seconds: 1));
    await lastCompleteMessageIdBox.compact();
    await Future.delayed(const Duration(seconds: 1));
    await lastVisibleMessageIdBox.compact();
    await Future.delayed(const Duration(seconds: 1));
    await clickGuildIdBox.compact();
    await Future.delayed(const Duration(seconds: 1));
    await numAtOfChannelBox.compact();
    await Future.delayed(const Duration(seconds: 1));
    await rejectVideoBox.compact();
    await Future.delayed(const Duration(seconds: 1));
    await circleDraftBox.compact();
    await Future.delayed(const Duration(seconds: 1));
    await segmentMemberListBox.compact();
    await Future.delayed(const Duration(seconds: 1));
    await sendFailMessageIdBox.compact();
    await Future.delayed(const Duration(seconds: 1));
    await guildRoleBox.compact();
    await Future.delayed(const Duration(seconds: 1));
    await mpAuthSettingBox.compact();
    await Future.delayed(const Duration(seconds: 1));
    await experimentalFeatureBox.compact();
    await Future.delayed(const Duration(seconds: 1));
    await hotChatFriendOfChannelBox.compact();
    await Future.delayed(const Duration(seconds: 1));
    await undoneTaskBox.compact();
    await Future.delayed(const Duration(seconds: 1));
    await doneTaskBox.compact();
    await Future.delayed(const Duration(seconds: 1));
    await dmLastDesc.compact();
    await Future.delayed(const Duration(seconds: 1));
    await guildRecentAtBox.compact();
    await Future.delayed(const Duration(seconds: 1));
    await voteCardBox.compact();
    await Future.delayed(const Duration(seconds: 1));
    await fileSendHistoryBox.compact();
    await Future.delayed(const Duration(seconds: 1));
    await guideBox.compact();
    await Future.delayed(const Duration(seconds: 1));
    await creditsBox.compact();
    await Future.delayed(const Duration(seconds: 1));
    await circleInfoCachedBox.compact();
    await Future.delayed(const Duration(seconds: 1));
    await circlePostCachedBox.compact();

    // update compact time
    unawaited(SpService.to.setInt(
        SP.preCompactAllBoxTime, DateTime.now().millisecondsSinceEpoch));
  }
}

///lastId???????????????
enum CleanLastIdType {
  all, //??????
  excludeDm, //?????????
}

///???????????????????????????
class DataBaseUpgradeException implements Exception {
  final String msg;

  final int code;

  DataBaseUpgradeException({this.msg = '', this.code = 0});

  @override
  String toString() => msg ?? 'DataBaseUpgradeException';
}

class DataBaseDataException implements Exception {
  final String msg;

  final int code;

  DataBaseDataException({this.msg = '', this.code = 0});

  @override
  String toString() => msg ?? 'DataBaseDataException';
}
