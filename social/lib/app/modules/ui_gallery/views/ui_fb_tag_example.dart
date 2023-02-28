/*
 * @FilePath       : /social/lib/app/modules/ui_gallery/views/ui_fb_tag_example.dart
 * 
 * @Info           : UI样例展示： 统一标签
 * 
 * @Author         : Whiskee Chan
 * @Date           : 2022-02-25 16:47:51
 * @Version        : 1.0.0
 * 
 * Copyright 2022 iDreamSky FanBook, All Rights Reserved.
 * 
 * @LastEditors    : Whiskee Chan
 * @LastEditTime   : 2022-03-11 16:58:58
 * 
 */

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:im/app/theme/app_theme.dart';
import 'package:im/icon_font.dart';
import 'package:im/themes/const.dart';
import 'package:im/widgets/app_bar/appbar_builder.dart';
import 'package:im/widgets/fb_ui_kit/tag/tag_builder.dart';

class UIFbTagExample extends StatefulWidget {
  const UIFbTagExample();

  @override
  _UIFbTagExampleState createState() => _UIFbTagExampleState();
}

class _UIFbTagExampleState extends State<UIFbTagExample> {
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
      appBar: const FbAppBar.custom("统一标签"),
      body: ListView(children: [
        const Text("\n  一、组件路径: ../lib/widgets/fb_ui_kit/tag"),
        const Text("\n  二、标签展示: \n"),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            sizeWidth20,
            FbTag.custom("默认标签", icon: IconFont.buffAllDone),
            sizeWidth15,
            FbTag.custom(
              "绿色标签",
              icon: IconFont.buffAlipay,
              primaryColor: Colors.green,
            )
          ],
        ),
        sizeHeight20,
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            sizeWidth20,
            const FbTag.label("机器人"),
            sizeWidth15,
            FbTag.label(
              "官方可见",
              primaryColor: appThemeData.scaffoldBackgroundColor,
            ),
          ],
        ),
        sizeHeight20,
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            sizeWidth20,
            FbTag.role("管理员"),
            sizeWidth15,
            FbTag.role(
              "不良少年",
              roleColor: Colors.red,
            ),
          ],
        ),
        sizeHeight20,
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            sizeWidth20,
            FbTag.reply(1),
          ],
        ),
        sizeHeight20,
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            sizeWidth20,
            FbTag.emoji("微笑"),
            sizeWidth15,
            FbTag.emoji(
              "裂开",
              isLight: true,
            ),
            sizeWidth15,
            FbTag.emoji(
              "拒绝",
              num: 20,
              isLight: true,
            ),
          ],
        ),
      ]),
    );
  }
}
