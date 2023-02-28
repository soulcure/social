// Copyright 2019 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';

import 'item_positions_listener.dart';

/// Internal implementation of [ItemPositionsListener].
class ItemPositionsNotifier implements ItemPositionsListener {
  @override
  final ValueNotifier<Iterable<ItemPosition>> itemPositions = ValueNotifier([]);
}

class PinNotifier extends ChangeNotifier implements ValueListenable<bool> {
  bool _value;
  bool enabled = true;

  /// 是否应该把 Stack 里的 pinItem 显示出来
  late ValueNotifier<bool> show;

  PinNotifier(this._value) : show = ValueNotifier(_value);

  @override
  bool get value => _value;

  set value(bool newValue) {
    if (newValue == _value) return;
    _value = newValue;
    notifyListeners();
  }

  void reset() {
    value = false;
    show.value = false;
  }

  @override
  void dispose() {
    super.dispose();
    show.dispose();
  }


}
