import 'package:flutter/material.dart';
import 'package:websafe_svg/websafe_svg.dart';

import '../../../../../svg_icons.dart';

class ListEndLayout extends StatelessWidget {
  const ListEndLayout({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 72,
      child: Center(
          child: WebsafeSvg.asset(
        SvgIcons.listEnd,
      )),
    );
  }
}
