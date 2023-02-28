import 'dart:core';
import 'dart:math';

import 'package:date_format/date_format.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/db/db.dart';
import 'package:im/pages/home/model/chat_index_model.dart';
import 'package:im/pages/member_list/model/member_list_model.dart';
import 'package:im/services/sp_service.dart';
import 'package:im/themes/const.dart';
import 'package:im/themes/default_theme.dart';
import 'package:im/widgets/app_bar/custom_appbar.dart';
import 'package:im/widgets/avatar.dart';
import 'package:im/widgets/segment_list/segment_member_list_service.dart';
import 'package:im/widgets/user_info/popup/user_info_popup.dart';
import 'package:provider/provider.dart';
import 'package:im/common/extension/string_extension.dart';

class TimeBeginEnd {
  String begin;
  String end;

  TimeBeginEnd({this.begin, this.end});
}

class TimeUtils {
  /// TODO 简化：是否是同一天可以使用以下方式判断：
  /// [dayA.year == dayB.year && dayA.month == dayB.month && dayA.day == dayB.day]
  // 按天比较，是否为同一天
  static int compareDay(DateTime dayA, DateTime dayB) {
    const int milsDay = 24 * 3600 * 1000;
    final int dayAMils = (dayA.millisecondsSinceEpoch / milsDay).round() * 1000;
    final int dayBMils = (dayB.millisecondsSinceEpoch / milsDay).round() * 1000;
    return dayAMils - dayBMils;
  }

  /// TODO 单词拼写错误，注释错误
  /// TODO 简化，并且如果是 1 号，会产生 day 为 0，没测过结果。不过减少一天的代码如下：
  /// [day.subtract(Duration(days: 1))]
  /// 增加一天
  static DateTime decreaseDay(DateTime day) {
    final newDay = DateTime(
        day.year, day.month, day.day - 1, day.hour, day.minute, day.second);
    return newDay;
  }

  ///获取现在的时间
  static int getDayNow() {
    final nowTime = DateTime.now();
    return nowTime.millisecondsSinceEpoch;
  }

  ///获取今天的开始时间
  static int getDayBegin() {
    final nowTime = DateTime.now();
    final day = DateTime(nowTime.year, nowTime.month, nowTime.day);
    return day.millisecondsSinceEpoch;
  }

  ///获取昨天的开始时间
  static int getBeginDayOfYesterday() {
    final nowTime = DateTime.now();

    /// TODO 使用 [nowTime.subtract]
    final yesterday = nowTime.add(const Duration(days: -1));
    final day = DateTime(yesterday.year, yesterday.month, yesterday.day);
    return day.millisecondsSinceEpoch;
  }

  /// TODO 单词拼写错误
  ///获取昨天的结束时间
  static int getEndDayOfYesterDay() {
    final nowTime = DateTime.now();

    /// TODO 使用 [nowTime.subtract]
    final yesterday = nowTime.add(const Duration(days: -1));
    final day =
        DateTime(yesterday.year, yesterday.month, yesterday.day, 23, 59, 59);
    return day.millisecondsSinceEpoch;
  }

  ///获取本周的开始时间
  static int getBeginDayOfWeek() {
    final nowTime = DateTime.now();
    final weekday = nowTime.weekday;

    /// TODO 使用 [nowTime.subtract]，变量命名歧义
    final yesterday = nowTime.add(Duration(days: -(weekday - 1)));
    final day = DateTime(yesterday.year, yesterday.month, yesterday.day);
    return day.millisecondsSinceEpoch;
  }

  ///获取本月的开始时间
  static int getBeginDayOfMonth() {
    final nowTime = DateTime.now();
    final day = DateTime(nowTime.year, nowTime.month);
    return day.millisecondsSinceEpoch;
  }

  ///获取本年的开始时间
  static int getBeginDayOfYear() {
    final nowTime = DateTime.now();
    final day = DateTime(nowTime.year);
    return day.millisecondsSinceEpoch;
  }
}

// 实现 ChoiceInput
// index 为标识ChoiceInput
// parent 为父控件
class InputSelect extends StatelessWidget {
  const InputSelect({
    @required this.index,
    @required this.widget,
    @required this.parentChoose,
    @required this.choice,
    @required this.onChoose,
  }) : super();

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
        label: Container(alignment: Alignment.center, child: Text(choice)),
        //未选定的时候背景
        selectedColor: const Color(0xFF6179F2),
        //被禁用得时候背景
        disabledColor: const Color(0xFFF2F3F5),
        labelStyle: TextStyle(
            fontWeight: FontWeight.w100,
            fontSize: 12,
            color: (parentChoose == index)
                ? Colors.white
                : const Color(0xFF8F959E)),
        labelPadding: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.symmetric(vertical: 1, horizontal: 1),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        onSelected: (value) {
          onChoose(index);
        },
        selected: parentChoose == index);
  }

  final int index;
  final Widget widget;
  final int parentChoose;
  final String choice;
  final void Function(int) onChoose;
}

class GuildOptDataTrendData {
  String dateStr;
  int totalUserCnt;
  int activityUserCnt;
  int increaseUserCnt;
  int totalMsgCnt;
  int avgMsgCnt;

  GuildOptDataTrendData(this.dateStr, this.totalUserCnt, this.activityUserCnt,
      this.increaseUserCnt, this.totalMsgCnt, this.avgMsgCnt);
}

class GuildOptDataGeneralData {
  int totalUserCnt = 0;
  int yesterdayUserCnt = 0;
  int yesterdayIncreasedUserCnt = 0;
  int yesterdayTotalMsgCnt = 0;
}

