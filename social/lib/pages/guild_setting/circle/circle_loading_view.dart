import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/app/modules/circle/views/portrait/portrait_circle_topic_page.dart';
import 'package:im/app/theme/app_theme.dart';
import 'package:im/core/http_middleware/http.dart';
import 'package:im/icon_font.dart';
import 'package:im/widgets/app_bar/appbar_builder.dart';

class CircleLoadingView extends StatefulWidget {
  @override
  _CircleLoadingViewState createState() => _CircleLoadingViewState();
}

class _CircleLoadingViewState extends State<CircleLoadingView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEDEFF2),
      appBar: FbAppBar.diyTitleView(
        leadingIcon: IconFont.buffNavBarBackChannelItem,
        titleBuilder: (context, p1) {
          return Row(
            children: [
              const SizedBox(width: 6),
              SizedBox(
                width: 20,
                height: 20,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: appThemeData.dividerColor,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              SizedBox(
                width: 166,
                height: 20,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: appThemeData.dividerColor,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ),
            ],
          );
        },
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            height: 35,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: List.generate(
                6,
                (index) => Center(
                  child: Container(
                    width: 56,
                    height: 18,
                    margin: const EdgeInsets.only(left: 24),
                    decoration: BoxDecoration(
                      color: appThemeData.dividerColor,
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(width: Get.width, child: const CircleLoadingGrid()),
        ],
      ),
    );
  }

  // ignore: avoid_annotating_with_dynamic
  bool isNetWorkError(dynamic e) {
    if (e is Exception) {
      return Http.isNetworkError(e) || e is TimeoutException;
    } else {
      return false;
    }
  }
}
