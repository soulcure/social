import '../bloc_model/fb_base_bloc.dart';

enum RefreshState {
  none,
  success,
  moreSuccess,
}

class FBRefreshWidgetBlocModel extends FBBaseBlocModel<bool?, RefreshState?> {
  FBRefreshWidgetBlocModel(RefreshState? initialState) : super(initialState) {
    on<bool?>((event, emit) {
      if (event!) {
        if (state == null) {
          return emit(RefreshState.success);
        } else if (state == RefreshState.success) {
          return emit(RefreshState.moreSuccess);
        } else {
          return emit(RefreshState.success);
        }
      } else {
        return emit(state);
      }
    });
  }
}
