import 'package:flutter/material.dart';
import 'package:im/common/extension/list_extension.dart';
import 'package:im/global.dart';
import 'package:im/pages/home/json/text_chat_json.dart';
import 'package:sqflite/sqflite.dart';

import 'async_db/async_db.dart';
import 'async_db/async_insert_model.dart';
import 'db.dart';

class MessageSearchTable {
  static String table = "MessageSearch2";

  /// VIRTUAL表 固定主键名，创建时无需设置
  static String columnRowId = 'rowid';
  static String columnUserId = 'userId';
  static String columnChannel = 'channel';
  static String columnMentions = 'mentions';
  static String columnMentionRoles = 'mentionRoles';
  static String columnContent = 'content';
  static String columnLinks = 'links';
  static String columnType = 'type';
  static String columnDelete = 'deleteBy';
  static String columnRecall = 'recallBy';
  static String columnHide = 'hide';

  static Future createTable(AsyncDB db) async {
    await db.execute("DROP TABLE IF EXISTS $table", isAsync: false);
    await db.execute(
        "CREATE VIRTUAL TABLE $table USING fts5($columnChannel, $columnMentions, $columnMentionRoles, $columnUserId, $columnContent, $columnLinks, $columnType, $columnDelete, $columnRecall,$columnHide, prefix='1 2 3 4 5');",
        isAsync: false);
  }

  static Future checkTable() async {
    await Db.db.select("select * from $table limit 1");
  }

  static Future<List> batchInsert(Transaction txn, List<MessageEntity> list,
      {bool isUpdate = false}) {
    final searchBatch = txn.batch();
    for (final e in list) {
      final map = getMessageSearchTableInsertion(e);
      if (isUpdate) {
        searchBatch.insert(table, map,
            conflictAlgorithm: ConflictAlgorithm.replace);
      } else {
        searchBatch.insert(table, map);
      }
    }
    return searchBatch.commit(noResult: true, continueOnError: true);
  }

  static Future<void> insert(MessageEntity msg,
      {InsertDBConflictType conflictAlgorithm =
          InsertDBConflictType.replace}) async {
    return Db.db.insert(
      MessageSearchTable.table,
      getMessageSearchTableInsertion(msg),
      conflictAlgorithm: conflictAlgorithm,
    );
  }

  /// 在数据库中搜索是 @ [atUser] 的消息，
  /// [atRoles] 包含了 [atUser] 的全部角色<p>
  /// 搜索范围在 [beginId] 和 [endId] 之间<p>
  static Future<int> searchAtMessage(
      {BigInt beginId,
      BigInt endId,
      String channelId,
      @required String atUser,
      List<String> atRoles,
      bool before = true}) async {
    final where = StringBuffer();
    if (before) {
      where.write("$columnRowId >= $beginId AND $columnRowId < $endId");
    } else {
      where.write("$columnRowId > $beginId AND $columnRowId <= $endId");
    }

    where.write("""
        AND $columnDelete ISNULL
        AND $columnRecall ISNULL
        AND $columnChannel = '$channelId'
        AND $columnUserId != '$atUser'
        AND $columnHide = "0"
        """);
    where.write(" AND ($columnMentions MATCH '$atUser'");
    if (atRoles.hasValue) {
      where.write(" OR $columnMentionRoles MATCH ");
      where.write("'${atRoles.join(" OR ")}'");
    }
    where.write(")");

    final messageId = Sqflite.firstIntValue(await Db.db.query(table,
        columns: [columnRowId],
        where: where.toString(),
        limit: 1,
        orderBy: '$columnRowId ${before ? 'DESC' : 'ASC'}'));

    if (messageId == null) return null;
    return messageId;
  }

