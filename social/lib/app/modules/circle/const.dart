import 'package:flutter/material.dart';
import 'package:tuple/tuple.dart';

const double tabBarHeight = 35;
const double avatarTopSpace = 100;
const double avatarSize = 64;
const double leadingSpace = 16;
const double topRadius = 12;
const double pinnedDynamicLineHeight = 16;
const double pinnedDynamicLineSpace = 16;
const double descLineHeight = 18;
const double circleHeaderHeight = 202;

const titleStyle = TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 20,
    color: Colors.white,
    height: 1.25,
    wordSpacing: 0.3);
const subTitleStyle = TextStyle(
  fontSize: 13,
  height: 1.25,
  color: Colors.white,
);
const descStyle = TextStyle(fontSize: 14, color: Colors.white, height: 1.2857);

// 置顶颜色样式 3:公告   2:活动    1:精华
final Map<String, Color> pinnedDynamicBgColor = {
  "3": const Color(0xff3366ff).withOpacity(0.1),
  "2": const Color(0xffff6a00).withOpacity(0.1),
  "1": const Color(0xff07d6ba).withOpacity(0.1),
};

final Map<String, Color> pinnedDynamicTitleColor = {
  "3": const Color(0xff3366ff),
  "2": const Color(0xffff6a00),
  "1": const Color(0xff07d6ba),
};

/// 除法后，保留一位小数
/// 39999 => 3.9
/// 40000 => 4
/// 10000 => 1
String formatCount(int count, int dividend) {
  final value = (count / (dividend / 10)).floorToDouble() / 10;
  String ret = value.toStringAsFixed(1);
  if (ret.endsWith('0') && ret.length > 2) {
    ret = ret.substring(0, ret.length - 2);
  }
  return ret;
}

Tuple2<String, String> getFormatDynamic(int count) {
  Tuple2<String, String> ret;
  if (count >= 100000000) {
    ret = Tuple2(formatCount(count, 100000000), '亿条动态');
  } else if (count >= 10000) {
    ret = Tuple2(formatCount(count, 10000), '万条动态');
  } else {
    ret = Tuple2(count.toString(), '条动态');
  }
  return ret;
}

Tuple2<String, String> getFormatMemberStatistics(int count) {
  Tuple2<String, String> ret;
  if (count >= 100000000) {
    ret = Tuple2(formatCount(count, 100000000), '亿人参与');
  } else if (count >= 10000) {
    ret = Tuple2(formatCount(count, 10000), '万人参与');
  } else {
    ret = Tuple2(count.toString(), '人参与');
  }
  return ret;
}
