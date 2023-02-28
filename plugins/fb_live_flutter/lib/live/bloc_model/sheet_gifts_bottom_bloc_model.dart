import '../bloc_model/fb_base_bloc.dart';

class SheetGiftsBottomBlocModel extends FBBaseBlocModel<double?, double?> {
  SheetGiftsBottomBlocModel(double? initialState) : super(initialState){
    on<double?>((event, emit) {
      return emit(event);
    });
  }
}