class GuildOptDataViewModel extends ChangeNotifier {
  String guildId;

  GuildOptDataGeneralData generalData;

  List<GuildOptDataTrendData> trendData = [];

  final List<String> _userIds = [];
  Map<String, List> activeUserMsgData = {};

  // final List<String> userChoice = ['总用户数'.tr, '活跃用户数'.tr, '新增用户数'.tr, '总消息量'.tr, '人均消息量'.tr];
  final List<String> userChoice = [
    '活跃用户数'.tr,
    '新增用户数'.tr,
    '总消息量'.tr,
    '人均消息量'.tr
  ];

  int _userSelected = 0;

  int get userSelected => _userSelected;

  set userSelected(int value) {
    _userSelected = value;
    // print("[dj] ${DateTime.now().toString()} userSelected notifyListeners call");

    notifyListeners();
  }

  bool _activitySortAscending = false;

  bool get activitySortAscending => _activitySortAscending;

  set activitySortAscending(bool value) {
    _activitySortAscending = value;
    updateActiveData();
  }

  int _activitySortIndex = 1;

  int get activitySortIndex => _activitySortIndex;

  set activitySortIndex(int index) {
    _activitySortIndex = index;
    updateActiveData();
  }

  List<Map> activeData = [];

  void updateActiveData() {
    if (_activitySortIndex == 1 && activitySortAscending == true) {
      activeData = activeUserMsgData["day7Asc"];
    } else if (_activitySortIndex == 1 && activitySortAscending == false) {
      activeData = activeUserMsgData["day7Desc"];
    } else if (_activitySortIndex == 2 && activitySortAscending == true) {
      activeData = activeUserMsgData["day30Asc"];
    } else if (_activitySortIndex == 2 && activitySortAscending == false) {
      activeData = activeUserMsgData["day30Desc"];
    } else {
      // 默认值
      activeData = activeUserMsgData["day7Asc"];
    }
    // print("[dj] ${DateTime.now().toString()} updateActiveData notifyListeners call");

    notifyListeners();
  }

  final List<String> daysChoice = ['近7日'.tr, '近30日'.tr];
  int _daySelected = 0;

  int get daySelected => _daySelected;

  set daySelected(int value) {
    _daySelected = value;
    // print("[dj] ${DateTime.now().toString()} daySelected notifyListeners call");
    notifyListeners();
  }

  GuildOptDataViewModel(this.guildId) {
    // print("[dj] ${DateTime.now().toString()} GuildOptDataViewModel begin");
    for (final id in MemberListModel.instance.fullList) {
      final info = Db.userInfoBox.get(id);
      _userIds.add(info.userId);
    }

    generalData = GuildOptDataGeneralData();

    getGuildCalc30RealTime(guildId).then((value) {
      trendData = value;
      // print("[dj] ${DateTime.now().toString()} getGuildCalc30RealTime notifyListeners call");
      notifyListeners();
    });
    // initCalcDB().then((value){
    //   getGuildCalc30(guildId).then((d) {
    //     trendData = d;
    //     notifyListeners();
    //   });
    // });

    final TimeBeginEnd yesterdayBeginEnd = beginEndTime(DateTime.now(), 1, -1);
    // print("[dj] ${DateTime.now().toString()} calcAnalysisData begin");
    calcAnalysisData(yesterdayBeginEnd).then((value) {
      // print("[dj] ${DateTime.now().toString()} calcAnalysisData end");
      generalData = GuildOptDataGeneralData();
      // generalData.totalUserCnt = value["totalUserCnt"];
      // generalData.totalUserCnt =
      //     MemberListModel.instance.fullList.length; //使用本地用户列表数据矫正
      generalData.totalUserCnt =
          SegmentMemberListService.to.guildCount(guildId);
      // TextChannelController.to().segmentMemberListModel.guildCount;
      generalData.yesterdayUserCnt = value["timeUserCnt"];
      generalData.yesterdayIncreasedUserCnt = value["dayIncreaseCnt"];
      generalData.yesterdayTotalMsgCnt = value["dayMsgCnt"];

      // print("[dj] ${DateTime.now().toString()} calcAnalysisData notifyListeners call");
      notifyListeners();
    });

    calcActiveUserMsg();
  }

  TimeBeginEnd beginEndTime(DateTime date, int begin, int end) {
    const int dayMils = 24 * 3600 * 1000;
    final int currMils =
        date.millisecondsSinceEpoch - date.timeZoneOffset.inMilliseconds;
    int beginMils = (currMils / dayMils).round() * dayMils;
    int endMils = beginMils + dayMils;
    beginMils =
        beginMils - begin * dayMils - date.timeZoneOffset.inMilliseconds;
    endMils = endMils + end * dayMils - date.timeZoneOffset.inMilliseconds - 1;
    return TimeBeginEnd(begin: beginMils.toString(), end: endMils.toString());
  }

