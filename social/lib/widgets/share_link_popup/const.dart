import 'package:get/get.dart';

enum ShareLinkTimes {
  infinite,
  times_1,
  times_5,
  times_10,
  times_25,
  times_50,
  times_100,
  times_500,
  times_1000,
}

enum ShareLinkDeadLine {
  infinite,
  day_30,
  day_15,
  day_7,
  day_1,
  hour_12,
  hour_6,
  hour_1,
  minute_30,
}

extension ShareTimesExtension on ShareLinkTimes {
  int get value {
    switch (this) {
      case ShareLinkTimes.infinite:
        return -1;
      case ShareLinkTimes.times_1:
        return 1;
      case ShareLinkTimes.times_5:
        return 5;
      case ShareLinkTimes.times_10:
        return 10;
      case ShareLinkTimes.times_25:
        return 25;
      case ShareLinkTimes.times_50:
        return 50;
      case ShareLinkTimes.times_100:
        return 100;
      case ShareLinkTimes.times_500:
        return 500;
      case ShareLinkTimes.times_1000:
        return 1000;
      default:
        return -1;
    }
  }

  String get desc {
    switch (this) {
      case ShareLinkTimes.infinite:
        return '无限'.tr;
      case ShareLinkTimes.times_1:
        return '1';
      case ShareLinkTimes.times_5:
        return '5';
      case ShareLinkTimes.times_10:
        return '10';
      case ShareLinkTimes.times_25:
        return '25';
      case ShareLinkTimes.times_50:
        return '50';
      case ShareLinkTimes.times_100:
        return '100';
      case ShareLinkTimes.times_500:
        return '500';
      case ShareLinkTimes.times_1000:
        return '1000';
      default:
        return '';
    }
  }
}

extension ShareLinkDeadLineExtension on ShareLinkDeadLine {
  int get value {
    switch (this) {
      case ShareLinkDeadLine.infinite:
        return -1;
      case ShareLinkDeadLine.day_30:
        return 30 * 24 * 60 * 60;
      case ShareLinkDeadLine.day_15:
        return 15 * 24 * 60 * 60;
      case ShareLinkDeadLine.day_7:
        return 7 * 24 * 60 * 60;
      case ShareLinkDeadLine.day_1:
        return 24 * 60 * 60;
      case ShareLinkDeadLine.hour_12:
        return 12 * 60 * 60;
      case ShareLinkDeadLine.hour_6:
        return 6 * 60 * 60;
      case ShareLinkDeadLine.hour_1:
        return 60 * 60;
      case ShareLinkDeadLine.minute_30:
        return 30 * 60;
      default:
        return -1;
    }
  }

  String get desc {
    switch (this) {
      case ShareLinkDeadLine.infinite:
        return '永久'.tr;
      case ShareLinkDeadLine.day_30:
        return '30天'.tr;
      case ShareLinkDeadLine.day_15:
        return '15天'.tr;
      case ShareLinkDeadLine.day_7:
        return '7天'.tr;
      case ShareLinkDeadLine.day_1:
        return '1天'.tr;
      case ShareLinkDeadLine.hour_12:
        return '12小时'.tr;
      case ShareLinkDeadLine.hour_6:
        return '6小时'.tr;
      case ShareLinkDeadLine.hour_1:
        return '1小时'.tr;
      case ShareLinkDeadLine.minute_30:
        return '30分钟'.tr;
      default:
        return '';
    }
  }
}
