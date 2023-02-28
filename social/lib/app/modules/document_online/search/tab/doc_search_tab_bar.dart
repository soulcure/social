import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/app/modules/document_online/controllers/online_document_controller.dart';
import 'package:im/app/modules/document_online/document_enum_defined.dart';
import 'package:im/app/theme/app_theme.dart';

import 'doc_search_list_page.dart';

class DocSearchTabBar extends StatefulWidget {
  final String guildId;
  final int initialIndex;

  static List<String> titles = [
    '最近查看'.tr,
    '我的文档'.tr,
    '我的收藏'.tr,
  ];

  const DocSearchTabBar(
      {@required this.guildId, this.initialIndex = 0, Key key})
      : assert(guildId != null, 'guildId is not null'),
        super(key: key);

  @override
  State<DocSearchTabBar> createState() => _DocSearchTabBarState();
}

class _DocSearchTabBarState extends State<DocSearchTabBar>
    with TickerProviderStateMixin {
  TabController _controller;

  @override
  void initState() {
    _controller = TabController(
      initialIndex: widget.initialIndex,
      length: DocSearchTabBar.titles.length,
      vsync: this,
    );
    _controller.addListener(() {
      final int index = _controller.index;
      OnlineDocumentController.to().entryType = EntryType.values[index];
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final labelColor = appThemeData.textTheme.bodyText2.color;
    const unselectedLabelColor = Color(0xFF8D93A6);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8),
          child: SizedBox(
            width: double.infinity,
            height: 44,
            child: Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 7),
              child: TabBar(
                controller: _controller,
                isScrollable: true,
                indicatorColor: Get.theme.primaryColor,
                indicatorSize: TabBarIndicatorSize.label,
                labelPadding: const EdgeInsets.only(left: 12, right: 12),
                labelColor: labelColor,
                labelStyle: TextStyle(
                    color: labelColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    height: 1.25),
                unselectedLabelColor: unselectedLabelColor,
                unselectedLabelStyle:
                    const TextStyle(color: unselectedLabelColor, fontSize: 14),
                indicatorPadding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
                tabs: getTabs(),
              ),
            ),
          ),
        ),
        const Divider(
          thickness: 0.5,
        ),
        Expanded(
          child: TabBarView(
            controller: _controller,
            children: getTabViews(widget.guildId),
          ),
        ),
      ],
    );
  }

  List<Widget> getTabs() {
    return DocSearchTabBar.titles.map((v) => Tab(child: Text(v))).toList();
  }

  List<Widget> getTabViews(String guildId) {
    return [
      DocSearchListPage(guildId, EntryType.view),
      DocSearchListPage(guildId, EntryType.my),
      DocSearchListPage(guildId, EntryType.collect),
    ];
  }
}
