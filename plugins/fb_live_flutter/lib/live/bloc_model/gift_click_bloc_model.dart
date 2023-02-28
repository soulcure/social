import 'dart:collection';
import 'fb_base_bloc.dart';

class GiftClickBlocModel extends FBBaseBlocModel<int?, int?> {
  GiftClickBlocModel(int? initialState) : super(initialState) {
    on<int?>((event, emit) {
      final _event = event ?? 0;
      if (_event > 0) {
        final _state = state ?? 0;
        final int _count = _state + _event;
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

  int? get count => state;

  Queue<int?> get likeClickQueue {
    return _likeClickQueue ??= Queue();
  }
}
