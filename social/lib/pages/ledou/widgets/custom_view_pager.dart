import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:im/themes/const.dart';
import 'package:provider/provider.dart';

/// 用tab bar控制多个页面切换的组件，indicator为tab下的小横线
class CustomViewPager extends StatefulWidget {
  /// tab bar包含的所有tab
  final List<CustomTab> tabs;

  /// tab bar控制切换的所有页面
  final List<Widget> pages;

  /// indicator的颜色
  final Color indicatorColor;

  /// indicator的宽度
  final double indicatorWidth;

  /// indicator的高
  final double indicatorThickness;

  /// 被选中时的tab颜色
  final Color selectedColor;

  /// 未选中时的tab颜色
  final Color unSelectedColor;

  /// tab文字的大小
  final double tabFontSize;

  /// tab底部距离indicator的距离
  final double tabGap;

  /// 默认选中的tab（如未指定，默认选中第一个）
  final int defaultTab;

  /// 切换页面时是否保留原页面
  final bool keepAlive;

  const CustomViewPager({
    Key key,
    @required this.tabs,
    @required this.pages,
    this.indicatorColor = const Color(0xFF363940),
    this.indicatorWidth = 60,
    this.indicatorThickness = 2.0,
    this.selectedColor = const Color(0xFF363940),
    this.unSelectedColor = const Color(0xFF8F959E),
    this.defaultTab = 0,
    this.tabFontSize = 15,
    this.tabGap = 10,
    this.keepAlive = true,
  })  : assert(tabs != null && pages != null),
        assert(tabs.length == pages.length),
        super(key: key);

  @override
  _CustomViewPagerState createState() => _CustomViewPagerState();
}

class _CustomViewPagerState extends State<CustomViewPager>
    with SingleTickerProviderStateMixin {
  CustomTabModel _customTabModel;
  TabController _tabController;

  int get tabCount => widget.tabs.length;

  @override
  void initState() {
    super.initState();
    _customTabModel = CustomTabModel(defaultTab: widget.defaultTab);
    _tabController = TabController(
      length: tabCount,
      vsync: this,
      initialIndex: widget.defaultTab,
    );
    _tabController.addListener(_onTabChange);
  }

  void _onTabChange() {
    _customTabModel.onTabChange(_tabController.index);
  }

  List<Widget> get pages {
    if (widget.keepAlive) {
      return widget.pages.map((p) => KeepAliveTabPage(p)).toList();
    }
    return widget.pages;
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<CustomTabModel>(
      create: (_) => _customTabModel,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TabBar(
            indicatorSize: TabBarIndicatorSize.label,
            indicatorColor: widget.indicatorColor,
            controller: _tabController,
            tabs: List.generate(tabCount, _buildTab),
          ),
          divider,
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: pages,
            ),
          ),
        ],
      ),
    );
  }

  /// 构造tab标签
  Widget _buildTab(int i) {
    final tab = widget.tabs[i];
    return Selector<CustomTabModel, int>(
      selector: (_, model) => model.currentTab,
      builder: (_, current, __) {
        Color tabColor;
        FontWeight fontWeight = FontWeight.w600;
        if (current == i) {
          // 当前tab被选中
          tabColor = widget.selectedColor ?? widget.indicatorColor;
          fontWeight = FontWeight.w600;
        } else {
          // 当前tab未被选中
          tabColor = widget.unSelectedColor;
          fontWeight = FontWeight.normal;
        }
        return Container(
          alignment: Alignment.center,
          padding: EdgeInsets.symmetric(vertical: widget.tabGap),
          width: 60,
          child: Text(
            tab.tab,
            style: TextStyle(
                fontSize: widget.tabFontSize,
                fontWeight: fontWeight,
                color: tabColor),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    super.dispose();
    _tabController.removeListener(_onTabChange);
  }
}

class CustomTab {
  final String tab;

  CustomTab(this.tab);
}

class CustomTabModel extends ChangeNotifier {
  int _currentTab;

  int get currentTab => _currentTab;

  CustomTabModel({int defaultTab}) : super() {
    _currentTab = defaultTab ?? 0;
  }

  /// 当tab发生切换
  void onTabChange(int selected) {
    if (selected == _currentTab) {
      return;
    }
    _currentTab = selected;
    notifyListeners();
  }
}

class KeepAliveTabPage extends StatefulWidget {
  final Widget page;

  const KeepAliveTabPage(this.page, {Key key}) : super(key: key);

  @override
  _KeepAliveTabPageState createState() => _KeepAliveTabPageState();
}

class _KeepAliveTabPageState extends State<KeepAliveTabPage>
    with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.page;
  }

  @override
  bool get wantKeepAlive => true;
}
