import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/app/modules/document_online/entity/doc_info_item.dart';
import 'package:im/app/modules/document_online/entity/doc_item.dart';
import 'package:im/app/modules/document_online/info/controllers/doc_link_preview_controller.dart';
import 'package:im/app/modules/tc_doc_page/controllers/tc_doc_page_controller.dart';
import 'package:im/app/theme/app_theme.dart';
import 'package:im/common/extension/string_extension.dart';
import 'package:im/core/widgets/button/fade_button.dart';
import 'package:im/icon_font.dart';
import 'package:im/pages/home/view/text_chat/items/document_item.dart';
import 'package:im/utils/tc_doc_utils.dart';
import 'package:oktoast/oktoast.dart';
import 'package:tuple/tuple.dart';

import '../../../../../loggers.dart';
import '../../document_api.dart';

class DocLinkPreview extends StatelessWidget {
  final String url;
  final String fileId;

  const DocLinkPreview(this.url, this.fileId, {Key key}) : super(key: key);

  Future<DocInfoItem> docInfo() async {
    return DocumentApi.docInfo(fileId, checkPermission: true);
  }

  @override
  Widget build(BuildContext context) {
    return FadeButton(
      alignment: Alignment.centerLeft,
      onTap: () {
        _openDocument(url);
      },
      child: body(),
    );
  }

  Widget body() {
    return GetBuilder<DocLinkPreviewController>(
      init: DocLinkPreviewController(fileId),
      tag: fileId,
      autoRemove: false,
      builder: (c) {
        ///文档是否被删除
        final bool isDel =
            c.docInfoItem != null && c.docInfoItem.fileId == null;
        if (c.docInfoItem != null) {
          return _buildDocument(c.docInfoItem, isDel);
        } else {
          return Container(
            width: 280,
            height: 56,
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(6)),
              color: Colors.white,
            ),
          );
        }
      },
    );
  }

  Widget _buildDocument(DocInfoItem item, bool isDel) {
    double height = 64;
    if (!isDel) {
      height = height + 0.5 + 32;
    }
    return Container(
      width: 280,
      height: height,
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(6)),
        color: Colors.white,
      ),
      child: _docInfo(item, isDel),
    );
  }

  Widget _docInfo(DocInfoItem item, bool isDel) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 64,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                ..._docIcon(item, isDel),
                Flexible(
                  child: Text(
                    item.getTitle(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      color: isDel
                          ? Get.theme.disabledColor
                          : Get.textTheme.headline1.color.withOpacity(1),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (!isDel)
          const Padding(
            padding: EdgeInsets.only(left: 12),
            child: Divider(),
          ),
        if (!isDel) _docStatus(isDel, item),
      ],
    );
  }

  List<Widget> _docIcon(DocInfoItem item, bool isDel) {
    if (isDel) {
      return [
        Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
              color: appThemeData.scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(4)),
          child: Icon(IconFont.buffDocDel,
              color: Get.theme.disabledColor, size: 20),
        ),
        const SizedBox(width: 8),
      ];
    }
    return [
      DocumentItem.getDocumentIcon(
        item.type,
        width: 32,
        height: 32,
      ),
      const SizedBox(width: 8),
    ];
  }

  Widget _docStatus(bool isDel, DocInfoItem item) {
    if (isDel || item == null) {
      return const SizedBox();
    }
    return SizedBox(
      height: 32,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Align(
          alignment: Alignment.centerLeft,
          child: item.docStatus(),
        ),
      ),
    );
  }

  Future<void> _openDocument(String url) async {
    try {
      final DocLinkPreviewController c = Get.find(tag: fileId);
      if (c.docInfoItem != null && c.docInfoItem.fileId == null) {
        showToast('文档已被删除'.tr);
        return;
      }
    } catch (e) {
      logger.warning(e.toString());
    }

    final docList = await TcDocUtils.toDocPage(url);
    if (docList is List<Tuple2<TcDocPageReturnType, DocInfoItem>>) {
      if (docList == null || docList.isEmpty) return;

      docList.forEach((res) {
        final TcDocPageReturnType type = res.item1;
        final DocItem item = DocItem.fromInfo(res.item2);

        switch (type) {
          case TcDocPageReturnType.update:
            updateData(fileId, item);
            break;
          default:
            break;
        }
      });
    }
  }

  ///更新数据
  void updateData(String tag, DocItem src) {
    if (src == null) return;

    DocLinkPreviewController c;

    try {
      c = Get.find(tag: tag);
    } catch (e) {
      print(e);
    }

    if (c != null && src.title.hasValue && src.title != c.docInfoItem.title) {
      c.docInfoItem.title = src.title;
      c.update();
    }
  }
}
