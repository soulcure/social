import 'fb_base_bloc.dart';

class TipsLoginBlocModel extends FBBaseBlocModel<bool?, bool?> {
  TipsLoginBlocModel(bool? initialState) : super(initialState) {
    on<bool?>((event, emit) {
      return emit(event);
    });
  }
}
