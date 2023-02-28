import 'package:im/loggers.dart';
import 'package:path/path.dart';
import 'package:pedantic/pedantic.dart';
import 'package:sqflite/sqlite_api.dart';

import '../../db/platform/interface.dart'
    if (dart.library.html) '../../db/platform/web.dart'
    if (dart.library.io) '../../db/platform/sqflite.dart';

import 'dlog_table.dart';

class DLogDb {
  static Database db;

  /// 用来处理数据库异步打开数据库(防止多次open)
  static Future openDBStateFuture;

  static Future<void> open() => openDBStateFuture ??= _openDatabase();

  static Future _openDatabase() async {
    DLogDb.db = await openDatabase(await _getPath(), version: 1,
        onCreate: (db, version) async {
      unawaited(DLogTable.createTable(db));
    }, onUpgrade: (db, oldVersion, newVersion) {
      logger.info('oldVersion $oldVersion newVersion $newVersion');
    });
  }

  static Future<String> _getPath() async {
    final databasePath = await getDatabasesPath();
    return join(databasePath, 'fb_dlog_cache.db');
  }

  static Future delDatabase({
    bool reopen = true,
  }) async {
    await closeDB();
    await deleteDatabase(await _getPath());
    //删除数据库后，是否
    if (reopen == true) {
      await _openDatabase();
    }
  }

  static Future closeDB() async {
    await DLogDb.db.close();
  }
}
