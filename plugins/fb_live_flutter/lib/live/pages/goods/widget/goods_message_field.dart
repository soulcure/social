import 'package:fb_live_flutter/live/model/goods/goods_add.dart';
import 'package:fb_live_flutter/live/utils/ui/frame_size.dart';
import 'package:flutter/material.dart';

class GoodsMessageField extends StatelessWidget {
  final GoodsMessageModel model;

  const GoodsMessageField(this.model);

  bool get isRequired {
    return model.required == 1;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: 17.5.px, bottom: 17.5.px, right: 12.px),
      child: Row(
        children: [
          if (isRequired)
            Text(
              '* ',
              style: TextStyle(color: const Color(0xffF24848), fontSize: 13.px),
            ),
          Text(
            model.name ?? '',
            style: TextStyle(color: const Color(0xff363940), fontSize: 13.px),
          ),
          Expanded(
            child: TextField(
              controller: model.controller ?? TextEditingController(),
              textAlign: TextAlign.right,
              decoration: InputDecoration(
                hintText: '请输入${model.name ?? ''}',
                border: InputBorder.none,
                hintStyle:
                    TextStyle(color: const Color(0xff8F959E), fontSize: 13.px),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
