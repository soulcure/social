import 'dart:convert';

import 'package:date_format/date_format.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_json_view/flutter_json_view.dart';
import 'package:get/get.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:im/pages/logging/let_log.dart';
import 'package:oktoast/oktoast.dart';

class WsLogView extends StatelessWidget {
  final RxList<WsLog> logs;

  const WsLogView({Key key, this.logs}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return Scrollbar(
        child: ListView.separated(
          padding: const EdgeInsets.all(8),
          separatorBuilder: (_, __) => const Divider(),
          itemBuilder: (_, i) {
            final data = logs[i];
            return ListTile(
              visualDensity: VisualDensity.comfortable,
              leading: Icon(
                data.type == WsLogType.Up
                    ? Icons.upload_sharp
                    : Icons.download_sharp,
                color: data.type == WsLogType.Up ? Colors.green : Colors.blue,
              ),
              title: Text(data.data['action']),
              trailing: Text(formatDate(data.time, [HH, ":", nn, ":", ss])),
              onTap: () {
                Get.dialog(
                  UnconstrainedBox(
                    child: Card(
                      child: Container(
                        width: context.widthTransformer(dividedBy: 1.1),
                        height: context.heightTransformer(dividedBy: 1.2),
                        padding: const EdgeInsets.all(5),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ElevatedButton(
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(
                                      text: jsonEncode(data.data)));
                                  showToast("复制成功".tr);
                                },
                                child: Text("复制".tr)),
                            Expanded(
                              child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: JsonView.map(
                                      data.data.cast<String, dynamic>())),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // backgroundColor: Theme.of(context).backgroundColor,
                  // isScrollControlled: true,
                );
              },
            );
          },
          itemCount: logs.length,
        ),
      );
    });
  }
}
