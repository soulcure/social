import 'package:flutter/material.dart';

class BgBoxDecoration extends BoxDecoration {
  const BgBoxDecoration()
      : super(
          color: const Color(0xff171D33),
          image: const DecorationImage(
            image: AssetImage('assets/live/main/bg_live.png'),
            alignment: Alignment.bottomCenter,
          ),
        );
}
