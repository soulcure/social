import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/app/modules/circle/views/portrait/widgets/circle_new_loading_view.dart';
import 'package:im/core/http_middleware/http.dart';
import 'package:im/svg_icons.dart';
import 'package:im/themes/const.dart';
import 'package:im/themes/default_theme.dart';
import 'package:im/widgets/svg_tip_widget.dart';

typedef FutureGenerator = Future Function();
typedef ErrorBuilder = Widget Function();

class NetChecker<T> extends StatefulWidget {
  const NetChecker({
    @required this.builder,
    @required this.retry,
    @required this.futureGenerator,
    this.errorBuilder,
    this.errorPadding,
    this.circleLoadingStyle,
  });

  final Widget Function(T) builder;
  final VoidCallback retry;
  final FutureGenerator futureGenerator;

  ///圈子的列表加载态，0是列表1是网格列表
  final int circleLoadingStyle;

  /// - 非网络错误的widget
  final ErrorBuilder errorBuilder;
  final EdgeInsetsGeometry errorPadding;

  @override
  _NetCheckerState createState() => _NetCheckerState<T>();
}

class _NetCheckerState<T> extends State<NetChecker<T>> {
  Future<T> future;
  bool _hasError = false;

  @override
  void initState() {
    _futureCall();
    super.initState();
  }

  void _futureCall() {
    future = widget.futureGenerator?.call();
  }

  @override
  void didUpdateWidget(NetChecker<T> oldWidget) {
    if (_hasError) {
      _futureCall();
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    if (future == null) {
      return widget.builder(null);
    }
    return FutureBuilder<T>(
        future: future,
        builder: (_, snapshot) {
          _hasError = snapshot.hasError;
          if (snapshot.connectionState != ConnectionState.done) {
            return _buildLoading();
          } else {
            if (_hasError) {
              return _buildError(snapshot.error);
            } else {
              return widget.builder(snapshot.data);
            }
          }
        });
  }

  Widget _buildLoading() {
    if (widget.circleLoadingStyle != null) {
      if (widget.circleLoadingStyle == 0) {
        return const CircleLoadingListView();
      } else {
        return const CircleLoadingGridView();
      }
    } else {
      return DefaultTheme.defaultLoadingIndicator();
    }
  }

  Widget _buildError(error) {
    final bool isNetworkError = Http.isNetworkError(error);
    return Center(
      child: Padding(
        padding: widget.errorPadding ?? const EdgeInsets.only(bottom: 100),
        child: !isNetworkError && widget.errorBuilder != null
            ? widget.errorBuilder()
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  SvgTipWidget(
                    svgName: SvgIcons.noNetState,
                    text: isNetworkError ? networkErrorText : '数据异常，请重试'.tr,
                  ),
                  sizeHeight32,
                  TextButton(
                    style: TextButton.styleFrom(
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 50, vertical: 10),
                      backgroundColor: Theme.of(context).primaryColor,
                    ),
                    onPressed: widget.retry,
                    child: Text(
                      '重新加载'.tr,
                      style: const TextStyle(fontSize: 14, color: Colors.white),
                    ),
                  )
                ],
              ),
      ),
    );
  }
}
