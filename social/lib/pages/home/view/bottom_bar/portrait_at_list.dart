import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/api/data_model/user_info.dart';
import 'package:im/core/widgets/button/fade_button.dart';
import 'package:im/db/db.dart';
import 'package:im/icon_font.dart';
import 'package:im/pages/guild_setting/role/role.dart';
import 'package:im/pages/home/model/input_model.dart';
import 'package:im/pages/home/model/input_prompt/at_selector_model.dart';
import 'package:im/pages/search/widgets/member_nickname.dart';
import 'package:im/themes/const.dart';
import 'package:im/utils/orientation_util.dart';
import 'package:im/widgets/mouse_hover_builder.dart';
import 'package:im/widgets/realtime_user_info.dart';
import 'package:provider/provider.dart';

///消息公屏：艾特列表
class PortraitAtList extends StatefulWidget {
  @override
  PortraitAtListState createState() => PortraitAtListState();
}

class PortraitAtListState extends State {
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Consumer<AtSelectorModel>(
      builder: (context, model, child) {
        if (!model.visible) return const SizedBox();
        return Container(
          alignment: Alignment.bottomCenter,
          padding: OrientationUtil.landscape
              ? const EdgeInsets.fromLTRB(24, 0, 24, 8)
              : const EdgeInsets.all(0),
          child: Container(
            height: OrientationUtil.landscape ? 300 : double.infinity,
            decoration: BoxDecoration(
                color: OrientationUtil.portrait
                    ? Colors.white
                    : Theme.of(context).backgroundColor,
                borderRadius: OrientationUtil.portrait
                    ? BorderRadius.circular(0)
                    : BorderRadius.circular(8),
                boxShadow: const [
                  BoxShadow(
                      blurRadius: 26,
                      spreadRadius: 7,
                      offset: Offset(0, 7),
                      color: Color(0x1F717D8D))
                ]),
            child: Scrollbar(
              child: ListView.separated(
                padding: EdgeInsets.zero,
                separatorBuilder: (_, index) => Padding(
                  padding: EdgeInsets.only(
                      left: model.list[index] is Role ? 16 : 68),
                  child: _buildDivider(model.list, index),
                ),
                itemBuilder: (_, index) {
                  final item = model.list[index];
                  if (OrientationUtil.portrait)
                    return FadeButton(
                        width: screenWidth,
                        height: item is ListHeader ? 38 : 50,
                        onTap: () => _onSelect(item),
                        child:
                            _buildItem(context, model.channel.guildId, item));
                  else
                    return MouseHoverBuilder(
                      builder: (context, selected) {
                        return FadeButton(
                            onTap: () => _onSelect(item),
                            backgroundColor: selected
                                ? Theme.of(context).primaryColor
                                : Colors.transparent,
                            child: _buildItem(
                                context, model.channel.guildId, item,
                                textColor: selected ? Colors.white : null));
                      },
                    );
                },
                // itemExtent: OrientationUtil.landscape ? 40 : 50,
                itemCount: model.list.length,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDivider(List list, int index) {
    if (list.length > 1 &&
        index + 1 < list.length &&
        list[index]?.runtimeType == list[index + 1]?.runtimeType) {
      return divider;
    }
    return const SizedBox();
  }

  Widget _buildItem(BuildContext context, String guildId, item,
      {Color textColor}) {
    if (item is ListHeader)
      return _buildHeader(context, item);
    else if (item is String)
      return _buildAtUserItem(item, guildId);
    else if (item is Role)
      return _buildRoleItem(item, textColor: textColor);
    else
      return _buildUserItem(item);
  }

  ///显示分段header
  Widget _buildHeader(BuildContext context, ListHeader item) {
    return Container(
      color: const Color(0xfff5f5f8),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
      width: Get.width,
      child: Text(
        item.name,
        style: Theme.of(context)
            .textTheme
            .bodyText1
            .copyWith(fontSize: 14, height: 1, color: const Color(0xFF646A73)),
      ),
    );
  }

  Widget _buildUserItem(UserInfo userInfo) {
    if (userInfo == null) return const SizedBox();
    return Row(
      children: <Widget>[
        sizeWidth16,
        RealtimeAvatar(
          userId: userInfo.userId,
          size: OrientationUtil.portrait ? 32 : 24,
        ),
        SizedBox(width: OrientationUtil.portrait ? 16 : 8),
        Expanded(
            child: Row(
          children: <Widget>[
            Flexible(
              child: HighlightMemberNickName(
                userInfo,
                // keyword: keyWord,
              ),
            ),
            sizeWidth8,
          ],
        )),
        sizeWidth16,
        Text(
          "#${userInfo.username}",
          style:
              TextStyle(fontSize: 13, color: Theme.of(context).disabledColor),
        ),
        sizeWidth16,
      ],
    );
  }

  Widget _buildRoleItem(Role item, {Color textColor}) {
    return Row(
      children: [
        sizeWidth16,
        if (OrientationUtil.landscape)
          Container(
            width: 24,
            height: 24,
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              color: item.name == '全体成员'.tr
                  ? Theme.of(context).primaryColor
                  : Theme.of(context).backgroundColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              IconFont.buffTabAt,
              size: 16,
              color: item.name == '全体成员'.tr
                  ? Theme.of(context).backgroundColor
                  : Theme.of(context).textTheme.bodyText2.color,
            ),
          ),
        Expanded(
          child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "@${item.name}",
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color:
                      textColor ?? (item.color == 0 ? null : Color(item.color)),
                ),
              )),
        ),
      ],
    );
  }

  ///显示：可能艾特的人
  Widget _buildAtUserItem(String userId, String guildId) {
    if (userId == null) return const SizedBox();
    final item = UserInfo.consume(userId, guildId: guildId,
        builder: (context, user, widget) {
      return Row(
        children: [
          sizeWidth14,
          RealtimeAvatar(
            userId: userId,
            size: 32,
          ),
          sizeWidth8,
          Expanded(
              child: Row(
            children: <Widget>[
              Flexible(
                child: RealtimeNickname(
                  userId: userId,
                  style:
                      const TextStyle(color: Color(0xFF1F2329), fontSize: 16),
                  showNameRule: ShowNameRule.remarkAndGuild,
                ),
              ),
              sizeWidth8,
            ],
          )),
          sizeWidth16,
          Text(
            "#${user?.username}",
            style:
                TextStyle(fontSize: 13, color: Theme.of(context).disabledColor),
          ),
          sizeWidth16,
        ],
      );
    });
    return item;
  }

  void _onSelect(item) {
    final model = Provider.of<InputModel>(context, listen: false);
    setState(() {
      String name;
      if (item is Role) {
        name = item.name;
        model.add(item.id, name, atRole: true);
      } else if (item is UserInfo) {
        final userInfo = item;
        UserInfo.set(userInfo);
        model.add(
          userInfo.userId,
          userInfo.showName(),
          atRole: false,
          isBot: userInfo.isBot,
        );
      } else if (item is String) {
        // 最近@过的人
        final userInfo = Db.userInfoBox.get(item);
        model.add(
          userInfo.userId,
          userInfo.showName(),
          atRole: false,
          isBot: userInfo.isBot,
        );
      } else {}
    });
  }
}
