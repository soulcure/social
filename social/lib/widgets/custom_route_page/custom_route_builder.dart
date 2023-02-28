import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'custom_route_model.dart';

class CustomRouteBuilder extends StatefulWidget {
  final Widget defaultChild;
  final Widget Function(BuildContext context, RouteModel currentRoute) builder;

  const CustomRouteBuilder({
    this.defaultChild,
    this.builder,
  });
  @override
  _CustomRouteBuilderState createState() => _CustomRouteBuilderState();
}

class _CustomRouteBuilderState extends State<CustomRouteBuilder>
    with SingleTickerProviderStateMixin {
  AnimationController _animationController;
  Animation _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
        duration: const Duration(milliseconds: 100), vsync: this);
    _animation =
        Tween<double>(begin: 220, end: 349).animate(_animationController);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CustomRouteModel>(
      builder: (context, model, child) {
        final lastRoute = model.routes.last;
        final Widget _child =
            widget.builder(context, lastRoute) ?? widget.defaultChild;
        return AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return SizedBox(
              width: _animation.value,
              child: child,
            );
          },
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (c, animation) {
              return FadeTransition(
                opacity: animation,
                child: c,
              );
            },
            child: _child,
          ),
        );
      },
      child: widget.defaultChild,
    );
  }
}
