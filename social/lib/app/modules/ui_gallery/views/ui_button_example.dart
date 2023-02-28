import 'package:flutter/material.dart';
import 'package:im/core/widgets/button/base_button.dart';
import 'package:im/core/widgets/button/fade_background_button.dart';
import 'package:im/core/widgets/button/fade_button.dart';
import 'package:im/widgets/app_bar/custom_appbar.dart';

class UiButtonExample extends StatelessWidget {
  const UiButtonExample();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppbar(title: "按钮"),
      body: ListView(
        children: [
          BaseButton(
            onTap: () {},
            child: Container(
              alignment: Alignment.center,
              width: 200,
              height: 50,
              child: const Text("BaseButton"),
            ),
          ),
          FadeButton(
            width: 200,
            height: 50,
            onTap: () {},
            backgroundColor: Colors.redAccent,
            child: const Text("FadeButton"),
          ),
          FadeBackgroundButton(
            width: 200,
            height: 50,
            backgroundColor: Colors.greenAccent,
            tapDownBackgroundColor: Colors.greenAccent.withOpacity(0.2),
            child: const Text("FadeBackgroundButton"),
          ),
        ],
      ),
    );
  }
}
