import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:im/app/modules/document_online/entity/doc_info_item.dart';
import 'package:im/app/modules/document_online/entity/doc_item.dart';
import 'package:im/app/modules/document_online/sub/doc_list_controller.dart';
import 'package:im/app/modules/tc_doc_page/controllers/tc_doc_page_controller.dart';
import 'package:im/utils/tc_doc_utils.dart';
import 'package:tuple/tuple.dart';

import 'doc_search_list_controller.dart';

class DocumentSearchItemWidget extends StatelessWidget {
  final String guildId;
  final DocItem item;
  final String keyword;
  final DocSearchListController controller;

  const DocumentSearchItemWidget(
      this.guildId, this.item, this.keyword, this.controller,
      {Key key})
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
          title: item.getHighlightTitle(keyword),
          subtitle: item.getDocSubTitle(),
          onTap: () async {
            final res = await TcDocUtils.toDocPage(item.url);
            if (res is List<Tuple2<TcDocPageReturnType, DocInfoItem>>) {
              ///文档搜索页面
              DocSearchListController.handleResult(res);

              ///服务器文档页面
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
}
