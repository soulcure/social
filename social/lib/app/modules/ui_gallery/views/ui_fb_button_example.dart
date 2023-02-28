/*
 * @FilePath       : /social/lib/app/modules/ui_gallery/views/ui_fb_button_example.dart
 * 
 * @Info           : UI样例展示： 统一按钮
 * 
 * @Author         : Whiskee Chan
 * @Date           : 2022-02-25 16:47:51
 * @Version        : 1.0.0
 * 
 * Copyright 2022 iDreamSky FanBook, All Rights Reserved.
 * 
 * @LastEditors    : Whiskee Chan
 * @LastEditTime   : 2022-03-11 16:47:03
 * 
 */

import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:im/app/theme/app_theme.dart';
import 'package:im/themes/const.dart';
import 'package:im/widgets/app_bar/appbar_builder.dart';
import 'package:im/widgets/fb_ui_kit/button/button_builder.dart';
import 'package:oktoast/oktoast.dart';

class UIFbButtonExample extends StatefulWidget {
  const UIFbButtonExample();

  @override
  _UIFbButtonExampleState createState() => _UIFbButtonExampleState();
}

class _UIFbButtonExampleState extends State<UIFbButtonExample> {
  /// 按钮测测试用属性
  //  状态
  FbButtonStatus _status;
  //  大小
  FbButtonSize _size;
  //  图标
  IconData _icon;
  //  颜色
  Color _primaryColor;
  //  颜色集合
  final List<Color> _colors = [
    null,
    Colors.orangeAccent,
    Colors.pinkAccent,
    Colors.redAccent,
    Colors.greenAccent,
    Colors.cyanAccent
  ];

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
      appBar: const FbAppBar.custom("统一按钮"),
      body: ListView(children: [
        const Text("\n  一、组件路径: ../lib/widgets/fb_ui_kit/button"),
        const Text("\n  二、按钮展示: \n"),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FbButton.text(
              "说明标签",
              status: _status,
              size: _size,
              primaryColor: _primaryColor,
              onPressed: () => showToast("Method: FbButton.text()",
                  position: ToastPosition.bottom),
            ),
            sizeHeight5,
            FbButton.elevated(
              "按钮",
              status: _status,
              size: _size,
              icon: _icon,
              primaryColor: _primaryColor,
              onPressed: () => showToast("Method: FbButton.elevated()",
                  position: ToastPosition.bottom),
            ),
            sizeHeight5,
            FbButton.subElevated(
              "按钮",
              status: _status,
              size: _size,
              icon: _icon,
              primaryColor: _primaryColor,
              onPressed: () => showToast("Method: FbButton.subElevated()",
                  position: ToastPosition.bottom),
            ),
            sizeHeight5,
            FbButton.lightElevated(
              "按钮",
              status: _status,
              size: _size,
              icon: _icon,
              primaryColor: _primaryColor,
              onPressed: () => showToast("Method: FbButton.lightElevated()",
                  position: ToastPosition.bottom),
            ),
            sizeHeight5,
            FbButton.outlined(
              "按钮",
              status: _status,
              size: _size,
              icon: _icon,
              primaryColor: _primaryColor,
              onPressed: () => showToast("Method: FbButton.outlined()",
                  position: ToastPosition.bottom),
            ),
            sizeHeight5,
            FbButton.subOutlined(
              "按钮",
              status: _status,
              size: _size,
              icon: _icon,
              primaryColor: _primaryColor,
              onPressed: () => showToast("Method: FbButton.subOutlined()",
                  position: ToastPosition.bottom),
            ),
            sizeHeight5,
            FbButton.warning(
              "按钮",
              status: _status,
              size: _size,
              icon: _icon,
              onPressed: () => showToast("Method: FbButton.warning()",
                  position: ToastPosition.bottom),
            ),
          ],
        ),
        const Text("\n  三、按钮属性 : "),
        Text.rich(
          TextSpan(text: "\n  - 大小: ", children: [
            TextSpan(
              text: "纯文字按钮只修改字体\n",
              style: TextStyle(
                  color: appThemeData.textTheme.caption.color, fontSize: 12),
            )
          ]),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FbButton.text(
              "小",
              onPressed: () => setState(() {
                _size = FbButtonSize.small;
              }),
            ),
            FbButton.text(
              "中",
              onPressed: () => setState(() {
                _size = FbButtonSize.middle;
              }),
            ),
            FbButton.text(
              "大",
              onPressed: () => setState(() {
                _size = FbButtonSize.big;
              }),
            ),
          ],
        ),
        const Text("\n  - 状态 : \n"),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FbButton.text(
              "正常",
              onPressed: () => setState(() {
                _status = FbButtonStatus.normal;
              }),
            ),
            FbButton.text(
              "未激活",
              onPressed: () => setState(() {
                _status = FbButtonStatus.unable;
              }),
            ),
            FbButton.text(
              "禁用",
              onPressed: () => setState(() {
                _status = FbButtonStatus.disable;
              }),
            ),
            FbButton.text(
              "完成",
              onPressed: () => setState(() {
                _status = FbButtonStatus.finish;
              }),
            ),
            FbButton.text(
              "加载中",
              onPressed: () => setState(() {
                _status = FbButtonStatus.loading;
              }),
            ),
          ],
        ),
        const Text("\n  - 其它 : \n"),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FbButton.text(
              "换颜色(随机)",
              onPressed: () => setState(() {
                final index = Random().nextInt(5);
                _primaryColor = _colors[index];
              }),
            ),
            FbButton.text(
              _icon == null ? "带图标" : "移除图标",
              status: (_size == null || _size == FbButtonSize.small)
                  ? FbButtonStatus.disable
                  : FbButtonStatus.normal,
              onPressed: () => setState(() {
                _icon = _icon == null ? Icons.access_alarm_sharp : null;
              }),
            ),
          ],
        ),
      ]),
    );
  }
}
