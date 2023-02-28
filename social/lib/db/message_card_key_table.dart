import 'package:im/global.dart';
import 'package:im/pages/home/json/message_card_entity.dart';
import 'package:im/pages/home/json/text_chat_json.dart';

import 'async_db/async_db.dart';
import 'db.dart';

class MessageCardKeyTable {
  static const String table = 'message_card_key';
  static const String columnChannelId = 'channel_id';
  static const String columnMessageId = 'message_id';
  static const String columnUserId = 'user_id';
  static const String columnKey = 'key';
  static const String columnMe = 'me';
  static const String columnCount = 'count';

  // static const String columnId = 'id';

  static Future<void> createTable(AsyncDB db) async {
    await db.execute('''
        CREATE TABLE $table (
          $columnChannelId INTEGER,
          $columnUserId TEXT,
          $columnMessageId INTEGER,
          $columnMe INTEGER DEFAULT 0,
          $columnKey TEXT,
          $columnCount INTEGER DEFAULT 0,
          PRIMARY KEY ($columnMessageId, $columnKey)
          )
        ''', isAsync: false);
  }

  static Future checkTable() async {
    await Db.db.select("select * from $table limit 1");
  }

  static Future<void> insert({
    String channelId,
    String messageId,
    String userId,
    String key,
    bool me,
  }) async {
    final String updateMe = me ? "me = 1," : "";
    await Db.db.execute(
        "INSERT OR IGNORE INTO $table ($columnKey, $columnMessageId, $columnChannelId) VALUES ($key,$messageId,$channelId)");
    return Db.db.execute('''
        UPDATE $table
        SET
          $columnUserId = $userId,
          $updateMe
          $columnCount = $columnCount + 1
        WHERE $columnMessageId = $messageId AND $columnKey = $key
      ''');
  }

  static Future<void> remove(
      {String messageId, String userId, String key}) async {
    final String updateMe = userId == Global.user.id ? "me = 0," : "";
    await Db.db.execute('''
        UPDATE $table
        SET
          $updateMe
          $columnCount = $columnCount - 1
        WHERE $columnMessageId = $messageId AND $columnKey = $key
      ''');
    return Db.db.execute('''
        delete from $table
        where $columnMessageId = $messageId AND $columnKey = $key AND $columnCount = 0
        ''');
  }

  static Future<void> load(
      String messageId, Map<String, MessageCardKeyModel> readInto) async {
    final result = await Db.db.query(
      table,
      where: "$columnMessageId=$messageId",
      columns: [columnKey, columnUserId, columnMe, columnCount],
    );
    for (final row in result) {
      final key = row[columnKey];
      readInto[key] ??= MessageCardKeyModel();
      readInto[key]
        ..userId = row[columnUserId]
        ..count = row[columnCount] ?? 0
        ..me = row[columnMe] == 1;
    }
  }

  /// 内存中可以对 notpull 的 key 进行一次组合，来减少数据库指令，但这是个极端情况，目前还不确定这么做的必要性
  static Future bulkInsert(List<MessageEntity> messages) {
    if (messages.isEmpty) return Future.value();

    return Db.db.transaction((txn) {
      final batch = txn.batch();
      for (final msg in messages) {
        final messageCardKeyPush = msg.content as MessageCardKeyPushEntity;
        String updateMe = "";
        String updateCount;
        if (messageCardKeyPush.action == "add") {
          if (msg.userId == Global.user.id) updateMe = "me = 1,";
          updateCount = "$columnCount + 1";
        } else {
          if (msg.userId == Global.user.id) updateMe = "me = 0,";
          updateCount = "$columnCount - 1";
        }
        batch.execute(
            "INSERT OR IGNORE INTO $table ($columnKey, $columnMessageId, $columnChannelId) VALUES (${messageCardKeyPush.key},${messageCardKeyPush.id},${msg.channelId})");
        batch.execute(
          '''
              UPDATE $table
              SET
                $columnMessageId = ${messageCardKeyPush.id},
                $columnUserId = CASE WHEN $columnUserId = ${msg.userId} THEN NULL ELSE $columnUserId END,
                $columnKey = ${messageCardKeyPush.key},
                $updateMe
                $columnCount = $updateCount
              WHERE $columnMessageId = ${messageCardKeyPush.id} AND $columnKey = ${messageCardKeyPush.key}
              ''',
        );
      }
      return batch.commit(noResult: true, continueOnError: true);
    });
  }
}
