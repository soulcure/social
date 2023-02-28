import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import 'package:im/widgets/image.dart';
import 'package:im/widgets/mouse_hover_builder.dart';
import 'package:url_launcher/url_launcher.dart';

Future<bool> showWebImageDialog(
  BuildContext context, {
  @required String url,
  @required double width,
  @required double height,
}) async {
  return showDialog(
      context: context,
      builder: (_) {
        return WebImageDialog(
          url: url,
          width: width,
          height: height,
        );
      });
}

class WebImageDialog extends StatefulWidget {
  final String url;
  final double width;
  final double height;

  const WebImageDialog({
    this.url,
    this.width,
    this.height,
  });

  @override
  _WebImageDialogState createState() => _WebImageDialogState();
}

class _WebImageDialogState extends State<WebImageDialog> {
  @override
  Widget build(BuildContext context) {
    final _theme = Theme.of(context);
    double width = MediaQuery.of(context).size.width * 0.8;
    double height = MediaQuery.of(context).size.height * 0.8;
    final ratio = widget.width / widget.height;
    if (widget.width < width && widget.height < height) {
      width = widget.width;
      height = widget.height;
    } else if (ratio < width / height) {
      width = height * ratio;
    } else {
      height = width / ratio;
    }
    return Align(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: width,
            height: height,
            child: NetworkImageWithPlaceholder(widget.url,
                imageBuilder: (context, imageProvider) => Container(
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: imageProvider,
                        ),
                      ),
                    )),
          ),
          SizedBox(
              width: max(width, 60),
              child: GestureDetector(
                onTap: () => launch(widget.url ?? ''),
                child: Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: MouseHoverBuilder(
                    cursor: SystemMouseCursors.click,
                    builder: (context, selected) {
                      return Text(
                        '查看原图'.tr,
                        style: selected
                            ? _theme.textTheme.bodyText2.copyWith(
                                color: Colors.white,
                                decoration: TextDecoration.underline)
                            : _theme.textTheme.bodyText2
                                .copyWith(color: const Color(0xFFDEE0E3)),
                      );
                    },
                  ),
                ),
              ))
        ],
      ),
    );
  }
}
