import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/core/http_middleware/http.dart';
import 'package:im/themes/const.dart';
import 'package:im/themes/default_theme.dart';

import '../../svg_icons.dart';
import '../svg_tip_widget.dart';

class CommonErrorMsgWidget extends StatelessWidget {
  final String errorMsg;
  final VoidCallback onRetry;

  const CommonErrorMsgWidget({Key key, @required this.errorMsg, this.onRetry})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return _buildError(errorMsg);
  }

  Widget _buildError(error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 100),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            SvgTipWidget(
              svgName: SvgIcons.noNetState,
              text: errorMsg ?? '数据异常，请重试'.tr,
            ),
            sizeHeight32,
            TextButton(
              style: TextButton.styleFrom(
                shape: const StadiumBorder(),
                padding:
                    const EdgeInsets.symmetric(horizontal: 50, vertical: 10),
                backgroundColor: primaryColor,
              ),
              onPressed: onRetry,
              child: Text(
                '重新加载'.tr,
                style: const TextStyle(fontSize: 14, color: Colors.white),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class CommonErrorWidget extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;

  const CommonErrorWidget({Key key, this.error, this.onRetry})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final errorMsg =
        Http.isNetworkError(error) ? networkErrorText : '数据异常，请重试'.tr;
    return CommonErrorMsgWidget(
      errorMsg: errorMsg,
      onRetry: onRetry,
    );
  }
}
