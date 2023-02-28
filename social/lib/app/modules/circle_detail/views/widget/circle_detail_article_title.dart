import 'package:flutter/material.dart';
import 'package:im/app/theme/app_theme.dart';
import 'package:im/themes/const.dart';

class CircleDetailArticleTitle extends StatelessWidget {
  final String title;
  final double top;
  final double bottom;

  const CircleDetailArticleTitle(this.title,
      {this.top = 6, this.bottom = 0, Key key})
      : super(key: key);

  @override
  Widget build(BuildContext context) => title.isEmpty
      ? sizedBox
      : Padding(
          padding: EdgeInsets.fromLTRB(16, top ?? 6, 16, bottom ?? 0),
          child: Text(
            title,
            style: appThemeData.textTheme.bodyText1.copyWith(
              fontSize: 18,
              height: 1.5,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
}