  static Map<String, dynamic> getMessageSearchTableInsertion(
      MessageEntity msg) {
    String content;
    List<String> links;
    String isHide = '0';
    if (msg.content is TextEntity) {
      final textContent = msg.content as TextEntity;
      content = textContent.text;
      links = [
        if (textContent.urlList.hasValue) ...textContent.urlList,
        if (textContent.inviteList.hasValue) ...textContent.inviteList,
      ];
      if (textContent.isHideCommand() && msg.userId != Global.user.id)
        isHide = '1';
    } else if (msg.content is RichTextEntity) {
      content = (msg.content as RichTextEntity).toSearchTextString();
      links = (msg.content as RichTextEntity).links;
    } else {
      content = null;
    }
    return {
      columnRowId: int.parse(msg.messageId),
      columnChannel: msg.channelId,
      columnContent: content,
      columnUserId: msg.userId,
      columnType: msg.content.typeInString,
      columnRecall: msg.recall,
      columnDelete: msg.deleted == 0 ? null : "1",
      if (msg.mentions != null) columnMentions: msg.mentions.join(' '),
      if (msg.mentionRoles != null)
        columnMentionRoles: msg.mentionRoles.join(' '),
      if (links.hasValue) columnLinks: links.join(' '),
      columnHide: isHide,
    };
  }

  static Future markDeleted(String messageId) async {
    await Db.db
        .update(table, {columnDelete: "1"}, where: '$columnRowId = $messageId');
  }

  static Future markRecalled(String messageId, String recalledBy) async {
    await Db.db.update(table, {columnRecall: recalledBy},
        where: '$columnRowId = $messageId');
  }

  static Future<int> countBetween(
      {String channel, String userId, BigInt begin, BigInt end}) async {
    final query = """
    SELECT COUNT(*) FROM $table WHERE
      $columnChannel = '$channel'
      AND $columnRowId >= $begin
      AND $columnRowId < $end 
      AND $columnUserId != '$userId'
      AND $columnDelete ISNULL
      AND $columnHide = "0"
    """;
    // debugPrint("count between $query");
    // var result = await Db.db.select(query);
    // return result.length;
    return Sqflite.firstIntValue(await Db.db.select(query));
  }

  ///查询最后的可见消息ID
  static Future<BigInt> queryLastId(String channelId, BigInt beginId) async {
    String where = """
      $columnChannel = '$channelId'
      AND $columnDelete ISNULL
      AND $columnHide = "0"
    """;
    if (beginId != null) {
      where += ' AND $columnRowId >= $beginId ';
    }
    final res = await Db.db.query(table,
        columns: [columnRowId],
        where: where,
        limit: 1,
        orderBy: '$columnRowId DESC');
    //增加非空判断
    if (res.noValue) return null;
    final result = res.first[columnRowId];
    return result != null ? BigInt.from(result) : null;
  }
}

///获取：插入的sql语句
String getInsertSql(String table, Map<String, dynamic> values,
    {bool isIgnoreMode = false}) {
  if (table == null || values == null || values.isEmpty) return null;
  final length = values.length;
  //该方法仅在notpull消息使用。所以不使用空消息替代已有内容的消息
  final StringBuffer resultSb = StringBuffer(
      'insert or ${isIgnoreMode ? "ignore" : "replace"} into $table (');
  final StringBuffer valueSb = StringBuffer(') values (');
  var i = 0;
  values.forEach((key, value) {
    resultSb.write(key);
    if (value == null) {
      valueSb.write('null');
    } else if (value is String) {
      valueSb.write("'$value'");
    } else {
      valueSb.write(value);
    }
    if (length - 1 != i++) {
      resultSb.write(',');
      valueSb.write(',');
    }
  });
  resultSb.write(valueSb.toString());
  resultSb.write(')');
  return resultSb.toString();
}

///获取：删除的sql语句
String getDeleteSql(String table, Map<String, dynamic> condition) {
  if (table == null || condition == null || condition.isEmpty) return null;
  final length = condition.length;
  final StringBuffer resultSb = StringBuffer('delete from $table where ');
  var i = 0;
  condition.forEach((key, value) {
    if (key == null || value == null) return;
    resultSb.write('$key = $value');
    if (length - 1 != i++) {
      resultSb.write(' and ');
    }
  });
  return resultSb.toString();
}
