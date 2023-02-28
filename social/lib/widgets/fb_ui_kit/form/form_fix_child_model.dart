// ignore_for_file: one_member_abstracts

/*
 * @FilePath       : /social/lib/widgets/fb_ui_kit/form/form_fix_child_model.dart
 * 
 * @Info           : 统一组件：表单
 * 
 * ///   详细说明地址： [https://idreamsky.feishu.cn/wiki/wikcnJr3H4ns2bBpgRIeYcSWRmg#]
 * ///   UI设计稿地址： [https://lanhuapp.com/web/#/item/project/detailDetach?pid=5218aaca-eb1f-445b-acc9-84885113b30b&image_id=43088c96-d845-475d-9218-abfbcb1dfaf3&project_id=5218aaca-eb1f-445b-acc9-84885113b30b&fromEditor=true]
 * ///   交互规范：    [https://idreamsky.feishu.cn/wiki/wikcn1JqxPhAlhcDMNbsUVFkxKf]
 * 
 * @Author         : Whiskee Chan
 * @Date           : 2022-02-23 15:55:35
 * @Version        : 1.0.0
 * 
 * Copyright 2022 iDreamSky FanBook, All Rights Reserved.
 * 
 * @LastEditors    : Whiskee Chan
 * @LastEditTime   : 2022-03-01 16:18:07
 * 
 */

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/app/theme/app_theme.dart';
import 'package:im/utils/custom_cache_manager.dart';
import 'package:im/widgets/realtime_user_info.dart';
import 'package:im/widgets/round_image.dart';

//*====================== 前缀视图 ======================*//
/// 抽象类： 表单子视图 - 前缀视图
abstract class FbFormPrefixChildModel {
  Widget prefixChild();
}

/// 前缀视图 - 图标
class FbFormIconPrefixChild extends FbFormPrefixChildModel {
  //  图标
  final IconData icon;

  //  大小
  final double size;

  //  颜色
  final Color color;

  FbFormIconPrefixChild(
    this.icon, {
    this.size,
    this.color,
  }) : assert(icon != null);

  @override
  Widget prefixChild() => Icon(
        icon,
        size: size ?? 20,
        //  在 appThemeData 替换掉默认主题后，null 就是使用 iconTheme 的 color，所以可以不用写 ??
        color: color ?? appThemeData.iconTheme.color,
      );
}

/// 前缀视图 - 头像
class FbFormAvatarPrefixChild extends FbFormPrefixChildModel {
  //  用户id
  final String userId;

  //  大小
  final double size;

  FbFormAvatarPrefixChild(
    this.userId, {
    this.size = 30,
  }) : assert(userId != null);

  @override
  Widget prefixChild() => RealtimeAvatar(
        userId: userId,
        size: size,
      );
}

//*====================== 后缀视图 ======================*//
/// 抽象类： 表单子视图 - 后缀视图
abstract class FbFormSuffixChildModel {
  Widget suffixChild();
}

/// 后缀视图 - 文本
class FbFormLabelSuffixChild extends FbFormSuffixChildModel {
  //  文案
  final String label;

  //  大小
  final Color color;

  FbFormLabelSuffixChild(
    this.label, {
    this.color,
  }) : assert(label != null);

  @override
  Widget suffixChild() => Text(
        label,
        textAlign: TextAlign.right,
        style: Get.textTheme.bodyText1.copyWith(
          color: color ?? appThemeData.dividerColor.withOpacity(1),
          fontSize: 15,
          height: 1.25,
        ),
      );
}

/// 后缀视图 - 图标
class FbFormIconSuffixChild extends FbFormSuffixChildModel {
  //  图标
  final IconData icon;

  //  大小
  final double size;

  // 颜色
  final Color color;

  FbFormIconSuffixChild(
    this.icon, {
    this.size,
    this.color,
  }) : assert(icon != null);

  @override
  Widget suffixChild() => Icon(
        icon,
        size: size ?? 20,
        //  在 appThemeData 替换掉默认主题后，null 就是使用 iconTheme 的 color，所以可以不用写 ??
        color: color ?? appThemeData.dividerColor.withOpacity(1),
      );
}

/// 后缀视图 - 网络图片
class FbFormImageSuffixChild extends FbFormSuffixChildModel {
  //  图标
  final String url;

  //  宽度
  final double width;

  //  高度
  final double height;

  FbFormImageSuffixChild(
    this.url, {
    this.width = 40,
    this.height = 40,
  }) : assert(url != null);

  @override
  Widget suffixChild() => SizedRoundImage(
        url: url,
        height: width,
        width: height,
        radius: 4,
        cacheManager: CustomCacheManager.instance,
      );
}

/// 后缀视图 - 自定义控件
class FbFormWidgetSuffixChild extends FbFormSuffixChildModel {
  //  自定义控件
  final Widget suffixWidget;

  FbFormWidgetSuffixChild(this.suffixWidget) : assert(suffixWidget != null);

  @override
  Widget suffixChild() => suffixWidget;
}
