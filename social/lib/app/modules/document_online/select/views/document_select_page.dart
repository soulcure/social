import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:im/app/modules/document_online/document_enum_defined.dart';
import 'package:im/app/modules/document_online/entity/create_doc_item.dart';
import 'package:im/app/modules/document_online/entity/doc_info_item.dart';
import 'package:im/app/modules/document_online/entity/doc_item.dart';
import 'package:im/app/modules/document_online/select/controllers/document_select_controller.dart';
import 'package:im/app/modules/document_online/select/views/select_document_item_widget.dart';
import 'package:im/app/modules/document_online/views/create_doc_bottom_sheet.dart';
import 'package:im/app/modules/document_online/views/create_sheet_widget.dart';
import 'package:im/app/modules/document_online/widget/loading_progress.dart';
import 'package:im/app/modules/tc_doc_page/controllers/tc_doc_page_controller.dart';
import 'package:im/app/theme/app_theme.dart';
import 'package:im/common/permission/permission.dart';
import 'package:im/core/widgets/button/fade_button.dart';
import 'package:im/pages/search/widgets/search_input_box.dart';
import 'package:im/svg_icons.dart';
import 'package:im/themes/const.dart';
import 'package:im/themes/custom_color.dart';
import 'package:im/utils/show_bottom_modal.dart';
import 'package:im/utils/tc_doc_utils.dart';
import 'package:im/widgets/app_bar/appbar_builder.dart';
import 'package:im/widgets/svg_tip_widget.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:tuple/tuple.dart';

import '../../../../../icon_font.dart';
import '../../document_api.dart';

