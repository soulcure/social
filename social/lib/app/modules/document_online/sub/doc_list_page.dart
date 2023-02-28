import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:im/app/modules/document_online/document_enum_defined.dart';
import 'package:im/app/modules/document_online/entity/doc_item.dart';
import 'package:im/app/theme/app_theme.dart';
import 'package:im/themes/const.dart';
import 'package:im/widgets/svg_tip_widget.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

import '../../../../svg_icons.dart';
import 'breathe_widget.dart';
import 'doc_list_controller.dart';
import 'document_item_widget.dart';

class DocListPage extends StatefulWidget {
  final String guildId;
  final EntryType entryType;

  const DocListPage(this.guildId, this.entryType, {Key key})
      : assert(guildId != null, 'guildId is null'),
        super(key: key);

  @override
  State<DocListPage> createState() => _DocListPageState();
}

class _DocListPageState extends State<DocListPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return GetBuilder<DocListController>(
      init: DocListController(widget.entryType),
      tag: EntryTypeExtension.name(widget.entryType),
      autoRemove: false,
      didChangeDependencies: (state) {
        state.controller.onData();
      },
      builder: (c) {
        switch (c.loadingStatus) {
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

  /// 加载中
  Widget _initStatus() {
    return ListView.builder(
      itemCount: 20,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) => ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
        leading: _breatheIcon(),
        minLeadingWidth: 4,
        isThreeLine: true,
        visualDensity: const VisualDensity(vertical: 4),
        title: _breatheTitle(),
        subtitle: _breatheTitle(),
      ),
    );
  }

  Widget _breatheIcon() {
    final color = Get.theme.iconTheme.color;
    final widget = Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(6),
        ));
    return BreatheWidget(widget);
  }

  Widget _breatheTitle() {
    final color = Get.theme.iconTheme.color;
    final widget = Row(
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: BreatheWidget(widget),
    );
  }

  /// 请求错误
  Widget _emptyError(DocListController c) {
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

  ///有成员
  Widget _buildList(DocListController c) {
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
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 22),
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

  Widget _contentWidget(DocListController c) {
    if (widget.entryType == EntryType.view) {
      return _contentRecentWidget(c);
    } else {
      return _contentMyAndCollectWidget(c);
    }
  }

  Widget _contentRecentWidget(DocListController c) {
    const style = TextStyle(fontSize: 14, color: Color(0xFF8D93A6));
    return CustomScrollView(
      slivers: [
        GetBuilder<DocListController>(
          tag: EntryTypeExtension.name(widget.entryType),
          builder: (c) {
            if (c.docToday.isNotEmpty) {
              return SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(left: 16, top: 16, bottom: 4),
                  child: Text('今天'.tr, style: style),
                ),
              );
            } else {
              return emptyAdapter();
            }
          },
        ),
        GetBuilder<DocListController>(
          tag: EntryTypeExtension.name(widget.entryType),
          builder: (c) {
            if (c.docToday.isNotEmpty) {
              return _buildSliverList(c, c.docToday);
            } else {
              return emptyAdapter();
            }
          },
        ),
        GetBuilder<DocListController>(
          tag: EntryTypeExtension.name(widget.entryType),
          builder: (c) {
            if (c.docThisWeek.isNotEmpty) {
              return SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(left: 16, top: 16, bottom: 4),
                  child: Text('一周内'.tr, style: style),
                ),
              );
            } else {
              return emptyAdapter();
            }
          },
        ),
        GetBuilder<DocListController>(
          tag: EntryTypeExtension.name(widget.entryType),
          builder: (c) {
            if (c.docThisWeek.isNotEmpty) {
              return _buildSliverList(c, c.docThisWeek);
            } else {
              return emptyAdapter();
            }
          },
        ),
        GetBuilder<DocListController>(
          tag: EntryTypeExtension.name(widget.entryType),
          builder: (c) {
            if (c.docEarlier.isNotEmpty) {
              return SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(left: 16, top: 16, bottom: 4),
                  child: Text('较早'.tr, style: style),
                ),
              );
            } else {
              return emptyAdapter();
            }
          },
        ),
        GetBuilder<DocListController>(
          tag: EntryTypeExtension.name(widget.entryType),
          builder: (c) {
            if (c.docEarlier.isNotEmpty) {
              return _buildSliverList(c, c.docEarlier);
            } else {
              return emptyAdapter();
            }
          },
        ),
      ],
    );
  }

  Widget _contentMyAndCollectWidget(DocListController c) {
    return CustomScrollView(
      slivers: [
        GetBuilder<DocListController>(
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

  SliverList _buildSliverList(DocListController c, List<DocItem> list) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) => DocumentItemWidget(widget.guildId, list[index], c),
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
