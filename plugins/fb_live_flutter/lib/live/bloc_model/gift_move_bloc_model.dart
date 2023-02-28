import 'package:fb_live_flutter/fb_live_flutter.dart';

import 'fb_base_bloc.dart';

class GiveGiftModel {
  FBUserInfo? sendUserInfo;
  Map<String, dynamic>? giftInfo;
  int? count;

  GiveGiftModel({
    required this.sendUserInfo,
    required this.giftInfo,
    this.count,
  });
}

class GiftMoveBlocModel
    extends FBBaseBlocModel<GiveGiftModel?, GiveGiftModel?> {
  GiftMoveBlocModel(GiveGiftModel? initialState) : super(initialState) {
    on<GiveGiftModel?>((event, emit) {
      if (event == null) {
        _count = 0;
        return emit(event);
      } else {
        if (containsGiveGiftModel(event, state)) {
          _count++;
        } else {
          _count = 1;
        }
        return emit(GiveGiftModel(
          sendUserInfo: event.sendUserInfo,
          giftInfo: event.giftInfo,
          count: event.count,
        ));
      }
    });
  }

  int _count = 0;

  bool containsGiveGiftModel(
      GiveGiftModel? giveGiftModel, GiveGiftModel? preGiveGiftModel) {
    if (preGiveGiftModel == null) {
      return false;
    }
    final GiveGiftModel stateModel = preGiveGiftModel;
    return giveGiftModel!.giftInfo!["giftId"] ==
            stateModel.giftInfo!["giftId"] &&
        giveGiftModel.sendUserInfo!.userId == stateModel.sendUserInfo!.userId;
  }

  int get count => _count;
}

class GiftMoveBlocModel2
    extends FBBaseBlocModel<GiveGiftModel?, GiveGiftModel?> {
  GiftMoveBlocModel2(GiveGiftModel? initialState) : super(initialState) {
    on<GiveGiftModel?>((event, emit) {
      if (event == null) {
        _count = 0;
        return emit(event);
      } else {
        if (containsGiveGiftModel(event, state)) {
          _count++;
        } else {
          _count = 1;
        }
        return emit(GiveGiftModel(
          sendUserInfo: event.sendUserInfo,
          giftInfo: event.giftInfo,
          count: event.count,
        ));
      }
    });
  }

  int _count = 0;

  bool containsGiveGiftModel(
      GiveGiftModel? giveGiftModel, GiveGiftModel? preGiveGiftModel) {
    if (preGiveGiftModel == null) {
      return false;
    }
    final GiveGiftModel stateModel = preGiveGiftModel;
    return giveGiftModel!.giftInfo!["giftId"] ==
            stateModel.giftInfo!["giftId"] &&
        giveGiftModel.sendUserInfo!.userId == stateModel.sendUserInfo!.userId;
  }

  int get count => _count;
}

class GiftMoveBlocModel3
    extends FBBaseBlocModel<GiveGiftModel?, GiveGiftModel?> {
  GiftMoveBlocModel3(GiveGiftModel? initialState) : super(initialState) {
    on<GiveGiftModel?>((event, emit) {
      if (event == null) {
        _count = 0;
        return emit(event);
      } else {
        if (containsGiveGiftModel(event, state)) {
          _count++;
        } else {
          _count = 1;
        }
        return emit(GiveGiftModel(
          sendUserInfo: event.sendUserInfo,
          giftInfo: event.giftInfo,
          count: event.count,
        ));
      }
    });
  }

  int _count = 0;

  bool containsGiveGiftModel(
      GiveGiftModel? giveGiftModel, GiveGiftModel? preGiveGiftModel) {
    if (preGiveGiftModel == null) {
      return false;
    }
    final GiveGiftModel stateModel = preGiveGiftModel;
    return giveGiftModel!.giftInfo!["giftId"] ==
            stateModel.giftInfo!["giftId"] &&
        giveGiftModel.sendUserInfo!.userId == stateModel.sendUserInfo!.userId;
  }

  int get count => _count;
}
