// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:im/icon_font.dart';

enum WebRadioType { circle, iconRight }

class WebRadio<T> extends StatefulWidget {
  const WebRadio(
      {Key key,
      @required this.value,
      @required this.groupValue,
      @required this.onChanged,
      this.activeColor,
      this.focusColor,
      this.hoverColor,
      this.materialTapTargetSize,
      this.focusNode,
      this.autofocus = false,
      this.type = WebRadioType.circle})
      : assert(autofocus != null),
        super(key: key);

  /// The value represented by this radio button.
  final T value;

  /// The currently selected value for a group of radio buttons.
  ///
  /// This radio button is considered selected if its [value] matches the
  /// [groupValue].
  final T groupValue;

  /// Called when the user selects this radio button.
  ///
  /// The radio button passes [value] as a parameter to this callback. The radio
  /// button does not actually change state until the parent widget rebuilds the
  /// radio button with the new [groupValue].
  ///
  /// If null, the radio button will be displayed as disabled.
  ///
  /// The provided callback will not be invoked if this radio button is already
  /// selected.
  ///
  /// The callback provided to [onChanged] should update the state of the parent
  /// [StatefulWidget] using the [State.setState] method, so that the parent
  /// gets rebuilt; for example:
  ///
  /// ```dart
  /// Radio<SingingCharacter>(
  ///   value: SingingCharacter.lafayette,
  ///   groupValue: _character,
  ///   onChanged: (SingingCharacter newValue) {
  ///     setState(() {
  ///       _character = newValue;
  ///     });
  ///   },
  /// )
  /// ```
  final ValueChanged<T> onChanged;

  /// The color to use when this radio button is selected.
  ///
  /// Defaults to [ThemeData.toggleableActiveColor].
  final Color activeColor;

  /// Configures the minimum size of the tap target.
  ///
  /// Defaults to [ThemeData.materialTapTargetSize].
  ///
  /// See also:
  ///
  ///  * [MaterialTapTargetSize], for a description of how this affects tap targets.
  final MaterialTapTargetSize materialTapTargetSize;

  /// The color for the radio's [Material] when it has the input focus.
  final Color focusColor;

  /// The color for the radio's [Material] when a pointer is hovering over it.
  final Color hoverColor;

  /// {@macro flutter.widgets.Focus.focusNode}
  final FocusNode focusNode;

  /// {@macro flutter.widgets.Focus.autofocus}
  final bool autofocus;

  final WebRadioType type;

  @override
  _WebRadioState<T> createState() => _WebRadioState<T>();
}

class _WebRadioState<T> extends State<WebRadio<T>> {
  bool get enabled => widget.onChanged != null;

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMaterial(context));
    final selected = widget.value == widget.groupValue;
    return Container(
      width: 18,
      height: 18,
      decoration: ShapeDecoration(
          color: (!selected || widget.type == WebRadioType.circle)
              ? Colors.transparent
              : Theme.of(context).primaryColor,
          shape: CircleBorder(
              side: BorderSide(
                  color: !selected
                      ? enabled
                          ? const Color(0xFF8F959E)
                          : const Color(0xFF8F959E).withOpacity(0.25)
                      : Theme.of(context).primaryColor))),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        opacity: selected ? 1 : 0,
        child: Padding(
          padding: const EdgeInsets.all(3),
          child: FittedBox(
            child: widget.type == WebRadioType.circle
                ? Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(context).primaryColor,
                    ),
                  )
                : const Icon(
                    IconFont.buffAudioVisualRight,
                    color: Colors.white,
                  ),
          ),
        ),
      ),
    );
  }
}
