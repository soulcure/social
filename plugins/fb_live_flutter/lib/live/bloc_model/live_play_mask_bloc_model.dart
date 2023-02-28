import 'fb_base_bloc.dart';

class LivePlayMaskBlocModel extends FBBaseBlocModel<bool, bool> {
  LivePlayMaskBlocModel(bool initialState) : super(initialState){
    on<bool>((event, emit) {
      return emit(event);
    });
  }

  void switchScreenClearState() {
    add(!state);
  }
}
