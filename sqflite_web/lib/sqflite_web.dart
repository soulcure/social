import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_web/src/database_factory.dart';

/// The database factory to use for Web.
///
/// Check support documentation.
DatabaseFactory get databaseFactoryWeb => databaseFactoryWebImpl;

/// The Web plugin registration.
class SqflitePluginWeb extends PlatformInterface {
  /// Registers the Web database factory.
  static void registerWith(Registrar registrar) {}
}
