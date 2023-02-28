import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/icon_font.dart';
import 'package:im/web/utils/confirm_dialog/base_dialog.dart';
import 'package:im/widgets/loading_action.dart';

/// 模板类
class SettingDialog extends StatefulWidget {
  @override
  SettingDialogState createState() => SettingDialogState();
}

class SettingDialogState<T extends SettingDialog> extends State<T> {
  ValueNotifier<bool> loading = ValueNotifier(false);
  ValueNotifier<bool> enable = ValueNotifier(true);

  double get dialogWidth => 440;

  bool get showSeparator => true;

  String get title => '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: WebBaseDialog(
        width: dialogWidth,
        showSeparator: showSeparator,
        header: _header(),
        body: body(),
        footer: footer(),
      ),
    );
  }

  Widget borderWraper({Widget child, EdgeInsetsGeometry padding}) {
    return Container(
      decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFDEE0E3)),
          borderRadius: BorderRadius.circular(4)),
      height: 40,
      alignment: Alignment.centerLeft,
      padding: padding,
      child: child,
    );
  }

  Widget body() {
    return const SizedBox();
  }

  Widget _header() {
    final _theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            title,
            style: _theme.textTheme.bodyText2
                .copyWith(fontSize: 16, fontWeight: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        SizedBox(
          width: 24,
          height: 24,
          child: TextButton(
              onPressed: Get.back,
              child: Icon(
                IconFont.webClose,
                size: 20,
                color: _theme.textTheme.bodyText1.color,
              )),
        )
      ],
    );
  }

  Widget footer() {
    final _theme = Theme.of(context);
    return Row(
      textDirection: TextDirection.rtl,
      children: [
        SizedBox(
            width: 88,
            height: 32,
            child: ValueListenableBuilder(
                valueListenable: enable,
                builder: (context, enable, child) {
                  return ValueListenableBuilder(
                      valueListenable: loading,
                      builder: (context, loading, child) {
                        return LoadingAction(
                          loading: loading,
                          onTap: (!enable || loading) ? null : finish,
                          color: enable
                              ? _theme.primaryColor
                              : _theme.primaryColor.withOpacity(0.5),
                          borderRadius: 4,
                          padding: const EdgeInsets.all(0),
                          loadingColor: Colors.white,
                          child: Center(
                            child: Text(
                              '保存'.tr,
                              textAlign: TextAlign.center,
                              style: _theme.textTheme.bodyText2
                                  .copyWith(color: Colors.white),
                            ),
                          ),
                        );
                      });
                })),
      ],
    );
  }

  // ignore: missing_return
  Future<void> finish() {}
}
