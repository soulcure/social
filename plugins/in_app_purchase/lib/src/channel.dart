import 'package:flutter/services.dart';

/// dart 调用原生通道
const MethodChannel channel =
    const MethodChannel('plugins.flutter.io/in_app_purchase');

/// 原生回调dart 通道
const MethodChannel callbackChannel =
    MethodChannel('plugins.flutter.io/in_app_purchase_callback');
