import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fb_live_flutter/live/utils/func/router.dart';
import 'package:fb_live_flutter/live/utils/theme/my_toast.dart';

abstract class BaseAppCubit<Event> extends Cubit<Event> {
  BaseAppCubit(Event state) : super(state);

  @override
  void onChange(Change<Event> change) {
    super.onChange(change);
  }

  @override
  void onError(Object error, StackTrace stackTrace) {
    super.onError(error, stackTrace);
  }

  /*
  * 出现异常，页面返回
  * */
  void popErrorMsg(String? msg) {
    RouteUtil.pop();
    myFailToast(msg);
  }

  @override
  Future<void> close() {
    return super.close();
  }
}

mixin BaseAppCubitState on BaseAppCubit<int> {
  /*
  * 刷新
  * */
  void onRefresh() {
    if (!isClosed) emit(state + 1);
  }
}
