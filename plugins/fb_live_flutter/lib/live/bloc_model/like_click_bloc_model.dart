import 'dart:collection';
import 'fb_base_bloc.dart';

class LikeClickBlocModel extends FBBaseBlocModel<int, int> {
  LikeClickBlocModel(int initialState) : super(initialState) {
    on<int>((event, emit) {
      if (event > 0) {
        final int _count = state + event;
        return emit(_count);
      } else {
        return emit(event);
      }
    });
  }

  Queue<int>? _likeClickQueue;

  void reset() {
    add(0);
  }

  int get count => state;

  Queue<int> get likeClickQueue {
    return _likeClickQueue ??= Queue();
  }
}

class LikeClickPreviewBlocModel extends FBBaseBlocModel<int?, int?> {
  LikeClickPreviewBlocModel(int? initialState) : super(initialState) {
    on<int?>((event, emit) {
      return emit(event);
    });
  }

  int? get count => state;
}
