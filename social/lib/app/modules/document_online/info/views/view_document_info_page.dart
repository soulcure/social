import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:im/app/modules/document_online/document_enum_defined.dart';
import 'package:im/app/modules/document_online/entity/doc_info_item.dart';
import 'package:im/app/modules/document_online/info/controllers/view_document_info_controller.dart';
import 'package:im/common/extension/string_extension.dart';
import 'package:im/pages/home/view/text_chat/items/document_item.dart';
import 'package:im/widgets/app_bar/appbar_builder.dart';

class ViewDocumentInfoPage extends GetView<ViewDocumentInfoController> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: FbAppBar.custom('文档信息'.tr),
      body: _body(),
    );
  }

  Widget _body() {
    return GetBuilder<ViewDocumentInfoController>(
      builder: (c) {
        switch (c.loadingStatus) {
          case LoadingStatus.noData:
          case LoadingStatus.error:
            return _emptyList(); //暂无数据
          case LoadingStatus.loading:
            return _initStatus(); //请求中
          default:
            return _buildList(c.docInfoItem);
        }
      },
    );
  }

  /// 没有文档
  Widget _emptyList() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 100),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset("assets/images/empty_doc.png", width: 72, height: 72),
            const SizedBox(height: 20),
            Text(
              '暂无文档'.tr,
              style: TextStyle(
                  color: Get.theme.dividerColor.withOpacity(0.5), fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }

  /// 加载中
  Widget _initStatus() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.only(bottom: 100),
        child: CircularProgressIndicator.adaptive(),
      ),
    );
  }

  ///有成员
  Widget _buildList(DocInfoItem docItem) {
    const style = TextStyle(
      color: Color(0XFF202121),
      fontWeight: FontWeight.w600,
      fontSize: 18,
    );
    return Column(
      children: [
        const SizedBox(height: 48),
        DocumentItem.getDocumentIcon(
          docItem.type,
          width: 72,
          height: 72,
        ),
        const SizedBox(height: 15.5),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 80),
          child: Text(
            docItem.title,
            style: style,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(height: 48),
        const Divider(height: 10, thickness: 10),
        _buildRow('类型'.tr, DocTypeExtension.nameDesc(docItem.type)),
        const Divider(height: 10, thickness: 0.5),
        _buildRow('所有者'.tr, docItem.getOwnerNickName()),
        const Divider(height: 10, thickness: 10),
        if (docItem.hasUpdate())
          _buildRow('最近编辑'.tr, docItem.getUpdateTime(),
              nickname: docItem.getUpdateNickName()),
        if (docItem.hasUpdate()) const Divider(height: 10, thickness: 0.5),
        if (docItem.hasView())
          _buildRow('最近查看'.tr, docItem.getViewTime(),
              nickname: docItem.getViewNickName()),
        if (docItem.hasView()) const Divider(height: 10, thickness: 0.5),
        _buildRow('创建时间'.tr, docItem.getCreateTime()),
        if (docItem.hasUpdate() || docItem.hasView()) const Divider(),
      ],
    );
  }

  Widget _buildRow(String title, String content, {String nickname}) {
    final _titleStyle = Get.textTheme.bodyText2.copyWith(fontSize: 16);
    final _contentStyle =
        TextStyle(color: Get.textTheme.headline2.color, fontSize: 15);

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Center(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                title,
                style: _titleStyle,
                maxLines: 1,
              ),
              const Spacer(),
              Text(
                content,
                style: _contentStyle,
                maxLines: 1,
              ),
              if (nickname.hasValue)
                Text(
                  "，$nickname",
                  style: _contentStyle,
                  maxLines: 1,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
