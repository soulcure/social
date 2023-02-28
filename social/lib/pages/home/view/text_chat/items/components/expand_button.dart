/*
 * @FilePath       : /social/lib/pages/home/view/text_chat/items/components/expand_button.dart
 *
 * @Info           :
 *
 * @Author         : Whiskee Chan
 * @Date           : 2022-04-15 22:29:33
 * @Version        : 1.0.0
 *
 * Copyright 2022 iDreamSky FanBook, All Rights Reserved.
 *
 * @LastEditors    : Whiskee Chan
 * @LastEditTime   : 2022-05-18 17:23:04
 *
 */
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ExpandButton extends StatelessWidget {
  final VoidCallback onTap;
  final Color bgColor;

  const ExpandButton({Key key, this.onTap, this.bgColor = Colors.white})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          gradient: LinearGradient(
        colors: [
          bgColor.withAlpha(0),
          bgColor.withAlpha(125),
          bgColor.withAlpha(255),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      )),
      child: Align(
          alignment: Alignment.bottomCenter,
          child: GestureDetector(
              onTap: onTap,
              child: Container(
                height: 36,
                width: 96,
                margin: const EdgeInsets.fromLTRB(10, 11, 10, 9),
                alignment: Alignment.center,
                decoration: ShapeDecoration(
                  shape: const StadiumBorder(
                      side: BorderSide(width: 0.5, color: Color(0xFFE0E2E6))),
                  color: Theme.of(context).backgroundColor,
                  shadows: const [
                    BoxShadow(
                        color: Color(0x1A6A7480),
                        offset: Offset(0, 1),
                        blurRadius: 8)
                  ],
                ),
                padding: const EdgeInsets.only(top: 1),
                child: Text(
                  "查看全文".tr,
                  style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontSize: 14,
                      height: 1.25),
                ),
              ))),
    );
  }
}
