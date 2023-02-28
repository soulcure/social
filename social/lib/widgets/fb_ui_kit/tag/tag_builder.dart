// ignore_for_file: must_be_immutable

/*
 * @FilePath       : /social/lib/widgets/fb_ui_kit/tag/tag_builder.dart
 * 
 * @Info           : 统一组件：标签 按钮
 * 
 * ///   详细说明地址： [https://idreamsky.feishu.cn/wiki/wikcnd1JBQHUeDPjbESUaLy4OTe#p8ihNl]
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

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/app/theme/app_theme.dart';
import 'package:im/icon_font.dart';
import 'package:im/utils/emo_util.dart';

/// 全局静态参数
//  标签默认尺寸
const double kFbTagSizeNormal = 32;
//  标签大尺寸
const double kFbTagSizeSmall = 20;
//  标签子视图尺寸
const double kFbTagChildSize = kFbTagSizeNormal - 15;

/// 枚举 - 标签大小（UI规范）
enum FbTagSize {
  normal,
  small,
}

class FbTag extends StatelessWidget {
  // ====== Properties: Constant ====== //
  //  高度
  final FbTagSize size;

  //  按钮文案
  final String text;

  //  主色
  final Color primaryColor;

  //  前景色
  final Color foregroundColor;

  //  是否展示边框
  final bool showBorder;

  // ====== Properties: Private ====== //
  //  Get: 获取标签高度
  double get _tagHeight =>
      size == FbTagSize.small ? kFbTagSizeSmall : kFbTagSizeNormal;

  const FbTag({
    Key key,
    this.size = FbTagSize.normal,
    this.text,
    this.primaryColor,
    this.foregroundColor,
    this.showBorder = false,
  }) : super(key: key);

  /// 工厂模式：默认样式
  const factory FbTag.custom(
    String text, {
    IconData icon,
    Color primaryColor,
  }) = _FbCustomTag;

  /// 工厂模式：说明标签
  const factory FbTag.label(
    String text, {
    Color primaryColor,
  }) = _FbLabelTag;

  /// 工厂模式：角色标签
  factory FbTag.role(
    String roleName, {
    Color roleColor,
  }) = _FbRoleTag;

  /// 工厂模式：回复标签
  factory FbTag.reply(
    int num,
  ) = _FbReplyTag;

  /// 工厂模式：表情标签
  factory FbTag.emoji(
    String emoji, {
    int num,
    bool isLight,
  }) = _FbEmojiTag;

  @override
  Widget build(BuildContext context) => Container(
        height: _tagHeight,
        // alignment: Alignment.center,
        decoration: BoxDecoration(
          color: _getBackgroundColor(),
          borderRadius: BorderRadius.all(Radius.circular(_tagHeight / 8)),
          border: showBorder
              ? Border.all(
                  color: Color.alphaBlend(
                      appThemeData.scaffoldBackgroundColor.withOpacity(0.2),
                      _getBackgroundColor()),
                )
              : null,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 8,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: assembleChildren(_getForegroundColor(), _tagHeight, [
            if (text != null && text.isNotEmpty) ...[
              Text(
                text,
                maxLines: 1,
                textAlign: TextAlign.center,
                strutStyle: const StrutStyle(
                  leading: 0,
                  //  调整线格的高度以适配文字高度
                  height: 1.2,
                  //  关键属性 强制改为文字高度
                  forceStrutHeight: true,
                ),
                style: TextStyle(
                  color: _getForegroundColor(),
                  fontSize: size == FbTagSize.small ? 11 : 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ]),
        ),
      );

  /// 获取标签背景色
  Color _getBackgroundColor() {
    if (primaryColor == null) {
      return Get.theme.primaryColor.withOpacity(0.1);
    }
    if (foregroundColor == null) {
      return primaryColor.withOpacity(0.1);
    }
    return primaryColor;
  }

  /// 获取标签背前景色
  Color _getForegroundColor() {
    return foregroundColor ?? (primaryColor ?? Get.theme.primaryColor);
  }

  // ====== Method: Public ====== //
  /// 组装展示视图
  List<Widget> assembleChildren(
          Color foregroundColor, double height, List<Widget> children) =>
      children;
}

// 统一标签：默认样式
class _FbCustomTag extends FbTag {
  // ====== Properties: Constant ====== //
  //  图标
  final IconData icon;

  const _FbCustomTag(
    String text, {
    @required this.icon,
    Color primaryColor,
  })  : assert(icon != null),
        super(
          text: text,
          primaryColor: primaryColor,
        );

  @override
  List<Widget> assembleChildren(
      Color foregroundColor, double height, List<Widget> children) {
    children.insert(
        0,
        Icon(
          icon,
          color: foregroundColor,
          size: height / 2,
        ));
    children.insert(
        1,
        const SizedBox(
          width: 5,
        ));
    return children;
  }
}

// 统一标签：说明标签
class _FbLabelTag extends FbTag {
  const _FbLabelTag(
    String text, {
    Color primaryColor,
  }) : super(
          size: FbTagSize.small,
          text: text,
          primaryColor: primaryColor,
        );
}

// 统一标签：角色样式
class _FbRoleTag extends FbTag {
  // ====== Properties: Constant ====== //
  //  角色名称
  final String roleName;

  //  角色颜色
  final Color roleColor;

  _FbRoleTag(
    this.roleName, {
    this.roleColor,
  })  : assert(roleName != null && roleName.isNotEmpty),
        super(
          text: roleName,
          primaryColor: appThemeData.textTheme.headline2.color,
        );

  @override
  List<Widget> assembleChildren(
      Color foregroundColor, double height, List<Widget> children) {
    children.insert(
      0,
      ClipOval(
        child: SizedBox(
            width: 8,
            height: 8,
            child: ColoredBox(color: roleColor ?? Get.theme.primaryColor)),
      ),
    );
    children.insert(
        1,
        const SizedBox(
          width: 5,
        ));
    return children;
  }
}

// 统一标签：回复标签
class _FbReplyTag extends FbTag {
  _FbReplyTag(
    int num,
  )   : assert(num > 0),
        super(
          text: "%s条回复".trArgs([num.toString()]),
          primaryColor: Colors.white,
          foregroundColor: Get.theme.primaryColor,
        );

  @override
  List<Widget> assembleChildren(
      Color foregroundColor, double height, List<Widget> children) {
    children.add(
      Icon(
        IconFont.buffPayArrowNext,
        color: Get.theme.primaryColor,
        size: height / 2.8,
      ),
    );
    return children;
  }
}

// 统一标签：表情
class _FbEmojiTag extends FbTag {
  // ====== Properties: Constant ====== //
  //  图标
  final String emoji;

  _FbEmojiTag(
    this.emoji, {
    int num,
    bool isLight = false,
  })  : assert(emoji != null && emoji.isNotEmpty),
        super(
          text: num == null ? "" : num.toString(),
          primaryColor: isLight
              ? Get.theme.primaryColor.withOpacity(0.1)
              : appThemeData.dividerColor,
          foregroundColor: isLight
              ? Get.theme.primaryColor
              : appThemeData.textTheme.headline2.color,
          showBorder: isLight,
        );

  @override
  List<Widget> assembleChildren(
      Color foregroundColor, double height, List<Widget> children) {
    EmoUtil.instance.doInitial();
    children.insert(
      0,
      EmoUtil.instance.getEmoIcon(emoji, size: height * 0.7),
    );
    if (children.length == 2) {
      children.insert(
          1,
          const SizedBox(
            width: 5,
          ));
    }
    return children;
  }
}
