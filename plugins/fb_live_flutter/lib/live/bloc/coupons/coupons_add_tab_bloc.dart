import 'package:fb_live_flutter/live/model/room_infon_model.dart';
import 'package:fb_live_flutter/live/utils/live/base_bloc.dart';

import 'coupons_add_api.dart';

class CouponsAddTabBloc extends BaseAppCubit<int>
    with BaseAppCubitState, CouponsRoomInfo, CouponsAddApi {
  CouponsAddTabBloc() : super(0);

  List<int?> selectData = [];

  late RoomInfon roomInfoObjectValue;

  void setRoomInfo(RoomInfon roomInfoObject) {
    roomInfoObjectValue = roomInfoObject;
    return;
  }

  @override
  RoomInfon get roomInfoObject => roomInfoObjectValue;
}
