import 'package:shared_preferences/shared_preferences.dart';

class SPManager {
  static SharedPreferences? _sp;

  static SharedPreferences? get sp {
    return _sp;
  }

  static void spInit(SharedPreferences sp) {
    _sp = sp;
    return;
  }
}
