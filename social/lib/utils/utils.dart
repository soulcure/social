import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:date_format/date_format.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' hide Text;
import 'package:get/get.dart';
import 'package:im/common/extension/operation_extension.dart';
import 'package:im/common/extension/string_extension.dart';
import 'package:im/core/config.dart';
import 'package:im/global.dart';
import 'package:im/locale/message_keys.dart';
import 'package:im/pages/home/view/check_permission.dart';
import 'package:im/pages/home/view/text_chat/rich_editor/utils.dart';
import 'package:im/utils/orientation_util.dart';
import 'package:im/utils/universal_platform.dart';
import 'package:intl/intl.dart' as intl;
import 'package:permission_handler/permission_handler.dart'
    as permission_handler;
import 'package:tuple/tuple.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wakelock/wakelock.dart';

import '../loggers.dart';

// ignore: avoid_annotating_with_dynamic
bool safeBoolFromJson(dynamic jsonValue, bool defaultValue) {
  if (jsonValue == null) return defaultValue;
  if (jsonValue is bool) return jsonValue;
  if (jsonValue is int) return jsonValue == 1;
  if (jsonValue is String) return jsonValue == "1";
  return defaultValue;
}

List<String> safeStringListFromJson(
  // ignore: avoid_annotating_with_dynamic
  dynamic jsonValue,
  List<String> defaultValue,
) {
  if (jsonValue == null) return defaultValue;
  if (jsonValue is List)
    return jsonValue.map((e) => e.toString()).toList() ?? defaultValue;
  if (jsonValue is String) {
    try {
      final data = jsonDecode(jsonValue);
      return safeStringListFromJson(data, defaultValue);
    } catch (_) {}
  }
  return defaultValue;
}

bool isNotNullAndEmpty(String str) {
  return str != null && str.isNotEmpty;
}

TextPainter calculateTextHeight(BuildContext context, String value,
    TextStyle style, double maxWidth, int maxLines) {
  ///AUTO??????????????????????????????locale???????????????????????????????????????????????????????????????????????????
  final TextPainter painter = TextPainter(
      textScaleFactor: MediaQuery.of(context).textScaleFactor,

      /// master ???????????? nullok
      locale: Localizations.localeOf(context),
      maxLines: maxLines,
      textDirection: TextDirection.ltr,
      text: TextSpan(text: value, style: style));
  painter.layout(maxWidth: max(0, maxWidth));
  return painter;
}

///cdnUrl ??????????????????
///thumbWidth ?????????????????????????????????
String fetchCdnThumbUrl(String cdnUrl, double thumbWidth) {
  final suffix = "?imageMogr2${Config.webpPath}/thumbnail/${thumbWidth}x";
  if (cdnUrl == null || cdnUrl.isEmpty) {
    return "";
  } else if (cdnUrl.endsWith("gif") || cdnUrl.endsWith(suffix)) {
    return cdnUrl;
  } else {
    return "$cdnUrl$suffix";
  }
}

/// ??????????????????????????????????????????????????????
/// ????????????????????????????????????[maxShortEdge]
/// ???????????????????????????(????????????)???
/// https://developer.qiniu.com/dora/1279/basic-processing-images-imageview2
String fetchYzCdnThumbUrl(String rawUrl, int maxShortEdge) {
  final suffix = "?imageView2/0/h/$maxShortEdge";
  if (rawUrl == null || rawUrl.isEmpty) {
    return "";
  } else if (rawUrl.endsWith("gif") || rawUrl.endsWith(suffix)) {
    return rawUrl;
  } else {
    return "$rawUrl$suffix";
  }
}

bool isNumeric(String s) {
  if (s == null) return false;
  return double.tryParse(s) != null;
}

