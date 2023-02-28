// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'relation.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RelationTypeAdapter extends TypeAdapter<RelationType> {
  @override
  final int typeId = 24;

  @override
  RelationType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return RelationType.none;
      case 1:
        return RelationType.friend;
      case 2:
        return RelationType.blocked;
      case 3:
        return RelationType.pendingIncoming;
      case 4:
        return RelationType.pendingOutgoing;
      case 99:
        return RelationType.unrelated;
      default:
        return RelationType.none;
    }
  }

  @override
  void write(BinaryWriter writer, RelationType obj) {
    switch (obj) {
      case RelationType.none:
        writer.writeByte(0);
        break;
      case RelationType.friend:
        writer.writeByte(1);
        break;
      case RelationType.blocked:
        writer.writeByte(2);
        break;
      case RelationType.pendingIncoming:
        writer.writeByte(3);
        break;
      case RelationType.pendingOutgoing:
        writer.writeByte(4);
        break;
      case RelationType.unrelated:
        writer.writeByte(99);
        break;
      default:
        writer.writeByte(0);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RelationTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
