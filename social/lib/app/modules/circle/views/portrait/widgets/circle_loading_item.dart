import 'package:flutter/material.dart';
import 'package:im/app/theme/app_theme.dart';

class CircleLoadingItem extends StatelessWidget {
  const CircleLoadingItem({Key key, this.grid = false}) : super(key: key);
  final bool grid;

  @override
  Widget build(BuildContext context) {
    return grid ? _gridItem : _item;
  }

  Widget get _item => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: appThemeData.dividerColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _greyBlock(width: 64, height: 16),
                    const SizedBox(height: 6),
                    _greyBlock(width: 102, height: 12),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            _greyBlock(width: double.infinity, height: 20),
            const SizedBox(height: 4),
            _greyBlock(width: double.infinity, height: 20),
            const SizedBox(height: 4),
            _greyBlock(width: double.infinity, height: 20),
            const SizedBox(height: 4),
            _greyBlock(width: 171, height: 20),
            const SizedBox(height: 12),
            Container(
              width: 105,
              height: 24,
              decoration: BoxDecoration(
                color: appThemeData.dividerColor,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ],
        ),
      );

  Widget get _gridItem => ClipRRect(
        borderRadius: BorderRadius.circular(4),
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
      );

  Widget _greyBlock({double width, double height}) {
    return Container(
      decoration: BoxDecoration(
        color: appThemeData.dividerColor,
        borderRadius: BorderRadius.circular(2),
      ),
      width: width,
      height: height,
    );
  }
}
