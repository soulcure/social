import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/core/widgets/button/fade_background_button.dart';
import 'package:im/themes/const.dart';
import 'package:im/utils/custom_radio.dart';
import 'package:im/utils/custom_textfield.dart';
import 'package:oktoast/oktoast.dart';

/// * 弹窗-圈子动态置顶
Future<Map<String, String>> showCirclePinCreateDialog(BuildContext context,
    {String title, int titleMaxLength = 30}) async {
  final theme = Theme.of(context);
  final screenSize = MediaQuery.of(context).size;
  final Map<String, String> result = {"type": "0"};
  if (title != null && title.isNotEmpty) {
    result['title'] = title;
  }
  final ret = await Get.dialog(
    Scaffold(
      //这里包一层Scaffold
      backgroundColor: Colors.transparent,
      body: Center(
        child: SingleChildScrollView(
          // 键盘出现页面自适应
          child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => FocusScope.of(context).requestFocus(FocusNode()),
              child: Container(
                margin: const EdgeInsets.fromLTRB(28, 0, 28, 0),
                width: min(screenSize.width, 320),
                height: 210,
                decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.all(Radius.circular(8))),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      height: 45,
                      alignment: Alignment.bottomCenter,
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        '设置置顶'.tr,
                        style: theme.textTheme.bodyText1.copyWith(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xff1f2125)),
                      ),
                    ),
                    CustomRadio(
                      items: ['精华'.tr, '活动'.tr, '公告'.tr],
                      onSelect: (type) {
                        result['type'] = type.toString();
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                      child: CustomTextField(
                        title: title,
                        maxLength: titleMaxLength,
                        placeHolder: '请输入置顶标题...'.tr,
                        onChanged: (title) {
                          result['title'] = title;
                        },
                      ),
                    ),
                    sizeHeight20,
                    Divider(
                      height: 0.5,
                      color: theme.disabledColor.withOpacity(0.2),
                    ),
                    Row(
                      children: [
                        Expanded(
                            child: FadeBackgroundButton(
                                height: 52,
                                tapDownBackgroundColor:
                                    theme.scaffoldBackgroundColor,
                                onTap: () {
                                  Navigator.of(context).pop(null);
                                },
                                child: Text('取消'.tr,
                                    style: theme.textTheme.bodyText1.copyWith(
                                        fontSize: 17,
                                        color: theme.disabledColor)))),
                        Container(
                          height: 52.5,
                          width: 0.5,
                          color: theme.disabledColor.withOpacity(0.2),
                        ),
                        Expanded(
                            child: FadeBackgroundButton(
                                height: 52,
                                onTap: () {
                                  final title = result['title'] ?? '';
                                  if (title.isEmpty) {
                                    showToast('请输入置顶标题'.tr);
                                  } else if (title.trim().characters.length >
                                      titleMaxLength) {
                                    showToast('置顶标题限制%s个字'
                                        .trArgs(['$titleMaxLength']));
                                  } else {
                                    Navigator.of(context).pop(result);
                                  }
                                },
                                tapDownBackgroundColor:
                                    theme.scaffoldBackgroundColor,
                                child: Text('完成'.tr,
                                    style: theme.textTheme.bodyText1.copyWith(
                                        fontSize: 17,
                                        color: theme.primaryColor)))),
                      ],
                    )
                  ],
                ),
              )),
        ),
      ),
    ),
    barrierDismissible: false,
  );
  return ret;
}
