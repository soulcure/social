import 'dart:async';

import 'package:im/pages/home/view/text_chat/items/components/parsed_text_extension.dart';

abstract class LinkHandler {
  const LinkHandler();

  /// 返回 true 才会被处理，并且中断处理链
  bool match(String url);

  /// 定义处理连接的逻辑
  Future handle(String url, {RefererChannelSource refererChannelSource});

  Future<void> handleIfMatch(String url) async {
    if (match(url)) await handle(url);
  }
}
