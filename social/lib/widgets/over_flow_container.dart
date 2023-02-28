/*
 * @FilePath       : /social/lib/widgets/over_flow_container.dart
 * 
 * @Info           : 
 * 
 * @Author         : Whiskee Chan
 * @Date           : 2022-04-15 22:29:33
 * @Version        : 1.0.0
 * 
 * Copyright 2022 iDreamSky FanBook, All Rights Reserved.
 * 
 * @LastEditors    : Whiskee Chan
 * @LastEditTime   : 2022-05-18 21:43:29
 * 
 */
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import 'package:im/app/theme/app_theme.dart';
import 'package:im/pages/home/view/text_chat/items/components/expand_button.dart';

class OverFlowContainer extends StatefulWidget {
  final Widget child;
  final double maxHeight;

  const OverFlowContainer({Key key, this.child, this.maxHeight = 300})
      : super(key: key);

  @override
  _OverFlowContainerState createState() => _OverFlowContainerState();
}

class _OverFlowContainerState extends State<OverFlowContainer> {
  RxBool showExpand = false.obs;
  RxBool useMaxHeight = true.obs;
  Color _backgroundColor = Colors.white;

  @override
  void initState() {
    _backgroundColor = Get.currentRoute.contains('circle')
        ? Colors.white
        : appThemeData.scaffoldBackgroundColor;
    super.initState();
  }

  @override
  void dispose() {
    showExpand.close();
    useMaxHeight.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      if (!mounted) return;
      if (context.size.height >= widget.maxHeight && useMaxHeight.value)
        showExpand.value = true;
    });

    return Obx(() => Stack(
          alignment: Alignment.bottomCenter,
          children: [
            ClipRect(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight:
                      useMaxHeight.value ? widget.maxHeight : double.infinity,
                ),
                child: SingleChildScrollView(
                  physics: const NeverScrollableScrollPhysics(),
                  child: widget.child,
                ),
              ),
            ),
            Visibility(
              visible: showExpand.value,
              child: ExpandButton(
                onTap: () {
                  showExpand.value = false;
                  useMaxHeight.value = false;
                },
                bgColor: _backgroundColor,
              ),
            ),
          ],
        ));
  }
}
