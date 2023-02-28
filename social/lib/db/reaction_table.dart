import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:im/db/bean/reaction_item.dart';
import 'package:im/db/chat_db.dart';
import 'package:im/db/db.dart';
import 'package:im/db/message_search_table.dart';
import 'package:im/db/quote_message_db.dart';
import 'package:im/db/topic_db.dart';

import 'async_db/async_db.dart';
import 'async_db/async_insert_model.dart';

class ReactionTable {
  ///表态旧表
  static const tableOld = "Reaction";

  ///表态新表
  static const table = "Reaction2";

  static const columnId = "reactionId";
  static const columnMsgId = "msgId";
  static const columnName = "name";
  static const columnCount = "count";
  static const columnMe = "me";

  static Future<void> createTable(AsyncDB db) async {
    await db.execute("DROP TABLE IF EXISTS $table", isAsync: false);
    await db.execute('''
    CREATE TABLE $table (
      $columnId INTEGER PRIMARY KEY,
      $columnMsgId INTEGER,
      $columnName TEXT,
      $columnCount INTEGER,
      $columnMe INTEGER,
      UNIQUE($columnMsgId, $columnName) ON CONFLICT REPLACE,
      FOREIGN KEY ($columnMsgId) REFERENCES ${ChatTable.table}(${ChatTable.columnMessageId}) ON DELETE CASCADE
      )''', isAsync: false);

    ///创建 "msgId" "name" 的联合索引
    await db.execute(
        "CREATE INDEX reaction_index on"
        " $table ($columnMsgId,$columnName)",
        isAsync: false);
  }

  static Future checkTable() async {
    await Db.db.select("select * from $table limit 1");
  }

  ///全新的批量插入
  static Future<void> insertBatch(
      List<String> sqlList, String messageId, List<Map> reactions) async {
    final BigInt msgId = BigInt.parse(messageId);
    // final batch = Db.db.batch();
    sqlList.add("DELETE FROM $table WHERE $columnMsgId = $messageId ");

    ///删除原有记录
    // batch.delete(table, where: '$columnMsgId = $messageId');
    // final List<Map<String, dynamic>> maps = [];
    for (final r in reactions) {
      final String emojiName = r['name'] as String; //is uri encode

      final int count = r['count'] as int;
      int me = 0;
      if (r['me'] as bool) {
        me = 1;
      }
      final ReactionItem reaction =
          ReactionItem(msgId: msgId, name: emojiName, count: count, me: me);
      // maps.add(reaction.toMap());
      sqlList.add(Db.db.sqlToInsert(table, reaction.toMap()));
      // batch.insert(table, reaction.toMap());
    }
    // await batch.commit();
    // await Db.db.insertArray(table, maps);
  }

  /// 新增表态时，表态总数入库
  static Future<void> append(
      String messageId, String emojiName, int count, bool me) async {
    if (count < 0 || me == null) return;

    final BigInt msgId = BigInt.parse(messageId);
    final int dbMe = me ? 1 : 0;

    final ReactionItem reaction =
        ReactionItem(msgId: msgId, name: emojiName, count: count, me: dbMe);

    await Db.db.insert(table, reaction.toMap(),
        conflictAlgorithm: InsertDBConflictType.replace);
  }

  /// 取消表态时，表态总数入库
  static Future<void> remove(
      String messageId, String emojiName, int count, bool me) async {
    if (me == null) return;

    //count=0 删除本条数据
    if (count <= 0) {
      final String sql =
          "DELETE FROM $table WHERE $columnMsgId = $messageId AND $columnName = '$emojiName'";
      await Db.db.execute(sql);
      return;
    } else {
      final BigInt msgId = BigInt.parse(messageId);
      final int dbMe = me ? 1 : 0;

      final ReactionItem reaction =
          ReactionItem(msgId: msgId, name: emojiName, count: count, me: dbMe);
      await Db.db.insert(table, reaction.toMap(),
          conflictAlgorithm: InsertDBConflictType.replace);
    }
  }

  /// push表态数据，携带count总数，消息不在内存中
  static Future<void> appendByDbCount(
      String messageId, String emojiName, int count, bool me) async {
    if (count < 0 || me == null) return;

    int dbMe = 0;
    if (me) {
      dbMe = 1;
    } else {
      final where = "$columnMsgId = $messageId AND $columnName = '$emojiName'";
      final List<Map> resMap = await Db.db.query(table, where: where);
      if (resMap != null && resMap.isNotEmpty) {
        dbMe = resMap.first[columnMe] ?? 0;
      }
    }

    final BigInt msgId = BigInt.parse(messageId);
    final ReactionItem reaction =
        ReactionItem(msgId: msgId, name: emojiName, count: count, me: dbMe);

    await Db.db.insert(table, reaction.toMap(),
        conflictAlgorithm: InsertDBConflictType.replace);
  }

