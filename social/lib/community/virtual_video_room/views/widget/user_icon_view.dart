import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

const double SMALL_ICON = 36;
const double BIG_ICON = 80;

class UserIconView extends StatelessWidget {
  final bool isSmall;
  final String imageFile;

  const UserIconView({Key key, this.isSmall = true, this.imageFile})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: isSmall ? SMALL_ICON : BIG_ICON,
      height: isSmall ? SMALL_ICON : BIG_ICON,
      decoration: BoxDecoration(
        color: const Color(0xFF373D78),
        borderRadius: BorderRadius.all(
          Radius.circular(isSmall ? SMALL_ICON / 2 : BIG_ICON / 2),
        ),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Center(
        child: SizedBox(
          width: isSmall ? 24 : 48,
          height: isSmall ? 24 : 48,
          child: imageFile == null
              ? const SizedBox()
              : Image.file(File(imageFile)),
        ),
      ),
    );
  }
}
