import 'dart:async';

import 'package:flutter/material.dart'
    hide RefreshIndicator, RefreshIndicatorState;
import 'package:flutter/material.dart' as material;
import 'package:im/themes/default_theme.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class RefreshHeader extends RefreshIndicator {
  const RefreshHeader() : super(height: 60, refreshStyle: RefreshStyle.Follow);

  @override
  State<StatefulWidget> createState() {
    return _RefreshHeaderState();
  }
}

class _RefreshHeaderState extends RefreshIndicatorState<RefreshHeader>
    with SingleTickerProviderStateMixin {
//  bool _isRefreshing = false;

//  @override
//  void onOffsetChange(double offset) {
////    if (_isRefreshing) return;
//    super.onOffsetChange(offset);
//  }

  @override
  void onModeChange(RefreshStatus mode) {
    if (mode == RefreshStatus.refreshing) {
//      _isRefreshing = true;
//      _lottieController.stop();
//      _lottieController.play();
    }
    super.onModeChange(mode);
  }

  @override
  Future<void> endRefresh() {
    return Future.delayed(const Duration(milliseconds: 600));
  }

  @override
  void resetValue() {
//    _lottieController.stop();
//    _isRefreshing = false;
    super.resetValue();
  }

  material.Widget _downWidget;
  material.Widget _refreshWidget;

  @override
  void initState() {
    _downWidget = Container(
      height: 60,
      alignment: Alignment.center,
      child: const material.Icon(material.Icons.arrow_downward),
    );
    _refreshWidget = Container(
      height: 60,
      alignment: Alignment.center,
      child: DefaultTheme.defaultLoadingIndicator(),
    );
    super.initState();
  }

  @override
  Widget buildContent(BuildContext context, RefreshStatus mode) {
    return mode == RefreshStatus.idle ? _downWidget : _refreshWidget;
  }
}
