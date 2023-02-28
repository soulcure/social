import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/core/widgets/button/fade_background_button.dart';
import 'package:im/themes/const.dart';
import 'package:im/themes/custom_color.dart';
import 'package:im/utils/utils.dart';
import 'package:sliding_sheet/sliding_sheet.dart';

Future<void> showManagerInviteLinkPopup(
  BuildContext context, {
  VoidCallback onCopyLink,
  VoidCallback onRemarkLink,
  VoidCallback onUndoLink,
}) async {
  final theme = Theme.of(context);
  final backgroundColor = theme.backgroundColor;

  const optionTextStyle1 = TextStyle(color: Color(0xFF363940), fontSize: 16);
  const optionTextStyle2 = TextStyle(color: Color(0xFFF24848), fontSize: 16);

  Widget _cancelButton(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 56),
      child: FadeBackgroundButton(
        backgroundColor: theme.backgroundColor,
        tapDownBackgroundColor: CustomColor(context).backgroundColor7,
        onTap: Get.back,
        child: Text("取消".tr, style: optionTextStyle1),
      ),
    );
  }

  final Widget _dividerHeight8 = Divider(
    color: theme.scaffoldBackgroundColor,
    height: 8,
    thickness: 8,
  );

  return showSlidingBottomSheet<void>(context, resizeToAvoidBottomInset: false,
      builder: (context) {
    return SlidingSheetDialog(
      axisAlignment: 1,
      color: CustomColor(context).backgroundColor7,
      extendBody: true,
      elevation: 8,
      cornerRadius: 12,
      padding: EdgeInsets.zero,
      duration: const Duration(milliseconds: 300),
      scrollSpec: const ScrollSpec(physics: ClampingScrollPhysics()),
      avoidStatusBar: true,
      snapSpec: SnapSpec(
        snappings: const [0.9],
        onSnap: (state, snap) {},
      ),
      builder: (_, state) {
        final theme = Theme.of(context);
        return Material(
          child: Column(
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 56),
                child: FadeBackgroundButton(
                  backgroundColor: backgroundColor,
                  tapDownBackgroundColor: CustomColor(context).backgroundColor7,
                  onTap: () {
                    Get.back();
                    onCopyLink();
                  },
                  child: Text('复制链接'.tr, style: optionTextStyle1),
                ),
              ),
              divider,
              ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 56),
                child: FadeBackgroundButton(
                  backgroundColor: backgroundColor,
                  tapDownBackgroundColor: CustomColor(context).backgroundColor7,
                  onTap: () {
                    // Navigator.of(context).pop();
                    onRemarkLink();
                  },
                  child: Text('设置备注'.tr, style: optionTextStyle1),
                ),
              ),
              _dividerHeight8,
              ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 56),
                child: FadeBackgroundButton(
                  backgroundColor: backgroundColor,
                  tapDownBackgroundColor: CustomColor(context).backgroundColor7,
                  onTap: () {
                    Get.back();
                    onUndoLink();
                  },
                  child: Text('撤销链接'.tr, style: optionTextStyle2),
                ),
              ),
              _dividerHeight8,
              _cancelButton(context),
              Container(
                color: theme.backgroundColor,
                height: getBottomViewInset(),
              )
            ],
          ),
        );
      },
    );
  });
}
