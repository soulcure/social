import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/app/modules/document_online/document_api.dart';
import 'package:im/app/modules/document_online/document_enum_defined.dart';
import 'package:im/app/theme/app_theme.dart';
import 'package:im/core/http_middleware/http.dart';
import 'package:im/services/server_side_configuration.dart';
import 'package:im/themes/const.dart';
import 'package:im/widgets/app_bar/appbar_builder.dart';
import 'package:im/widgets/check_circle_box.dart';
import 'package:im/widgets/link_tile.dart';
import 'package:oktoast/oktoast.dart';

class TcDocSettingPageView extends StatefulWidget {
  final String fileId;
  final DocType type;
  final RxBool canCopy;
  final Rx<bool> canReaderComment;

  const TcDocSettingPageView({
    Key key,
    @required this.fileId,
    @required this.type,
    @required this.canCopy,
    @required this.canReaderComment,
  }) : super(key: key);

  @override
  State<TcDocSettingPageView> createState() => _TcDocSettingPageViewState();
}

class _TcDocSettingPageViewState extends State<TcDocSettingPageView> {
  bool canComment;
  @override
  void initState() {
    // 支持批注的类型： word、excel，excel暂时关闭
    if (widget.type == DocType.doc) {
      canComment = true;
    } else if (widget.type == DocType.sheet) {
      canComment = !ServerSideConfiguration.to.disableExcelComment;
    } else {
      canComment = false;
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: FbAppBar.custom(
        '文档设置'.tr,
        backgroundColor: appThemeData.scaffoldBackgroundColor,
      ),
      body: ListView(
        children: [
          if (canComment) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4.0 + 6),
              child: Text(
                '哪些人可给文档添加批注'.tr,
                style: TextStyle(
                  height: 17 / 14,
                  fontSize: 14,
                  color: Get.textTheme.headline2.color,
                ),
              ),
            ),
            LinkTile(
              context,
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ObxValue<Rx<bool>>(
                      (type) => CheckCircleBox(
                            value: type.value == true,
                            onChanged: (val) => _onCommentTypeChange(true),
                          ),
                      widget.canReaderComment),
                  sizeWidth12,
                  Text(
                    '可查看此文档的用户'.tr,
                    style: const TextStyle(
                      height: 20 / 16,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              height: 52,
              showTrailingIcon: false,
              onTap: () => _onCommentTypeChange(true),
            ),
            const Divider(
              thickness: 0.5,
              indent: 46,
            ),
            LinkTile(
              context,
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ObxValue<Rx<bool>>(
                      (type) => CheckCircleBox(
                          value: type.value == false,
                          onChanged: (val) => _onCommentTypeChange(false)),
                      widget.canReaderComment),
                  sizeWidth12,
                  Text(
                    '可编辑此文档的用户'.tr,
                    style: const TextStyle(
                      height: 20 / 16,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              height: 52,
              showTrailingIcon: false,
              onTap: () => _onCommentTypeChange(false),
            ),
          ],
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4.0 + 6),
            child: Text(
              '高级安全设置'.tr,
              style: TextStyle(
                height: 17 / 14,
                fontSize: 14,
                color: Get.textTheme.headline2.color,
              ),
            ),
          ),
          LinkTile(
            context,
            Text(
              '禁止阅读者复制内容、生成副本'.tr,
              style: const TextStyle(
                height: 20 / 16,
                fontSize: 16,
              ),
            ),
            trailing: Transform.scale(
              scale: 0.8,
              alignment: Alignment.centerRight,
              child: ObxValue<RxBool>(
                  (canCopy) => CupertinoSwitch(
                        activeColor: Theme.of(context).primaryColor,
                        value: !canCopy.value,
                        onChanged: _onCanCopyChange,
                      ),
                  widget.canCopy),
            ),
            height: 52,
            showTrailingIcon: false,
          )
        ],
      ),
    );
  }

  void _onCanCopyChange(bool val) {
    final originVal = widget.canCopy.value;
    widget.canCopy.value = !val;
    DocumentApi.docPermissionSet(widget.fileId, canCopy: !val).catchError((e) {
      showToast(Http.isNetworkError(e) ? networkErrorText : '数据异常，请重试'.tr);
      widget.canCopy.value = originVal;
    });
  }

  void _onCommentTypeChange(bool canReaderComment) {
    if (widget.canReaderComment.value == canReaderComment) {
      widget.canReaderComment.subject.add(canReaderComment);
      return;
    }
    final originVal = widget.canReaderComment.value;
    widget.canReaderComment.value = canReaderComment;
    DocumentApi.docPermissionSet(widget.fileId,
            canReadeComment: canReaderComment)
        .catchError((e) {
      showToast(Http.isNetworkError(e) ? networkErrorText : '数据异常，请重试'.tr);
      widget.canReaderComment.value = originVal;
    });
  }
}
