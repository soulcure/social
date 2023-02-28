import 'package:flutter/material.dart';
import 'package:im/pages/ledou/detail_page.dart';
import 'package:im/pages/ledou/model/entity.dart';
import 'package:im/pages/ledou/widgets/detail_item.dart';
import 'package:im/routes.dart';
import 'package:im/themes/const.dart';
import 'package:im/widgets/refresh/list_model.dart';
import 'package:im/widgets/refresh/refresh.dart';

/// 展示乐豆充值，消费，收益的列表组件
class TransactionListView<T extends TransactionEntity> extends StatelessWidget {
  final TransactionListViewAdapter adapter;

  /// 当数据为空时展示的view
  final Widget emptyView;

  const TransactionListView({
    Key key,
    @required this.adapter,
    this.emptyView,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Refresher(
      builder: (_) {
        /// 列表为空
        if (adapter.length == 0) {
          return emptyView ?? sizedBox;
        }

        /// 列表不为空
        return ListView.builder(
          itemCount: adapter.length,
          itemBuilder: (_, i) {
            final data = adapter.list[i];
            return TransactionItem(data, onTap: () {
              Routes.pushLedouDetailPage( TransactionDetailViewModel(data.orderNum)
              );
            });
          },
        );
      },
      model: adapter,
    );
  }
}

abstract class TransactionListViewAdapter<T extends TransactionEntity>
    extends ListModel<T> {
  /// 构建详情页数据
  // TransactionDetailViewModel convert2Detail(T data);
}
