import 'core/config.dart';
import 'main.dart' as _main;

void main() {
  Config.env = Env.newtest;

  Config.autoLogin = true;

  _main.main();
}
