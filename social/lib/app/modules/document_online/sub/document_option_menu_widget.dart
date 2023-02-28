import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:im/app/modules/document_online/document_enum_defined.dart';
import 'package:im/app/modules/document_online/entity/doc_info_item.dart';
import 'package:im/app/modules/document_online/entity/doc_item.dart';
import 'package:im/app/modules/document_online/sub/doc_list_controller.dart';
import 'package:im/app/modules/document_online/sub/rename_sheet_widget.dart';
import 'package:im/app/modules/tc_doc_add_group_page/entities/tc_doc_group.dart';
import 'package:im/app/modules/tc_doc_page/views/share_action_popup.dart';
import 'package:im/app/modules/tc_doc_page/views/tc_doc_setting_page_view.dart';
import 'package:im/app/routes/app_pages.dart' as app_pages;
import 'package:im/app/theme/app_colors.dart';
import 'package:im/common/permission/permission.dart';
import 'package:im/core/widgets/button/fade_button.dart';
import 'package:im/themes/custom_color.dart';
import 'package:im/utils/show_bottom_modal.dart';
import 'package:im/widgets/toast.dart';
import 'package:oktoast/oktoast.dart';

import '../document_api.dart';
import 'delete_sheet_widget.dart';

class OptionMenuResult {
  OptionMenuType type;
  bool result;
  String info;
  String fileId;

  OptionMenuResult(this.type,
      {this.result = false, this.info = '', this.fileId = ''});
}

class DocumentOptionMenuWidget extends StatefulWidget {
  const DocumentOptionMenuWidget(
      this.guildId, this.documentInfo, this.entryType,
      {Key key})
      : super(key: key);

  final String guildId;
  final DocItem documentInfo;
  final EntryType entryType;

  @override
  _DocumentOptionMenuWidgetState createState() =>
      _DocumentOptionMenuWidgetState();
}

