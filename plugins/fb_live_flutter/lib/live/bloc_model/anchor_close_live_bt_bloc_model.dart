import 'package:fb_live_flutter/live/bloc_model/fb_base_bloc.dart';

class AnchorCloseLiveBtBlocModel extends FBBaseBlocModel<int?, int> {
  AnchorCloseLiveBtBlocModel(int initialState) : super(initialState) {
    on<int?>((event, emit) {
      if (event != state) {
        return emit(event!);
      } else {
        return emit(state + 1);
      }
    });
  }
}
