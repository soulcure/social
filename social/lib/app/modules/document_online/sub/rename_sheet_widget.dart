import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/app/modules/document_online/document_api.dart';
import 'package:im/app/modules/document_online/document_enum_defined.dart';
import 'package:im/app/modules/document_online/sub/document_option_menu_widget.dart';
import 'package:im/app/modules/document_online/widget/loading_progress.dart';
import 'package:im/app/modules/document_online/widget/normal_textfild_widget.dart';
import 'package:im/common/extension/string_extension.dart';
import 'package:im/core/widgets/button/fade_button.dart';
import 'package:im/global.dart';
import 'package:im/utils/content_checker.dart';
import 'package:oktoast/oktoast.dart';

class RenameSheetWidget extends StatefulWidget {
  final String fileId;
  final String name;

  const RenameSheetWidget(this.fileId, this.name);

  @override
  State<RenameSheetWidget> createState() => _RenameSheetWidgetState();
}

class _RenameSheetWidgetState extends State<RenameSheetWidget> {
  String renameTitle;
  RxBool rxCommit = false.obs;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: double.infinity,
          height: 44,
          child: Row(
            textBaseline: TextBaseline.alphabetic,
            children: [
              const SizedBox(width: 12),
              _buildCancelButton(),
              const Spacer(),
              SizedBox(
                height: 21,
                child: Text('重命名'.tr,
                    style: const TextStyle(
                      color: Color(0xFF1F2126),
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    )),
              ),
              const Spacer(),
              _buildSaveButton(),
              const SizedBox(width: 12),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding:
              const EdgeInsets.only(left: 16, top: 6, bottom: 10, right: 16),
          child: NormalTextField(
            (text) {
              renameTitle = text.trim();
              if (renameTitle.hasValue) {
                rxCommit.value = true;
              } else {
                rxCommit.value = false;
              }
            },
            hintText: '输入新文档标题'.tr,
            inputLength: inputLength,
            content: widget.name,
            autofocus: true,
          ),
        ),
        const SizedBox(height: 32),

        ///删除取消按钮
        //_buildOption('取消'.tr, Get.back),
        SizedBox(height: Get.mediaQuery.viewPadding.bottom),
      ],
    );
  }

  Widget _buildCancelButton() {
    return SizedBox(
      width: 32,
      child: Padding(
        padding: const EdgeInsets.only(right: 10),
        child: FadeButton(
          child: const Icon(
            Icons.clear,
          ),
          onTap: () {
            renameTitle = null;
            Get.back();
          },
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    final enableColor = Get.theme.primaryColor;
    final disableColor = Get.theme.primaryColor.withOpacity(0.4);
    return ObxValue(
      (data) {
        return FadeButton(
          onTap: (data as RxBool).value ? _commitRename : null,
          child: Text('保存'.tr,
              style: TextStyle(
                color: (data as RxBool).value ? enableColor : disableColor,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              )),
        );
      },
      rxCommit,
    );
  }

  Future<void> _commitRename() async {
    if (renameTitle.noValue) {
      return;
    }
    if (_checkReNameLength()) {
      showToast("内容长度超出限制".tr);
      return;
    }

    LoadingProgress.start(
      context,
      widget: LoadingProgress.loadingWidget(),
      barrierDismissible: false,
    );

    final checkPassed = await CheckUtil.startCheck(
      TextCheckItem(renameTitle, TextChannelType.FB_WD_TITLE),
      toastError: false,
    );

    if (checkPassed == null) {
      showToast('系统繁忙，请稍后重试'.tr);
      LoadingProgress.stop(context);
      return;
    }

    if (!checkPassed) {
      showToast('文档名称涉及不适宜内容'.tr);
      LoadingProgress.stop(context);
      return;
    }

    final bool res = await DocumentApi.docEdit(
      Global.user.id,
      widget.fileId,
      renameTitle,
    );

    LoadingProgress.stop(context);

    if (res == true) {
      ///重命名成功，关闭软键盘
      FocusManager.instance.primaryFocus.unfocus();

      final optionMenuResult = OptionMenuResult(
        OptionMenuType.rename,
        result: true,
        info: renameTitle,
        fileId: widget.fileId,
      );

      Get.back(result: optionMenuResult);
      return;
    }

    Get.back();
  }

  ///解决emoji字符长度问题
  bool _checkReNameLength() {
    final int len = renameTitle.characters.length;
    return len > inputLength;
  }
}