  // 计算某一时段的统计
  Future<Map<String, int>> calcAnalysisData(TimeBeginEnd timeBeginEnd) async {
    final Map<String, int> analysisData = {};

    // 总用户数
    final totalUserCntResult = await Db.db
        .select("select count(*) as total  from (select user_id from Chat "
            "where guild_id = $guildId  group by user_id)");
    analysisData["totalUserCnt"] =
        int.parse(totalUserCntResult.first["total"].toString()) ?? 0;

    // 活动用户
    final timeUserCntResult = await Db.db.select(
        "select count(*) as total  from (select user_id from Chat "
        "where  guild_id =$guildId and  time >= ${timeBeginEnd.begin} and time <= ${timeBeginEnd.end}  group by user_id)");
    analysisData["timeUserCnt"] =
        int.parse(timeUserCntResult.first["total"].toString()) ?? 0;

    // 昨日新增用户数
    final dayIncreaseCntResult = await Db.db
        .select("select count(*) as total  from (select user_id from Chat "
            "where  guild_id =$guildId and  time >= ${timeBeginEnd.begin} "
            "and time <= ${timeBeginEnd.end} "
            "and content like '{\"type\":\"newJoin\"%' group by user_id)");
    analysisData["dayIncreaseCnt"] =
        int.parse(dayIncreaseCntResult.first["total"].toString()) ?? 0;

    // 昨日消息量
    final dayMsgCntResult = await Db.db.select(
        "select count(*) as total  from  Chat "
        "where guild_id = $guildId and time >= ${timeBeginEnd.begin} and time <= ${timeBeginEnd.end}");

    analysisData["dayMsgCnt"] =
        int.parse(dayMsgCntResult.first["total"].toString()) ?? 0;

    return analysisData;
  }

