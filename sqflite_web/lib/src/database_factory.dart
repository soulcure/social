import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_web/src/sqflite_web_impl.dart';

DatabaseFactory _databaseFactoryWebImpl;

/// The web database factory.
DatabaseFactory get databaseFactoryWebImpl {
  return _databaseFactoryWebImpl ??= DatabaseFactoryWeb();
}

/// The web database factory.
class DatabaseFactoryWeb extends DatabaseFactory {
  SqfliteWebDatabase _db;

  @override
  Future<bool> databaseExists(String path) async {
    //TODO
    return _db != null;
  }

  @override
  Future<void> deleteDatabase(String path) async {
    //TODO
    return _db = null;
  }

  @override
  Future<String> getDatabasesPath() async {
    //TODO
    return null;
  }

  @override
  Future<Database> openDatabase(String path,
      {OpenDatabaseOptions options}) async {
    return SqfliteWebDatabase();
  }

  @override
  Future<void> setDatabasesPath(String path) {
    // TODO: implement setDatabasesPath
    throw UnimplementedError();
  }
}
