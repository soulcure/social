import 'package:flutter/widgets.dart';
import 'package:hive/hive.dart';
import 'package:im/app/modules/redpack/redpack_item/redpack_info_ben.dart';

part 'redpack_item_bean.g.dart';

@HiveType(typeId: 22)
class RedPackItemBean extends HiveObject {
  @HiveField(0)
  String channelId;

  @HiveField(1)
  List<RedPackInfoBean> redPackInfoList;

  RedPackItemBean({
    @required this.channelId,
    @required this.redPackInfoList,
  });
}
