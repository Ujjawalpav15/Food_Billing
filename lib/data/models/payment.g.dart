// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PaymentAdapter extends TypeAdapter<Payment> {
  @override
  final typeId = 5;

  @override
  Payment read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Payment(
      id: fields[0] as String,
      customerId: fields[1] as String,
      paymentDate: fields[2] as DateTime,
      amountPaisa: (fields[3] as num).toInt(),
      method:
          fields[4] == null ? PaymentMethod.cash : fields[4] as PaymentMethod,
      notes: fields[5] as String?,
      referenceNumber: fields[6] as String?,
      createdAt: fields[7] as DateTime,
      updatedAt: fields[8] as DateTime,
      isVoided: fields[9] == null ? false : fields[9] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, Payment obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.customerId)
      ..writeByte(2)
      ..write(obj.paymentDate)
      ..writeByte(3)
      ..write(obj.amountPaisa)
      ..writeByte(4)
      ..write(obj.method)
      ..writeByte(5)
      ..write(obj.notes)
      ..writeByte(6)
      ..write(obj.referenceNumber)
      ..writeByte(7)
      ..write(obj.createdAt)
      ..writeByte(8)
      ..write(obj.updatedAt)
      ..writeByte(9)
      ..write(obj.isVoided);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PaymentAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PaymentMethodAdapter extends TypeAdapter<PaymentMethod> {
  @override
  final typeId = 11;

  @override
  PaymentMethod read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return PaymentMethod.cash;
      case 1:
        return PaymentMethod.esewa;
      case 2:
        return PaymentMethod.khalti;
      case 3:
        return PaymentMethod.bankTransfer;
      case 4:
        return PaymentMethod.other;
      default:
        return PaymentMethod.cash;
    }
  }

  @override
  void write(BinaryWriter writer, PaymentMethod obj) {
    switch (obj) {
      case PaymentMethod.cash:
        writer.writeByte(0);
      case PaymentMethod.esewa:
        writer.writeByte(1);
      case PaymentMethod.khalti:
        writer.writeByte(2);
      case PaymentMethod.bankTransfer:
        writer.writeByte(3);
      case PaymentMethod.other:
        writer.writeByte(4);
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PaymentMethodAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
