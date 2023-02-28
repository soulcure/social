import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:im/app/modules/document_online/search/controllers/document_search_controller.dart';
import 'package:im/app/modules/document_online/search/tab/doc_search_tab_bar.dart';
import 'package:im/core/widgets/button/fade_button.dart';
import 'package:im/pages/search/widgets/search_input_box.dart';

class DocumentSearchPage extends GetView<DocumentSearchController> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        titleSpacing: 0,
        title: _buildSearch(),
      ),
      body: Container(
        color: Colors.white,
        child: _buildTabBar(),
      ),
    );
  }

  Widget _buildSearch() {
    return Row(
      children: [
        const SizedBox(width: 16),
        Expanded(
          child: GetBuilder<DocumentSearchController>(
            builder: (c) {
              return SizedBox(
                height: 36,
                child: SearchInputBox(
                  searchInputModel: c.searchInputModel,
                  inputController: c.textEditingController,
                  hintText: '搜索文档标题'.tr,
                  borderRadius: 4,
                  //autoFocus: false,
                  focusNode: c.focusNode,
                  useFlutter: true,
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 16),
        FadeButton(
          onTap: Get.back,
          child: Text(
            '取消'.tr,
            style: TextStyle(
              fontSize: 16,
              color: Get.theme.primaryColor,
            ),
          ),
        ),
        const SizedBox(width: 12),
      ],
    );
  }

  Widget _buildTabBar() {
    return DocSearchTabBar(
      guildId: controller.guildId,
      initialIndex: controller.initialIndex,
    );
  }
}
