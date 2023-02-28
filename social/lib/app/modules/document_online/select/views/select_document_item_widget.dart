import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/app/modules/document_online/entity/doc_item.dart';
import 'package:im/core/widgets/button/fade_button.dart';

class SelectDocumentItemWidget extends StatelessWidget {
  final String guildId;
  final DocItem item;

  const SelectDocumentItemWidget(this.guildId, this.item, {Key key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FadeButton(
      onTap: () {
        Get.back(result: item);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            dense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            leading: item.getDocIcon(),
            minLeadingWidth: 32,
            horizontalTitleGap: 12,
            minVerticalPadding: 12,
            title: item.getDocTitle(),
            subtitle: item.getDocSubTitle(),
          ),
          const Divider(
            thickness: 0.5,
            indent: 60,
          )
        ],
      ),
    );
  }
}
