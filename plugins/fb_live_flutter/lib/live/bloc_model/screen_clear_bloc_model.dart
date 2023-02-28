import '../bloc_model/fb_base_bloc.dart';

class ScreenClearBlocModel extends FBBaseBlocModel<bool, bool> {
  ScreenClearBlocModel(bool initialState) : super(initialState) {
    on<bool>((event, emit) {
      return emit(event);
    });
  }

  void switchScreenClearState() {
    add(!state);
  }
}
