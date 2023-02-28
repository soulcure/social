/*
 * @FilePath       : /social/lib/app/modules/wallet/views/wallet_home_loading_view.dart
 * 
 * @Info           : 
 * 
 * @Author         : Whiskee Chan
 * @Date           : 2022-04-19 10:05:39
 * @Version        : 1.0.0
 * 
 * Copyright 2022 iDreamSky FanBook, All Rights Reserved.
 * 
 * @LastEditors    : Whiskee Chan
 * @LastEditTime   : 2022-04-19 15:06:52
 * 
 */

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:im/app/theme/app_theme.dart';
import 'package:im/themes/const.dart';

class WalletHomeLoadingView extends StatefulWidget {
  @override
  _WalletHomeLoadingViewState createState() => _WalletHomeLoadingViewState();
}

class _WalletHomeLoadingViewState extends State<WalletHomeLoadingView>
    with SingleTickerProviderStateMixin {
  //  加载：动画控制器
  AnimationController controller;

  //  加载：颜色
  Color loadingColor = appThemeData.textTheme.headline2.color;

  @override
  void initState() {
    //  初始化控制器
    controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500))
      ..repeat(min: 0.05, max: 0.2, reverse: true);
    super.initState();
  }

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Container(
            color: appThemeData.scaffoldBackgroundColor,
            height: 104,
            child: _assembleLoadingUserInfoView(),
          ),
          Container(
            height: 44,
            color: Colors.white,
            child: _assembleLoadingCollectLabelView(),
          ),
          Expanded(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: _assembleLoadingCollects(),
            ),
          ),
        ],
      );

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  /// 组装视图 - 加载：头部用户信息
  Widget _assembleLoadingUserInfoView() => AnimatedBuilder(
        animation: controller,
        builder: (context, child) => Opacity(
          opacity: controller.value,
          child: child,
        ),
        child: Row(
          children: [
            sizeWidth16,
            Container(
              width: 64,
              height: 64,
              decoration:
                  BoxDecoration(color: loadingColor, shape: BoxShape.circle),
            ),
            sizeWidth12,
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 68,
                  height: 21,
                  color: loadingColor,
                ),
                sizeHeight8,
                Container(
                  width: 136,
                  height: 16,
                  color: loadingColor,
                ),
              ],
            ),
          ],
        ),
      );

  /// 组装视图 - 加载：艺术藏品展示标签
  Widget _assembleLoadingCollectLabelView() => AnimatedBuilder(
        animation: controller,
        builder: (context, child) => Opacity(
          opacity: controller.value,
          child: child,
        ),
        child: Row(
          children: [
            sizeWidth16,
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                  color: appThemeData.textTheme.headline2.color,
                  shape: BoxShape.circle),
            ),
            sizeWidth8,
            Container(
              width: 65,
              height: 16,
              color: appThemeData.textTheme.headline2.color,
            ),
          ],
        ),
      );

  /// 组装视图 - 加载：艺术品列表
  Widget _assembleLoadingCollects() => AnimatedBuilder(
        animation: controller,
        builder: (context, child) => Opacity(
          opacity: controller.value,
          child: child,
        ),
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
          ),
          itemCount: 9,
          itemBuilder: (context, index) => Container(
            height: 109,
            decoration: BoxDecoration(
              color: loadingColor,
              borderRadius: const BorderRadius.all(Radius.circular(2)),
            ),
          ),
        ),
      );
}
