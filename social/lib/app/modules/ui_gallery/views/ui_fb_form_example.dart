/*
 * @FilePath       : /social/lib/app/modules/ui_gallery/views/ui_fb_form_example.dart
 * 
 * @Info           : UI样例展示： 统一表单
 * 
 * @Author         : Whiskee Chan
 * @Date           : 2022-02-25 16:47:51
 * @Version        : 1.0.0
 * 
 * Copyright 2022 iDreamSky FanBook, All Rights Reserved.
 * 
 * @LastEditors    : Whiskee Chan
 * @LastEditTime   : 2022-03-11 14:57:33
 * 
 */

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:im/app/routes/spectial_routes.dart';
import 'package:im/global.dart';
import 'package:im/icon_font.dart';
import 'package:im/themes/const.dart';
import 'package:im/widgets/app_bar/appbar_builder.dart';
import 'package:im/widgets/fb_ui_kit/button/button_builder.dart';
import 'package:im/widgets/fb_ui_kit/form/form_builder.dart';
import 'package:im/widgets/fb_ui_kit/form/form_fix_child_model.dart';

class UIFbFormExample extends StatefulWidget {
  const UIFbFormExample();

  @override
  _UIFbFormExampleState createState() => _UIFbFormExampleState();
}

class _UIFbFormExampleState extends State<UIFbFormExample> {
  // 滑动开关状态
  bool _isSwitchOn = false;

  // 子文案
  String _subLabel = "";

  //  输入框输出内容
  String _outPutTextOne = "";

  //  是否显示箭头
  bool _isShowArrow = true;

  //  Common后缀视图展示选择
  int _commonSIIndex;

  //  Switch后缀图标
  IconData _switchIconSI;

  // 展示更多输入样式
  bool _isShowMoreLine = false;

  //  前缀视图展示选择
  int _prefixIndex;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus.unfocus(),
      child: Scaffold(
        appBar: const FbAppBar.custom("统一表单"),
        body: Container(
          color: Colors.transparent,
          height: double.infinity,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("\n  一、组件路径: ../lib/widgets/fb_ui_kit/form"),
                const Text("\n  二、表单展示: \n"),
                const Text("    FbForm.common: "),
                sizeHeight10,
                FbForm.common(
                  "扫描二维码",
                  prefixChildModel: _getPrefixChild(_prefixIndex),
                  suffixChildModel: _getCommonSuffixChild(_commonSIIndex),
                  subLabel: _subLabel,
                  isShowArrow: _isShowArrow,
                  onTap: SpectialRoutes.openQrScanner,
                ),
                sizeHeight10,
                Row(
                  children: [
                    const Text(
                      "    -- 后缀视图: ",
                      style: TextStyle(fontSize: 14),
                    ),
                    FbButton.text(
                      "清除",
                      onPressed: () {
                        setState(() {
                          _commonSIIndex = null;
                        });
                      },
                    ),
                    FbButton.text(
                      "图标",
                      onPressed: () {
                        setState(() {
                          _commonSIIndex = 0;
                        });
                      },
                    ),
                    FbButton.text(
                      "文本",
                      onPressed: () {
                        setState(() {
                          _commonSIIndex = 1;
                        });
                      },
                    ),
                    FbButton.text(
                      "图片",
                      onPressed: () {
                        setState(() {
                          _commonSIIndex = 2;
                        });
                      },
                    ),
                  ],
                ),
                sizeHeight10,
                const Text("    FbForm.wSwitch: "),
                sizeHeight10,
                FbForm.wSwitch(
                  "打开权限",
                  prefixChildModel: _getPrefixChild(_prefixIndex),
                  iconSuffixChild: _switchIconSI == null
                      ? null
                      : FbFormIconSuffixChild(_switchIconSI),
                  subLabel: _subLabel,
                  isOn: _isSwitchOn,
                  onChanged: (isOn) {
                    setState(() {
                      _isSwitchOn = isOn;
                      _switchIconSI = _isSwitchOn ? IconFont.buffAlipay : null;
                    });
                  },
                ),
                sizeHeight20,
                Row(
                  children: [
                    const Text(
                      "    -- 基础属性: ",
                      style: TextStyle(fontSize: 14),
                    ),
                    sizeWidth10,
                    FbButton.text(
                      "${_subLabel == null ? "显示" : "隐藏"}子文本",
                      onPressed: () {
                        setState(() {
                          if (_subLabel == null || _subLabel.isEmpty) {
                            _subLabel = "这是子文本子文本";
                            return;
                          }
                          _subLabel = null;
                        });
                      },
                    ),
                    FbButton.text(
                      "${_isShowArrow == null ? "显示" : "隐藏"}箭头",
                      onPressed: () {
                        setState(() {
                          if (_isShowArrow == null || _isShowArrow == false) {
                            _isShowArrow = true;
                            return;
                          }
                          _isShowArrow = null;
                        });
                      },
                    ),
                  ],
                ),
                sizeHeight10,
                Row(
                  children: [
                    const Text(
                      "    -- 前缀视图: ",
                      style: TextStyle(fontSize: 14),
                    ),
                    FbButton.text(
                      "清除",
                      onPressed: () {
                        setState(() {
                          _prefixIndex = null;
                        });
                      },
                    ),
                    FbButton.text(
                      "图标",
                      onPressed: () {
                        setState(() {
                          _prefixIndex = 0;
                        });
                      },
                    ),
                    FbButton.text(
                      "头像",
                      onPressed: () {
                        setState(() {
                          _prefixIndex = 1;
                        });
                      },
                    ),
                  ],
                ),
                sizeHeight10,
                const Text("    FbForm.input: "),
                sizeHeight10,
                FbForm.input(
                  text: _outPutTextOne,
                  isShowMoreLine: _isShowMoreLine,
                  hintText: "这是单行输入",
                  onOutput: (text) {
                    _outPutTextOne = text;
                  },
                ),
                sizeHeight15,
                Row(
                  children: [
                    const Text(
                      "    -- 输入样式: ",
                      style: TextStyle(fontSize: 14),
                    ),
                    FbButton.text(
                      "单行",
                      onPressed: () {
                        setState(() {
                          _isShowMoreLine = false;
                        });
                      },
                    ),
                    FbButton.text(
                      "多行",
                      onPressed: () {
                        setState(() {
                          _isShowMoreLine = true;
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 获取common模式下后缀视图
  FbFormSuffixChildModel _getCommonSuffixChild(int index) {
    // ignore: void_checks
    if (index == 0) {
      return FbFormIconSuffixChild(IconFont.buffTabMore);
    } else if (index == 1) {
      return FbFormLabelSuffixChild("v2.10.3");
    } else if (index == 2) {
      return FbFormImageSuffixChild(
          "https://cdn2.ettoday.net/images/3268/d3268416.jpg");
    }
    return null;
  }

  // 获取通用前缀视图
  FbFormPrefixChildModel _getPrefixChild(int index) {
    // ignore: void_checks
    if (index == 0) {
      return FbFormIconPrefixChild(IconFont.buffTabMore);
    } else if (index == 1) {
      return FbFormAvatarPrefixChild(Global.user.id);
    }
    return null;
  }
}
