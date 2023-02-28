import 'package:sqflite/sqlite_api.dart';
import 'package:sqflite_web/sqflite_web.dart';

Future<Database> openDatabase(String path,
    {int version,
    OnDatabaseConfigureFn onConfigure,
    OnDatabaseCreateFn onCreate,
    OnDatabaseVersionChangeFn onUpgrade,
    OnDatabaseVersionChangeFn onDowngrade,
    OnDatabaseOpenFn onOpen,
    bool readOnly = false,
    bool singleInstance = true}) {
  return databaseFactoryWeb.openDatabase(path,
      options: OpenDatabaseOptions(
        version: version,
        onConfigure: onConfigure,
        onCreate: onCreate,
        onUpgrade: onUpgrade,
        onDowngrade: onDowngrade,
        onOpen: onOpen,
        readOnly: readOnly,
        singleInstance: singleInstance,
      ));
}

Future<void> deleteDatabase(String path) =>
    databaseFactoryWeb.deleteDatabase(path);

Future<String> getDatabasesPath() async {
  final res = await databaseFactoryWeb.getDatabasesPath();
  return res ?? "";
}
