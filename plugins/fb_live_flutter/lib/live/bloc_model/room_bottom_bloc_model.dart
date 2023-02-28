import 'fb_base_bloc.dart';
import 'fb_refresh_widget_bloc_model.dart';

class RoomBottomBlocModel extends FBBaseBlocModel<bool, RefreshState?> {
  RoomBottomBlocModel(RefreshState initialState) : super(initialState) {
    on<bool>((event, emit) {
      if (state == null || state == RefreshState.moreSuccess) {
        return emit(RefreshState.success);
      }
      if (state == RefreshState.success) {
        return emit(RefreshState.moreSuccess);
      } else {
        return emit(RefreshState.success);
      }
    });
  }
}
