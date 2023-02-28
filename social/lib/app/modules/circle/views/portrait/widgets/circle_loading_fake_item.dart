import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/app/theme/app_theme.dart';

class CircleLoadingFakeItem extends StatelessWidget {
  const CircleLoadingFakeItem({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: SizedBox(
        height: 247,
        width: Get.width / 2 - 7.5,
        child: Column(
          children: [
            SizedBox(
              width: double.infinity,
              height: 180,
              child: DecoratedBox(
                decoration: BoxDecoration(
                    color: appThemeData.dividerColor.withOpacity(.05)),
              ),
            ),
            Container(
              width: double.infinity,
              height: 67,
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 100,
                    height: 17,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: appThemeData.dividerColor,
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: appThemeData.dividerColor,
                            borderRadius: BorderRadius.circular(9),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      SizedBox(
                        width: 44,
                        height: 14,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: appThemeData.dividerColor,
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
