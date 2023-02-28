import 'fb_base_bloc.dart';

class ChatListBlocModel extends FBBaseBlocModel<Map?, Map?> {
  ChatListBlocModel(Map? initialState) : super(initialState) {
    on<Map?>((event, emit) {
      return emit(event);
    });
  }
}
