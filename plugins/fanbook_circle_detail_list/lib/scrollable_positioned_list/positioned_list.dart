// Copyright 2019 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'element_registry.dart';
import 'item_positions_listener.dart';
import 'item_positions_notifier.dart';
import 'scroll_view.dart';
import 'wrapping.dart';

/// Fanbook 圈子动态详情页列表
/// 基于 PositionedList 修改
class FanbookCircleDetailList extends StatefulWidget {
  /// Create a [FanbookCircleDetailList].
  const FanbookCircleDetailList({
    Key? key,
    required this.detailWidget,
    required this.replyItemCount,
    required this.replyItemBuilder,
    required this.pinItemHeight,
    required this.buildPinItem,
    required this.onUnderscroll,
    this.physics,
    this.emptyReplyWidget,
    this.controller,
    this.itemPositionsNotifier,
    required this.pinNotifier,
    this.initialIndex = 0,
    this.alignment = 0,
    this.padding,
  })
      : assert((initialIndex == 0) || (initialIndex < replyItemCount)),
        super(key: key);

  final VoidCallback onUnderscroll;
  final Widget detailWidget;
  final Widget? emptyReplyWidget;

  final double pinItemHeight;
  final Widget Function(bool)? buildPinItem;

  /// Number of items the [replyItemBuilder] can produce.
  final int replyItemCount;

  /// Called to build children for the list with
  /// 0 <= index < itemCount.
  final IndexedWidgetBuilder replyItemBuilder;

  final ScrollPhysics? physics;

  /// An object that can be used to control the position to which this scroll
  /// view is scrolled.
  final ScrollController? controller;

  /// Notifier that reports the items laid out in the list after each frame.
  final ItemPositionsNotifier? itemPositionsNotifier;

  final PinNotifier pinNotifier;

  /// Index of an item to initially align to a position within the viewport
  /// defined by [alignment].
  final int initialIndex;

  /// Determines where the leading edge of the item at [initialIndex]
  /// should be placed.
  ///
  /// See [ItemScrollController.jumpTo] for an explanation of alignment.
  final double alignment;

  /// The amount of space by which to inset the children.
  final EdgeInsets? padding;

  @override
  State<StatefulWidget> createState() => _FanbookCircleDetailListState();
}

class _FanbookCircleDetailListState extends State<FanbookCircleDetailList> {
  final Key _centerKey = UniqueKey();

  final registeredElements = ValueNotifier<Set<Element>?>(null);
  late final ScrollController scrollController;

  bool updateScheduled = false;

  GlobalKey detailWidgetKey = GlobalKey();
  double? detailWidgetHeight;

  @override
  void initState() {
    super.initState();
    scrollController = widget.controller ?? ScrollController();
    scrollController.addListener(_schedulePositionNotificationUpdate);
    _schedulePositionNotificationUpdate();
  }

  @override
  void dispose() {
    scrollController.removeListener(_schedulePositionNotificationUpdate);
    super.dispose();
  }

