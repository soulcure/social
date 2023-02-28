import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/app/modules/document_online/document_enum_defined.dart';
import 'package:im/app/modules/document_online/sub/icon_text.dart';
import 'package:im/core/widgets/button/fade_button.dart';
import 'package:im/svg_icons.dart';
import 'package:websafe_svg/websafe_svg.dart';

class CreateDocBottomSheet extends StatelessWidget {
  const CreateDocBottomSheet({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return _bottomSheet();
  }

  Widget _bottomSheet() {
    final style = TextStyle(color: Get.textTheme.headline1.color, fontSize: 12);
    return Container(
      width: double.infinity,
      height: 210 + Get.mediaQuery.padding.bottom,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.white),
        borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(8), topRight: Radius.circular(8)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 18),
          Expanded(
            child: GridView(
                padding: const EdgeInsets.symmetric(vertical: 18),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3, //宽高比为1时，子widget
                  childAspectRatio: 1.2,
                ),
                children: <Widget>[
                  IconText(
                    '在线文档'.tr,
                    style: style,
                    icon: WebsafeSvg.asset(SvgIcons.doc, width: 40, height: 40),
                    padding: const EdgeInsets.only(bottom: 12),
                    onTap: () {
                      Get.back(result: DocType.doc);
                    },
                  ),
                  IconText(
                    '在线表格'.tr,
                    style: style,
                    icon:
                        WebsafeSvg.asset(SvgIcons.sheet, width: 40, height: 40),
                    padding: const EdgeInsets.only(bottom: 12),
                    onTap: () {
                      Get.back(result: DocType.sheet);
                    },
                  ),
                  // IconText(
                  //   '在线收集表'.tr,
                  //   style: style,
                  //   icon:
                  //       WebsafeSvg.asset(SvgIcons.form, width: 40, height: 40),
                  //   padding: const EdgeInsets.only(bottom: 15.5),
                  //   onTap: () {
                  //     Get.back(result: DocType.form);
                  //   },
                  // ),
                  IconText(
                    '在线幻灯片'.tr,
                    style: style,
                    icon:
                        WebsafeSvg.asset(SvgIcons.slide, width: 40, height: 40),
                    padding: const EdgeInsets.only(bottom: 12),
                    onTap: () {
                      Get.back(result: DocType.slide);
                    },
                  ),
                  // IconText(
                  //   '在线思维导图'.tr,
                  //   style: style,
                  //   icon:
                  //       WebsafeSvg.asset(SvgIcons.mind, width: 40, height: 40),
                  //   padding: const EdgeInsets.only(bottom: 15.5),
                  //   onTap: () {
                  //     Get.back(result: DocType.mind);
                  //   },
                  // ),
                  // IconText(
                  //   '在线流程图'.tr,
                  //   style: style,
                  //   icon: WebsafeSvg.asset(SvgIcons.flowchart,
                  //       width: 40, height: 40),
                  //   padding: const EdgeInsets.only(bottom: 15.5),
                  //   onTap: () {
                  //     Get.back(result: DocType.flowchart);
                  //   },
                  // ),
                ]),
          ),
          const SizedBox(height: 18),
          const Divider(thickness: 8),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: FadeButton(
              onTap: Get.back,
              child: Text(
                '取消'.tr,
                style: Get.textTheme.bodyText1,
              ),
            ),
          ),
          SizedBox(height: Get.mediaQuery.padding.bottom),
        ],
      ),
    );
  }
}
