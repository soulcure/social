import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/themes/const.dart';

class BoundDialog extends StatelessWidget {
  final String nickname;
  final String thirdNickname;

  const BoundDialog({
    Key key,
    this.nickname,
    this.thirdNickname,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final textStyle = Get.textTheme.bodyText2.copyWith(
      color: const Color(0xFF5C6273),
      fontSize: 16,
      height: 1.5,
    );
    final mediumStyle = Get.textTheme.bodyText2.copyWith(
        fontSize: 17,
        color: const Color(0xFF1F2126),
        fontWeight: FontWeight.w500);

    return Material(
      borderRadius: BorderRadius.circular(10),
      color: Colors.white,
      child: Container(
        alignment: Alignment.center,
        width: 280,
        padding: const EdgeInsets.only(
          top: 32,
        ),
        // height: 195,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '提示'.tr,
                style: mediumStyle,
              ),
              sizeHeight20,
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                ),
                child: Text.rich(TextSpan(
                    text: '该支付宝账号已绑定 '.tr,
                    style: textStyle,
                    children: [
                      TextSpan(
                          text: thirdNickname,
                          style:
                              textStyle.copyWith(fontWeight: FontWeight.w500),
                          children: [
                            TextSpan(
                                text: '，是否解绑并换绑为 '.tr,
                                style: textStyle,
                                children: [
                                  TextSpan(
                                    text: nickname,
                                    style: textStyle.copyWith(
                                        fontWeight: FontWeight.w500),
                                  )
                                ])
                          ])
                    ])),
              ),
              sizeHeight20,
              const Divider(
                height: 1,
                color: Color(0x33919499),
              ),
              SizedBox(
                height: 53,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Get.back(result: false),
                        behavior: HitTestBehavior.translucent,
                        child: Container(
                          alignment: Alignment.center,
                          child: Text(
                            '取消'.tr,
                            style: mediumStyle,
                          ),
                        ),
                      ),
                    ),
                    const VerticalDivider(
                      width: 1,
                      color: Color(0x33919499),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Get.back(result: true),
                        behavior: HitTestBehavior.translucent,
                        child: Container(
                          alignment: Alignment.center,
                          child: Text('确定换绑'.tr,
                              style: mediumStyle.copyWith(
                                color: const Color(0xFF198CFE),
                              )),
                        ),
                      ),
                    )
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
