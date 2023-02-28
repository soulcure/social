import 'package:im/pages/bot_market/model/channel_cmds_model.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:pedantic/pedantic.dart';

/// 频道快捷指令处理器
// ignore: type_annotate_public_apis
Future<void> botSettingHandler(data) async {
  if (data == null) return;

  final channelId = data["channel_id"];
  final guildId = data["guild_id"];
  final botSetting = data["bot_setting"];
  List<Map<String, String>> commands;
  if (botSetting != null) {
    commands = ChatChannel.parseBotSetting(
        List.from(botSetting).map((e) => Map<String, String>.from(e)).toList());
  } else {
    commands = null;
  }
  final cmdModel = ChannelCmdsModel.instance;
  unawaited(cmdModel.updateLocal(
    channelId: channelId,
    guildId: guildId,
    cmds: commands,
  ));
}
