import 'dart:typed_data';
import 'dart:ui' as ui show Codec;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

@immutable
class FutureMemory extends ImageProvider<FutureMemory> {
  const FutureMemory(this.futureBytes, {this.scale = 1.0})
      : assert(futureBytes != null),
        assert(scale != null);

  final Future<Uint8List> futureBytes;

  final double scale;

  @override
  Future<FutureMemory> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<FutureMemory>(this);
  }

  @override
  ImageStreamCompleter load(FutureMemory key, DecoderCallback decode) {
    return MultiFrameImageStreamCompleter(
      codec: _loadAsync(key, decode),
      scale: key.scale,
      debugLabel: 'MemoryImage(${describeIdentity(key.futureBytes)})',
    );
  }

  Future<ui.Codec> _loadAsync(FutureMemory key, DecoderCallback decode) async {
    assert(key == this);
    final bytes = await futureBytes;
    return decode(bytes);
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) return false;
    return other is FutureMemory &&
        other.futureBytes == futureBytes &&
        other.scale == scale;
  }

  @override
  int get hashCode => hashValues(futureBytes.hashCode, scale);

  @override
  String toString() =>
      '${objectRuntimeType(this, 'MemoryImage')}(${describeIdentity(futureBytes)}, scale: $scale)';
}
