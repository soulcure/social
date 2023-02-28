import 'package:fb_live_flutter/live/utils/theme/my_theme.dart';
import 'package:fb_live_flutter/live/utils/ui/frame_size.dart';
import 'package:fb_live_flutter/live/utils/ui/ui.dart';
import 'package:flutter/material.dart';

class DetectionVoiceWidget extends StatelessWidget {
  final double? value;
  final ValueChanged<double>? onChanged;
  final ValueChanged<double>? onChangeEnd;

  const DetectionVoiceWidget({this.value, this.onChanged, this.onChangeEnd});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Image.asset(
          'assets/live/main/ic_voice${value! > 0 ? "" : "_no"}.png',
          width: FrameSize.px(20),
        ),
        Space(width: 8.px),
        Expanded(
            child: Slider(
          value: value!,
          activeColor: MyTheme.themeColor,
          inactiveColor: MyTheme.noActivityColor,
          max: 100,
          onChanged: onChanged,
          onChangeEnd: onChangeEnd,
        )),
      ],
    );
  }
}
