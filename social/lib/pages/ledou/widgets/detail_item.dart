import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:im/pages/ledou/model/entity.dart';
import 'package:im/themes/const.dart';
import 'package:im/utils/utils.dart';

/// 消费，充值，收益详情页面的item
class DetailItem extends StatelessWidget {
  final DetailItemViewModel item;

  const DetailItem(this.item, {Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            item.title,
            style: const TextStyle(color: Color(0xFF8F959E), fontSize: 16),
          ),
          Text(
            item.content,
            style: const TextStyle(color: Color(0xFF363940), fontSize: 15),
          ),
        ],
      ),
    );
  }
}

/// 详情item的数据模型
class DetailItemViewModel {
  /// item标题
  final String title;

  /// item内容
  final String content;

  /// 内容展示最大行数，默认展示1行
  final int maxLine;

  DetailItemViewModel(this.title, this.content, {this.maxLine = 1});
}

/// 乐豆明细，和收益明细的列表item
class TransactionItem extends StatelessWidget {
  final TransactionEntity data;
  final VoidCallback onTap;

  const TransactionItem(this.data, {Key key, this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String title, content;
    final data = this.data;
    if (data.type == TransactionType.topUp) {
      title = "充值".tr;
      content = "+%s 乐豆".trArgs([data.amount.toString()]);
    } else if (data.type == TransactionType.consumption) {
      title = "送出礼物-%s".trArgs([data.merchandiseName]);
      content = "-%s 乐豆".trArgs([data.amount.toString()]);
    } else if (data.type == TransactionType.earning) {
      title = "收到-%s".trArgs([data.merchandiseName]);
      content = "+%s 乐豆".trArgs([data.amount.toString()]);
    }

    /// 数据错误
    if (title == null || content == null) {
      return sizedBox;
    }
    final formattedDate = formatDate2Str(
      data.date,
      showToday: true,
    );
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.only(top: 16, bottom: 16, right: 16),
        margin: const EdgeInsets.only(left: 16),
        decoration: BoxDecoration(
            border: Border(
                bottom: BorderSide(
                    width: 0.5,
                    color: const Color(0xFF8F959E).withOpacity(0.2)))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                      fontSize: 16, height: 1.25, color: Color(0xFF1F2125)),
                ),
                const Expanded(child: sizeWidth2),
                Text(
                  content,
                  style: const TextStyle(
                      fontSize: 16, height: 1.25, color: Color(0xFF1F2125)),
                ),
              ],
            ),
            sizeHeight4,
            Text(
              formattedDate,
              style: const TextStyle(
                  fontSize: 14, height: 1.21, color: Color(0xFF8F959E)),
            ),
          ],
        ),
      ),
    );
  }
}
