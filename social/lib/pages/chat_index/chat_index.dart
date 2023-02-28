import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/pages/home/home_page.dart';
import 'package:im/pages/home/model/chat_index_model.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/pages/home/view/tab_bar.dart';
import 'package:im/svg_icons.dart';
import 'package:im/themes/custom_color.dart';
import 'package:im/utils/orientation_util.dart';
import 'package:im/widgets/svg_tip_widget.dart';
import 'package:provider/provider.dart';

/// 聊天索引页面，显示在首页的最左边一栏
class ChatIndex extends StatelessWidget {
  static BuildContext context;

  final Widget chatTargetList;
  final Widget Function(BaseChatTarget) buildGuildView;

  final Widget emptyWidget;

  const ChatIndex({
    @required this.chatTargetList,
    @required this.buildGuildView,
    this.emptyWidget,
  });

  @override
  Widget build(BuildContext context) {
    ChatIndex.context = context;
    return Row(
      children: <Widget>[
        Container(
          width: 72,
          color: OrientationUtil.portrait
              ? Colors.transparent
              : Theme.of(context).textTheme.bodyText2.color,
          child: chatTargetList,
        ),
        Expanded(
            child: Selector<ChatTargetsModel, BaseChatTarget>(
          // todo 局部刷新
          selector: (_, model) => model.selectedChatTarget,
          builder: (context, chatTarget, child) {
            if (chatTarget == null && OrientationUtil.portrait) {
              return _emptyWidget(context);
            }
            return Container(
              width: double.infinity,
              height: double.infinity,
              decoration: OrientationUtil.portrait
                  ? HomePage.getWindowDecorator(context)
                  : BoxDecoration(
                      color: CustomColor(context).globalBackgroundColor3,
                    ),
              child: buildGuildView(chatTarget),
            );
          },
        )),
        if (OrientationUtil.portrait)
          Container(
            color: Colors.transparent,
            width: 8,
          )
        else
          const SizedBox()
      ],
    );
  }

  Container _buildDirectMessageListHeader(TextStyle _titleStyle,
      {String name}) {
    return Container(
      height: 56,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.only(left: 16, top: 16, right: 12, bottom: 16),
      child: Text(
        name ?? ChatTargetsModel.instance.selectedChatTarget?.name,
        style: _titleStyle.copyWith(height: 1.1),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _emptyWidget(BuildContext context) {
    return Container(
      decoration: HomePage.getWindowDecorator(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDirectMessageListHeader(Theme.of(context).textTheme.headline5,
              name: '频道'.tr),
          Divider(color: Theme.of(context).dividerColor.withOpacity(0.1)),
          Expanded(
            child: Container(
              alignment: Alignment.center,
              padding: EdgeInsets.only(
                  bottom: HomeTabBar.height +
                      MediaQuery.of(context).padding.bottom),
              child: emptyWidget ??
                  SvgTipWidget(
                    svgName: SvgIcons.nullState,
                    text: '暂无内容'.tr,
                    textSize: 17,
                  ),
            ),
          )
        ],
      ),
    );
  }
}