/// ???????????????????????????????????????????????????4???
String formatNum(int value) {
  if (value > 100000000) {
    // ignore: prefer_interpolation_to_compose_strings
    return (value / 100000000).toStringAsFixed(1) + " ???".tr;
  } else if (value > 10000000) {
    // ignore: prefer_interpolation_to_compose_strings
    return (value / 100000000).toStringAsFixed(2) + " ???".tr;
  } else if (value > 1000000) {
    // ignore: prefer_interpolation_to_compose_strings
    return (value / 10000).toStringAsFixed(0) + " ???".tr;
  } else if (value > 10000) {
    // ignore: prefer_interpolation_to_compose_strings
    return (value / 10000).toStringAsFixed(1) + " ???".tr;
  } else {
    return value.toString();
  }
}

Future<bool> checkPhotoAlbumPermissions() async {
  /// ??????????????????
  final hasPermission = await checkSystemPermissions(
    context: Get.context,
    permissions: [
      if (UniversalPlatform.isIOS) permission_handler.Permission.photos,
      if (UniversalPlatform.isAndroid) permission_handler.Permission.storage,
    ],
  );

  return hasPermission;
}

/// ????????????
String formatSecond(int value) {
  int _value = value;
  String ret = '';
  if (_value >= 24 * 60 * 60) {
    final tmp = (_value / (24 * 60 * 60)).floor();
    ret += '%s???'.trArgs([tmp?.toString()]);
    _value -= tmp * 24 * 60 * 60;
    return ret;
  }

  if (_value >= 60 * 60) {
    final tmp = (_value / (60 * 60)).floor();
    ret += '${twoDigits(tmp)}:';
    _value -= tmp * 60 * 60;
  } else {
    ret += '00:';
  }

  if (_value >= 60) {
    final tmp = (_value / 60).floor();
    ret += '${twoDigits(tmp)} ';
    _value -= tmp * 24 * 60 * 60;
  } else {
    ret += '00';
  }
  return ret;
}

//???????????????????????????????????? ????????????
String timeFormatted(int totalSeconds) {
  final int sec = totalSeconds % 60;
  final int min = ((totalSeconds / 60) % 60).toInt();
  final int hours = totalSeconds ~/ 3600;

  final String seconds = (sec >= 10) ? sec.toString() : '0$sec';
  final String minutes = (min >= 10) ? min.toString() : '0$min';

  if (hours > 0) {
    return '$hours:$minutes:$seconds';
  } else {
    return '$minutes:$seconds';
  }
}

/// ????????????????????? MM-DD HH:MM
// String formatDate(int time) {
//   DateTime date = DateTime.fromMillisecondsSinceEpoch(time * 1000);
//   Duration diff = DateTime.now().difference(date);
// if (diff.inSeconds < 60) {
//   return "??????";
// } else if (diff.inHours < 1) {
//   return "${diff.inMinutes}?????????";
// } else if (diff.inDays < 1) {
//   return "?????? ${twoDigits(date.hour)}:${twoDigits(date.minute)}";
// } else if (diff.inDays < 2) {
//   return "?????? ${twoDigits(date.hour)}:${twoDigits(date.minute)}";
// } else

