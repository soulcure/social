import 'fb_base_bloc.dart';
import 'fb_refresh_widget_bloc_model.dart';

class ChatListUnreadBlocModel extends FBBaseBlocModel<bool, RefreshState?> {
  ChatListUnreadBlocModel(RefreshState? initialState) : super(initialState) {
    on<bool>((event, emit) {
      if (event) {
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