class DocumentSelectPage extends GetView<DocumentSelectController> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: FbAppBar.custom('选择文档'.tr),
      body: Container(
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSearch(),
            ..._buildCreate(context),
            _buildDocumentTitle(),
            Expanded(
              child: _body(),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildCreate(BuildContext context) {
    final createWidget = GetBuilder<DocumentSelectController>(
      builder: (c) {
        if (c.isSearch) {
          return const SizedBox();
        }
        return _buildCreateDocument(context);
      },
    );
    final dividerWidget = GetBuilder<DocumentSelectController>(
      builder: (c) {
        if (c.isSearch) {
          return const SizedBox();
        }
        return _buildCreateDivider(context);
      },
    );
    return [createWidget, dividerWidget];
  }

  Widget _buildCreateDocument(BuildContext context) {
    return ValidPermission(
      permissions: [
        Permission.CREATE_DOCUMENT,
      ],
      builder: (isAllowed, isOwner) {
        if (isAllowed) {
          return _createDocumentWidget(context);
        }
        return const SizedBox();
      },
    );
  }

  Widget _buildCreateDivider(BuildContext context) {
    return ValidPermission(
      permissions: [
        Permission.CREATE_DOCUMENT,
      ],
      builder: (isAllowed, isOwner) {
        if (isAllowed) {
          return const Divider(height: 10, thickness: 10);
        }
        return const SizedBox();
      },
    );
  }

  Widget _createDocumentWidget(BuildContext context) {
    final style =
        appThemeData.textTheme.bodyText2.copyWith(height: 1.4); //text color
    return FadeButton(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Icon(
            IconFont.buffTianjia,
            color: style.color,
            size: 20,
          ),
          const SizedBox(width: 12),
          Text(
            '新建文档'.tr,
            style: style,
          ),
        ],
      ),
      onTap: () {
        _createDocument(context);
      },
    );
  }

  Widget _buildDocumentTitle() {
    final Color color = appThemeData.textTheme.headline2.color; //text color
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 16, bottom: 4),
      child: Text(
        '我的文档'.tr,
        style: TextStyle(
          color: color,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }

  Widget _buildSearch() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      height: 56,
      child: GetBuilder<DocumentSelectController>(
        builder: (c) {
          return SearchInputBox(
            searchInputModel: c.searchInputModel,
            inputController: c.textEditingController,
            hintText: '搜索文档标题'.tr,
            borderRadius: 4,
            height: 36,
            autoFocus: false,
            focusNode: c.focusNode,
          );
        },
      ),
    );
  }

  Widget _body() {
    return GetBuilder<DocumentSelectController>(
      builder: (c) {
        switch (c.loadingStatus()) {
          case LoadingStatus.noData:
            return _emptyList(); //暂无数据
          case LoadingStatus.loading:
            return _initStatus(); //请求中
          case LoadingStatus.error:
            return _emptyError(c); //请求发生错误
          default:
            return _buildList(c);
        }
      },
    );
  }

  /// 请求错误
  Widget _emptyError(DocumentSelectController c) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 100),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgTipWidget(
              svgName: SvgIcons.noNetState,
              text: '加载失败'.tr,
            ),
            const SizedBox(height: 20),
            SizedBox(
                width: 180,
                height: 36,
                child: ElevatedButton(
                  onPressed: () {
                    c.reLoading();
                  },
                  child: Text('重新加载'.tr),
                )),
          ],
        ),
      ),
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
  Widget _buildList(DocumentSelectController c) {
    return SmartRefresher(
      enablePullDown: false,
      enablePullUp: true,
      controller: c.refreshController,
      onLoading: c.onLoading,
      footer: CustomFooter(
        height: 60 + Get.mediaQuery.padding.bottom,
        builder: (context, mode) {
          if (mode == LoadStatus.idle) {
            return sizedBox;
          } else if (mode == LoadStatus.loading) {
            return const CupertinoActivityIndicator.partiallyRevealed(
                radius: 8);
          } else if (mode == LoadStatus.failed) {
            return const Icon(Icons.error, size: 20, color: Colors.grey);
          } else if (mode == LoadStatus.canLoading) {
            return sizedBox;
          } else if (mode == LoadStatus.noMore) {
            return _noMoreWidget();
          } else {
            return sizedBox;
          }
        },
      ),
      child: _contentWidget(c),
    );
  }

  Widget _noMoreWidget() {
    return Container(
      height: 60,
      alignment: Alignment.center,
      child: Text("- 腾讯文档提供技术支持 -".tr,
          style: TextStyle(
            color: appThemeData.dividerColor.withOpacity(0.75),
            fontSize: 12,
          )),
    );
  }

  Widget _contentWidget(DocumentSelectController c) {
    return CustomScrollView(
      slivers: [
        GetBuilder<DocumentSelectController>(
          builder: (c) {
            if (c.docList.isNotEmpty) {
              return _buildSliverList(c, c.docList);
            } else {
              return emptyAdapter();
            }
          },
        ),
      ],
    );
  }

  SliverList _buildSliverList(DocumentSelectController c, List<DocItem> list) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) => SelectDocumentItemWidget(c.guildId, list[index]),
        childCount: list.length,
      ),
    );
  }

  SliverToBoxAdapter emptyAdapter() {
    return const SliverToBoxAdapter(
      child: SizedBox(),
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
    BuildContext context,
    String guildId,
    String type,
  ) async {
    final CreateDocResult res = await showBottomModal<CreateDocResult>(context,
        bottomInset: false,
        backgroundColor: CustomColor(context).backgroundColor6,
        builder: (c, _) => CreateSheetWidget(guildId, type));
    if (res != null) {
      LoadingProgress.start(
        context,
        widget: LoadingProgress.loadingWidget(),
      );

      final CreateDocItem doc = await DocumentApi.docCreate(
        res.guildId,
        res.type,
        title: res.title,
      );

      LoadingProgress.stop(context);

      if (doc != null) {
        final DocItem item = DocItem.fromCreate(doc);
        controller.createItem(item);
        final res = await TcDocUtils.toDocPage(doc.url, fromSelectPage: true);

        if (res is List<Tuple2<TcDocPageReturnType, DocInfoItem>>) {
          controller.handleResult(res);
        } else if (res is DocInfoItem) {
          Get.back(result: DocItem.fromInfo(res));
        }
      }
    }
  }
}
