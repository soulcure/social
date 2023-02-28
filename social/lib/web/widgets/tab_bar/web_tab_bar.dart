import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/icon_font.dart';

class WebTabBarModel extends GetxController {
  static WebTabBarModel get to => GetInstance().find();

  List<String> _tabTitles = [];
  List<String> get tabTitles => _tabTitles;

  TabController _tabController;
  TabController get tabController => _tabController;

  int _selectIndex = 0;
  bool _expand = false;

  int get selectIndex => _selectIndex;
  bool get expand => _expand;

  void select(int index) {
    tabController.index = index;
    selectIndex = index;
  }

  set selectIndex(int index) {
    _selectIndex = index;
    update();
  }

  void updateExpand(bool expand) {
    _expand = expand;
    update();
  }

  void updateTabTitles(List<String> tabTitles) {
    _tabTitles = tabTitles;
    tabController.index = selectIndex;
    update();
  }

  void updateTabController(TabController controller) {
    _tabController = controller;
    update();
  }
}

class WebTabBar extends StatefulWidget {
  const WebTabBar();

  @override
  _WebTabBarState createState() => _WebTabBarState();
}

class _WebTabBarState extends State<WebTabBar> {
  @override
  void initState() {
    super.initState();
  }

  final _maxContentHeight = 30;

  List<Widget> buildItems(int selectIndex, List<String> titles) {
    final List<Widget> ret = [];
    for (int i = 0;
        i <
            titles
                .map((e) => e.length > 9 ? '${e.substring(0, 9)}...' : e)
                .toList()
                .length;
        i++) {
      final selected = i == selectIndex;
      ret.add(GestureDetector(
        onTap: () => WebTabBarModel.to.select(i),
        behavior: HitTestBehavior.opaque,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
              child: Text(titles[i],
                  style: Theme.of(context)
                      .textTheme
                      .bodyText2
                      .copyWith(color: selected ? Colors.black : Colors.grey)),
            ),
            if (selected)
              Container(
                height: 2,
                width: 10,
                color: Theme.of(context).primaryColor,
              )
            else
              const SizedBox(
                height: 2,
              ),
          ],
        ),
      ));
    }
    return ret;
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<WebTabBarModel>(builder: (model) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final height = measureHeight(constraints.maxWidth, model.tabTitles);
          final isOverflow = height > _maxContentHeight;
          Widget child = Wrap(
            children: buildItems(model.selectIndex, model.tabTitles),
          );
          if (!model.expand) {
            child = ClipRect(
              child: SizedBox(
                height: 40,
                child: LimitedBox(
                  maxHeight: 40,
                  child: child,
                ),
              ),
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: child,
              ),
              if (isOverflow)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: SizedBox(
                    width: 32,
                    height: 32,
                    // ignore: deprecated_member_use
                    child: FlatButton(
                      onPressed: () => model.updateExpand(!model.expand),
                      padding: const EdgeInsets.all(0),
                      color: Colors.white,
                      child: Icon(
                        model.expand
                            ? IconFont.webCircleUp
                            : IconFont.webCircleDown,
                        size: 16,
                        color: Theme.of(context).textTheme.bodyText1.color,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      );
    });
  }

  double measureHeight(double width, List<String> titles) {
    final TextPainter painter = TextPainter(

        /// master 分支注释 nullOk
        locale: Localizations.localeOf(context),
        textDirection: TextDirection.ltr,
        text: TextSpan(
            children: titles
                .map(
                  (e) => TextSpan(
                      text: e, style: Theme.of(context).textTheme.bodyText2),
                )
                .toList()));
    painter.layout(maxWidth: max(1, width - 40 * (titles.length) - 32));
    return painter.height;
  }
}
