import 'core/config.dart';
import 'main.dart' as _main;

void main() {
  Config.env = Env.newtest;
  _main.main();
}
