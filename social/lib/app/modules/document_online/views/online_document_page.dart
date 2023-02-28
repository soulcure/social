import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:im/app/modules/document_online/controllers/online_document_controller.dart';
import 'package:im/app/modules/document_online/document_enum_defined.dart';
import 'package:im/app/modules/document_online/entity/create_doc_item.dart';
import 'package:im/app/modules/document_online/entity/doc_info_item.dart';
import 'package:im/app/modules/document_online/entity/doc_item.dart';
import 'package:im/app/modules/document_online/sub/doc_list_controller.dart';
import 'package:im/app/modules/document_online/views/create_sheet_widget.dart';
import 'package:im/app/modules/document_online/widget/loading_progress.dart';
import 'package:im/app/modules/tc_doc_page/controllers/tc_doc_page_controller.dart';
import 'package:im/app/theme/app_colors.dart';
import 'package:im/app/theme/app_theme.dart';
import 'package:im/common/permission/permission.dart';
import 'package:im/core/widgets/button/fade_button.dart';
import 'package:im/icon_font.dart';
import 'package:im/themes/custom_color.dart';
import 'package:im/utils/show_bottom_modal.dart';
import 'package:im/utils/tc_doc_utils.dart';
import 'package:im/widgets/app_bar/appbar_builder.dart';
import 'package:tuple/tuple.dart';

import '../../../../routes.dart';
import '../document_api.dart';
import 'create_doc_bottom_sheet.dart';
import 'doc_tab_bar.dart';

class OnlineDocumentPage extends GetView<OnlineDocumentController> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: FbAppBar.custom('在线文档'.tr),
      body: Container(
        color: Colors.white,
        child: Column(children: [
          _buildSearchInput(context),
          Expanded(child: _buildTabBar()),
        ]),
      ),
      floatingActionButton: _buildCreateButton(context),
    );
  }

  Widget _buildCreateButton(BuildContext context) {
    return ValidPermission(
      permissions: [
        Permission.CREATE_DOCUMENT,
      ],
      builder: (isAllowed, isOwner) {
        if (isAllowed) {
          return Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: appThemeData.primaryColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: appThemeData.primaryColor.withOpacity(0.3),
                  offset: const Offset(0, 2),
                  blurRadius: 8,
                ),
              ],
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              onPressed: () {
                _createDocument(context);
              },
              icon: const Icon(
                IconFont.buffTianjia,
                size: 24,
                color: Colors.white,
              ),
            ),
          );
        }
        return const SizedBox();
      },
    );
  }

  Widget _buildSearchInput(BuildContext context) {
    final Color color =
        Theme.of(context).textTheme.bodyText2.color.withOpacity(0.4);
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 4, right: 16, bottom: 8),
      child: SizedBox(
        width: double.infinity,
        height: 36,
        child: Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(5),
          ),
          child: FadeButton(
            onTap: () {
              Routes.pushSearchDocumentPage(
                  controller.guildId, controller.curIndex);
            },
            child: Row(
              children: [
                const SizedBox(width: 12),
                Icon(
                  IconFont.buffCommonSearch,
                  size: 18,
                  color: color,
                ),
                const SizedBox(width: 5.5),
                Text(
                  '搜索文档标题'.tr,
                  style: TextStyle(color: color, fontWeight: FontWeight.w400),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return DocTabBar(
      guildId: controller.guildId,
      selectTab: controller.tabChoose,
    );
  }

  Future<void> _createDocument(BuildContext context) async {
    final DocType res =
        await Get.bottomSheet<DocType>(const CreateDocBottomSheet());
    if (res != null) {
      final String guildId = controller.guildId;
      final String type = DocTypeExtension.name(res);
      await buttonCreate(context, guildId, type);
    }
  }

  ///新建文档
  Future<void> buttonCreate(
      BuildContext context, String guildId, String type) async {
    // final CreateDocResult res = await Get.bottomSheet<CreateDocResult>(
    //     CreateSheetWidget(guildId, type));
    ///要求跟服务台昵称重命名效果一致
    final CreateDocResult res = await showBottomModal(
      context,
      routeSettings: const RouteSettings(name: guildNicknameSettingRoute),
      builder: (c, s) => CreateSheetWidget(guildId, type),
      backgroundColor: CustomColor(context).backgroundColor6,
      bottomInset: false,
    );

    if (res != null) {
      LoadingProgress.start(
        context,
        widget: LoadingProgress.loadingWidget(message: '创建中'.tr),
      );

      final CreateDocItem doc = await DocumentApi.docCreate(
        res.guildId,
        res.type,
        title: res.title,
      );

      LoadingProgress.stop(context);

      if (doc != null) {
        final DocItem item = DocItem.fromCreate(doc);
        DocListController.handleItemAdd(item, addView: true);
        final res = await TcDocUtils.toDocPage(doc.url);

        if (res is List<Tuple2<TcDocPageReturnType, DocInfoItem>>) {
          DocListController.handleResult(res);
        }
      }
    }
  }
}