  Future<void> calcActiveUserMsg() async {
    // print("[dj] ${DateTime.now().toString()} calcActiveUserMsg begin");

    final TimeBeginEnd last7DaysBeginEnd = beginEndTime(DateTime.now(), 6, 0);
    final TimeBeginEnd last30DaysBeginEnd = beginEndTime(DateTime.now(), 29, 0);
    const int topCnt = 50; //改成个比较大的数, 改回top50

    // ------------------------ 近7日消息数升序 --------------------------------

    // print("[dj] ${DateTime.now().toString()} calcActiveUserMsg 近7日消息数升序 begin");

    // 近7日消息数升序
    final day7AscSpeak =
        await Db.db.select("select user_id, count(*) as total from Chat where  "
            "guild_id = $guildId "
            "and time >= ${last7DaysBeginEnd.begin} "
            "and time <= ${last7DaysBeginEnd.end} "
            "group by user_id order by total asc limit $topCnt");

    // 优先使用未发言的用户id, 如果不够，则把查出来的排序后的数据补上
    final day7AscUsers = await Future.wait(day7AscSpeak.toList().map((e) async {
      return e['user_id'];
    }));
    final dtSet1 = _userIds.toSet().difference(day7AscUsers.toSet());
    List<String> l11 = <String>[];
    if (dtSet1.length > topCnt) {
      l11 = dtSet1.toList().sublist(0, topCnt);
    } else {
      l11 = dtSet1.toList();
    }

    List<Map<String, dynamic>> l12 = [];
    for (final uid in l11) {
      l12.add({'user_id': uid, 'total': 0});
    }
    l12.addAll(day7AscSpeak.toList());
    if (l12.length > topCnt) {
      l12 = l12.sublist(0, topCnt);
    }
    // print("[dj] ${DateTime.now().toString()} calcActiveUserMsg 近7日消息数升序 end");

    // print("[dj] ${DateTime.now().toString()} calcActiveUserMsg 近7日消息数升序后的近30日 begin");
    // 近7日消息数升序后，逐个查出近30天的消息数
    final day7Asc = await Future.wait(l12.map((e) async {
      final String uId = e['user_id'];
      final day7AscDay30 =
          await Db.db.select("select count(*) as total from Chat where  "
              "guild_id = $guildId "
              "and time >= ${last30DaysBeginEnd.begin} "
              "and time <= ${last30DaysBeginEnd.end} "
              "and user_id = ${e['user_id']} ");
      final Map p = {
        "userId": uId,
        "avatar": Db.userInfoBox.get(uId)?.avatar ?? "",
        "nickname": Db.userInfoBox.get(uId)?.nickname ?? "",
        "column1": e['total'],
        "column2": day7AscDay30[0]['total']
      };
      return p;
    }));
    // print("[dj] ${DateTime.now().toString()} calcActiveUserMsg 近7日消息数升序后的近30日 end");

    // ------------------------ 近7日消息数降序 --------------------------------
    // print("[dj] ${DateTime.now().toString()} calcActiveUserMsg 近7日消息数降序 begin");
    // 近7日消息数降序
    final day7DescSpeak =
        await Db.db.select("select user_id, count(*) as total from Chat where  "
            "guild_id = $guildId "
            "and time >= ${last7DaysBeginEnd.begin} "
            "and time <= ${last7DaysBeginEnd.end} "
            "group by user_id order by total desc limit $topCnt");

    // 优先使用有消息的用户id, 如果不够，则把未发言的用户补上
    final day7DescUsers =
        await Future.wait(day7DescSpeak.toList().map((e) async {
      return e['user_id'];
    }));
    final List<Map<String, dynamic>> l22 = [];
    l22.addAll(day7DescSpeak.toList().map((e) {
      return {"user_id": e["user_id"], "total": e["total"]};
    }).toList());
    if (l22.length > topCnt) {
      l22.sublist(0, topCnt);
    } else {
      final dtSet2 = _userIds.toSet().difference(day7DescUsers.toSet());
      for (final uid in dtSet2) {
        l22.add({'user_id': uid, 'total': 0});
        if (l22.length >= topCnt) {
          break;
        }
      }
    }
    // print("[dj] ${DateTime.now().toString()} calcActiveUserMsg 近7日消息数降序 end");

    // print("[dj] ${DateTime.now().toString()} calcActiveUserMsg 近7日消息数降序近30天 begin");
    // 近7日消息数降序后，逐个查出近30天的消息数
    final day7Desc = await Future.wait(l22.map((e) async {
      final String uId = e['user_id'];
      final day7DescDay30 =
          await Db.db.select("select count(*) as total from Chat where  "
              "guild_id = $guildId "
              "and time >= ${last30DaysBeginEnd.begin} "
              "and time <= ${last30DaysBeginEnd.end} "
              "and user_id = ${e['user_id']} ");
      final Map p = {
        "userId": uId,
        "avatar": Db.userInfoBox.get(uId)?.avatar ?? "",
        "nickname": Db.userInfoBox.get(uId)?.nickname ?? "",
        "column1": e['total'],
        "column2": day7DescDay30[0]['total']
      };
      return p;
    }));

    // print("[dj] ${DateTime.now().toString()} calcActiveUserMsg 近7日消息数降序近30天 end");

    // ------------------------ 近30日消息数升序 ----------------------------------
    // 近30日消息数升序
    // print("[dj] ${DateTime.now().toString()} calcActiveUserMsg 近30日消息数升序 begin");
    final day30AscSpeak =
        await Db.db.select("select user_id, count(*) as total from Chat where  "
            "guild_id = $guildId "
            "and time >= ${last30DaysBeginEnd.begin} "
            "and time <= ${last30DaysBeginEnd.end} "
            "group by user_id order by total asc limit $topCnt");

    // 优先使用未发言的用户id, 如果不够，则把查出来的排序后的数据补上
    final day30AscUsers =
        await Future.wait(day30AscSpeak.toList().map((e) async {
      return e['user_id'];
    }));
    final dtSet3 = _userIds.toSet().difference(day30AscUsers.toSet());
    List<String> l31 = <String>[];
    if (dtSet3.length > topCnt) {
      l31 = dtSet3.toList().sublist(0, topCnt);
    } else {
      l31 = dtSet3.toList();
    }

    List<Map<String, dynamic>> l32 = [];
    for (final uid in l31) {
      l32.add({'user_id': uid, 'total': 0});
    }
    l32.addAll(day30AscSpeak.toList());
    if (l32.length > topCnt) {
      l32 = l32.sublist(0, topCnt);
    }
    // print("[dj] ${DateTime.now().toString()} calcActiveUserMsg 近30日消息数升序 end");

    // 近30日消息数升序后，逐个查出近7天的消息数
    // print("[dj] ${DateTime.now().toString()} calcActiveUserMsg 近30日消息数升序近7天 begin");
    final day30Asc = await Future.wait(l32.map((e) async {
      final String uId = e['user_id'];
      final day30AscDay7 =
          await Db.db.select("select count(*) as total from Chat where  "
              "guild_id = $guildId "
              "and time >= ${last7DaysBeginEnd.begin} "
              "and time <= ${last7DaysBeginEnd.end} "
              "and user_id = ${e['user_id']}");
      final Map p = {
        "userId": uId,
        "avatar": Db.userInfoBox.get(uId)?.avatar ?? "",
        "nickname": Db.userInfoBox.get(uId)?.nickname ?? "",
        "column1": day30AscDay7[0]['total'],
        "column2": e['total']
      };
      return p;
    }));

    // print("[dj] ${DateTime.now().toString()} calcActiveUserMsg 近30日消息数升序近7天 end");

    // ------------------------ 近30日消息数降序 --------------------------------

    // 近30日消息数降序
    // print("[dj] ${DateTime.now().toString()} calcActiveUserMsg 近30日消息数降序 begin");
    final day30DescParty =
        await Db.db.select("select user_id, count(*) as total from Chat where  "
            "guild_id = $guildId "
            "and time >= ${last30DaysBeginEnd.begin} "
            "and time <= ${last30DaysBeginEnd.end} "
            "group by user_id order by total desc limit $topCnt");

    // 优先使用有消息的用户id, 如果不够，则把未发言的用户补上
    final day30DescUsers =
        await Future.wait(day30DescParty.toList().map((e) async {
      return e['user_id'];
    }));
    final List<Map<String, dynamic>> l42 = [];
    l42.addAll(day30DescParty.toList());
    if (l42.length > topCnt) {
      l42.sublist(0, topCnt);
    } else {
      final dtSet4 = _userIds.toSet().difference(day30DescUsers.toSet());
      for (final e in dtSet4) {
        l42.add({'user_id': e, 'total': 0});
        if (l42.length >= topCnt) {
          break;
        }
      }
    }
    // print("[dj] ${DateTime.now().toString()} calcActiveUserMsg 近30日消息数降序 end");

    // 近30日消息数降序后，逐个查出近7天的消息数
    // print("[dj] ${DateTime.now().toString()} calcActiveUserMsg 近30日消息数降序近7天 begin");
    final day30Desc = await Future.wait(l42.map((e) async {
      final String uId = e['user_id'].toString();
      final day30DescDay7 =
          await Db.db.select("select count(*) as total from Chat where  "
              "guild_id = $guildId "
              "and time >= ${last7DaysBeginEnd.begin} "
              "and time <= ${last7DaysBeginEnd.end} "
              "and user_id = ${e['user_id']}");
      final uInfo = Db.userInfoBox.get(uId);
      final Map p = {
        "userId": uId,
        "avatar": (uInfo != null) ? uInfo.avatar : "",
        "nickname": (uInfo != null) ? uInfo.nickname : "",
        "column1": day30DescDay7[0]['total'],
        "column2": e['total']
      };
      return p;
    }));

    // print("[dj] ${DateTime.now().toString()} calcActiveUserMsg 近30日消息数降序近7天 end");

    activeUserMsgData["day7Asc"] = day7Asc;
    activeUserMsgData["day7Desc"] = day7Desc;
    activeUserMsgData["day30Asc"] = day30Asc;
    activeUserMsgData["day30Desc"] = day30Desc;

    // print("[dj] ${DateTime.now().toString()} calcActiveUserMsg end");

    updateActiveData();

    // print("[dj] ${DateTime.now().toString()} calcActiveUserMsg notifyListeners call");
    notifyListeners();
  }

