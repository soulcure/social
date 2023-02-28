import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/app/modules/document_online/entity/doc_item.dart';
import 'package:im/app/modules/tc_doc_add_group_page/entities/tc_doc_group.dart';
import 'package:im/app/theme/app_theme.dart';
import 'package:im/common/extension/string_extension.dart';
import 'package:im/icon_font.dart';
import 'package:im/themes/const.dart';

/// * 圈子详情的腾讯文档
class CircleDetailDocView extends StatelessWidget {
  final DocItem docItem;
  final VoidCallback onTap;

  const CircleDetailDocView({this.docItem, this.onTap, Key key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (docItem != null) {
      final child = Container(
        decoration: BoxDecoration(
          color: appThemeData.scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(6),
        ),
        width: double.infinity,
        height: docItem.fileId.hasValue ? 96 : 64,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Stack(
          children: [
            if (docItem.fileId.hasValue)
              Column(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          docItem.getDocIcon(),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              docItem.title ?? '',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: appThemeData.textTheme.bodyText1
                                  .copyWith(fontSize: 16, height: 1.25),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: Divider(
                      height: .5,
                      color: appThemeData.dividerColor,
                    ),
                  ),
                  Container(
                    height: 32,
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.only(left: 12),
                    child: Text(
                      docItem.role == TcDocGroupRole.edit ? '可编辑'.tr : '可阅读'.tr,
                      style: TextStyle(
                        color: appThemeData.disabledColor,
                        fontSize: 12,
                      ),
                    ),
                  )
                ],
              )
            else
              Container(
                padding: const EdgeInsets.only(left: 12),
                alignment: Alignment.centerLeft,
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: appThemeData.backgroundColor,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      child: Icon(IconFont.buffDocDel,
                          size: 24,
                          color: appThemeData.disabledColor.withOpacity(0.4)),
                    ),
                    sizeWidth12,
                    Text(
                      '文档已被删除'.tr,
                      style: appThemeData.textTheme.bodyText1.copyWith(
                          fontSize: 14, color: appThemeData.disabledColor),
                    ),
                  ],
                ),
              ),
          ],
        ),
      );
      if (docItem.fileId.hasValue)
        return GestureDetector(
          onTap: onTap,
          child: child,
        );
      else
        return child;
    } else
      return const SizedBox();
  }
}
