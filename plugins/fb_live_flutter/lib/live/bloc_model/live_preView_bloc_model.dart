import 'fb_base_bloc.dart';

class LivePreviewBlocModel extends FBBaseBlocModel<int, int> {
  LivePreviewBlocModel(int initialState) : super(initialState) {
    on<int>((event, emit) {
      if (event == state) {
        /// 如果重复数据不加1的话视图不会有任何变化
        return emit(state + 1);
      } else {
        return emit(event);
      }
    });
  }
}
