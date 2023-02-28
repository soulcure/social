@JS('sqflite_web')
library sqflite_web;

import 'dart:js' as js;
import 'dart:typed_data';

import 'package:js/js.dart';
import 'package:meta/meta.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common/src/sql_builder.dart'; // ignore: implementation_imports

/// Web log level.
int logLevel = sqfliteLogLevelNone;

class FakeBatch extends Batch {
  @override
  noSuchMethod(Invocation invocation) {
    return null;
  }

  @override
  Future<List<dynamic>> commit(
      {bool exclusive, bool noResult, bool continueOnError}) async {
    return const [];
  }
}

/// Web database
class SqfliteWebDatabase extends Database {
  /// Create web database.
  SqfliteWebDatabase({this.path, this.readOnly, this.logLevel});

  /// Open web database from byte data.
  SqfliteWebDatabase.fromData(
      {@required this.path,
      @required this.readOnly,
      @required this.logLevel,
      Uint8List data});

  /// P$ath.
  @override
  final String path;

  /// If read-only
  final bool readOnly;

  /// Log level.
  final int logLevel;

  /// Debug map.
  Map<String, dynamic> toDebugMap() =>
      <String, dynamic>{'path': path, 'readOnly': readOnly};

  bool _isOpen = false;

  @override
  bool get isOpen => _isOpen;

  /// Last insert id.
  int _getLastInsertId() {
    return 0;
  }

  /// Return the count of updated rows.
  int _getUpdatedRows() {
    return 0;
  }

  /// Close the database.
  @override
  Future<void> close() {
    return null;
  }

  @override
  Future<int> delete(String table, {String where, List whereArgs}) async {
    return 0;
  }

  @override
  @deprecated
  Future<T> devInvokeMethod<T>(String method, [arguments]) {
    throw UnimplementedError('deprecated');
  }

  @override
  @deprecated
  Future<T> devInvokeSqlMethod<T>(String method, String sql, [List arguments]) {
    throw UnimplementedError('deprecated');
  }

  /// Handle execute.
  @override
  Future<void> execute(String sql, [List sqlArguments]) {}

  @override
  Future<int> insert(String table, Map<String, dynamic> values,
      {String nullColumnHack, ConflictAlgorithm conflictAlgorithm}) async {
    return 0;
  }

  @override
  Future<List<Map<String, dynamic>>> query(String table,
      {bool distinct,
      List<String> columns,
      String where,
      List whereArgs,
      String groupBy,
      String having,
      String orderBy,
      int limit,
      int offset}) async {
    return const [];
  }

  @override
  Future<int> rawDelete(String sql, [List sqlArguments]) async {
    return 0;
  }

  @override
  Future<int> rawInsert(String sql, [List sqlArguments]) async {
    return 0;
  }

  @override
  Future<List<Map<String, dynamic>>> rawQuery(String sql,
      [List sqlArguments]) async {
    return [];
  }

  @override
  Future<int> rawUpdate(String sql, [List sqlArguments]) async {
    return 0;
  }

  @override
  Future<int> getVersion() async {
    return 0;
  }

  @override
  Future<void> setVersion(int version) {
    return null;
  }

  @override
  Batch batch() {
    return FakeBatch();
  }

  @override
  Future<T> transaction<T>(Future<T> Function(Transaction txn) action,
      {bool exclusive}) {
    // TODO: implement transaction
    throw UnimplementedError();
  }

  @override
  Future<int> update(String table, Map<String, dynamic> values,
      {String where,
      List whereArgs,
      ConflictAlgorithm conflictAlgorithm}) async {
    return 0;
  }

  /// Export the whole database.
  Future<Uint8List> export() async {
    return null;
  }

  @override
  String toString() => toDebugMap().toString();
}

/// Pack the result in the expected sqflite format.
List<Map<String, dynamic>> packResult(js.JsObject result) {
  return null;
}

/// Dart api wrapping an underlying prepared statement object from the sql.js
/// library.
class Statement {
  Statement._(this._obj);

  final js.JsObject _obj;

  /// Executes this statement with the bound [args].
  bool executeWith(List<dynamic> args) => true;

  /// Performs `step` on the underlying js api
  bool step() => true;

  /// Reads the current from the underlying js api
  dynamic currentRow(List<dynamic> params) {}

  /// The columns returned by this statement. This will only be available after
  /// [step] has been called once.
  List<String> columnNames() => const [];

  /// Calls `free` on the underlying js api
  void free() {}
}
