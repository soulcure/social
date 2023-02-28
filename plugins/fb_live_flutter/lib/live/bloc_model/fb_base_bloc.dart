import 'package:flutter_bloc/flutter_bloc.dart';

abstract class FBBaseBlocModel<Event, State> extends Bloc<Event, State> {
  FBBaseBlocModel(State initialState) : super(initialState);
  @override
  void onEvent(Event event) {
    super.onEvent(event);
  }

  @override
  void onError(Object error, StackTrace stackTrace) {
    super.onError(error, stackTrace);
  }

  @override
  void onChange(Change<State> change) {
    super.onChange(change);
  }

  @override
  void onTransition(Transition<Event, State> transition) {
    super.onTransition(transition);
  }
}
