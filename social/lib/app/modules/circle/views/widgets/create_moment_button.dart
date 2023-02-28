import 'package:flutter/material.dart';
import 'package:im/app/modules/circle/views/landscape/widgets/landscape_create_moment_button.dart';
import 'package:im/app/modules/circle/views/portrait/widgets/portrait_create_moment_button.dart';
import 'package:im/utils/orientation_util.dart';

class CreateMomentButton extends StatelessWidget {
  const CreateMomentButton({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return OrientationUtil.portrait
        ? const PortraitCreateMomentButton()
        : const LandscapeCreateMomentButton();
  }
}
