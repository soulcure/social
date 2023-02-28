import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:im/app/modules/document_online/document_enum_defined.dart';
import 'package:im/app/modules/document_online/entity/doc_item.dart';
import 'package:im/app/modules/document_online/search/controllers/document_search_controller.dart';
import 'package:im/app/theme/app_theme.dart';
import 'package:im/themes/const.dart';
import 'package:im/widgets/svg_tip_widget.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

import '../../../../../svg_icons.dart';
import 'doc_search_list_controller.dart';
import 'document_search_item_widget.dart';

class DocSearchListPage extends StatefulWidget {
  final String guildId;
  final EntryType entryType;

  const DocSearchListPage(this.guildId, this.entryType, {Key key})
      : assert(guildId != null, 'guildId is null'),
        super(key: key);

  @override
  State<DocSearchListPage> createState() => _DocSearchListPageState();
}

class _DocSearchListPageState extends State<DocSearchListPage> {
  ScrollController scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    scrollController.addListener(() {
      FocusManager.instance.primaryFocus.unfocus();
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<DocSearchListController>(
      init: DocSearchListController(widget.entryType),
      tag: EntryTypeExtension.name(widget.entryType),
      builder: (c) {
        switch (c.loadingStatus) {
          case LoadingStatus.noData:
            return _emptyList(); //暂无数据
          case LoadingStatus.loading:
            return _initStatus(); //请求中
          case LoadingStatus.error:
            return _emptyError(c); //请求发生错误
          case LoadingStatus.complete:
            return _buildList(c); //加载完成
          default:
            return _searchStart(); //搜索文档
        }
      },
    );
  }

  /// 加载中
  Widget _initStatus() {
    return ListView.builder(
      itemCount: 20,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) => ListTile(
        leading: _breatheIcon(),
        isThreeLine: true,
        visualDensity: const VisualDensity(vertical: 4),
        minLeadingWidth: 4,
        title: _breatheTitle(),
        subtitle: _breatheTitle(),
      ),
    );
  }

  Widget _breatheIcon() {
    final color = Get.theme.dividerColor.withOpacity(0.1);
    return Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(6),
        ));
  }

  Widget _breatheTitle() {
    final color = Get.theme.dividerColor.withOpacity(0.1);
    return Row(
      children: [
        Container(
          width: Get.width * 0.6 * (Random().nextInt(80) + 20) / 100,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
      ],
    );
  }

  /// 请求错误
  Widget _emptyError(DocSearchListController c) {
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

  /// 搜索文档
  Widget _searchStart() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 100),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset("assets/images/empty_doc.png", width: 72, height: 72),
            const SizedBox(height: 20),
            Text(
              '搜索文档'.tr,
              style: TextStyle(
                  color: Get.theme.dividerColor.withOpacity(0.5), fontSize: 15),
            ),
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

  ///有成员
  Widget _buildList(DocSearchListController c) {
    return SmartRefresher(
      enablePullDown: false,
      enablePullUp: true,
      controller: c.refreshController,
      onLoading: c.onLoading,
      footer: CustomFooter(
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
      height: 60 + Get.mediaQuery.padding.bottom,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 23),
            child: Text("- 腾讯文档提供技术支持 -".tr,
                style: TextStyle(
                  color: appThemeData.dividerColor.withOpacity(0.75),
                  fontSize: 12,
                )),
          ),
          SizedBox(
            height: Get.mediaQuery.padding.bottom,
          ),
        ],
      ),
    );
  }

  Widget _contentWidget(DocSearchListController c) {
    return _contentMyAndCollectWidget(c);
  }

  Widget _contentMyAndCollectWidget(DocSearchListController c) {
    return CustomScrollView(
      controller: scrollController,
      slivers: [
        GetBuilder<DocSearchListController>(
          tag: EntryTypeExtension.name(widget.entryType),
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

  SliverList _buildSliverList(DocSearchListController c, List<DocItem> list) {
    final String keyword = DocumentSearchController.to().keyword;
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) =>
            DocumentSearchItemWidget(widget.guildId, list[index], keyword, c),
        childCount: list.length,
      ),
    );
  }

  SliverToBoxAdapter emptyAdapter() {
    return const SliverToBoxAdapter(
      child: SizedBox(),
    );
  }
}