//   if (diff.inDays < 365) {
//     return "${date.month}-${date.day} ${_twoDigits(date.hour)}:${_twoDigits(date.minute)}";
//   } else {
//     return "${date.year}-${date.month}-${date.day} ${_twoDigits(date.hour)}:${_twoDigits(date.minute)}";
//   }
// }
String formatDate2Str(DateTime date, {bool showToday = false}) {
  List<String> args;
  final now = DateTime.now();
  if (date.year == now.year) {
    if (date.month == now.month) {
      if (date.day == now.day) {
        // ?????????????????????????????? 10:00
        if (showToday)
          args = ["?????? ".tr, HH, ":", nn];
        else
          args = const [HH, ":", nn];
      } else if (date.add(const Duration(days: 1)).day == now.day) {
        // ??????????????????????????? ?????? 10:00
        args = ["?????? ".tr, HH, ":", nn];
//      } else if (now.difference(date).inDays < 7 &&
//          date.weekday < now.weekday) {
//        // ?????????????????????????????????????????? ????????? 10:00
//        const weekDayString = {
//          1: "???",
//          2: "???",
//          3: "???",
//          4: "???",
//          5: "???",
//          6: "???",
//          7: "???".tr
//        };
//        args = ["??????${weekDayString[date.weekday]} ", HH, ":", nn];
      } else {
        if (Get.locale.languageCode != MessageKeys.zh)
          return intl.DateFormat.MMMd().add_Hm().format(date);

        args = [m, "???".tr, d, "??? ".tr, HH, ":", nn];
      }
    } else {
      if (Get.locale.languageCode != MessageKeys.zh)
        return intl.DateFormat.MMMd().add_Hm().format(date);
      // ?????????????????????????????????????????? 11-11 02-02 10:00
      args = [m, "???".tr, d, "??? ".tr, HH, ":", nn];
    }
  } else {
    if (Get.locale.languageCode != MessageKeys.zh)
      return intl.DateFormat.yMMMd().add_Hm().format(date);
    // ????????????????????????????????? 1999-11-11 02-02 10:00
    args = [yyyy, "???".tr, m, "???".tr, d, "??? ".tr, HH, ":", nn];
  }
  return formatDate(date, args);
}

String lastMsgFormatDate2Str(DateTime date) {
  List<String> args;
  final now = DateTime.now();
  if (date.year == now.year) {
    if (date.month == now.month) {
      if (date.day == now.day) {
        args = const [HH, ":", nn];
      } else if (date.add(const Duration(days: 1)).day == now.day) {
        // ??????????????????????????? ?????? 10:00
        args = ["??????".tr];
      } else {
        args = [m, "???", d, "??? "];
      }
    } else {
      // ?????????????????????????????????????????? 11-11 02-02 10:00
      args = [m, "???", d, "??? "];
    }
  } else {
    // ????????????????????????????????? 1999-11-11 02-02 10:00
    args = [yyyy, "???", m, "???", d, "??? "];
  }
  return formatDate(date, args);
}

/// ???????????????
/// @param time: milliseconds since epoch
/// @return ???????????????xxxx???xx???xx??? hh:mm:ss
String formatDetailDate(int time) {
  final date = DateTime.fromMillisecondsSinceEpoch(time);
  if (Get.locale.languageCode != MessageKeys.zh)
    return intl.DateFormat.yMMMd().add_Hms().format(date);
  return formatDate(
    date,
    [yyyy, "???".tr, mm, "???".tr, dd, "??? ".tr, hh, ":", nn, ":", ss],
  );
}

/// ???????????????
String formatCountdownTime(int seconds) {
  final hour = (seconds / 3600).floor();
  final minute = ((seconds - hour * 3600) / 60).floor();
  final second = seconds % 60;
  if (hour < 1) return "${twoDigits(minute)}:${twoDigits(second)}";
  return "${twoDigits(hour)}:${twoDigits(minute)}:${twoDigits(second)}";
}

String twoDigits(int n) {
  if (n >= 10) return "$n";
  return "0$n";
}

// retry(Function fun, {int retryNum = 3, int retryDelay = 1000}) async {
//   try {
//     await fun();
//   } catch (e) {
//     if (retryNum > 0) {
//       Future.delayed(Duration(milliseconds: retryDelay),
//           retry(fun, retryNum: --retryNum, retryDelay: retryDelay));
//     } else {
//       throw 'retry fail';
//     }
//   }
// }

Future delay(Function func, [int milliseconds = 300]) {
  return Future.delayed(Duration(milliseconds: milliseconds), func?.call);
}

String getPlatform() {
  if (UniversalPlatform.isAndroid) return 'android';
  if (UniversalPlatform.isIOS) return 'ios';
  return 'web';
}

Future<bool> hasInstallWeChat() {
  return canLaunch("weixin://");
}

Future<bool> hasInstallQQ() {
  return canLaunch("mqq://");
}

bool isDarkMode(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark;
}

