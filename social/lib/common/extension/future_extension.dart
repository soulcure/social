import 'package:im/loggers.dart';

extension FutureExtension<T> on Future<T> {
  Future<T> printError(String error) {
    return catchError((e) {
      logger.warning("$error. $e");
    });
  }

  Future get ignoreError => catchError((_) {});

  void get unawaited {}
}
