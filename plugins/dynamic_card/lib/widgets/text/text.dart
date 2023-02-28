import '../../widget_nodes/all.dart';
import '../all.dart';
import 'package:flutter/material.dart';

class TextWidget extends StatelessWidget {
  final TextData data;
  final TempWidgetConfig? config;

  const TextWidget({Key? key, required this.data, this.config}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      width: config?.defaultWidth ?? defaultWidth,
      padding: EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: textConfig?.textRep?.call(data) ??
          Text(
            data.text ?? '',
            maxLines: data.line == 0 ? 99 : 1,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: data.type == 0 ? color2 : color3,
            ),
          ),
    );
  }

  TextConfig? get textConfig => config?.textConfig ?? WidgetConfig().textConfig;
}

typedef Widget TextReplacer(TextData? data);