TextStyle copyWithFs12(TextStyle ts) {
  return ts.copyWith(fontSize: 12);
}

// todo delete it
Widget bottomViewInset({Color color}) {
  return Container(
    height: Global.mediaInfo.padding.bottom,
    color: color,
  );
}

double getTopViewInset() {
  return Global.mediaInfo.padding.top;
}

double getBottomViewInset() {
  double padding = Global.mediaInfo?.padding?.bottom ?? 0;
  if (Global.mediaInfo?.padding?.bottom == 0.0 &&
      Global.mediaInfo?.viewInsets?.bottom != 0.0)
    padding = Global.mediaInfo.viewPadding.bottom;
  if (UniversalPlatform.isAndroid && padding == 0)
    padding = Global.mediaInfo.systemGestureInsets.bottom;
  return padding;
}

String subRichString(String str, int len) {
  // ??????emoji??????
  final sRunes = str.runes;
  return sRunes.length > len ? String.fromCharCodes(sRunes, 0, len) : str;
}

const minSizeConstraint = 48.0;
const maxSizeConstraint = 225.0;

double get maxMediaWidth => OrientationUtil.landscape ? 400 : 225.0;

Tuple3<num, num, BoxFit> getImageSize(num _width, num _height,
    {BoxFit defaultFit, double maxSizeConstraint}) {
  maxSizeConstraint ??= maxMediaWidth;
  // todo 120 or minSizeConstraint?
  var width = _width ?? 120;
  width = width > 0 ? width : 120;
  var height = _height ?? maxSizeConstraint;
  height = height > 0 ? height : maxSizeConstraint;
  BoxFit fit = defaultFit ?? BoxFit.contain;
  if (width / height > (maxSizeConstraint / minSizeConstraint)) {
    // ????????????
    width = maxSizeConstraint;
    height = minSizeConstraint;
    fit = BoxFit.fitHeight;
  } else if (height / width > (maxSizeConstraint / minSizeConstraint)) {
    // ????????????
    width = minSizeConstraint;
    height = maxSizeConstraint;
    fit = BoxFit.fitWidth;
  } else if (width > maxSizeConstraint || height > maxSizeConstraint) {
    final s = min(maxSizeConstraint / width, maxSizeConstraint / height);
    width = _width * s;
    height = _height * s;
  } else if (width < minSizeConstraint || height < minSizeConstraint) {
    final s = max(minSizeConstraint / width, minSizeConstraint / height);
    width = _width * s;
    height = _height * s;
  }
  return Tuple3(width, height, fit);
}

/// ????????????
void setAwake(bool value) {
  if (!UniversalPlatform.isMobileDevice) return;
  Wakelock.toggle(enable: value);
}

/// ?????????????????????????????????
Future<ImageInfo> getImageInfo(String filePath) {
  return getImageInfoByProvider(NetworkImage(filePath));
}

Future<ImageInfo> getImageInfoByProvider(ImageProvider provider) {
  final Completer<ImageInfo> completer = Completer<ImageInfo>();
  bool flag = false;
  provider
      .resolve(const ImageConfiguration())
      .addListener(ImageStreamListener((info, _) {
    if (!flag) {
      completer.complete(info);
      flag = true;
    }
  }));
  return completer.future;
}

Scaffold popWrap(
    {double width = 440, double height, Widget child, double horizontal = 24}) {
  return Scaffold(
    backgroundColor: Colors.transparent,
    body: Center(
      child: Container(
        width: width,
        height: height,
        padding: EdgeInsets.symmetric(horizontal: horizontal),
        decoration: BoxDecoration(
            color: Get.theme.backgroundColor,
            borderRadius: const BorderRadius.all(Radius.circular(8))),
        child: child,
      ),
    ),
  );
}

