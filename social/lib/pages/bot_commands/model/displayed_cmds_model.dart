import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/api/entity/bot_info.dart';
import 'package:im/pages/bot_market/bot_utils.dart';
import 'package:im/pages/bot_market/model/robot_model.dart';
import 'package:im/utils/utils.dart';
import 'package:pedantic/pedantic.dart';
import 'package:sliding_sheet/sliding_sheet.dart';
import '../../home/model/chat_target_model.dart';

/// 此Model用于控制机器人指令展示列表，供用户选择触发想要的指令，指令来源可能来自以下场景：
/// 1. 频道聊天窗口中，点击展示指令按钮，显示当前频道的快捷指令
/// 2. 频道聊天窗口中，@机器人，显示该机器人的指令
/// 3. 机器人私聊窗口，点击展示指令按钮，显示该机器人的所有指令
///
/// 展示的指令会根据当前场景与指令级别进行过滤，比如指令级别为私聊时，只有私聊窗口能看到，
/// 详细的过滤规则参考: _isCmdVisible方法
class DisplayedCmdsController extends GetxController
    implements RobotCmdInputListener {
  final SheetController controller;

  final String channelId;

  Future<List<BotCommandItem>> _future;

  /// 缓存获取指令的请求，防止连续build展示指令按钮，导致重复请求
  Future<List<BotCommandItem>> get _btnCtlCmdsFuture => _future;

  set _btnCtlCmdsFuture(Future<List<BotCommandItem>> future) {
    _future = future?.then((cmds) {
      // 成功获取到指令，更新由展示指令按钮控制的指令，决定按钮的可见性
      _btnCtlCmds = cmds;
      update();
      return cmds;
    })?.catchError((e) {
      // 当请求失败时，清空缓存，使得下次build展示指令按钮时重新去请求
      _btnCtlCmdsFuture = null;
      // 触发隐藏指令展示按钮
      _btnCtlCmds = null;
    });
  }

  /// 点击展示指令按钮触发展示的指令，可能来自私聊机器人，也可能来自频道快捷指令
  List<BotCommandItem> _btnCtlCmds;

  List<BotCommandItem> get btnCtlCmds => _btnCtlCmds;

  /// 展示的指令列表，可能来自点击展示指令按钮，也可能来自@机器人
  List<BotCommandItem> _displayedCmds = [];

  List<BotCommandItem> get displayedCmds => _displayedCmds;

  /// 是否按钮控制展示的指令不为空
  bool get hasCmds => _btnCtlCmds != null && _btnCtlCmds.isNotEmpty;

  /// 指令列表是否处于展开状态
  bool get isShow => _displayedCmds != null && _displayedCmds.isNotEmpty;

  /// 是否正在输入，如果正在输入则按钮不可见
  final hasInput = ValueNotifier<bool>(false);

  DisplayedCmdsController(this.controller, this.channelId);

  @override
  void onInit() {
    super.onInit();
  }

  /// 当前聊天频道更新时，刷新频道快捷指令
  void resetCommands() {
    // 是否为当前频道的更新
    final currentChannel = GlobalState.selectedChannel.value;
    final isCurrentChange = currentChannel?.id == channelId;
    if (isCurrentChange && _btnCtlCmdsFuture != null) {
      _btnCtlCmdsFuture = null;
      getChannelCmds(channelId, currentChannel.guildId);
    }
  }

  /// 获取当前频道的快捷指令
  Future<List<BotCommandItem>> getChannelCmds(
      String channelId, String guildId) {
    if (_btnCtlCmdsFuture != null) {
      // 如果存在指令请求，则复用缓存
      return _btnCtlCmdsFuture;
    }

    // 发起网络请求，获取频道快捷指令
    return _btnCtlCmdsFuture = BotUtils.getChannelCmds(guildId, channelId);
  }

  /// 获取指定机器人的指令
  Future<List<BotCommandItem>> getRobotCmds(
    String robotId,
    bool isPrivateChat,
  ) async {
    if (isPrivateChat) {
      // 私聊机器人，指令的展示交给指令展示按钮
      if (_btnCtlCmdsFuture != null) {
        return _btnCtlCmdsFuture;
      }

      return _btnCtlCmdsFuture = getVisibleRobotCmds(robotId, isPrivateChat);
    }

    // 频道中@机器人，直接更新显示指令列表
    final cmds = await getVisibleRobotCmds(robotId, isPrivateChat);
    _displayedCmds = cmds;
    update();
    unawaited(delay(controller.expand, 200));
    return cmds;
  }

  Future<List<BotCommandItem>> getVisibleRobotCmds(
    String robotId,
    bool isPrivateChat,
  ) async {
    final robot = await RobotModel.instance.getRobot(robotId);

    return robot.commands
        ?.where((cmd) => BotUtils.isCmdVisible(cmd, isPrivateChat))
        ?.toList();
  }

  /// 点击展开指令按钮，显示指令
  void showCmds() {
    if (_btnCtlCmds == null || _btnCtlCmds.isEmpty) {
      // 指令列表为空
      return;
    }

    // 更新展示指令列表
    _displayedCmds = _btnCtlCmds;

    update();

    delay(controller.expand, 100);
  }

  /// 点击展开指令按钮，隐藏指令
  void hideCmds() {
    // 如果展示指令为null，则认为指令列表已隐藏
    if (_displayedCmds == null) return;

    _displayedCmds = null;
    update();
  }

  @override
  void isInputting(bool isInput) {
    hasInput.value = isInput;
    if (isInput) {
      // 当输入框正在输入，则隐藏命令列表
      hideCmds();
    }
  }

  @override
  void onAtRobot(String robotId) {
    if (robotId != null) {
      // 输入框@机器人，弹出该机器人的命令列表
      getRobotCmds(robotId, false);
    } else {
      // 输入框取消@机器人，隐藏命令列表
      hideCmds();
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}

/// 监听输入框的输入
abstract class RobotCmdInputListener {
  /// 是否正在输入
  void isInputting(bool isInput);

  /// 是否@机器人
  void onAtRobot(String robotId);
}
