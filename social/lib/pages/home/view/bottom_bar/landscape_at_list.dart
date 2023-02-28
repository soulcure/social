import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:im/api/data_model/user_info.dart';
import 'package:im/db/db.dart';
import 'package:im/loggers.dart';
import 'package:im/pages/guild_setting/role/role.dart';
import 'package:im/pages/home/model/input_model.dart';
import 'package:im/pages/home/model/input_prompt/at_selector_model.dart';
import 'package:im/pages/search/widgets/member_nickname.dart';
import 'package:im/themes/const.dart';
import 'package:im/widgets/realtime_user_info.dart';
import 'package:provider/provider.dart';

import '../../../../icon_font.dart';

class AddIntent extends Intent {}

class SubIntent extends Intent {}

class EnterIntent extends Intent {}

class HideIntent extends Intent {}

class LandscapeAtList extends StatefulWidget {
  @override
  LandscapeAtListState createState() => LandscapeAtListState();
}

const double AtListMaxHeight = 280;

class LandscapeAtListState extends State<LandscapeAtList> {
  int currentIndex = 0;
  int viewportStartIndex = 0;
  int viewportEndIndex = AtListMaxHeight ~/ 40 - 1;
  ScrollController _scrollController;

  @override
  void initState() {
    _scrollController = ScrollController();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AtSelectorModel>(
      builder: (context, model, child) {
        if (!model.visible) {
          currentIndex = 0;
          return const SizedBox();
        }

        return Container(
          alignment: Alignment.bottomCenter,
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
          child: Container(
            height: AtListMaxHeight,
            decoration: BoxDecoration(
                color: Theme.of(context).backgroundColor,
                borderRadius: BorderRadius.circular(8),
                boxShadow: const [
                  BoxShadow(
                      blurRadius: 26,
                      spreadRadius: 7,
                      offset: Offset(0, 7),
                      color: Color(0x1F717D8D))
                ]),
            child: Scrollbar(
              child: Shortcuts(
                shortcuts: {
                  LogicalKeySet(LogicalKeyboardKey.arrowUp): AddIntent(),
                  LogicalKeySet(LogicalKeyboardKey.arrowDown): SubIntent(),
                  LogicalKeySet(LogicalKeyboardKey.enter): EnterIntent(),
                  LogicalKeySet(LogicalKeyboardKey.numpadEnter): EnterIntent(),
                  LogicalKeySet(LogicalKeyboardKey.escape): HideIntent(),
                },
                child: Actions(
                  actions: {
                    AddIntent: CallbackAction<AddIntent>(
                        onInvoke: (_) => setIndex(--currentIndex)),
                    SubIntent: CallbackAction<SubIntent>(
                        onInvoke: (_) => setIndex(++currentIndex)),
                    EnterIntent: CallbackAction<EnterIntent>(
                        onInvoke: (_) => onSelect(model.list[currentIndex])),
                    HideIntent:
                        CallbackAction<HideIntent>(onInvoke: (_) => onEsc()),
                  },
                  child: Focus(
                    // focusNode: model.inputModel.textFieldFocusNode,
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      controller: _scrollController,
                      itemBuilder: (_, index) {
                        final item = model.list[index];
                        final selected = currentIndex == index;
                        return _buildItem(item, selected, index);
                      },
                      itemExtent: 40,
                      itemCount: model.list.length,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildItem(item, bool isSelected, int index) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (e) {
        setIndex(index);
      },
      child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => onSelect(item),
          child: Container(
            height: 40,
            // padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            decoration: BoxDecoration(
                color:
                    isSelected ? Theme.of(context).primaryColor : Colors.white),
            child: _buildItemByType(context, item,
                textColor: isSelected ? Colors.white : null),
          )),
    );
  }

  Widget _buildItemByType(BuildContext context, item, {Color textColor}) {
    if (item is ListHeader)
      return _buildHeader(context, item);
    else if (item is String)
      return _buildAtUserItem(item);
    else if (item is Role)
      return buildRoleItem(item, textColor: textColor);
    else
      return buildUserItem(item);
  }

  Widget buildRoleItem(Role item, {Color textColor}) {
    return Row(
      children: [
        sizeWidth16,
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
                ? Colors.white
                : Theme.of(context).textTheme.bodyText2.color,
          ),
        ),
        Expanded(
          child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                item.name,
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

  Widget buildUserItem(UserInfo userInfo, {Color textColor}) {
    if (userInfo == null) return const SizedBox();
    return Row(
      children: <Widget>[
        sizeWidth16,
        RealtimeAvatar(
          userId: userInfo.userId,
          size: 24,
        ),
        const SizedBox(width: 8),
        Expanded(
            child: Row(
          children: <Widget>[
            Flexible(
              child: HighlightMemberNickName(
                userInfo,
                // keyword: keyWord,
              ),
            ),
          ],
        )),
        sizeWidth8,
        Text(
          "#${userInfo?.username}",
          style:
              TextStyle(fontSize: 13, color: Theme.of(context).disabledColor),
        ),
        sizeWidth16,
      ],
    );
  }

  ///显示：可能艾特的人
  Widget _buildAtUserItem(String userId) {
    if (userId == null) return const SizedBox();
    final item = UserInfo.consume(userId, builder: (context, user, widget) {
      return Row(
        children: [
          sizeWidth14,
          RealtimeAvatar(
            userId: userId,
            size: 24,
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

  ///显示分段header
  Widget _buildHeader(BuildContext context, ListHeader item) {
    final width = MediaQuery.of(context).size.width;
    return Container(
      color: const Color(0xfff5f5f8),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      width: width,
      child: Text(
        item.name,
        style: Theme.of(context)
            .textTheme
            .bodyText2
            .copyWith(fontSize: 13, color: const Color(0xFF646A73)),
      ),
    );
  }

  void setIndex(int index) {
    setState(() {
      try {
        final listLen =
            Provider.of<AtSelectorModel>(context, listen: false).list.length;
        if (index > listLen - 1) {
          currentIndex = listLen - 1;
        } else if (index < 0) {
          currentIndex = 0;
        } else {
          currentIndex = index;
        }
      } on Exception catch (e, s) {
        logger.severe('@列表setIndex执行错误', e, s);
      }
    });
    ensureVisible();
  }

  // ignore: type_annotate_public_apis
  void onSelect(item) {
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
          userInfo.showName(hideRemarkName: true),
          atRole: false,
          isBot: userInfo.isBot,
        );
      } else if (item is String) {
        final userInfo = Db.userInfoBox.get(item);
        model.add(
          userInfo.userId,
          userInfo.showName(hideRemarkName: true),
          atRole: false,
          isBot: userInfo.isBot,
        );
      } else {}
    });
  }

  void ensureVisible() {
    if (currentIndex < viewportStartIndex || currentIndex > viewportEndIndex) {
      if (currentIndex < viewportStartIndex) {
        viewportStartIndex = currentIndex;
        viewportEndIndex = AtListMaxHeight ~/ 40 - 1;
      } else if (currentIndex > viewportEndIndex) {
        viewportEndIndex = currentIndex;
        viewportStartIndex = viewportEndIndex - AtListMaxHeight ~/ 40 + 1;
      }
      _scrollController.animateTo((viewportStartIndex * 40).toDouble(),
          curve: Curves.easeInOut, duration: const Duration(milliseconds: 100));
    }
  }

  void onEsc() {
    try {
      final model = Provider.of<AtSelectorModel>(context, listen: false);
      model.visible = false;
      // ignore: invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member
      model.notifyListeners();
    } on Exception catch (e, s) {
      logger.severe('hide atList error', e, s);
    }
  }
}
