import 'dart:convert';

import 'package:flutter/foundation.dart';

/// 递归获取字典中的value
/// keys = keya.keyb.keyc
// ignore: avoid_annotating_with_dynamic
dynamic getRecursionKeyFromMap(String keys, dynamic data) {
  if (data != null && data is Map) {
    if (keys.contains(".")) {
      final first = keys.split(".").first;
      if (data.containsKey(first)) {
        return getRecursionKeyFromMap(
            keys.substring(first.length + 1), data[first]);
      }
      return null;
    }
    return data[keys];
  }
  return null;
}

dynamic _parseAndDecode(String response) {
  return jsonDecode(response);
}

/// 异步解析json
Future parseJson(String text) {
  if (text.isEmpty) return Future.value();
  return compute(_parseAndDecode, text);
}
