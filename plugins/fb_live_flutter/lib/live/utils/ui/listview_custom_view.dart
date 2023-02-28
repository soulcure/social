import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'frame_size.dart';

class CustomFooterView extends StatelessWidget {
  final LoadStatus? loadStatus;
  final bool isHistory;
  final Color? mainColor;
  final String? noDataStr;

  const CustomFooterView({
    this.loadStatus,
    this.isHistory = false,
    this.mainColor,
    this.noDataStr,
  });

  Widget getBody(LoadStatus? mode) {
    // 【翻页】截图几个页面，“到底了”全部去掉  修改样式，包含了列表的样所有样式（非IM列表）。
    final Color color = mainColor ?? const Color(0xff8F959E).withOpacity(0.75);
    Widget body;
    if (mode == LoadStatus.idle) {
      body = Text("上拉加载", style: TextStyle(color: color));
    } else if (mode == LoadStatus.loading) {
      body = Text("正在加载……", style: TextStyle(color: color));
    } else if (mode == LoadStatus.failed) {
      body = Text("网络连接有误，请检查网络后重试", style: TextStyle(color: color));
    } else if (mode == LoadStatus.canLoading) {
      body = Text("松手,加载更多!", style: TextStyle(color: color));
    } else if (mode == LoadStatus.noMore) {
      body = Text(noDataStr ?? "没有更多了",
          style: TextStyle(color: color, fontSize: 12.px));
    } else {
      body = const Text(" ");
    }

    return SizedBox(height: (64 + 12).px, child: Center(child: body));
  }

  @override
  Widget build(BuildContext context) {
    if (loadStatus != null) {
      return getBody(loadStatus);
    }

    return CustomFooter(
      height: (64 + 12).px,
      builder: (context, mode) {
        if (isHistory) {
          return Container();
        }
        return getBody(mode);
      },
    );
  }
}

class NullFooterView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomFooter(
      height: 0,
      builder: (context, mode) {
        return Container(
          color: Colors.red,
        );
      },
    );
  }
}
