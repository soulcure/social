import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:im/pages/guild/widget/guild_icon.dart';
import 'package:im/pages/home/model/chat_index_model.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/themes/const.dart';
import 'package:im/widgets/app_bar/custom_appbar.dart';
import 'package:im/widgets/link_tile.dart';
import 'package:provider/provider.dart';

class GuildModifyPage extends StatefulWidget {
  final String guildId;
  const GuildModifyPage(this.guildId);
  @override
  _GuildModifyPageState createState() => _GuildModifyPageState();
}

class _GuildModifyPageState extends State<GuildModifyPage> {
  ThemeData _theme;
  @override
  Widget build(BuildContext context) {
    _theme = Theme.of(context);
    return Scaffold(
      backgroundColor: _theme.scaffoldBackgroundColor,
      appBar: CustomAppbar(
        title: '编辑资料'.tr,
      ),
      body: ChangeNotifierProvider.value(
        value: ChatTargetsModel.instance,
        child: Selector<ChatTargetsModel, BaseChatTarget>(
          selector: (context, model) => model.selectedChatTarget,
          builder: (context, target, child) {
            return ListView(
              children: <Widget>[
                sizeHeight20,
                LinkTile(
                  context,
                  Text(
                    target.name,
                    overflow: TextOverflow.ellipsis,
                  ),
                  height: 48,
                  trailing: Row(
                    children: <Widget>[
                      GuildIcon(
                        target,
                        size: 32,
                      ),
                    ],
                  ),
                  onTap: () async {
//                    await getImageFromCameraOrFile(context,
//                        title: '设置服务器头像', crop: true);
                  },
                ),
                divider,
                LinkTile(
                  context,
                  Text("服务器名字".tr),
                  height: 48,
                  trailing: Text(
                    target.name,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () {
//                    Routes.pushMemberManagePage(context, widget.guildId);
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
