import 'package:im/common/permission/permission.dart';
import 'package:im/common/permission/permission_model.dart';
import 'package:im/common/permission/permission_utils.dart';
import 'package:im/core/config.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/pages/home/model/input_model.dart';
import 'package:im/utils/string_filter_utils.dart';
import '../chat_index_model.dart';
import 'base_input_prompt_model.dart';

class ChannelSelectorModel extends InputPromptModel<ChatChannel> {
  ChannelSelectorModel({InputModel inputModel}) : super(inputModel, "#");

  @override
  Future<List<ChatChannel>> getCompleteList() async {
    final GuildPermission gp = PermissionModel.getPermission(
        ChatTargetsModel.instance.selectedChatTarget.id);
    final origChannels =
        (ChatTargetsModel.instance.selectedChatTarget as GuildTarget).channels;
    //去掉没有权限的分类 [dj private channel]
    return origChannels
        .where((element) => PermissionUtils.isChannelVisible(gp, element.id))
        .toList();
  }

  @override
  Future<void> onMatch(String match) async {
    _filterChannels(match);
    visible = list.isNotEmpty &&
        list
            .where((element) => element.type != ChatChannelType.guildCategory)
            .isNotEmpty;
  }

  void _filterChannels(String str) {
    if (str.isEmpty) {
      list = completeList;
      return;
    }

    list = [];
    for (final c in completeList) {
      if (c.type == ChatChannelType.guildCategory) {
        list.add(c);
        continue;
      }

      final match = StringFilterUtils.checkMatch(c.name, str);
      if (match) {
        list.add(c);
      }
    }
  }

  void insertChannelBlock(ChatChannel channel) {
    final c = inputModel.inputController;
    if (!Config.useNativeInput)
      c.replaceRange(
        '',
        start: matchInputContentResult.matchIndex,
        end: matchInputContentResult.caretIndex,
      );
    c.insertChannelName(channel.name,
        data: "\${#${channel.id}}",
        backSpaceLength: matchInputContentResult.caretIndex -
            matchInputContentResult.matchIndex);
  }
}