  /// push表态数据，携带count总数，消息不在内存中
  static Future<void> removeByDbCount(
      String messageId, String emojiName, int count, bool me) async {
    if (me == null) return;

    if (count <= 0) {
      final String sql =
          "DELETE FROM $table WHERE $columnMsgId = $messageId AND $columnName = '$emojiName'";
      await Db.db.execute(sql);
      debugPrint("reaction delete msgId=$columnMsgId emojiName=$emojiName");
      return;
    } else {
      int dbMe = 0;

      if (me) {
        dbMe = 0;
      } else {
        final where =
            "$columnMsgId = $messageId AND $columnName = '$emojiName'";
        final List<Map> resMap = await Db.db.query(table, where: where);
        if (resMap != null && resMap.isNotEmpty) {
          dbMe = resMap.first[columnMe] ?? 0;
        }
      }

      final BigInt msgId = BigInt.parse(messageId);

      final ReactionItem reaction =
          ReactionItem(msgId: msgId, name: emojiName, count: count, me: dbMe);
      await Db.db.insert(table, reaction.toMap(),
          conflictAlgorithm: InsertDBConflictType.replace);
    }
  }

  /// NotPull离线合并表态,此消息不在内存中加载
  static Future<void> appendByNotPullDbCount(
      String messageId, String emojiName, bool me,
      {int count = 0}) async {
    final BigInt msgId = BigInt.parse(messageId);
    final where = "$columnMsgId = $messageId AND $columnName = '$emojiName'";

    ReactionItem reaction;

    final List<Map> resMap = await Db.db.query(table, where: where);
    if (resMap != null && resMap.isNotEmpty) {
      final int oldCount = resMap.first[columnCount] ?? 0;
      final bool oldMe = (resMap.first[columnMe] ?? 0) == 1;
      count = count + oldCount;

      if (oldMe == true && me == true) {
        count--;
      }

      if (count <= 0) {
        final String sql =
            "DELETE FROM $table WHERE $columnMsgId = $messageId AND $columnName = '$emojiName'";
        await Db.db.execute(sql);
        return;
      }

      final int dbMe = (me || oldMe) ? 1 : 0;
      reaction =
          ReactionItem(msgId: msgId, name: emojiName, count: count, me: dbMe);
    } else {
      if (count <= 0) return;

      reaction = ReactionItem(
          msgId: msgId, name: emojiName, count: count, me: me ? 1 : 0);
    }

    await Db.db.insert(table, reaction.toMap(),
        conflictAlgorithm: InsertDBConflictType.replace);
  }

  ///sqLite 不支持建表后修改主键，或删除列。所以要修改列的类型，只能采用下面的方式<p>
  ///步骤：1 创建临时表 2 删除消息ID为reject开头的记录;  3 复制数据到临时表
  ///4 删除原表 5 创建原表 6 复制临时表数据到原表 7 删除临时表
  static Future<void> transferReactionTable(AsyncDB db) async {
    try {
      await db.transaction((txn) async {
        ///1 创建临时表
        await txn.execute("DROP TABLE IF EXISTS $table");
        await createTable(db);

        ///2 旧表里面按照 messageId 去重提取数据
        final reactionList =
            await txn.rawQuery("SELECT DISTINCT $columnMsgId FROM $tableOld");

        if (reactionList != null && reactionList.isNotEmpty) {
          //所有 messageId list <int 类型>
          final listMsg = reactionList.map((e) => e[columnMsgId]).toList();

          ///3 旧表数据转变表格式到临时表
          for (final int msgId in listMsg) {
            //查询每条messageId的表态数据
            final listOld = await txn.rawQuery(
                "SELECT * FROM $tableOld WHERE $columnMsgId = $msgId");
            final List<ReactionItem> list = [];

            listOld.forEach((e) {
              final mapOld = e.cast<String, dynamic>();

              final ReactionItem reactionItem = ReactionItem.fromMapOld(mapOld);
              if (list.isEmpty) {
                list.add(reactionItem);
              } else {
                bool hasName = false;
                for (final r in list) {
                  if (r.name == reactionItem.name) {
                    r.count++;

                    if (reactionItem.me == 1) {
                      r.me = 1;
                    }

                    hasName = true;
                    break;
                  }
                }
                if (!hasName) {
                  list.add(reactionItem);
                }
              }
            });

            list.forEach((e) async {
              await txn.insert(table, e.toMap());
            });
          }

          ///4 删除旧表
          await txn.execute("DROP TABLE IF EXISTS $tableOld");

          debugPrint('ReactionTable transfer success');
        }
      });
    } catch (e) {
      debugPrint('ReactionTable transfer error=$e');

      await db.execute("DROP TABLE IF EXISTS $table");
      await createTable(db);

      await db.execute("DELETE FROM ${ChatTable.table}");
      await db.execute("DELETE FROM ${TopicTable.tableTopic}");
      await db.execute("DELETE FROM ${QuoteMessageTable.table}");
      await db.execute("DELETE FROM ${MessageSearchTable.table}");

      //删除旧表
      await db.execute("DROP TABLE IF EXISTS $tableOld");

      await Db.lastMessageIdBox.clear();
      await Db.readMessageIdBox.clear();
      await Db.numUnrealOfChannelBox.clear();

      await Db.undoneTaskBox.clear();
      await Db.doneTaskBox.clear();
      await Db.dmLastDesc.clear();
    }
  }
}
