import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:im/themes/const.dart';

typedef ListBuilder<T> = Widget Function(List<T> data);
typedef DataFetcher<T> = Future<List<T>> Function();

class SearchListView<T> extends StatefulWidget {
  final DataFetcher<T> dataFetcher;
  final ListBuilder<T> listBuilder;
  final WidgetBuilder emptyResultBuilder;

  const SearchListView({
    Key key,
    @required this.dataFetcher,
    @required this.listBuilder,
    this.emptyResultBuilder,
  }) : super(key: key);

  @override
  _SearchListViewState<T> createState() => _SearchListViewState<T>();
}

class _SearchListViewState<T> extends State<SearchListView<T>> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<T>>(
      future: widget.dataFetcher(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          /// 正在搜索中
          return _buildSearchingView();
        }
        if (snapshot.hasError) {
          /// 搜索失败
          if (snapshot.error is Error) {
            final error = snapshot.error as Error;
            print(
                "SearchListView fetch data error: ${error.toString()}\n${error.stackTrace}");
          } else {
            print(snapshot.error);
          }
          return _buildRetryView();
        }

        final isEmpty = snapshot.data == null || snapshot.data.isEmpty;
        if (isEmpty && widget.emptyResultBuilder != null) {
          return widget.emptyResultBuilder(context);
        }

        /// 搜索成功
        return widget.listBuilder(snapshot.data);
      },
    );
  }

  /// 构建搜索中的界面
  Widget _buildSearchingView() {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          sizeWidth4,
          Text(
            "加载中...".tr,
            style: const TextStyle(fontSize: 14, color: Color(0xFF8F959E)),
          ),
        ],
      ),
    );
  }

  /// 构建搜索失败重试的界面
  Widget _buildRetryView() {
    return Center(
      child: TextButton(
        onPressed: _refresh,
        child: Text("搜索失败，点击重试".tr),
      ),
    );
  }

  /// 刷新组件，重新请求数据
  void _refresh() {
    setState(() {});
  }
}
