import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';

class ConnectivityService extends GetxService {
  static ConnectivityService get to => Get.find<ConnectivityService>();

  StreamSubscription<ConnectivityResult> _netSubscription;

  final Rx<ConnectivityResult> _state = ConnectivityResult.none.obs;

  ConnectivityResult get state => _state.value;

  bool get disabled => state == ConnectivityResult.none;

  bool get enabled => state != ConnectivityResult.none;

  Stream<ConnectivityResult> _onConnectivityChanged;

  Stream<ConnectivityResult> get onConnectivityChanged =>
      _onConnectivityChanged;

  @override
  void onInit() {
    Connectivity().checkConnectivity().then((value) {
      _state.value = value;
    });

    _onConnectivityChanged = Connectivity().onConnectivityChanged;
    if (!_onConnectivityChanged.isBroadcast) {
      _onConnectivityChanged = _onConnectivityChanged.asBroadcastStream();
    }
    _netSubscription = _onConnectivityChanged.listen((result) {
      _state.value = result;
    });
    super.onInit();
  }

  @override
  void onClose() {
    _netSubscription.cancel();
    super.onClose();
  }

  Future<void> waitUtilConnected() async {
    if (state != ConnectivityResult.none) return;

    final c = Completer();
    once(_state, (_) => c.complete());
    return c.future;
  }
}