  Future<void> initCalcDB() async {
    // 建表
    await Db.db.execute('''
        CREATE TABLE IF NOT EXISTS GuildCalc (
          date Date PRIMARY KEY, 
          guildId INTEGER,
          totalUserCnt INTEGER,
          activeUserCnt INTEGER, 
          increaseUserCnt INTEGER, 
          totalMsgCnt INTEGER
          )
        ''');
    // 根据上次最后统计日期，统计下最近的数据
    final int lastCalcTime =
        SpService.to.getInt2("${SP.lastGuildCalcTime}|$guildId") ?? 0;

    final DateTime lastDate = DateTime.fromMillisecondsSinceEpoch(lastCalcTime);
    final DateTime today = DateTime.now();
    int cnt = 30;
    // 从昨天开始往前统计
    for (var currDate = TimeUtils.decreaseDay(today);
        TimeUtils.compareDay(currDate, lastDate) > 0 && cnt > 0;
        currDate = TimeUtils.decreaseDay(currDate), cnt--) {
      final TimeBeginEnd currDateBeginEnd = beginEndTime(currDate, 0, 0);
      final data = await calcAnalysisData(currDateBeginEnd);
      await addToGuildCalc(guildId, currDate, data["totalUserCnt"],
          data["timeUserCnt"], data["dayIncreaseCnt"], data["dayMsgCnt"]);
    }

    await SpService.to.rawSp.setInt(
        "${SP.lastGuildCalcTime}|$guildId", today.millisecondsSinceEpoch);
  }

  Future<void> addToGuildCalc(String guildId, DateTime date, int totalUserCnt,
      int activeUserCnt, int increaseUserCnt, int totalMsgCnt) async {
    final String dateStr = formatDate(date, [yyyy, '-', mm, '-', dd]);
    final String sqlStr =
        "insert into GuildCalc(date,guildId,totalUserCnt,activeUserCnt,increaseUserCnt,totalMsgCnt) "
        "VALUES(Date('$dateStr'),$guildId,$totalUserCnt,$activeUserCnt,$increaseUserCnt,$totalMsgCnt) ";
    print(sqlStr);
    //      "ON DUPLICATE KEY UPDATE guildId=$guildId,totalUserCnt=$totalUserCnt,activeUserCnt=$activeUserCnt,increaseUserCnt=$increaseUserCnt,totalMsgCnt=$totalMsgCnt";
    await Db.db.execute(sqlStr);
  }

  // 实时统计
  Future<List<GuildOptDataTrendData>> getGuildCalc30RealTime(
      String guildId) async {
    // print("[dj] ${DateTime.now().toString()} getGuildCalc30RealTime begin");
    final List<GuildOptDataTrendData> data = [];
    final DateTime today = DateTime.now();
    int cnt = 30;
    // 从昨天开始往前统计
    for (var currDate = TimeUtils.decreaseDay(today);
        cnt > 0;
        currDate = TimeUtils.decreaseDay(currDate), cnt--) {
      final TimeBeginEnd currDateBeginEnd = beginEndTime(currDate, 0, 0);
      final dataRtn = await calcAnalysisData(currDateBeginEnd);
      final String dateStr = formatDate(currDate, [yyyy, '-', mm, '-', dd]);
      final int avgMsgCnt = dataRtn["timeUserCnt"] == 0
          ? 0
          : (dataRtn["dayMsgCnt"] / dataRtn["timeUserCnt"]).round();
      data.add(GuildOptDataTrendData(
          dateStr,
          dataRtn["totalUserCnt"],
          dataRtn["timeUserCnt"],
          dataRtn["dayIncreaseCnt"],
          dataRtn["dayMsgCnt"],
          avgMsgCnt));
    }
    data.sort((a, b) {
      return TimeUtils.compareDay(
          DateTime.parse(a.dateStr), DateTime.parse(b.dateStr));
    });

    // dj test
    // final guildCalcResult = await Db.db.rawQuery(
    //     "select * from Chat where guild_id=$guildId order by time desc"
    // );
    // final l = guildCalcResult.toList().map((e) {
    //   final String s = " ${e["time"]} ${e["user_id"]} ${e["content"]}";
    //   print(s);
    //   return s;
    // }).toList();
    // // print(l);

    // print("[dj] ${DateTime.now().toString()} getGuildCalc30RealTime end");

    return data;
  }

  Future<List<GuildOptDataTrendData>> getGuildCalc30(String guildId) async {
    // 查出前30天的统计数据
    final TimeBeginEnd last30DaysBeginEnd = beginEndTime(DateTime.now(), 29, 0);

    final DateTime dateBegin = DateTime.fromMillisecondsSinceEpoch(
        int.parse(last30DaysBeginEnd.begin));
    final String dateBeginStr = formatDate(dateBegin, [yyyy, '-', mm, '-', dd]);
    final DateTime endBegin =
        DateTime.fromMillisecondsSinceEpoch(int.parse(last30DaysBeginEnd.end));
    final String endBeginStr = formatDate(endBegin, [yyyy, '-', mm, '-', dd]);

    final List guildCalcResult = await Db.db.select(
        "select * from GuildCalc where guildId=$guildId and date>=Date('$dateBeginStr') and date<=Date('$endBeginStr')");
    print(guildCalcResult);

    return guildCalcResult.toList().map((e) {
      final int avgMsgCnt = e["totalUserCnt"] == 0
          ? 0
          : (e["totalMsgCnt"] / e["totalUserCnt"]).round();
      return GuildOptDataTrendData(
          e["date"].toString(),
          e["totalUserCnt"],
          e["activeUserCnt"],
          e["increaseUserCnt"],
          e["totalMsgCnt"],
          avgMsgCnt);
    }).toList();
  }
}

