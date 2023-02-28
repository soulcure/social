import 'dart:async';

// In order to *not* need this ignore, consider extracting the "web" version
// of your plugin as a separate package, instead of inlining it in the same
// package as the core of your plugin.
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html show window;

import 'package:flutter/services.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';

export 'src/zego_engine_manager.dart';
export 'src/interface/zego_ww_engine.dart';
export 'src/zego_ww_defines.dart';
export 'src/interface/zego_ww_video_view.dart';
export 'src/interface/zego_ww_media_model.dart';
export 'src/zego_ww_defines.dart';
export 'src/zego_ww_web_defines.dart';
export 'src/web/zego_web_sdk_js.dart' hide ZegoDeviceInfo;

/// A web implementation of the ZegoWw plugin.
class ZegoWwWeb {
  // ZegoExpressEngine _zg;
  static void registerWith(Registrar registrar) {
    final MethodChannel channel = MethodChannel(
      'zego_ww',
      const StandardMethodCodec(),
      registrar,
    );
    final pluginInstance = ZegoWwWeb();
    channel.setMethodCallHandler(pluginInstance.handleMethodCall);
  }

  /// Handles method calls over the MethodChannel of this plugin.
  /// Note: Check the "federated" architecture for a new way of doing this:
  /// https://flutter.dev/go/federated-plugins
  Future<dynamic> handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'getPlatformVersion':
        return getPlatformVersion();
        break;
      default:
        throw PlatformException(
          code: 'Unimplemented',
          details: 'zego_ww for web doesn\'t implement \'${call.method}\'',
        );
    }
  }

  /// Returns a [String] containing the version of the platform.
  Future<String> getPlatformVersion() {
    final version = html.window.navigator.userAgent;
    return Future.value(version);
  }
}
