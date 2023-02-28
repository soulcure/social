import 'package:fb_live_flutter/live/pages/live_room/live_room.dart';
import 'package:fb_live_flutter/live/pages/live_room/live_room_obs.dart';
import 'package:fb_live_flutter/live/utils/solve_repeat/solve_repeat.dart';
import 'package:flutter/material.dart';

mixin LiveObsPageHandle on State<LiveRoomObs>, LivePageCommon {
  @override
  void initState() {
    super.initState();
    initStateHandle();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    didChangeDependenciesHandle();
  }

  @override
  void deactivate() {
    super.deactivate();
    deactivateHandle();
  }

  @override
  void dispose() {
    super.dispose();
    disposeHandle();
  }
}

mixin LivePageHandle on State<LiveRoom>, LivePageCommon {
  @override
  void initState() {
    super.initState();
    initStateHandle();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    didChangeDependenciesHandle();
  }

  @override
  void deactivate() {
    super.deactivate();
    deactivateHandle();
  }

  @override
  void dispose() {
    super.dispose();
    disposeHandle();
  }
}
