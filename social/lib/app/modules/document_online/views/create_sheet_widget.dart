import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/app/modules/document_online/widget/normal_textfild_widget.dart';
import 'package:im/common/extension/string_extension.dart';
import 'package:im/core/widgets/button/fade_button.dart';
import 'package:im/utils/content_checker.dart';
import 'package:oktoast/oktoast.dart';

class CreateDocResult {
  String guildId;
  String type;
  int dirId;
  String title;

  CreateDocResult(this.guildId, this.type, {this.dirId, this.title});
}

class CreateSheetWidget extends StatefulWidget {
  final String guildId;
  final String type;

  const CreateSheetWidget(this.guildId, this.type);

  @override
  State<CreateSheetWidget> createState() => _CreateSheetWidgetState();
}

class _CreateSheetWidgetState extends State<CreateSheetWidget> {
  String createTitle;
  RxBool rxBan = false.obs;

  @override
  Widget build(BuildContext context) {
    return _createDocumentSheet();
  }

  Widget _createDocumentSheet() {
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
                child: Text('新建文档'.tr,
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
              createTitle = text.trim();
              if (createTitle.hasValue) {
                rxBan.value = true;
              } else {
                rxBan.value = false;
              }
            },
            hintText: '输入新文档标题'.tr,
            inputLength: inputLength,
            autofocus: true,
          ),
        ),
        const SizedBox(height: 32),
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
            createTitle = null;
            Get.back();
          },
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    final enableColor = Get.theme.primaryColor;
    final disableColor = Get.theme.primaryColor.withOpacity(0.4);
    return SizedBox(
      width: 32,
      child: ObxValue(
        (data) {
          return FadeButton(
            onTap: (data as RxBool).value ? _commitCreate : null,
            child: Text('保存'.tr,
                style: TextStyle(
                  color: (data as RxBool).value ? enableColor : disableColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                )),
          );
        },
        rxBan,
      ),
    );
  }

  Future<void> _commitCreate() async {
    if (createTitle.noValue) {
      return;
    }
    if (_checkCreateLength()) {
      showToast("内容长度超出限制".tr);
      return;
    }
    final checkPassed = await CheckUtil.startCheck(
      TextCheckItem(createTitle, TextChannelType.FB_WD_TITLE),
      toastError: false,
    );

    if (checkPassed == null) {
      showToast('系统繁忙，请稍后重试'.tr);
      return;
    }
    if (!checkPassed) {
      showToast('文档名称涉及不适宜内容'.tr);
      return;
    }

    final CreateDocResult res =
        CreateDocResult(widget.guildId, widget.type, title: createTitle);

    Get.back(result: res);
  }

  ///解决emoji字符长度问题
  bool _checkCreateLength() {
    final int len = createTitle.characters.length;
    return len > inputLength;
  }
}
