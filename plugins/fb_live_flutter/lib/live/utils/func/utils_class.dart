import 'package:fb_live_flutter/fb_live_flutter.dart';
import 'package:fb_live_flutter/live/utils/theme/my_toast.dart';
import 'package:flutter/services.dart';

import 'check.dart';

/// 优惠券价格字号显示
///
/// 1. 少于7位字符显示56号数字体
/// 1. 超过7位字符显示，32号数字体
/// 2. 超过9位字符显示，24号数字体
double fontSizeGet(String sizeStr) {
  final int length = sizeStr.length;
  if (length < 7) {
    // 56 / 2
    return 28;
  } else if (length >= 7 && length <= 9) {
    // 32 / 2
    return 16;
  } else {
    // 24 / 2
    return 12;
  }
}

class UtilsClass {
  static String calcNum(int? number) {
    if (number == null) {
      return "";
    }
    if (number < 10000) {
      return number.toString();
    } else if (number >= 10000 && number < 100000000) {
      return '${(number / 10000).toStringAsFixed(1)}w';
    } else if (100000000 <= number) {
      return '${(number / 100000000).toStringAsFixed(1)}y';
    } else {
      return "";
    }
  }

  /// 显示千分位和万单位
  ///
  /// [2021 12.14]新需求
  /// 4. 乐豆最多显示金额五位数，超过五位数用缩写显示。如：10.1w
  static String calcNumAndThousands(int? number) {
    if (number == null) {
      return "";
    }
    if (number > 9999 && number < 100000) {
      return formatNum(number.toString());
    } else if (number < 100000) {
      return number.toString();
    } else if (number >= 10000 && number < 100000000) {
      return '${(number / 10000).toStringAsFixed(1)}w';
    } else if (100000000 <= number) {
      return '${(number / 100000000).toStringAsFixed(1)}y';
    } else {
      return "";
    }
  }
}

/// 字符串不为空
bool strNoEmpty(String? value) {
  if (value == null) return false;
  if (value == 'null') return false;

  return value.trim().isNotEmpty;
}

///判断List是否为空
bool listNoEmpty(List? list) {
  if (list == null || list.isEmpty) return false;

  return true;
}

/// 判断是否网络
bool isNetWorkImg(String img) {
  return img.startsWith('http') || img.startsWith('https');
}

/// 判断是否资源图片
bool isAssetsImg(String img) {
  return img.startsWith('asset') || img.startsWith('assets');
}

Future copyText(String text, [String? tips]) async {
  final String str = text;
  await Clipboard.setData(ClipboardData(text: str));
  mySuccessToast(tips ?? "复制成功");

  fbApi.fbLogger.info("复制文本：$text");
}

Future<String?> getCopyText() async {
  final ClipboardData? clipboardData =
      await Clipboard.getData(Clipboard.kTextPlain); //获取粘贴板中的文本
  return clipboardData?.text;
}
