import 'package:fb_live_flutter/live/model/room_infon_model.dart';
import 'package:fb_live_flutter/live/utils/live/base_bloc.dart';

import 'goods_add_api.dart';

class GoodsAddTabBloc extends BaseAppCubit<int>
    with BaseAppCubitState, GoodsAddApiRoomInfo, GoodsAddApi {
  final RoomInfon roomInfoObjectValue;

  GoodsAddTabBloc(this.roomInfoObjectValue) : super(0);

  List<int?> selectData = [];

  @override
  RoomInfon get roomInfoObject => roomInfoObjectValue;
}
