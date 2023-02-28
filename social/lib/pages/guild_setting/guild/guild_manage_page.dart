import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/api/guild_api.dart';
import 'package:im/global.dart';
import 'package:im/pages/home/model/chat_index_model.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/routes.dart';
import 'package:im/utils/show_action_sheet.dart';
import 'package:im/widgets/app_bar/appbar_button.dart';
import 'package:im/widgets/app_bar/custom_appbar.dart';
import 'package:im/widgets/link_tile.dart';
import 'package:oktoast/oktoast.dart';

class GuildManagePage extends StatefulWidget {
  @override
  _GuildManagePageState createState() => _GuildManagePageState();
}

class _GuildManagePageState extends State<GuildManagePage> {
  ThemeData _theme;

  int systemChannelFlags;
  String systemChannelId;
  bool _loading = false;
  bool _changed = false;
  GuildTarget guild;

  @override
  void initState() {
    resetConfig();
    guild = (ChatTargetsModel.instance.selectedChatTarget as GuildTarget)
      ..addListener(onGuildChange);

    super.initState();
  }

  bool isSelect(int value, int index) {
    return value & (1 << index) == 0;
  }

  int setValueSelect(int value, int index, bool isSelect) {
    if (isSelect) {
      return value & ~(1 << index);
    } else {
      return value | 1 << index;
    }
  }

  void onGuildChange() {
    resetConfig(refresh: true);
  }

  void resetConfig({bool refresh = false}) {
    final guildTarget =
        ChatTargetsModel.instance.selectedChatTarget as GuildTarget;
    systemChannelFlags = guildTarget?.systemChannelFlags ?? 0;
    systemChannelId = guildTarget?.systemChannelId;
    if (refresh && mounted) setState(() {});
  }

  @override
  void dispose() {
    guild.removeListener(onGuildChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _theme = Theme.of(context);
    return Scaffold(
      backgroundColor: _theme.scaffoldBackgroundColor,
      appBar: CustomAppbar(title: '服务器管理'.tr, actions: [
        if (_changed)
          AppbarTextButton(
            text: '确定'.tr,
            enable: _changed,
            loading: _loading,
            onTap: _onConfirm,
          )
      ]),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _buildSubtitle('加入服务器消息'.tr),
          LinkTile(
            context,
            Text(
              '当有人加入此服务器时，发送一条随机欢迎语'.tr,
            ),
            showTrailingIcon: false,
            trailing: Transform.scale(
              scale: 0.9,
              alignment: Alignment.centerRight,
              child: CupertinoSwitch(
                  activeColor: Theme.of(context).primaryColor,
                  value: isSelect(systemChannelFlags, 0),
                  onChanged: (v) {
                    if (_loading) return;
                    systemChannelFlags =
                        setValueSelect(systemChannelFlags, 0, v);
                    _updateChanged();
                  }),
            ),
            onTap: () {
//              Routes.pushMemberManagePage(context, widget.guildId);
            },
          ),
          LinkTile(
            context,
            Text('服务器欢迎语展示的文字频道'.tr),
            trailing: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 110),
              child: Text(
                _getChannelName(systemChannelId),
                overflow: TextOverflow.ellipsis,
                style: _theme.textTheme.bodyText1,
              ),
            ),
            onTap: _showSelectChannels,
          ),
          // if (PermissionUtils.isGuildOwner()) ...[
          //   const SizedBox(height: 20),
          //   SizedBox(
          //       height: 48,
          //       child: FadeBackgroundButton(
          //         onTap: () async {
          //           unawaited(GuildApi.dissolveGuild(Global.user.id, guild.id)
          //               .then((_) => quitGuild(guild)));
          //         },
          //         height: 48,
          //         backgroundColor: Theme.of(context).backgroundColor,
          //         tapDownBackgroundColor:
          //             Theme.of(context).backgroundColor.withOpacity(0.5),
          //         child: const Text(
          //           "解散服务器",
          //           style: TextStyle(color: DefaultTheme.dangerColor),
          //         ),
          //       ))
          // ]
//          divider,
//          TextLinkTile(
//            context,
//            '服务器欢迎语可见范围',
//            onTap: () {
////              Routes.pushMemberManagePage(context, widget.guildId);
//            },
//          ),
        ],
      ),
    );
  }

  Widget _buildSubtitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.bodyText1.copyWith(fontSize: 14),
      ),
    );
  }

  String _getChannelName(String channelId) {
    final GuildTarget guild =
        ChatTargetsModel.instance.selectedChatTarget as GuildTarget;
    final selectedChannel = guild.channels
        .firstWhere((element) => element.id == channelId, orElse: () => null);
    return selectedChannel?.name ?? '该频道已被删除'.tr;
  }

  Future<void> _showSelectChannels() async {
    if (_loading) return;
    final GuildTarget guild =
        ChatTargetsModel.instance.selectedChatTarget as GuildTarget;
    final List<ChatChannel> textChannels = guild.channels
        .where((element) => element.type == ChatChannelType.guildText)
        .toList();
    if (textChannels.isEmpty) {
      showToast('无文字频道，无法设置'.tr);
      return;
    }
    final res = await showCustomActionSheet(
      textChannels
          .map((e) => Text(
                e.name,
                style: TextStyle(
                    color: Theme.of(context).textTheme.bodyText1.color),
              ))
          .toList(),
      footerFixed: true,
    );
    if (res != null) {
      systemChannelId = textChannels[res].id;
      _updateChanged();
    }
  }

  void _updateChanged() {
    setState(() {
      _changed = systemChannelFlags != guild.systemChannelFlags ||
          systemChannelId != guild.systemChannelId;
    });
  }

  Future<void> _onConfirm() async {
    _toggleLoading(true);
    final guild = ChatTargetsModel.instance.selectedChatTarget as GuildTarget;
    try {
      await GuildApi.updateGuildConfig(
        guildId: guild.id,
        userId: Global.user.id,
        systemChannelId: systemChannelId,
        systemChannelFlags: systemChannelFlags,
      );
      Routes.pop(context);
      guild.update(
          systemChannelFlags: systemChannelFlags,
          systemChannelId: systemChannelId);
      _toggleLoading(false);
    } catch (e) {
      _toggleLoading(false);
    }
  }

  void _toggleLoading(bool value) {
    setState(() {
      _loading = value;
    });
  }
}
