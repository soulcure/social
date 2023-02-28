import 'package:intl/intl.dart';

class MyDate {
  static String full = "yyyy-MM-dd HH:mm:ss";

  /*
   * 时间格式转换
   * @param timestamp
   * @param format format yyyy-MM-dd HH:mm:ss
   *
   * */
  static String formatTimeStampToString(int? timestamp, [String? format]) {
    assert(timestamp != null);

    int time = 0;

    if (timestamp is int) {
      time = timestamp;
    } else {
      time = int.parse(timestamp.toString());
    }

    format ??= 'yyyy-MM-dd HH:mm:ss';

    final DateFormat dateFormat = DateFormat(format);

    final date = DateTime.fromMillisecondsSinceEpoch(time * 1000);

    return dateFormat.format(date);
  }

  /*
  * 获取最近时间
  *
  * 示例代码
  // return MyDate.recentTimeNew(DateTime.now()
  //     .subtract(const Duration(seconds: 10,minutes: 1,hours: 2,days: 6))
  //     .millisecondsSinceEpoch ~/
  // 1000);
  * */
  static String recentTimeNew(int? time) {
    if (time == null || time <= 0) {
      return '未知';
    }
    final DateTime now = DateTime.now();
    final DateTime publishTime =
        DateTime.fromMillisecondsSinceEpoch(time * 1000);
    final Duration def = now.difference(publishTime);
    final String _strTotal = MyDate.formatTimeStampToString(time);
    if (def.inMinutes < 1 && def.inSeconds >= 1) {
      return '${def.inSeconds}秒前';
    } else if (def.inHours < 1 && def.inMinutes >= 1) {
      return '${def.inMinutes}分钟前';
    } else if (def.inDays < 1 && def.inHours >= 1) {
      return '${def.inHours}小时前';
    } else if (def.inDays < 7 && def.inDays >= 1) {
      return '${def.inDays}天前';
    } else {
      return _strTotal;
    }
  }
}
