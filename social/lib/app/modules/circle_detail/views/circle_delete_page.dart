import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:im/app/modules/circle_detail/controllers/circle_delete_controller.dart';
import 'package:im/app/theme/app_colors.dart';
import 'package:im/app/theme/app_theme.dart';
import 'package:im/core/widgets/button/fade_background_button.dart';
import 'package:im/core/widgets/loading.dart';
import 'package:im/pages/guild_setting/circle/circle_detail_page/menu_button/menu_button.dart';
import 'package:im/themes/const.dart';
import 'package:im/themes/custom_color.dart';
import 'package:im/widgets/app_bar/custom_appbar.dart';
import 'package:im/widgets/custom_inputbox.dart';
import 'package:im/widgets/fb_ui_kit/button/button_builder.dart';

import '../../../../icon_font.dart';

/// - 删除动态
class CircleDeletePage extends StatefulWidget {
  final CircleDeleteParam param;

  const CircleDeletePage({
    Key key,
    this.param,
  }) : super(key: key);

  @override
  _CircleDeletePageState createState() => _CircleDeletePageState();
}

/// - 删除动态页面的参数
class CircleDeleteParam {
  final String channelId;
  final String topicId;
  final String postId;
  final Function(MenuButtonType type, {List param}) onSuccess;
  final Function(int code, MenuButtonType type) onError;

  const CircleDeleteParam(
      {this.channelId,
      this.topicId,
      this.postId,
      this.onSuccess,
      this.onError});
}

class _CircleDeletePageState extends State<CircleDeletePage> {
  final FocusNode _focusNode = FocusNode();

  TextEditingController _textEditController;

  //其他的描述限制字数
  final int maxDescLength = 50;

  /// * 删除按钮的状态
  FbButtonStatus _status;

  bool get _buttonEnable => _status == FbButtonStatus.normal;

  @override
  void initState() {
    _status = FbButtonStatus.unable;
    super.initState();
    _textEditController = TextEditingController.fromValue(
      const TextEditingValue(),
    );
  }

  @override
  void dispose() {
    super.dispose();
    _focusNode?.dispose();
    _textEditController?.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<CircleDeleteController>(
        init: CircleDeleteController(widget.param),
        builder: (controller) {
          return Scaffold(
            appBar: CustomAppbar(
              backgroundColor: appThemeData.scaffoldBackgroundColor,
              title: '选择删除动态理由'.tr,
              leadingIcon: IconFont.buffNavBarCloseItem,
            ),
            backgroundColor: appThemeData.scaffoldBackgroundColor,
            body: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _focusNode.unfocus,
              child: Container(
                margin: const EdgeInsets.only(top: 16),
                child: Column(
                  children: [
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemBuilder: (context, index) {
                          final reason = controller.reasonList[index];
                          if (reason.detail != null) {
                            return _buildReasonOther(
                              reason,
                              controller,
                              context,
                            );
                          } else {
                            return _buildReason(
                              reason,
                              controller,
                              context,
                            );
                          }
                        },
                        separatorBuilder: (context, index) {
                          return index == controller.reasonList.length - 1
                              ? sizedBox
                              : Container(
                                  color: Colors.white,
                                  padding: const EdgeInsets.only(left: 50),
                                  child: Divider(
                                    height: 0.5,
                                    color: appThemeData.dividerColor
                                        .withOpacity(0.15),
                                  ),
                                );
                        },
                        itemCount: controller.reasonList.length,
                      ),
                    ),
                    sizeHeight10,
                    sizeHeight16,
                    GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: () {
                        delete(controller);
                      },
                      child: Container(
                        height: 52,
                        color: Colors.white,
                        child: FbButton.text(
                          '删除动态'.tr,
                          status: _status,
                          primaryColor: redTextColor,
                          size: FbButtonSize.free,
                          onPressed: () {
                            delete(controller);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        });
  }

  /// *  删除动态
  Future delete(CircleDeleteController c) async {
    if (!_buttonEnable) return;
    final selReason = c.selReason;
    if (selReason == null) return;
    Loading.show(context);
    await c.deletePost(selReason);
    Loading.hide();
  }

  /// *  设置按钮是否可用
  void setButtonEnable() {
    final length = _textEditController.text.trim().characters.length;
    _status =
        length <= maxDescLength ? FbButtonStatus.normal : FbButtonStatus.unable;
  }

  /// *  其他理由，有输入框
  Widget _buildReasonOther(CircleDeleteReason reason,
      CircleDeleteController controller, BuildContext context) {
    if (reason.isSelected) {
      return Column(
        children: [
          Container(
              color: Colors.white,
              child: Row(
                children: [
                  SizedBox(
                    height: 52,
                    width: 50,
                    child: Icon(
                      IconFont.buffSelectSingle,
                      size: 19,
                      color: appThemeData.primaryColor,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      reason.desc,
                      style: Get.textTheme.bodyText2,
                    ),
                  ),
                ],
              )),
          Container(
            color: Colors.white,
            child: Container(
              height: 133,
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: appThemeData.dividerColor.withOpacity(0.15),
                    width: 0.5),
              ),
              child: CustomInputBox(
                fillColor: Colors.white,
                controller: _textEditController,
                hintText: '请输入删除动态的理由'.tr,
                maxLength: maxDescLength,
                maxLines: 4,
                useFlutter: true,
                showSuffixIcon: false,
                focusNode: _focusNode,
                onChange: (value) {
                  reason.detail = value;
                  final _pro = _buttonEnable;
                  setButtonEnable();
                  if (_buttonEnable != _pro) {
                    setState(() {});
                  }
                },
                style: const TextStyle(fontSize: 17, color: Color(0xFF1F2125)),
              ),
            ),
          ),
        ],
      );
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 52),
      child: FadeBackgroundButton(
        backgroundColor: Colors.white,
        tapDownBackgroundColor: CustomColor(context).backgroundColor7,
        onTap: () {
          setButtonEnable();
          controller.setSelected(reason);
        },
        child: Row(
          children: [
            SizedBox(
              height: 52,
              width: 50,
              child: Icon(
                IconFont.buffUnselectSingle,
                size: 19,
                color: appThemeData.dividerColor.withOpacity(0.5),
              ),
            ),
            Expanded(
              child: Text(
                reason.desc,
                style: Get.textTheme.bodyText2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// * 单个删除理由
  Widget _buildReason(CircleDeleteReason reason,
      CircleDeleteController controller, BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 52),
      child: FadeBackgroundButton(
        backgroundColor: Colors.white,
        tapDownBackgroundColor: CustomColor(context).backgroundColor7,
        onTap: () {
          _status = FbButtonStatus.normal;
          controller.setSelected(reason);
        },
        child: Row(
          children: [
            if (reason.isSelected)
              SizedBox(
                height: 52,
                width: 50,
                child: Icon(
                  IconFont.buffSelectSingle,
                  size: 19,
                  color: appThemeData.primaryColor,
                ),
              )
            else
              SizedBox(
                height: 52,
                width: 50,
                child: Icon(
                  IconFont.buffUnselectSingle,
                  size: 19,
                  color: const Color(0xFF8F959E).withOpacity(0.5),
                ),
              ),
            Expanded(
              child: Text(
                reason.desc,
                style: Get.textTheme.bodyText2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
