import 'package:flutter/services.dart';
import 'package:im/common/extension/string_extension.dart';
import 'package:im/core/config.dart';
import 'package:im/pages/home/json/text_chat_json.dart';
import 'package:im/services/sp_service.dart';
import 'package:im/utils/universal_platform.dart';

import '../../loggers.dart';

class InviteCodeUtil {
  /// 用来检测粘贴板是否有邀请链接,有就把邀请码保存下来
  /// 此接口只是用来保存邀请码,没有做别的操作
  static Future<void> checkInviteUrl() async {
    // android12 和 ios14 以上系统不做粘贴板检测
    if (UniversalPlatform.isAndroidBelowLevel(31) ||
        UniversalPlatform.isIOSBelowLevel(14)) {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      final url = (data?.text ?? '').pureValue;
      InviteCodeUtil.setInviteCode(url);
    }
  }

  /// 获取缓存中的邀请码
  static String get inviteCode {
    return SpService.to.getString(SP.inviteCode) ?? '';
  }

  /// 通过邀请链接进行保存邀请码
  static void setInviteCode(String inviteUrl) {
    try {
      final url = filterLinkFromText(inviteUrl);
      if (url.noValue) {
        return;
      }
      final index = url.lastIndexOf('/') + 1;
      final qIndex = url.lastIndexOf('?');
      String code;
      if (index > 0 && index <= url.length) {
        final lastIndex =
            qIndex > index && qIndex < url.length ? qIndex : url.length;
        code = url.substring(index, lastIndex) ?? '';
        SpService.to.setString(SP.inviteCode, code);
      }
    } catch (e) {
      return;
    }
  }

  static void setInviteCode2(String code) {
    SpService.to.setString(SP.inviteCode, code);
  }
}

/// 校验邀请链接地址是否为 fanBook 域名下
String filterLinkFromText(String text) {
  try {
    final matchList = TextEntity.urlPattern.allMatches(text).toList();
    if (matchList?.isEmpty ?? true) return null;
    for (var i = 0; i < matchList.length; ++i) {
      final curMatch = matchList[i];
      final url = text.substring(curMatch.start, curMatch.end);

      /// TODO: 这里后期如果有其他规则,需要再特殊处理或者做链接优化
      if (url.startsWith(Config.webLinkPrefix) &&
          !url.startsWith('${Config.webLinkPrefix}channels')) {
        return url;
      }
    }
  } catch (e) {
    logger.warning('链接提取失败:$e');
  }
  return null;
}
