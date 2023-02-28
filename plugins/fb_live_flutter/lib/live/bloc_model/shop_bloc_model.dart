import 'fb_base_bloc.dart';

/// 商品bloc
class ShopEvent {
  int? count;
  String? url;

  ShopEvent(this.count, this.url);
}

class ShopState extends ShopEvent {
  ShopState({int? count, String? url}) : super(count, url);
}

class ShopBlocModelQuick extends FBBaseBlocModel<ShopEvent?, ShopState?> {
  ShopBlocModelQuick(ShopState? initialState) : super(initialState) {
    on<ShopEvent?>((event, emit) {
      switch (event) {
        case null:
          return emit(state);
        default:
          return emit(ShopState(count: event!.count, url: event.url));
      }
    });
  }
}

/// 优惠券bloc
class CouponsEvent {
  bool? isShowCoupons;

  CouponsEvent(this.isShowCoupons);
}

class CouponsState extends CouponsEvent {
  CouponsState({bool? isShowCoupons}) : super(isShowCoupons);
}

class CouponsBlocModelQuick
    extends FBBaseBlocModel<CouponsEvent?, CouponsState?> {
  CouponsBlocModelQuick(CouponsState? initialState) : super(initialState) {
    on<CouponsEvent?>((event, emit) {
      switch (event) {
        case null:
          return emit(state);
        default:
          return emit(CouponsState(isShowCoupons: event!.isShowCoupons));
      }
    });
  }
}
