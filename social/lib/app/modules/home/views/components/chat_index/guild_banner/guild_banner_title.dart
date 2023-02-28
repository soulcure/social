import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/pages/home/model/chat_index_model.dart';
import 'dart:ui' as ui;

class GuildBannerName extends StatelessWidget {
  final TextStyle style;
  final List<ui.Shadow> textShadows;
  const GuildBannerName({Key key, this.style, this.textShadows = const []})
      : super(key: key);

  TextStyle get titleStyle {
    final titleStyle = Theme.of(Get.context).textTheme.headline5;
    return titleStyle
        .copyWith(
          shadows: textShadows,
        )
        .merge(style);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
        valueListenable:
            ChatTargetsModel.instance.selectedChatTarget.nameNotifier,
        builder: (context, value, c) {
          return Text(
            value,
            style: titleStyle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          );
        });
  }
}
