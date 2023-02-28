import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide Router;

class RouteNotFound extends StatelessWidget {
  const RouteNotFound({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          '404',
          style: Theme.of(context).textTheme.headline1,
        ),
      ),
    );
  }
}
