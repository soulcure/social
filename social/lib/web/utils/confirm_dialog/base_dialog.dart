import 'package:flutter/material.dart';
import 'package:im/themes/const.dart';

class WebBaseDialog extends StatelessWidget {
  final double width;
  final double height;
  final Widget header;
  final Widget footer;
  final Widget body;
  final bool showSeparator;
  const WebBaseDialog({
    this.header,
    this.footer,
    this.body,
    this.width,
    this.height,
    this.showSeparator = false,
  });

  @override
  Widget build(BuildContext context) {
    final _theme = Theme.of(context);
    return Center(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          color: _theme.backgroundColor,
        ),
        child: Column(
          mainAxisSize: height != null ? MainAxisSize.max : MainAxisSize.min,
          children: [
            Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                child: header),
            if (showSeparator) divider,
            if (body != null && height != null) Expanded(child: body),
            if (body != null && height == null) body,
            if (footer != null) ...[
              if (showSeparator) divider,
              Padding(
                  padding:
                  const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                  child: footer),
            ]
          ],
        ),
      ),
    );
  }
}
