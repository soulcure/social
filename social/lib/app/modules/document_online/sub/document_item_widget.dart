import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/app/modules/document_online/controllers/online_document_controller.dart';
import 'package:im/app/modules/document_online/document_api.dart';
import 'package:im/app/modules/document_online/entity/create_doc_item.dart';
import 'package:im/app/modules/document_online/entity/doc_info_item.dart';
import 'package:im/app/modules/document_online/entity/doc_item.dart';
import 'package:im/app/modules/document_online/sub/document_option_menu_widget.dart';
import 'package:im/app/modules/document_online/widget/loading_progress.dart';
import 'package:im/app/modules/tc_doc_page/controllers/tc_doc_page_controller.dart';
import 'package:im/utils/tc_doc_utils.dart';
import 'package:im/widgets/toast.dart';
import 'package:tuple/tuple.dart';

import '../../../../icon_font.dart';
import '../document_enum_defined.dart';
import 'doc_list_controller.dart';

class DocumentItemWidget extends StatelessWidget {
  final String guildId;
  final DocItem item;
  final DocListController controller;

  const DocumentItemWidget(this.guildId, this.item, this.controller, {Key key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          dense: true,
          contentPadding: const EdgeInsets.only(left: 16, right: 6),
          leading: item.getDocIcon(),
          minLeadingWidth: 32,
          horizontalTitleGap: 12,
          minVerticalPadding: 12,
          title: item.getDocTitle(),
          subtitle: item.getDocSubTitle(entryType: controller.entryType),
          trailing: InkWell(
            child: const Padding(
              padding:
                  EdgeInsets.only(left: 10, top: 10, right: 10, bottom: 10),
              child: Icon(
                IconFont.buffMoreHorizontal,
                size: 20,
              ),
            ),
            onTap: () {
              _optionDocument(context, item);
            },
          ),
          onTap: () async {
            final res = await TcDocUtils.toDocPage(item.url);
            if (res is List<Tuple2<TcDocPageReturnType, DocInfoItem>>) {
              DocListController.handleResult(res);
            }
          },
        ),
        const Divider(
          thickness: 0.5,
          indent: 60,
        )
      ],
    );
  }

  Future<void> _optionDocument(BuildContext context, DocItem item) async {
    final res = await Get.bottomSheet<OptionMenuResult>(
        DocumentOptionMenuWidget(guildId, item, controller.entryType));
    if (res is OptionMenuResult) {
      switch (res.type) {
        case OptionMenuType.newCopy:
          LoadingProgress.start(
            context,
            widget: LoadingProgress.loadingWidget(),
          );

          final CreateDocItem res = await DocumentApi.docCopy(item.fileId);
          if (res != null) {
            final DocItem item = DocItem.fromCreate(res);
            DocListController.handleItemAdd(item);
            LoadingProgress.stop(context);

            Toast.iconToast(icon: ToastIcon.success, label: '副本创建成功'.tr);

            ///如果tab在最近查看页面，就切换到我的文档页面
            if (OnlineDocumentController.to().entryType == EntryType.view) {
              OnlineDocumentController.to().selectTab(EntryType.my);
            }

            ///await TcDocUtils.toDocPage(res.url);
            return;
          }

          LoadingProgress.stop(context);
          break;
        default:
          break;
      }
    }
  }
}
