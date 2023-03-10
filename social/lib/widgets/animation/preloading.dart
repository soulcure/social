import 'package:flutter/material.dart';

///
/// 页面预加载动画
///
class Preloading extends StatefulWidget {
  /// 条子颜色
  final Color sliverColor;

  const Preloading({this.sliverColor = const Color(0xFF737780)});

  @override
  _PreloadingState createState() => _PreloadingState();
}

class _PreloadingState extends State<Preloading> {
  final double _targetAlpha = 0.3;
  double _alpha = 1;

  @override
  void initState() {
    Future.microtask(() {
      _alpha = _targetAlpha;
      setState(() {});
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _alpha,
      duration: const Duration(milliseconds: 3000),
      curve: Curves.easeOutSine,
      onEnd: () {
        _alpha = _alpha == _targetAlpha ? 1 : _targetAlpha;
        setState(() {});
      },
      child: Container(
        padding: const EdgeInsets.only(top: 15),
        color: Theme.of(context).backgroundColor,
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            _getItem(slivers: <Widget>[
              _genSliver(216),
              _genSliver(111),
            ]),
            _getItem(slivers: <Widget>[
              _genSliver(16),
              _genSliver(111),
              _genSliver(216),
              _genSliver(61),
            ]),
            _getItem(slivers: <Widget>[
              _genSliver(111),
              _genSliver(61),
              _genSliver(16),
            ]),
            _getItem(slivers: <Widget>[
              _genSliver(16),
              _genSliver(111),
              _genSliver(216),
              _genSliver(61),
            ]),
            _getItem(slivers: <Widget>[
              _genSliver(216),
              _genSliver(111),
            ]),
            _getItem(slivers: <Widget>[
              _genSliver(111),
              _genSliver(61),
              _genSliver(16),
              _genSliver(216),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _getItem({List<Widget> slivers}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 30,
            height: 30,
            margin: const EdgeInsets.only(left: 16, right: 18),
            decoration: BoxDecoration(
                color: widget.sliverColor, shape: BoxShape.circle),
          ),
          Expanded(
            child: Column(
              children: slivers,
            ),
          )
        ],
      ),
    );
  }

  Container _genSliver(double rightPadding) {
    return Container(
      height: 20,
      margin: EdgeInsets.only(right: rightPadding, bottom: 12),
      decoration: BoxDecoration(
        color: widget.sliverColor,
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }
}
