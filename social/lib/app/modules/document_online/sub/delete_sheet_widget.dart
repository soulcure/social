import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/app/modules/document_online/document_api.dart';
import 'package:im/app/modules/document_online/document_enum_defined.dart';
import 'package:im/app/modules/document_online/entity/doc_item.dart';
import 'package:im/app/theme/app_colors.dart';
import 'package:im/global.dart';

import 'document_option_menu_widget.dart';

class DeleteSheetWidget extends StatefulWidget {
  final DocItem item;
  final EntryType entryType;

  const DeleteSheetWidget(this.item, this.entryType);

  @override
  State<DeleteSheetWidget> createState() => _DeleteSheetWidgetState();
}

class _DeleteSheetWidgetState extends State<DeleteSheetWidget> {
  @override
  Widget build(BuildContext context) {
    return _checkDeleteSheet(widget.item);
  }

  // color: appThemeData.iconTheme.color,
  Widget _checkDeleteSheet(DocItem item) {
    return Container(
      padding: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.white),
        borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(8), topRight: Radius.circular(8)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 20),
          Text(
            '该记录删除后将无法找回，确定删除吗？'.tr,
            style: TextStyle(fontSize: 14, color: Get.theme.iconTheme.color),
          ),
          const SizedBox(height: 20),
          const Divider(height: 0.5, thickness: 0.5),
          ..._deleteButton(item),
          const Divider(height: 8, thickness: 8),
          _buildOption('取消'.tr, cancelColor, Get.back),
          SizedBox(height: Get.mediaQuery.padding.bottom),
        ],
      ),
    );
  }

  List<Widget> _deleteButton(DocItem item) {
    if (widget.entryType == EntryType.view) {
      return viewDeleteButton(item);
    } else if (widget.entryType == EntryType.my) {
      return myDeleteButton(item);
    }
    return [const SizedBox()];
  }

  ///最近查看删除按钮
  List<Widget> viewDeleteButton(DocItem item) {
    if (item.userId == Global.user.id) {
      return [
        _buildOption('仅删除记录'.tr, Get.textTheme.bodyText2.color, () async {
          final res = await DocumentApi.docDel(
            item.guildId,
            item.fileId,
            DelType.delRecord,
          );
          if (res == true) {
            final optionMenuResult = OptionMenuResult(
              OptionMenuType.deleteRecord,
              result: true,
              info: '删除记录成功'.tr,
            );
            Get.back(result: optionMenuResult);
          }
        }),
        const Divider(height: 0.5, thickness: 0.5),
        _buildOption('删除记录并删除文档'.tr, destructiveRed, () async {
          final res = await DocumentApi.docDel(
            item.guildId,
            item.fileId,
            DelType.delFile,
          );
          if (res == true) {
            final optionMenuResult = OptionMenuResult(
              OptionMenuType.delete,
              result: true,
              info: '删除文档成功'.tr,
            );
            Get.back(result: optionMenuResult);
          }
        }),
      ];
    } else {
      return [
        _buildOption('仅删除记录'.tr, destructiveRed, () async {
          final res = await DocumentApi.docDel(
            item.guildId,
            item.fileId,
            DelType.delRecord,
          );
          if (res == true) {
            final optionMenuResult = OptionMenuResult(
              OptionMenuType.delete,
              info: '删除记录成功'.tr,
              result: true,
            );
            Get.back(result: optionMenuResult);
          }
        }),
      ];
    }
  }

  ///我的文档
  List<Widget> myDeleteButton(DocItem item) {
    return [
      _buildOption('确认删除'.tr, destructiveRed, () async {
        final res = await DocumentApi.docDel(
          item.guildId,
          item.fileId,
          DelType.delFile,
        );
        if (res == true) {
          final optionMenuResult = OptionMenuResult(
            OptionMenuType.delete,
            info: '删除文档成功'.tr,
            result: true,
          );
          Get.back(result: optionMenuResult);
        }
      }),
    ];
  }

  //destructiveRed
  Widget _buildOption(String text, Color color, VoidCallback callback) {
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        onPressed: callback,
        child: Text(
          text,
          style: TextStyle(
            fontSize: 16,
            color: color,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
