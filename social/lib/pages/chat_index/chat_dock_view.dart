import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:im/pages/home/view/tab_bar.dart';
import 'package:im/utils/universal_platform.dart';
import 'package:im/widgets/list_view/clamp_sliver_reorder.dart';

/// 应用左侧Dock视图
///
/// 为防止item拖动时不越界以及第一次加载数据时正确显示，使用[Overlay]和[StatefulWidget]
///
/// See also [ReorderableListView]
class DockView extends StatefulWidget {
  DockView({
    Key key,
    @required List<Widget> children,
    @required this.onReorder,
    this.header,
    this.extraList,
    this.footer,
  })  : itemBuilder = ((context, index) => children[index]),
        itemCount = children.length,
        super(key: key);

  const DockView.builder({
    Key key,
    @required this.itemBuilder,
    @required this.itemCount,
    @required this.onReorder,
    this.header,
    this.extraList,
    this.footer,
  })  : assert(itemCount >= 0),
        assert(onReorder != null),
        super(key: key);

  final IndexedWidgetBuilder itemBuilder;

  final int itemCount;

  final ClampReorderCallback onReorder;

  final Widget header;
  final Widget extraList;
  final Widget footer;

  @override
  _DockViewState createState() => _DockViewState();
}

class _DockViewState extends State<DockView> {
  OverlayEntry _listOverlayEntry;

  @override
  void initState() {
    super.initState();
    _listOverlayEntry = OverlayEntry(builder: (context) {
      return CustomScrollView(
        controller: ScrollController(),
        slivers: <Widget>[
          // const SliverToBoxAdapter(child: SizedBox(height: 8)),
          if (widget.header != null) SliverToBoxAdapter(child: widget.header),
          if (widget.extraList != null) widget.extraList,
          if (widget.header != null)
            SliverToBoxAdapter(
              child: Divider(
                height: 16,
                color: Theme.of(context).disabledColor.withOpacity(0.5),
                indent: 16,
                endIndent: 16,
              ),
            ),
          ClampSliverReorderableList(
            itemBuilder: _itemBuilder,
            itemCount: widget.itemCount,
            onReorder: widget.onReorder,
            proxyDecorator: _proxyDecorator,
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 8)),
          if (widget.footer != null) SliverToBoxAdapter(child: widget.footer),
          SliverPadding(
              padding: EdgeInsets.only(
                  bottom: HomeTabBar.height + context.mediaQueryPadding.bottom))
        ],
      );
    });
  }

  @override
  void didUpdateWidget(DockView oldWidget) {
    super.didUpdateWidget(oldWidget);
    _listOverlayEntry.markNeedsBuild();
  }

  Widget _proxyDecorator(Widget child, int index, Animation<double> animation) {
    final AnimationController controller = animation as AnimationController;
    animation = CurvedAnimation(
        parent: controller,
        reverseCurve: const ElasticInCurve(),
        curve: const ElasticOutCurve());

    // 修改拖动时item的效果
    // ignore: prefer_int_literals
    animation = Tween(begin: 1.0, end: 1.2).animate(animation);
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) =>
          Transform.scale(scale: animation.value, child: child),
      child: child,
    );
  }

  Widget _itemBuilder(BuildContext context, int index) {
    final Widget item = widget.itemBuilder(context, index);

    if (UniversalPlatform.isIOS || UniversalPlatform.isAndroid) {
      return ClampReorderableDelayedDragStartListener(
        key: ValueKey(index),
        index: index,
        child: item,
      );
    } else {
      // web端直接拖动排序，整个list滑动由鼠标滚轮完成
      return ClampReorderableDragStartListener(
        key: ValueKey(index),
        index: index,
        child: item,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    //　防止item被拖动时越界
    return Overlay(initialEntries: [_listOverlayEntry]);
  }
}
