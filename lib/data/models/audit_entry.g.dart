// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'audit_entry.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AuditEntryAdapter extends TypeAdapter<AuditEntry> {
  @override
  final typeId = 8;

  @override
  AuditEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AuditEntry(
      id: fields[0] as String,
      action: fields[1] as AuditAction,
      entityType: fields[2] as String,
      entityId: fields[3] as String,
      customerId: fields[4] as String?,
      originalValue: fields[5] as String?,
      newValue: fields[6] as String?,
      reason: fields[7] as String?,
      createdAt: fields[8] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, AuditEntry obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.action)
      ..writeByte(2)
      ..write(obj.entityType)
      ..writeByte(3)
      ..write(obj.entityId)
      ..writeByte(4)
      ..write(obj.customerId)
      ..writeByte(5)
      ..write(obj.originalValue)
      ..writeByte(6)
      ..write(obj.newValue)
      ..writeByte(7)
      ..write(obj.reason)
      ..writeByte(8)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuditEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class AuditActionAdapter extends TypeAdapter<AuditAction> {
  @override
  final typeId = 13;

  @override
  AuditAction read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return AuditAction.created;
      case 1:
        return AuditAction.updated;
      case 2:
        return AuditAction.deleted;
      case 3:
        return AuditAction.voided;
      case 4:
        return AuditAction.finalized;
      case 5:
        return AuditAction.reopened;
      default:
        return AuditAction.created;
    }
  }

  @override
  void write(BinaryWriter writer, AuditAction obj) {
    switch (obj) {
      case AuditAction.created:
        writer.writeByte(0);
      case AuditAction.updated:
        writer.writeByte(1);
      case AuditAction.deleted:
        writer.writeByte(2);
      case AuditAction.voided:
        writer.writeByte(3);
      case AuditAction.finalized:
        writer.writeByte(4);
      case AuditAction.reopened:
        writer.writeByte(5);
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuditActionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
