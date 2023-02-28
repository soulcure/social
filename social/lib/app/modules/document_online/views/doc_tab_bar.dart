import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/app/modules/circle/views/portrait/widgets/custom_tabbar_indicator.dart';
import 'package:im/app/modules/document_online/controllers/online_document_controller.dart';
import 'package:im/app/modules/document_online/document_enum_defined.dart';
import 'package:im/app/modules/document_online/sub/doc_list_page.dart';
import 'package:im/app/theme/app_theme.dart';

typedef SelectTab = void Function(TabController c);

class DocTabBar extends StatefulWidget {
  final String guildId;
  final SelectTab selectTab;

  static List<String> titles = [
    '最近查看'.tr,
    '我的文档'.tr,
    '我的收藏'.tr,
  ];

  const DocTabBar({@required this.guildId, this.selectTab, Key key})
      : assert(guildId != null, 'guildId is not null'),
        super(key: key);

  @override
  State<DocTabBar> createState() => _DocTabBarState();
}

class _DocTabBarState extends State<DocTabBar> with TickerProviderStateMixin {
  TabController _controller;

  @override
  void initState() {
    _controller = TabController(
      length: DocTabBar.titles.length,
      vsync: this,
    );
    _controller.addListener(() {
      final int index = _controller.index;
      OnlineDocumentController.to().entryType = EntryType.values[index];
    });

    if (widget.selectTab != null) {
      widget.selectTab(_controller);
    }

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final labelColor = appThemeData.textTheme.bodyText2.color;
    const unselectedLabelColor = Color(0xFF8D93A6);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 44,
          child: TabBar(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            controller: _controller,
            isScrollable: true,
            indicatorColor: Get.theme.primaryColor,
            indicatorSize: TabBarIndicatorSize.label,
            labelColor: labelColor,
            labelPadding: const EdgeInsets.symmetric(horizontal: 12),
            labelStyle: TextStyle(
              color: labelColor,
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
            unselectedLabelColor: unselectedLabelColor,
            unselectedLabelStyle:
                const TextStyle(color: unselectedLabelColor, fontSize: 14),
            indicator: MyUnderlineTabIndicator(
              insets: const EdgeInsets.only(bottom: 7),
              borderSide: BorderSide(width: 2, color: Get.theme.primaryColor),
            ),
            tabs: getTabs(),
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
    return DocTabBar.titles.map((v) => Tab(child: Text(v))).toList();
  }

  List<Widget> getTabViews(String guildId) {
    return [
      DocListPage(guildId, EntryType.view),
      DocListPage(guildId, EntryType.my),
      DocListPage(guildId, EntryType.collect),
    ];
  }
}