  @override
  void didUpdateWidget(FanbookCircleDetailList oldWidget) {
    super.didUpdateWidget(oldWidget);
    _schedulePositionNotificationUpdate();
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance!.addPostFrameCallback((timeStamp) {
      final renderObject =
      detailWidgetKey.currentContext?.findRenderObject() as RenderBox?;
      if (renderObject != null) {
        detailWidgetHeight = renderObject.size.height;
      }
      updatePin();
    });
    return Stack(
      children: [
        RegistryWidget(
          elementNotifier: registeredElements,
          child: UnboundedCustomScrollView(
            physics: _CricleDetailPhysics(this,
                parent: widget.physics ??
                    const AlwaysScrollableScrollPhysics()),
            anchor: widget.alignment,
            center: widget.initialIndex != 0 && widget.emptyReplyWidget == null
                ? _centerKey
                : null,
            controller: scrollController,
            semanticChildCount: widget.replyItemCount,
            slivers: <Widget>[
              SliverToBoxAdapter(
                  child: SizedBox(
                      key: detailWidgetKey, child: widget.detailWidget)),
              if (widget.buildPinItem != null)
                SliverPersistentHeader(
                  delegate: _PersistentHeaderBuilder(
                    max: widget.pinItemHeight,
                    min: widget.pinItemHeight,
                    builder: (context, offset) {
                      return SizedBox(
                        height: widget.pinItemHeight,
                        child: widget.buildPinItem!(false),
                      );
                    },
                  ),
                  pinned: false,
                ),
              if (widget.emptyReplyWidget != null)
                SliverToBoxAdapter(child: widget.emptyReplyWidget!)
              else
                ...[
                  if (widget.initialIndex > 0)
                    SliverPadding(
                      padding: _leadingSliverPadding,
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                              (context, index) =>
                              _buildItem(widget.initialIndex - (index + 1)),
                          childCount: widget.initialIndex,
                          addSemanticIndexes: false,
                        ),
                      ),
                    ),
                  SliverPadding(
                    key: _centerKey,
                    padding: _centerSliverPadding,
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                            (context, index) =>
                            _buildItem(index + widget.initialIndex),
                        childCount: widget.replyItemCount != 0 ? 1 : 0,
                        addSemanticIndexes: false,
                      ),
                    ),
                  ),
                  if (widget.initialIndex >= 0 &&
                      widget.initialIndex < widget.replyItemCount - 1)
                    SliverPadding(
                      padding: _trailingSliverPadding,
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                              (context, index) =>
                              _buildItem(index + widget.initialIndex + 1),
                          childCount:
                          widget.replyItemCount - widget.initialIndex - 1,
                          addSemanticIndexes: false,
                        ),
                      ),
                    ),
                ]
            ],
          ),
        ),
        if (widget.buildPinItem != null)
          ValueListenableBuilder<bool>(
              valueListenable: widget.pinNotifier.show,
              builder: (context, visibile, child) =>
                  Visibility(visible: visibile, child: child!),
              child: SizedBox(
                  height: widget.pinItemHeight,
                  child: widget.buildPinItem!(true))),
      ],
    );
  }

  Widget _buildItem(int index) {
    return RegisteredElementWidget(
      key: ValueKey(index),
      child: IndexedSemantics(
          index: index, child: widget.replyItemBuilder(context, index)),
    );
  }

  EdgeInsets get _leadingSliverPadding =>
      (widget.padding?.copyWith(bottom: 0)) ?? const EdgeInsets.all(0);

  EdgeInsets get _centerSliverPadding =>
      widget.padding?.copyWith(
          top: widget.initialIndex == 0 ? widget.padding!.top : 0,
          bottom: widget.initialIndex == widget.replyItemCount - 1
              ? widget.padding!.bottom
              : 0) ??
          const EdgeInsets.all(0);

  EdgeInsets get _trailingSliverPadding =>
      widget.padding?.copyWith(top: 0) ?? const EdgeInsets.all(0);

  void _schedulePositionNotificationUpdate() {
    updatePin();

    if (!updateScheduled) {
      updateScheduled = true;
      SchedulerBinding.instance!.addPostFrameCallback((_) {
        if (registeredElements.value == null) {
          updateScheduled = false;
          return;
        }
        final positions = <ItemPosition>[];
        RenderViewportBase? viewport;
        for (var element in registeredElements.value!) {
          final RenderBox box = element.renderObject as RenderBox;
          viewport ??= RenderAbstractViewport.of(box) as RenderViewportBase?;
          var anchor = 0.0;
          if (viewport is RenderViewport) {
            anchor = viewport.anchor;
          }

          if (viewport is CustomRenderViewport) {
            anchor = viewport.anchor;
          }

          final ValueKey<int> key = element.widget.key as ValueKey<int>;
          final reveal = viewport!.getOffsetToReveal(box, 0).offset;
          if (!reveal.isFinite) continue;
          final itemOffset =
              reveal - viewport.offset.pixels + anchor * viewport.size.height;
          positions.add(ItemPosition(
              index: key.value,
              itemLeadingEdge: itemOffset.round() /
                  scrollController.position.viewportDimension,
              itemTrailingEdge: (itemOffset + box.size.height).round() /
                  scrollController.position.viewportDimension));
        }
        widget.itemPositionsNotifier?.itemPositions.value = positions;
        updateScheduled = false;
      });
    }
  }

  void updatePin() {
    if (!scrollController.hasClients) return;
    if (detailWidgetHeight == null) return;

    widget.pinNotifier.show.value =
        scrollController.position.extentBefore >= detailWidgetHeight!;
    if (widget.pinNotifier.enabled) {
      widget.pinNotifier.value =
          scrollController.position.extentBefore >= detailWidgetHeight!;
    }
  }
}

class _PersistentHeaderBuilder extends SliverPersistentHeaderDelegate {
  final double max;
  final double min;
  final Widget Function(BuildContext context, double offset) builder;

  _PersistentHeaderBuilder({
    required this.max,
    required this.min,
    required this.builder,
  }) : assert(max >= min);

  @override
  Widget build(BuildContext context, double shrinkOffset,
      bool overlapsContent) {
    return builder(context, shrinkOffset);
  }

  @override
  double get maxExtent => max;

  @override
  double get minExtent => min;

  @override
  bool shouldRebuild(covariant _PersistentHeaderBuilder oldDelegate) =>
      max != oldDelegate.max ||
          min != oldDelegate.min ||
          builder != oldDelegate.builder;
}

class _CricleDetailPhysics extends ScrollPhysics {
  final _FanbookCircleDetailListState _state;

  const _CricleDetailPhysics(this._state, {ScrollPhysics? parent})
      : super(parent: parent);

  @override
  ScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return _CricleDetailPhysics(
      _state,
      parent: buildParent(ancestor),
    );
  }

  @override
  double applyPhysicsToUserOffset(ScrollMetrics position, double value) {
    if (_state.widget.pinNotifier.value &&
        position.extentBefore - value < _state.detailWidgetHeight!) {
      _state.widget.onUnderscroll();
      return position.extentBefore - _state.detailWidgetHeight!;
    }
    return super.applyPhysicsToUserOffset(position, value);
  }

  @override
  double applyBoundaryConditions(ScrollMetrics position, double value) {
    if (_state.widget.pinNotifier.value &&
        value < position.pixels &&
        value - position.minScrollExtent <= _state.detailWidgetHeight!) {
      _state.widget.onUnderscroll();
      return value - (position.minScrollExtent + _state.detailWidgetHeight!);
    }
    return super.applyBoundaryConditions(position, value);
  }
}
