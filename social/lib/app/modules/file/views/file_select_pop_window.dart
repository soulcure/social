import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/core/widgets/button/fade_background_button.dart';
import 'package:im/themes/custom_color.dart';

/// - 描述：文件选择路径
///
/// - author: seven
/// - data: 2021/10/18 3:13 下午
enum ClickType {
  fanbook,
  storage,
  photo,
  outside,
}

typedef OnItemClick = Function(ClickType clickType);

class FileSelectPopWindow extends StatefulWidget {
  /// 背景色
  final Color barrierColor;
  final OnItemClick onClick;

  const FileSelectPopWindow({
    Key key,
    this.barrierColor,
    this.onClick,
  }) : super(key: key);

  @override
  _FileSelectPopWindowState createState() => _FileSelectPopWindowState();
}

class _FileSelectPopWindowState extends State<FileSelectPopWindow> {
  final theme = Get.theme;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        widget.onClick?.call(ClickType.outside);
      },
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: widget.barrierColor ?? Colors.black12,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Divider(
              height: 0.5,
              color: const Color(0xFFEEEEEE).withOpacity(0.15),
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 52),
              child: FadeBackgroundButton(
                backgroundColor: Theme.of(context).backgroundColor,
                tapDownBackgroundColor: CustomColor(context).backgroundColor7,
                onTap: () {
                  widget.onClick?.call(ClickType.fanbook);
                },
                child: Text(
                  'Fanbook文件'.tr,
                  style: theme.textTheme.bodyText2.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Get.theme.primaryColor,
                  ),
                ),
              ),
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 52),
              child: FadeBackgroundButton(
                backgroundColor: Theme.of(context).backgroundColor,
                tapDownBackgroundColor: CustomColor(context).backgroundColor7,
                onTap: () {
                  widget.onClick?.call(ClickType.storage);
                },
                child: Text(
                  '手机存储'.tr,
                  style: theme.textTheme.bodyText2.copyWith(fontSize: 16),
                ),
              ),
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 52),
              child: FadeBackgroundButton(
                backgroundColor: Theme.of(context).backgroundColor,
                tapDownBackgroundColor: CustomColor(context).backgroundColor7,
                onTap: () {
                  widget.onClick?.call(ClickType.photo);
                },
                child: Text(
                  '手机相册'.tr,
                  style: theme.textTheme.bodyText2.copyWith(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
