import 'package:flutter/material.dart';
import 'package:im/pages/chat_index/chat_target_list.dart';

import '../../../../../icon_font.dart';

class CreateGuildButton extends StatelessWidget {
  final VoidCallback onPressed;

  const CreateGuildButton({Key key, this.onPressed}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const double size = 48;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Center(
        child: Container(
          width: size,
          height: size,
          decoration: ShapeDecoration(
            shadows: [ChatTargetList.iconShadow],
            shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(size / 6))),
            color: Theme.of(context).backgroundColor,
          ),
          child: IconButton(
            icon: const Icon(IconFont.buffAdd),
            onPressed: onPressed,
          ),
        ),
      ),
    );
  }
}
