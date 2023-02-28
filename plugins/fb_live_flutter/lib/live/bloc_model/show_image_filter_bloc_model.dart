import 'fb_base_bloc.dart';

class ShowImageFilterBlocModel extends FBBaseBlocModel<bool, bool> {
  ShowImageFilterBlocModel(bool initialState) : super(initialState) {
    on<bool>((event, emit) {
      return emit(event);
    });
  }
}

class ShowScreenSharingBlocModel extends FBBaseBlocModel<bool, bool> {
  ShowScreenSharingBlocModel(bool initialState) : super(initialState) {
    on<bool>((event, emit) {
      return emit(event);
    });
  }
}