class _DocumentOptionMenuWidgetState extends State<DocumentOptionMenuWidget> {
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
    return _bottomSheet(context, widget.documentInfo);
  }

  Widget _bottomSheet(BuildContext context, DocItem item) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.white),
        borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(8), topRight: Radius.circular(8)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          //const ShortDividerWidget(),
          //const SizedBox(height: 20),
          //分享
          _buildOption('分享'.tr, () {
            buttonShare(context, item);
          }),
          const Divider(height: 0.5, thickness: 0.5),
          //收藏/取消收藏
          _buildOption(collectStr(), () {
            buttonCollect(item);
          }),
          const Divider(height: 0.5, thickness: 0.5),

          ///仅文档创作者可以重命名文档
          if (item.isCreator)
            _buildOption('重命名'.tr, () {
              buttonRename(item);
            }),
          if (item.isCreator) const Divider(height: 0.5, thickness: 0.5),

          ///仅文档可编辑者可见，文档可阅读者不可见
          ..._buildNewCopyItem('生成副本'.tr, () {
            buttonNewCopy(item);
          }),

          if (item.isCreator)
            _buildOption('文档设置'.tr, () {
              buttonToSetting(item);
            }),
          if (item.isCreator) const Divider(height: 0.5, thickness: 0.5),

          _buildOption('查看文档信息'.tr, () {
            buttonViewDocumentInfo(item.fileId);
          }),
          const Divider(height: 0.5, thickness: 0.5),

          if (widget.entryType != EntryType.collect)
            _buildOption(
              getDeleteStr(),
              () {
                buttonDeleteRecount(item, widget.entryType);
              },
              style: Theme.of(context)
                  .textTheme
                  .bodyText2
                  .copyWith(color: destructiveRed),
            ),
          // const Divider(height: 0.5, thickness: 0.5),
          const Divider(height: 8, thickness: 8),

          _buildOption('取消'.tr, Get.back),
          SizedBox(height: Get.mediaQuery.padding.bottom),
        ],
      ),
    );
  }

  String getDeleteStr() {
    if (widget.entryType == EntryType.view) {
      return '删除记录'.tr;
    } else if (widget.entryType == EntryType.my) {
      return '删除'.tr;
    }
    return '';
  }

  String collectStr() {
    if (widget.documentInfo.isCollect()) {
      return '取消收藏'.tr;
    }
    return '收藏'.tr;
  }

  List<Widget> _buildNewCopyItem(String text, VoidCallback callback,
      {TextStyle style}) {
    final canCopy = widget.documentInfo.canCopy == true ||
        widget.documentInfo.role == TcDocGroupRole.edit ||
        widget.documentInfo.isCreator;
    return [
      if (canCopy)
        ValidPermission(
          permissions: [
            Permission.CREATE_DOCUMENT,
          ],
          builder: (isAllowed, isOwner) {
            if (isAllowed) {
              return _buildOption(text, callback, style: style);
            }
            return const SizedBox();
          },
        ),
      if (canCopy)
        ValidPermission(
          permissions: [
            Permission.CREATE_DOCUMENT,
          ],
          builder: (isAllowed, isOwner) {
            if (isAllowed) {
              return const Divider(height: 0.5, thickness: 0.5);
            }
            return const SizedBox();
          },
        ),
    ];
  }

  Widget _buildOption(String text, VoidCallback callback, {TextStyle style}) {
    style ??= Theme.of(context).textTheme.bodyText2;
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FadeButton(
        onTap: callback,
        child: Text(text, style: style),
      ),
    );
  }

  ///分享
  void buttonShare(BuildContext context, DocItem item) {
    Get.back();
    showShareActionPopup(
      context: context,
      docInfo: DocInfoItem.fromDocItem(item),
    );
  }

  ///收藏，取消收藏
  Future<void> buttonCollect(DocItem item) async {
    if (item.isCollect()) {
      final bool res = await DocumentApi.docCollectRemove(item.fileId);
      if (res == true) {
        showToast('已取消收藏'.tr);
        item.setCollect(false); //更改收藏属性
        DocListController.handleItemRemoveCollect(item);

        Get.back();
        return;
      }
    } else {
      final bool res = await DocumentApi.docCollectAdd(item.fileId);
      if (res == true) {
        Toast.iconToast(icon: ToastIcon.success, label: '已添加到我的收藏'.tr);
        item.setCollect(true); //更改收藏属性

        DocListController.handleItemAddCollect(item);

        Get.back();
        return;
      }
    }
    Get.back();
  }

  ///重命名
  Future<void> buttonRename(DocItem item) async {
    Get.back();
    // final res = await Get.bottomSheet<OptionMenuResult>(
    //     RenameSheetWidget(item.fileId, item.title));
    ///要求跟服务台昵称重命名效果一致
    final OptionMenuResult res = await showBottomModal(
      context,
      builder: (c, s) => RenameSheetWidget(item.fileId, item.title),
      backgroundColor: CustomColor(context).backgroundColor6,
      bottomInset: false,
    );

    if (res is OptionMenuResult && res.type == OptionMenuType.rename) {
      Toast.iconToast(icon: ToastIcon.success, label: '重命名成功'.tr);
      item.title = res.info;
      DocListController.handleItemUpdate(item);
      return;
    }
  }

  ///文档设置
  Future<void> buttonToSetting(DocItem item) async {
    Get.back();
    final RxBool canCopy = RxBool(item.canCopy);
    canCopy.listen((val) {
      item.canCopy = val;
    });
    final Rx<bool> tcDocCommentType = Rx<bool>(item.canReaderComment);
    tcDocCommentType.listen((type) {
      item.canReaderComment = type;
    });
    await Get.to(() => TcDocSettingPageView(
          fileId: item.fileId,
          type: item.type,
          canCopy: canCopy,
          canReaderComment: tcDocCommentType,
        ));
    await Future.delayed(500.milliseconds);
    canCopy.close();
    tcDocCommentType.close();
  }

  ///生成副本
  Future<void> buttonNewCopy(DocItem item) async {
    final optionMenuResult = OptionMenuResult(
      OptionMenuType.newCopy,
      result: true,
    );
    Get.back(result: optionMenuResult);
  }

  ///查看文档信息
  void buttonViewDocumentInfo(String fileId) {
    Get.back();
    Get.toNamed(app_pages.Routes.DOCUMENT_INFO, arguments: fileId);
  }

  ///删除记录
  Future<void> buttonDeleteRecount(DocItem item, EntryType entryType) async {
    Get.back();
    final res = await Get.bottomSheet<OptionMenuResult>(
        DeleteSheetWidget(item, entryType));
    if (res is OptionMenuResult) {
      if (res.type == OptionMenuType.delete) {
        Toast.iconToast(icon: ToastIcon.success, label: res.info);
        DocListController.handleItemDel(item.fileId);
      } else if (res.type == OptionMenuType.deleteRecord) {
        Toast.iconToast(icon: ToastIcon.success, label: res.info);
        DocListController.handleItemDel(item.fileId, isRecord: true);
      }
    }
  }
}