/// - ????????????double??????
String formatDouble(double num, int position) {
  if ((num.toString().length - num.toString().lastIndexOf(".") - 1) <
      position) {
    //???????????????????????????
    return num.toStringAsFixed(position)
        .substring(0, num.toString().lastIndexOf(".") + position + 1)
        .toString();
  } else {
    return num.toString()
        .substring(0, num.toString().lastIndexOf(".") + position + 1)
        .toString();
  }
}

String generateMd5(String data) {
  final content = const Utf8Encoder().convert(data);
  final md5 = crypto.md5;
  final digest = md5.convert(content);
  return hex.encode(digest.bytes);
}

///??????????????????????????????????????????
String getRichStringForParsedText(List contentList) {
  Document document;
  try {
    // RichEditorUtils.transformAToLink(contentList);
    document = Document.fromJson(contentList);
  } catch (e) {
    document = RichEditorUtils.defaultDoc;
    logger.severe('??????????????????:$e');
  }

  final List<Operation> _operationList =
      RichEditorUtils.formatDelta(document.toDelta()).toList();

  final stringBuffer = getRichText(_operationList);
  final tmpString = stringBuffer
      .toString()
      .trim()
      .replaceAllMapped(RegExp("(\n| )+"), (match) => match.group(1));
  // ????????????????????????????????????5????????????5??????????????????\n ParseText????????????...????????????????????????
  final contents = tmpString.split('\n');

  return contents.join('\n');
}

///???????????????????????????(?????????????????????)
StringBuffer getRichText(List<Operation> operationList) {
  final stringBuffer = StringBuffer();
  for (final e in operationList) {
    if (e.isMedia) break;
    if (e.key == Operation.insertKey && e.value is Map) {
      final embed = Embeddable.fromJson(e.value);
      if (embed.data is Map && embed.data['value'] is String) {
        stringBuffer.write(embed.data['value']);
      }
    } else {
      if (e.data is String) {
        stringBuffer.write(e.data);
      }
    }
  }
  return stringBuffer;
}

/// * ??????????????????????????????Operation
List<Operation> getOperationList(String text) {
  Document document;
  final content = text.hasValue ? text : RichEditorUtils.defaultDoc.encode();
  try {
    List<Map<String, dynamic>> contentJson = [];
    contentJson = List<Map<String, dynamic>>.from(jsonDecode(content));
    RichEditorUtils.transformAToLink(contentJson);
    // ?????????????????????
    final last = contentJson.last['insert'];
    if (!(last is String && last.endsWith('\n'))) {
      contentJson.add({'insert': '\n'});
    }
    document = Document.fromJson(contentJson);
  } catch (_) {
    document = RichEditorUtils.defaultDoc;
  }
  final list = RichEditorUtils.formatDelta(document.toDelta()).toList();
  return list;
}

///????????????(????????????,????????????)?????????????????????:
double circleImageMinRatio = 3 / 4;
double circleImageMaxRatio = 4 / 3;

/// * ???????????????????????????????????????????????????
/// * imageWidth imageHeight????????????????????????????????????
/// * widgetWidth????????????????????????????????????dp
double getImageHeightByRatio(
    double imageWidth, double imageHeight, double widgetWidth) {
  if (imageWidth == 0 || imageHeight == 0) {
    return widgetWidth / circleImageMinRatio;
  }
  double widgetHeight;
  final itemRatio = imageWidth / imageHeight;
  if (itemRatio >= circleImageMinRatio && itemRatio <= circleImageMaxRatio) {
    final itemWidth = imageWidth / Get.pixelRatio;
    final itemHeight = imageHeight / Get.pixelRatio;
    // ?????????: ???????????????????????????????????????
    widgetHeight = itemHeight * (widgetWidth / itemWidth);
  } else if (itemRatio < circleImageMinRatio) {
    // ?????????: ???????????????????????????????????????
    widgetHeight = widgetWidth / circleImageMinRatio;
  } else if (itemRatio > circleImageMaxRatio) {
    // ?????????: ???????????????????????????????????????
    widgetHeight = widgetWidth / circleImageMaxRatio;
  }
  return widgetHeight;
}
