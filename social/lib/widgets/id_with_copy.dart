import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:im/utils/orientation_util.dart';
import 'package:oktoast/oktoast.dart';

import '../icon_font.dart';

class IdWithCopy extends StatelessWidget {
  final String username;

  const IdWithCopy(this.username);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () {
        Clipboard.setData(ClipboardData(text: username));
        showToast("#号已复制".tr);
      },
      child: Row(
        children: [
          Text(
            '#$username',
            style: theme.textTheme.bodyText1.copyWith(
              fontSize: OrientationUtil.portrait ? 13 : 12,
              height: 1.25,
              color: theme.disabledColor,
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            IconFont.buffCopy,
            size: OrientationUtil.portrait ? 16 : 12,
            color: theme.disabledColor.withOpacity(0.7),
          ),
        ],
      ),
    );
  }
}
