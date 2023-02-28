// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reaction_cache_bean.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ReactionCacheBeanAdapter extends TypeAdapter<ReactionCacheBean> {
  @override
  final int typeId = 20;

  @override
  ReactionCacheBean read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ReactionCacheBean()
      ..channelId = fields[0] as String
      ..messageId = fields[1] as String
      ..emojiName = fields[2] as String
      ..count = fields[3] as int;
  }

  @override
  void write(BinaryWriter writer, ReactionCacheBean obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.channelId)
      ..writeByte(1)
      ..write(obj.messageId)
      ..writeByte(2)
      ..write(obj.emojiName)
      ..writeByte(3)
      ..write(obj.count);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReactionCacheBeanAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
