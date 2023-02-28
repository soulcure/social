import '../bloc_model/fb_base_bloc.dart';

class EmojiKeyBoradBlocModel extends FBBaseBlocModel<double?, double?> {
  EmojiKeyBoradBlocModel(double? initialState) : super(initialState) {
    on<double?>((event, emit) {
      return emit(event);
    });
  }
}
