import 'package:get/get.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:im/widgets/app_bar/custom_appbar.dart';
import 'package:im/widgets/default_tip_widget.dart';

import '../../icon_font.dart';

class InsertFlowPage extends StatefulWidget {
  final String tipText;

  const InsertFlowPage({this.tipText});

  @override
  _InsertFlowPageState createState() => _InsertFlowPageState();
}

class _InsertFlowPageState extends State<InsertFlowPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Theme.of(context).backgroundColor,
        appBar: CustomAppbar(title: '提示'.tr),
        body: SafeArea(
            top: false,
            left: false,
            right: false,
            child: Center(
              child: DefaultTipWidget(
                icon: IconFont.buffChatMessage,
                iconSize: 34,
                text: widget.tipText ?? "请完成相应的流程".tr,
              ),
            )));
  }
}
