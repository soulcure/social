import 'package:get/get.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:im/widgets/button/back_button.dart';

class SuggestFeedbackPage extends StatefulWidget {
  @override
  _SuggestFeedbackPageState createState() => _SuggestFeedbackPageState();
}

class _SuggestFeedbackPageState extends State<SuggestFeedbackPage> {
  @override
  Widget build(BuildContext context) {
    final ThemeData _theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('意见反馈'.tr),
        elevation: 0,
        backgroundColor: _theme.backgroundColor,
        leading: const CustomBackButton(),
      ),
      body: const Text('data'),
    );
  }
}
