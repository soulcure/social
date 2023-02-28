import 'fb_base_bloc.dart';

class OnlineUserCountBlocModel extends FBBaseBlocModel<int?, int> {
  OnlineUserCountBlocModel(int initialState) : super(initialState) {
    on<int?>((event, emit) {
      if (event != state) {
        return emit(event!);
      } else {
        return emit(state + 1);
      }
    });
  }
}
