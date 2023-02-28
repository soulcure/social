import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/api/relation_api.dart';
import 'package:im/core/widgets/button/fade_background_button.dart';
import 'package:im/global.dart';
import 'package:im/pages/guild/widget/guild_icon.dart';
import 'package:im/pages/home/model/chat_index_model.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/pages/home/view/tab_bar.dart';
import 'package:im/routes.dart';
import 'package:im/themes/const.dart';
import 'package:im/utils/orientation_util.dart';
import 'package:im/widgets/app_bar/custom_appbar.dart';
import 'package:im/widgets/refresh/net_checker.dart';

class CommonGuildPage extends StatefulWidget {
  final String relationId;

  const CommonGuildPage(this.relationId);

  @override
  _CommonGuildPageState createState() => _CommonGuildPageState();
}

class _CommonGuildPageState extends State<CommonGuildPage> {
  final ValueNotifier<int> _amount = ValueNotifier(0);

  @override
  void initState() {
    _resetFuture();
    super.initState();
  }

  Future _resetFuture() async {
    final res =
        await RelationApi.getRelation(Global.user.id, widget.relationId);
    final List<GuildTarget> _guildList = (res['guilds'] as List)
        .map((v) => GuildTarget.tmp(
            id: v['guild_id'], icon: v['icon'], name: v['name']))
        .toList();
    _amount.value = _guildList.length;
    return _guildList;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OrientationUtil.landscape
          ? Theme.of(context).backgroundColor
          : Theme.of(context).scaffoldBackgroundColor,
      appBar: OrientationUtil.portrait
          ? CustomAppbar(
              titleBuilder: (style) {
                return ValueListenableBuilder<int>(
                    valueListenable: _amount,
                    builder: (context, amount, _) {
                      return Text(
                        '%s个共同服务器'.trArgs([amount.toString()]),
                        style: style,
                      );
                    });
              },
            )
          : null,
      body: NetChecker(
          futureGenerator: _resetFuture,
          retry: () {
            setState(() {});
          },
          builder: (list) {
            return Builder(
              builder: (context) {
                if (list.isEmpty) return Center(child: Text('暂时没有共同服务器哦 '.tr));
                return ListView.builder(
                  padding:
                      EdgeInsets.only(top: OrientationUtil.landscape ? 12 : 0),
                  itemBuilder: (context, index) {
                    return _item(list[index]);
                  },
                  itemCount: list.length,
                );
              },
            );
          }),
    );
  }

  FadeBackgroundButton _item(GuildTarget guild) {
    return FadeBackgroundButton(
      onTap: () async {
        try {
          Routes.backHome();
          if (HomeTabBar.currentIndex != 0) {
            await Future.delayed(const Duration(milliseconds: 200));
            HomeTabBar.gotoIndex(0);
          } else if (GlobalState.isDmChannel) {
            await Future.delayed(const Duration(milliseconds: 200));
          }
          await ChatTargetsModel.instance.selectChatTargetById(guild.id,
              channelId: ChatTargetsModel.instance
                  .getChatTarget(guild.id)
                  .defaultChannel
                  ?.id,
              gotoChatView: true);
        } catch (e) {
          print(e.toString());
        }
      },
      backgroundColor: Theme.of(context).backgroundColor,
      tapDownBackgroundColor:
          Theme.of(context).backgroundColor.withOpacity(0.5),
      child: Stack(
        children: [
          Container(
            padding: EdgeInsets.symmetric(
                vertical: 10, horizontal: OrientationUtil.portrait ? 16 : 24),
            child: Row(
              children: <Widget>[
                GuildIcon(
                  guild,
                  size: OrientationUtil.landscape ? 40 : 32,
                ),
                sizeWidth16,
                Expanded(
                  child: Text(
                    guild.name ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                )
              ],
            ),
          ),
          if (OrientationUtil.landscape)
            const Positioned(
              bottom: 0,
              right: 0,
              left: 24,
              child: divider,
            )
        ],
      ),
    );
  }
}
