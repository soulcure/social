import 'package:sqflite/sqflite.dart' as s;
import 'package:sqflite/sqlite_api.dart';

Future<Database> openDatabase(String path,
    {int version,
    OnDatabaseConfigureFn onConfigure,
    OnDatabaseCreateFn onCreate,
    OnDatabaseVersionChangeFn onUpgrade,
    OnDatabaseVersionChangeFn onDowngrade,
    OnDatabaseOpenFn onOpen,
    bool readOnly = false,
    bool singleInstance = true}) {
  return s.openDatabase(
    path,
    version: version,
    onConfigure: onConfigure,
    onCreate: onCreate,
    onUpgrade: onUpgrade,
    onDowngrade: onDowngrade,
    onOpen: onOpen,
    readOnly: readOnly,
    singleInstance: singleInstance,
  );
}

Future<void> deleteDatabase(String path) => s.deleteDatabase(path);
Future<String> getDatabasesPath() => s.getDatabasesPath();
