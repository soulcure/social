import 'package:flutter/material.dart';
import '../model/room_gift_model.dart';
import 'fb_base_bloc.dart';

class GiveGiftEvent {
  Offset? position;
  Result? giftResultModel;
  double? itemWidth;
  int? count;

  GiveGiftEvent({
    required this.position,
    required this.giftResultModel,
    required this.itemWidth,
    required this.count,
  });
}

class GiveGiftState extends GiveGiftEvent {
  GiveGiftState({
    Offset? position,
    int? count,
    Result? giftResultModel,
    double? itemWidth,
  }) : super(
          position: position,
          count: count,
          giftResultModel: giftResultModel,
          itemWidth: itemWidth,
        );
}

class GiveGiftBlocModel
    extends FBBaseBlocModel<GiveGiftEvent?, GiveGiftState?> {
  GiveGiftBlocModel(GiveGiftState? initialState) : super(initialState) {
    on<GiveGiftEvent?>((event, emit) {
      switch (event) {
        case null:
          return emit(state);
        default:
          return emit(GiveGiftState(
            position: event!.position,
            count: event.count,
            giftResultModel: event.giftResultModel,
            itemWidth: event.itemWidth,
          ));
      }
    });
  }
}

class GiveGiftBlocModelQuick
    extends FBBaseBlocModel<GiveGiftEvent?, GiveGiftState?> {
  GiveGiftBlocModelQuick(GiveGiftState? initialState) : super(initialState) {
    on<GiveGiftEvent?>((event, emit) {
      switch (event) {
        case null:
          return emit(state);
        default:
          return emit(GiveGiftState(
            position: event!.position,
            count: event.count,
            giftResultModel: event.giftResultModel,
            itemWidth: event.itemWidth,
          ));
      }
    });
  }
}
