// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:im/core/config.dart';
import 'package:im/web/utils/confirm_dialog/setting_dialog.dart';
import 'package:im/widgets/dialog/ui_fake.dart' if (dart.library.html) 'dart:ui'
    as ui;

class HtmlPage extends SettingDialog {

  final String url;
  final double height;
  final String title;

  HtmlPage({
    this.url,
    this.height = 600,
    this.title,
  });

  @override
  _EditLinkSettingPageState createState() => _EditLinkSettingPageState();
}

class _EditLinkSettingPageState extends SettingDialogState<HtmlPage> {
  html.IFrameElement _termsElement;

  static int index = 0;

  @override
  String get title => widget.title;

  @override
  void initState() {
    index++;
    final appToken = Config.token == null
        ? ''
        : '&apptoken=${Uri.encodeQueryComponent(Config.token ?? "")}';
    _termsElement = html.IFrameElement()
      ..src =
          '${widget.url}$appToken'
      ..height = '${widget.height}'
      ..allowFullscreen = true
      ..style.border = 'none';
    ui.platformViewRegistry
        .registerViewFactory('url-$index', (viewId) => _termsElement);
    super.initState();
  }

  @override
  void dispose() {
    _termsElement?.removeAttribute('src');
    super.dispose();
  }

  @override
  Widget body() {
    return SizedBox(
        height: 600, child: HtmlElementView(viewType: 'url-$index'));
  }

  @override
  Widget footer() {
    return const SizedBox();
  }
}