class GuildCalcDataView extends StatelessWidget {
  final String title;
  final String desc;

  const GuildCalcDataView({Key key, this.title, this.desc}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 24,
            color: Color(0xFF333333),
            fontWeight: FontWeight.w500,
            height: 1,
          ),
        ),
        const SizedBox(height: 12),
        Text(desc,
            style: const TextStyle(
                fontSize: 12, color: Color(0xFF8F959E), height: 1)),
      ],
    );
  }
}

class GuildCalcView extends StatelessWidget {
  final String title;
  final Widget child;
  final Color color;

  const GuildCalcView({this.title, this.child, this.color});

  @override
  Widget build(BuildContext context) {
    final ThemeData _theme = Theme.of(context);
    return Container(
      color: color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 53.5,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.only(left: 16),
            child: Text(title,
                textAlign: TextAlign.left,
                style: _theme.textTheme.headline4.copyWith(fontSize: 16)),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 0, 0),
            child: divider,
          ),
          Container(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ],
      ),
    );
  }
}

class GuildOptDataPage extends StatefulWidget {
  final String guildId;

  const GuildOptDataPage(this.guildId);

  @override
  _GuildOptDataPageState createState() => _GuildOptDataPageState();
}

class _GuildOptDataPageState extends State<GuildOptDataPage> {
  GuildOptDataViewModel viewModel;

  ThemeData _theme;

  List<CalcUser> topUserdata() {
    if (viewModel.activeData != null) {
      return viewModel.activeData.map((e) {
        return CalcUser(e["nickname"], e["column1"], e["column2"],
            avatar: e["avatar"], userId: e["userId"]);
      }).toList();
    } else {
      return [];
    }
  }

  void onUserSelectedChanged(int _index) {
    setState(() {
      viewModel.userSelected = _index;
    });
  }

  void onDaySelectedChanged(int _index) {
    setState(() {
      viewModel.daySelected = _index;
    });
  }

  @override
  void initState() {
    // 获取当前服务器ID
    viewModel = GuildOptDataViewModel(widget.guildId);
    super.initState();
  }

  Iterable<Widget> get _userInputSelects sync* {
    for (int i = 0; i < viewModel.userChoice.length; i++) {
      yield InputSelect(
        index: i,
        choice: viewModel.userChoice[i],
        parentChoose: viewModel.userSelected,
        onChoose: onUserSelectedChanged,
        widget: null,
      );
    }
  }

