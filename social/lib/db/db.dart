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
  /// - hivebox.get(key) key如果为空就会报错
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
  static Box<RoleBean> guildRoleBox; // 存用户的角色
  static Box<bool> experimentalFeatureBox; // 存用户的角色
  static Box<Map> creditsBox; //
  static Box<String> circleInfoCachedBox;
  static Box<String> circlePostCachedBox;

  /// TODO 使用了 JSON 字符串
  static Box<String> stickMessageBox;

  ///频道的最新消息ID (包括可见和不可见消息)
  static Box<String> lastMessageIdBox;

  ///频道已读的消息ID
  static Box<String> readMessageIdBox;

  ///频道最后一条完整消息ID (只包括可见消息)
  static Box<BigInt> lastCompleteMessageIdBox;

  ///频道的最后一条可见消息ID (只包括可见消息)
  static Box<BigInt> lastVisibleMessageIdBox;

  ///用户点击的服务器ID（保存点击的时间，用于排序）
  static Box<DateTime> clickGuildIdBox;

  ///频道的第一条未读消息ID todo 修改变量名称，使它符合实际意义
  static Box<BigInt> firstMessageIdBox;

  ///频道的未读艾特消息
  static Box<AtMeBean> numAtOfChannelBox;

  ///成员列表分页数据
  static Box<String> segmentMemberListBox;

  ///频道的发送失败消息ID
  static Box<Map> sendFailMessageIdBox;

  ///小程序授权缓存，只保存已经授权的设置
  static Box<List<String>> mpAuthSettingBox;

  ///未完成任务列表
  static Box<TaskBean> undoneTaskBox;

  ///已完成任务列表
  static Box<TaskBean> doneTaskBox;

  ///私信最后一条描述消息
  static Box<DmLastMessageDesc> dmLastDesc;

  ///服务器内最近艾特过的用户(最多5个，包括：发消息和圈子时艾特别人)
  static Box<List> guildRecentAtBox;

  /// 投票卡片解析
  static Box<Map> voteCardBox;

  /// 文件收发历史记录
  static Box<List> fileSendHistoryBox;

  /// COS文件发送缓存本地路径
  static Box<String> cosFileDirIndexBox;

  ///引导任务进度数据
  static Box<dynamic> guideBox;

  ///上一次打开的userId
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

  //subDir: 用户ID
  static Future<void> open(String subDir) async {
    //如果之前打开的就是这个用户的db，就不重复打开了
    if (subDir == lastOpenId) {
      return;
    }
    lastOpenId = subDir;
    try {
      //先检查一下硬盘情况
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
        logger.severe("数据库升级异常 $e");
      } catch (e) {
        debugPrint('getChat openDatabase error: ${e?.toString()}');
        logger.severe("数据库打开异常 $e");
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

  ///删除box，并且重新打开
  static Future<void> deleteAndReOpenBox() async {
    await Hive.deleteFromDisk();
    await _openBoxes();
  }

  ///本地数据库版本号
  static int dbVersion = 11;

  ///QuoteMessageTable TopicTable 复制于 ChatTable，变更字段注意同步
  static Future _openDatabase() async {
    debugPrint('getChat openDatabase:  dbVersion:$dbVersion');

    ///升级数据库版本
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
        throw DataBaseUpgradeException(msg: '表态数据库升级,如果遇到表态数据多时,第一次加载很慢.'.tr);
      if (oldVersion < 10 && newVersion >= 10)
        await CircleNewsTable.createTable(db);
      // 1.6.60 上的
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

  //是否已经检查过一次硬盘
  static bool isCheckDiskComplete = false;

  ///用户第一次打开使用数据库前先检查手机的硬盘情况
  ///如果硬盘不足，就提醒用户去清理缓存，用户点击确认后跳转至清理页面
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
        title: '存储空间不足，清理缓存可释放存储空间'.tr,
      );
      if (isConfirm != null && isConfirm == true) {
        unawaited(
            Routes.pushCleanCachePage(Global.navigatorKey.currentContext));
      }
    }
  }

  static Future delDatabase() async {
    //删除db文件前先清空队列里的任务
    await Db.db?.clearAllTask();
    await Db.db?.close();
    AsyncDB.shared.dbPath = "";
    await deleteDatabase(await getPath());
    await _openDatabase();
  }

  ///清理用户的本地消息数据，包括：sqlite数据库，lastId、未读数等
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

  ///清理单个频道消息的box数据，包括：lastId、未读数等
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

  ///批量清理频道消息的box数据，包括：lastId、未读数等
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

  ///清理频道的 lastMessageIdBox
  /// cleanType：0 清理所有; 1 不清理私信
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
    //debug页面的删除
    await delDatabase();
  }

  ///初始化全文搜索库
  /*static Future<void> openSearchDb() async {
    searchEngine = SearchEngine();
    SearchEngine.setup();
    //数据格式
    const schema =
        '{"${ChatTable.columnMessageId}": "string","${ChatTable.columnUserId}": "string", '
        '"${ChatTable.columnGuildId}": "string", '
        '"${ChatTable.columnChannelId}": "string", '
        '"${ChatTable.columnTime}": "u64", "${ChatTable.columnContent}": "text"}';
    //存储目录
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

  ///删除当前用户的全文搜索库
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

    /// 目前 chatChannel 的构造函数会取这里的数据
    /// 而 chatChannel 会在频道 box 打开时初始化
    /// 因此需要确保此 box 已经被打开
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

    /// 清理一下
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

///lastId清理的类型
enum CleanLastIdType {
  all, //所有
  excludeDm, //非私信
}

///数据库升级失败异常
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
