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
  throw UnimplementedError("UnimplementedError openDatabase");
}

Future<void> deleteDatabase(String path) async {}

Future<String> getDatabasesPath() async => null;
