import 'fb_base_bloc.dart';

class ShowAnchorLeaveBlocModel extends FBBaseBlocModel<bool, bool> {
  ShowAnchorLeaveBlocModel(bool initialState) : super(initialState) {
    on<bool>((event, emit) {
      return emit(event);
    });
  }
}
