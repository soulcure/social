import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fb_carrier_info_plugin/fb_carrier_info_plugin.dart';

void main() {
  const MethodChannel channel = MethodChannel('fb_carrier_info_plugin');

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return '42';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('getPlatformVersion', () async {
    // expect(await FbCarrierInfoPlugin.platformVersion, '42');
  });
}
