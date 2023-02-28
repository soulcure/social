import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/icon_font.dart';
import 'package:im/themes/const.dart';

// 最后时限和次数限制的item
class Item extends StatelessWidget {
  final String content;
  final bool selected;
  final VoidCallback onTap;

  const Item({
    Key key,
    @required this.content,
    @required this.selected,
    @required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.translucent,
      child: SizedBox(
        height: 50,
        child: Row(
          children: [
            if (selected)
              Icon(
                IconFont.buffCommonCheck,
                size: 24,
                color: Get.theme.primaryColor,
              )
            else
              Container(
                width: 24,
                height: 24,
                padding: const EdgeInsets.all(2),
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: const Color(0xff919499).withOpacity(0.5))),
                ),
              ),
            sizeWidth8,
            Text(content),
          ],
        ),
      ),
    );
  }
}
