import 'package:fb_live_flutter/fb_live_flutter.dart';
import 'package:fb_live_flutter/live/model/goods/goods_push_model.dart';

import '../bloc_model/fb_base_bloc.dart';

class UserJoinLiveRoomModel extends FBBaseBlocModel<FBUserInfo?, FBUserInfo?> {
  UserJoinLiveRoomModel(FBUserInfo? initialState) : super(initialState) {
    on<FBUserInfo?>((event, emit) {
      return emit(event);
    });
  }
}

class PushGoodsLiveRoomModel
    extends FBBaseBlocModel<GoodsPushModel?, GoodsPushModel?> {
  PushGoodsLiveRoomModel(GoodsPushModel? initialState) : super(initialState) {
    on<GoodsPushModel?>((event, emit) {
      return emit(event);
    });
  }
}
