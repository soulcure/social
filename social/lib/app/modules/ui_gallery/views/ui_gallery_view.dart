/*
 * @FilePath       : /social/lib/app/modules/ui_gallery/views/ui_gallery_view.dart
 * 
 * @Info           : 
 * 
 * @Author         : Whiskee Chan
 * @Date           : 2021-12-06 16:49:02
 * @Version        : 1.0.0
 * 
 * Copyright 2021 iDreamSky FanBook, All Rights Reserved.
 * 
 * @LastEditors    : Whiskee Chan
 * @LastEditTime   : 2022-03-04 14:20:59
 * 
 */

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/app/modules/ui_gallery/views/ui_button_example.dart';
import 'package:im/app/modules/ui_gallery/views/ui_fb_appbar_example.dart';
import 'package:im/app/modules/ui_gallery/views/ui_fb_button_example.dart';
import 'package:im/app/modules/ui_gallery/views/ui_fb_form_example.dart';
import 'package:im/app/modules/ui_gallery/views/ui_fb_tag_example.dart';
import 'package:im/app/modules/ui_gallery/views/ui_icon_example.dart';
import 'package:im/widgets/app_bar/appbar_builder.dart';
import 'package:im/widgets/fb_ui_kit/button/button_builder.dart';
import 'package:im/widgets/toast.dart';
import 'package:oktoast/oktoast.dart';

class UiGalleryView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const FbAppBar.custom("UI 设计规范"),
      body: ListView(
        itemExtent: 50,
        children: [
          FbButton.text(
            "Fb组件系列：导航栏",
            onPressed: () {
              Get.to(() => const UIFbAppBarExample());
            },
          ),
          FbButton.text(
            "Fb组件系列：按钮",
            onPressed: () {
              Get.to(() => const UIFbButtonExample());
            },
          ),
          FbButton.text(
            "Fb组件系列：标签",
            onPressed: () {
              Get.to(() => const UIFbTagExample());
            },
          ),
          FbButton.text(
            "Fb组件系列：表单",
            onPressed: () {
              Get.to(() => const UIFbFormExample());
            },
          ),
          TextButton(
              onPressed: () {
                showToast("普通的 toast 展示");
              },
              child: const Text("showToast")),
          TextButton(
              onPressed: () {
                Toast.iconToast(icon: ToastIcon.success, label: "带成功图标的提示");
              },
              child: const Text("显示带图标的 toast")),
          TextButton(
              onPressed: () {
                Get.to(const UiButtonExample());
              },
              child: const Text("按钮")),
          TextButton(
              onPressed: () {
                Get.to(const UiIconExample());
              },
              child: const Text("图标")),
        ],
      ),
    );
  }
}