  Iterable<Widget> get _dayInputSelects sync* {
    for (int i = 0; i < viewModel.daysChoice.length; i++) {
      yield InputSelect(
        index: i,
        choice: viewModel.daysChoice[i],
        parentChoose: viewModel.daySelected,
        onChoose: onDaySelectedChanged,
        widget: null,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    _theme = Theme.of(context);
    return ChangeNotifierProvider.value(
        value: viewModel,
        builder: (context, snapshot) {
          // print("[dj] ${DateTime.now().toString()} viewModel changed build");
          return Scaffold(
            backgroundColor: _theme.scaffoldBackgroundColor,
            appBar: CustomAppbar(
              title: '服务器数据'.tr,
            ),
            body: Consumer<GuildOptDataViewModel>(
                builder: (context, model, child) {
              return ListView(
                children: [
                  GuildCalcView(
                      title: "用户量".tr,
                      color: Colors.white,
                      child: Row(
                          // crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: GuildCalcDataView(
                                  title: viewModel.generalData.totalUserCnt
                                      .toString(),
                                  desc: "总用户数".tr),
                            ),
                            Expanded(
                              child: GuildCalcDataView(
                                  title: viewModel.generalData.yesterdayUserCnt
                                      .toString(),
                                  desc: "昨日活跃用户数".tr),
                            ),
                            Expanded(
                              child: GuildCalcDataView(
                                  title: viewModel
                                      .generalData.yesterdayIncreasedUserCnt
                                      .toString(),
                                  desc: "昨日新增用户数".tr),
                            ),
                          ])),
                  sizeHeight8,
                  GuildCalcView(
                      title: "消息量".tr,
                      color: Colors.white,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: GuildCalcDataView(
                                title: viewModel
                                    .generalData.yesterdayTotalMsgCnt
                                    .toString(),
                                desc: "昨日总消息数".tr),
                          ),
                          Expanded(
                            child: GuildCalcDataView(
                                title: () {
                                  if (viewModel.generalData.yesterdayUserCnt >
                                      0) {
                                    final avg = viewModel
                                            .generalData.yesterdayTotalMsgCnt /
                                        viewModel.generalData.yesterdayUserCnt;
                                    return avg.toStringAsFixed(2);
                                  } else {
                                    return "0";
                                  }
                                }(),
                                desc: "昨日人均消息数".tr),
                          ),

                          // Expanded(
                          //   flex: 1,
                          //   child: SizedBox(),
                          // ),
                        ],
                      )),
                  sizeHeight8,
                  GuildCalcView(
                    title: "数据趋势".tr,
                    color: Colors.white,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        GridView.count(
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          crossAxisSpacing: 1,
                          mainAxisSpacing: 1,
                          // padding: EdgeInsets.all(10.0),
                          crossAxisCount: 3,
                          //子Widget宽高比例
                          childAspectRatio: 113.5 / 36,
                          //子Widget列表
                          children: _userInputSelects.toList(),
                        ),
                        sizeHeight8,
                        GridView.count(
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          crossAxisSpacing: 1,
                          mainAxisSpacing: 1,
                          // padding: EdgeInsets.all(10.0),
                          crossAxisCount: 3,
                          //子Widget宽高比例
                          childAspectRatio: 113.5 / 36,
                          //子Widget列表
                          children: _dayInputSelects.toList(),
                        ),
                        sizeHeight16,
                        SizedBox(height: 250, child: LineChart(mainData())),
                      ],
                    ),
                  ),
                  sizeHeight8,
                  GuildCalcView(
                    title: "服务器成员发言消息量".tr,
                    color: Colors.white,
                    child: Selector<GuildOptDataViewModel, List>(
                        selector: (context, model) => model.activeData,
                        builder: (context, count, child) {
                          return DataTable(
                            headingRowColor:
                                MaterialStateProperty.resolveWith<Color>(
                                    (states) {
                              return const Color(
                                  0xFFF2F3F5); // Use the default value.
                              // if (states.contains(MaterialState.hovered))
                              //   return Theme.of(context)
                              //       .colorScheme
                              //       .primary
                              //       .withOpacity(0.08);
                              // return null; // Use the default value.
                            }),
                            dividerThickness: 0.5,
                            columnSpacing: 0,
                            horizontalMargin: 0,
                            headingRowHeight: 36,
                            sortColumnIndex: model.activitySortIndex,
                            sortAscending: model.activitySortAscending,
                            columns: [
                              DataColumn(
                                  label: Row(children: [
                                const SizedBox(width: 12),
                                Text('成员'.tr,
                                    style: const TextStyle(
                                        color: Color(0xFF17181A), fontSize: 12))
                              ])),
                              DataColumn(
                                  label: Text('近7日'.tr,
                                      style: const TextStyle(fontSize: 12)),
                                  onSort: (index, sortAscending) {
                                    setState(() {
                                      viewModel.activitySortIndex = 1;
                                      viewModel.activitySortAscending =
                                          sortAscending;
                                    });
                                  }),
                              DataColumn(
                                  label: Text('近30日'.tr,
                                      style: const TextStyle(fontSize: 12)),
                                  onSort: (index, sortAscending) {
                                    setState(() {
                                      viewModel.activitySortIndex = 2;
                                      viewModel.activitySortAscending =
                                          sortAscending;
                                    });
                                  }),
                            ],
                            rows: List.generate(
                                    topUserdata().length,
                                    (index) => MyDataTableSource(topUserdata())
                                        .getRow(index))
                                .where((element) => element != null)
                                .toList(),
                          );
                        }),
                  ),
                ],
              );
            }),
          );
        });
  }

  LineChartData mainData() {
    // List choosedOptData = [
    //   ["2020-10-11",30],
    //   ["2020-10-12",130],
    //   ["2020-10-13",230],
    //   ["2020-10-14",320],
    //   ["2020-10-15",330],
    //   ["2020-10-16",30],
    //   ["2020-10-17",304],
    // ];
    List<List> choosedOptData = viewModel.trendData.map((e) {
      return [
        e.dateStr,
        e.totalUserCnt,
        e.activityUserCnt,
        e.increaseUserCnt,
        e.totalMsgCnt,
        e.avgMsgCnt
      ];
    }).toList();
    if (choosedOptData.isEmpty) {
      choosedOptData = [
        ["2020-10-16", 0, 0, 0, 0, 0]
      ];
    }
    int start = 0;
    if (viewModel.daySelected == 0) {
      start = choosedOptData.length - 7;
    } else if (viewModel.daySelected == 1) {
      start = choosedOptData.length - 30;
    }
    if (start < 0) start = 0;
    choosedOptData = choosedOptData.sublist(start);

    final List<Color> gradientColors = [
      primaryColor,
      primaryColor,
    ];

    return LineChartData(
      lineTouchData: LineTouchData(touchTooltipData:
          LineTouchTooltipData(getTooltipItems: (touchedSpots) {
        return touchedSpots
            .asMap()
            .map((index, e) => MapEntry(
                0,
                LineTooltipItem(
                    "${touchedSpots[index].y.toInt()}",
                    TextStyle(
                        color: primaryColor, fontWeight: FontWeight.w500))))
            .values
            .toList();
      })),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: const Color(0xFF8F959E),
            strokeWidth: 0.5,
            dashArray: [2, 2],
          );
        },
        // getDrawingVerticalLine: (value) {
        //   return FlLine(
        //     color: const Color(0xff37434d),
        //     strokeWidth: 0.5,
        //   );
        // },
      ),
      titlesData: FlTitlesData(
        show: true,
        bottomTitles: SideTitles(
          showTitles: true,
          reservedSize: 30,
          getTextStyles: (_, n) =>
              const TextStyle(color: Color(0xFF333333), fontSize: 9),
          getTitles: (value) {
            if (value == 0 ||
                value == choosedOptData.length - 1 ||
                value == (choosedOptData.length / 2).round() - 1) {
              final String dateStr = choosedOptData[value.round()][0];
              final DateTime d = DateTime.parse(dateStr);
              return "${d.month}-${d.day}";
            } else {
              return "";
            }
          },
          margin: 8,
        ),
        leftTitles: SideTitles(
          showTitles: true,
          getTextStyles: (_, n) => const TextStyle(
            color: Color(0xFF333333),
            fontSize: 9,
          ),
          getTitles: (value) {
            final int maxV = choosedOptData
                .map((e) => e[viewModel.userSelected + 2])
                .reduce((value, element) => max(value as int, element as int));
            if (value == 0 || value == maxV) {
              return value.round().toString();
            } else {
              return "";
            }
          },
          reservedSize: 28,
          margin: 12,
        ),
      ),
      borderData: FlBorderData(
          show: true,
          border: const Border(
              bottom: BorderSide(color: Color(0xFFE1E1E6), width: 0.5))),
      minX: 0,
      maxX: (choosedOptData.length - 1).toDouble(),
      minY: (choosedOptData
                  .map((e) => e[viewModel.userSelected + 2])
                  .reduce((value, element) => min(value as int, element as int))
              as int)
          .toDouble(),
      maxY: (choosedOptData
                  .map((e) => e[viewModel.userSelected + 2])
                  .reduce((value, element) => max(value as int, element as int))
              as int)
          .toDouble(),
      lineBarsData: [
        LineChartBarData(
          spots: () {
            final List<FlSpot> v = choosedOptData
                .map((e) {
                  final int idx = choosedOptData.indexOf(e);
                  final int d = choosedOptData[idx][viewModel.userSelected + 2];
                  return FlSpot(idx.toDouble(), d.toDouble());
                })
                .toList()
                .cast<FlSpot>();
            return v;
          }(),
          isCurved: false,
          colors: gradientColors,
          barWidth: 1.5,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (_, __, ___, ____) {
              return DotCirclePainter(
                  color: primaryColor,
                  radius: 2.5,
                  strokeColor: Colors.white,
                  strokeWidth: 0);
            },
          ),
          belowBarData: BarAreaData(
            show: true,
            gradientFrom: const Offset(0.5, 0),
            gradientTo: const Offset(0.5, 1),
            gradientColorStops: [0, 0.5, 1],
            colors: [
              const Color(0xFF006AFF).withOpacity(0.04),
              const Color(0xFF026BFF).withOpacity(0.04),
              Colors.white.withOpacity(0),
            ],
          ),
        ),
      ],
    );
  }
}

