import 'package:im/api/bot_api.dart';
import 'package:im/api/entity/bot_info.dart';
import 'package:im/core/http_middleware/http.dart';
import 'package:im/pages/home/model/text_channel_event.dart';
import 'package:im/ws/ws.dart';

import 'bot_market_controller.dart';

/// 机器人数据缓存
class RobotModel {
  static final instance = RobotModel();

  RobotModel() {
    // 监听用户被移除或者用户加入事件
    Ws.instance
        .on<WsMessage>()
        .where((e) => e.data is UserJoinEvent || e.data is UserRemoveEvent)
        .listen((e) async {
      if (e.data is UserJoinEvent) {
        final guildId = (e.data as UserJoinEvent).guildId;
        final botId = (e.data as UserJoinEvent).userId;
        // TODO _addedRobotsFutureMap的value目前包含了机器人和普通用户的id，后续需删除
        await addGuildRobot(guildId, botId);
      }
      if (e.data is UserRemoveEvent) {
        final guildId = (e.data as UserRemoveEvent).guildId;
        final botId = (e.data as UserRemoveEvent).userId;
        await removeGuildRobot(guildId, botId);
      }
    });
  }

  /// 保存每个服务台已添加的机器人的future
  final Map<String, Future<List<String>>> _addedRobotsFutureMap = {};

  /// 缓存的机器人列表
  Map<String, CachedValue<BotInfo>> _robots;

  /// 获取所有的机器人
  // Future<List<BotInfo>> fetchRobots() async {
  //   // 缓存不可用，从网络获取数据，并更新缓存
  //   return BotApi.getBots(guildId: gui).then((robots) {
  //     _robots = {};
  //     robots.forEach((robot) => _robots[robot.botId] = CachedValue(robot));
  //     return robots;
  //   });
  // }

  Future<List<String>> getAddedRobotsFuture(String guildId) {
    if (_addedRobotsFutureMap.containsKey(guildId)) {
      return _addedRobotsFutureMap[guildId];
    }
    _addedRobotsFutureMap[guildId] = getAddedRobots()
        .then((value) => value.map((e) => e.userId).toList())
        .catchError((e) {
      _addedRobotsFutureMap.remove(guildId);
      throw e;
    });
    return _addedRobotsFutureMap[guildId];
  }

  Future<void> removeGuildRobot(String guildId, String botId) async {
    if (!_addedRobotsFutureMap.containsKey(guildId)) return;
    return _addedRobotsFutureMap[guildId].then((bots) {
      bots.remove(botId);
    });
  }

  Future<void> addGuildRobot(String guildId, String botId) async {
    if (!_addedRobotsFutureMap.containsKey(guildId)) return;
    return _addedRobotsFutureMap[guildId].then((bots) {
      if (!bots.contains(botId)) bots.add(botId);
    });
  }

  /// 获取机器人信息
  Future<BotInfo> getRobot(String robotId) async {
    _robots ??= {};
    // 获取缓存的机器人信息
    final cachedRobot = _robots[robotId];
    if (cachedRobot != null && cachedRobot.isValid) {
      // 有缓存值并且缓存未超时，使用缓存
      return cachedRobot.value;
    }

    // 没有缓存或缓存失效，从网络拉机器人信息
    BotInfo robot;
    try {
      robot = await BotApi.getBot(robotId);
    } on RequestArgumentError catch (e) {
      if (e.code == 2001) {
        // 机器人被删除
        _robots.remove(robotId);
        throw InvalidRobotError(robotId, error: e);
      }
    }
    if (cachedRobot == null) {
      // 缓存为空，添加缓存
      _robots[robotId] = CachedValue(robot);
    } else {
      // 更新缓存
      cachedRobot.value = robot;
    }

    return robot;
  }

  /// 获取机器人的指令
  Future<List<BotCommandItem>> getCommands(String robotId) async {
    final robot = await getRobot(robotId);
    return robot?.commands;
  }

  /// 获取机器人的某条指令
  /// @param robotId: 机器人id
  /// @param command: 指令名
  Future<BotCommandItem> getCommand(String robotId, String command) async {
    // 获取该机器人所有的指令
    final commands = await getCommands(robotId);
    if (commands == null) return null;

    // 返回查找到的指令，如果没有找到，认为此指令不存在或被删除，返回null
    return commands.firstWhere((c) => c.command == command, orElse: () => null);
  }

  /// 删除指定的机器人缓存
  void refreshRobot(String robotId) {
    _robots?.remove(robotId);
  }

  /// 清空缓存
  void reset() {
    _robots = null;
  }
}

/// 保存缓存的数据，可设置缓存时间
class CachedValue<T> {
  /// 缓存时间
  final Duration expiredIn;

  /// 缓存的数据
  T _value;

  /// 上次更新数据的时间
  DateTime _updateAt = DateTime.now();

  CachedValue(this._value, {this.expiredIn = const Duration(minutes: 5)});

  /// 缓存数据是否过期
  bool get isValid => DateTime.now().difference(_updateAt) <= expiredIn;

  /// 获取缓存数据，如果缓存过期则返回null
  T get value => isValid ? _value : null;

  /// 更新缓存数据
  set value(T v) {
    // 重置缓存数据更新时间
    _updateAt = DateTime.now();
    _value = v;
  }
}

class InvalidRobotError implements Exception {
  dynamic error;
  final String robotId;

  InvalidRobotError(this.robotId, {this.error});

  String get message =>
      "robot $robotId has been deleted. error: ${error?.toString()}";

  @override
  String toString() {
    var msg = "InvalidRobotError: $message";
    if (error is Error) {
      msg += '\n${error.stackTrace}';
    }
    return msg;
  }
}
