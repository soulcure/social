import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:im/web/utils/confirm_dialog/setting_dialog.dart';

class HtmlPage extends SettingDialog {

  final String url;
  final double height;
  final String title;

  HtmlPage({
    this.url,
    this.height = 600,
    this.title
  });

  @override
  _EditLinkSettingPageState createState() => _EditLinkSettingPageState();
}

class _EditLinkSettingPageState extends SettingDialogState<HtmlPage> {

  @override
  String get title => widget.title;

  @override
  Widget footer() {
    return const SizedBox();
  }

}