class CalcUser {
  CalcUser(this.name, this.days7Msg, this.days30Msg,
      {this.avatar = "", @required this.userId});

  final String name;
  final int days7Msg;
  final int days30Msg;
  final String avatar;
  final String userId;

  String getNickName() {
    final userInfo = Db.userInfoBox.get(userId);
    String nickName = userInfo?.showName();
    if (nickName.noValue) {
      nickName = name;
    }
    return nickName;
  }
}

class MyDataTableSource extends DataTableSource {
  MyDataTableSource(this.data);

  final List<CalcUser> data;

  @override
  DataRow getRow(int index) {
    if (index >= data.length) {
      return null;
    }
    return DataRow.byIndex(
      index: index,
      cells: [
        DataCell(Builder(builder: (context) {
          return GestureDetector(
            onTap: () {
              return showUserInfoPopUp(
                context,
                userId: data[index].userId,
                guildId: ChatTargetsModel.instance.selectedChatTarget.id,
              );
            },
            child: Row(children: [
              const SizedBox(width: 5),
              Avatar(url: data[index].avatar),
              const SizedBox(width: 5),
              SizedBox(
                width: 100,
                child: Text(
                  data[index].getNickName(),
                  style: const TextStyle(fontSize: 12),
                  softWrap: false,
                  overflow: TextOverflow.ellipsis,
                ),
              )
            ]),
          );
        })),
        DataCell(Text(
          '${data[index].days7Msg}',
          style: const TextStyle(fontSize: 12),
        )),
        DataCell(Text(
          '${data[index].days30Msg}',
          style: const TextStyle(fontSize: 12),
        )),
      ],
    );
  }

  @override
  int get selectedRowCount {
    return 0;
  }

  @override
  bool get isRowCountApproximate {
    return false;
  }

  @override
  int get rowCount {
    return data.length;
  }
}

/// This class is an implementation of a [FlDotPainter] that draws
/// a circled shape
class DotCirclePainter extends FlDotPainter {
  /// The fill color to use for the circle
  Color color;

  /// Customizes the radius of the circle
  double radius;

  /// The stroke color to use for the circle
  Color strokeColor;

  /// The stroke width to use for the circle
  double strokeWidth;

  /// The color of the circle is determined determined by [color],
  /// [radius] determines the radius of the circle.
  /// You can have a stroke line around the circle,
  /// by setting the thickness with [strokeWidth],
  /// and you can change the color of of the stroke with [strokeColor].
  DotCirclePainter({
    this.color,
    this.radius,
    this.strokeColor,
    this.strokeWidth,
  });

  /// Implementation of the parent class to draw the circle
  @override
  void draw(Canvas canvas, FlSpot spot, Offset offsetInCanvas) {
    if (strokeWidth != null) {
      canvas.drawCircle(
          offsetInCanvas,
          radius + (strokeWidth / 2),
          Paint()
            ..color = strokeColor ?? color
            ..strokeWidth = strokeWidth
            ..style = PaintingStyle.stroke);
    }
    canvas.drawCircle(
        offsetInCanvas,
        radius,
        Paint()
          ..color = color
          ..style = PaintingStyle.fill);
  }

  /// Implementation of the parent class to get the size of the circle
  @override
  Size getSize(FlSpot spot) {
    return Size(radius, radius);
  }

  /// Used for equality check, see [EquatableMixin].
  @override
  List<Object> get props => [
        color,
        radius,
        strokeColor,
        strokeWidth,
      ];
}
