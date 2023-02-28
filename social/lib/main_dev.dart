import 'core/config.dart';
import 'main.dart' as _main;

void main() {
  Config.env = Env.dev;
  _main.main();
}
