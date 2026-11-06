// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'monthly_bill.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MonthlyBillAdapter extends TypeAdapter<MonthlyBill> {
  @override
  final typeId = 7;

  @override
  MonthlyBill read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MonthlyBill(
      id: fields[0] as String,
      customerId: fields[1] as String,
      billingYear: (fields[2] as num).toInt(),
      billingMonth: (fields[3] as num).toInt(),
      breakfastCount: (fields[4] as num).toInt(),
      breakfastTotalPaisa: (fields[5] as num).toInt(),
      dinnerCount: (fields[6] as num).toInt(),
      dinnerTotalPaisa: (fields[7] as num).toInt(),
      additionalItemsTotalPaisa: (fields[8] as num).toInt(),
      adjustmentsTotalPaisa: (fields[9] as num).toInt(),
      previousBalancePaisa: (fields[10] as num).toInt(),
      paymentsReceivedPaisa: (fields[11] as num).toInt(),
      status: fields[12] == null ? BillStatus.draft : fields[12] as BillStatus,
      finalizedAt: fields[13] as DateTime?,
      createdAt: fields[14] as DateTime,
      updatedAt: fields[15] as DateTime,
      notes: fields[16] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, MonthlyBill obj) {
    writer
      ..writeByte(17)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.customerId)
      ..writeByte(2)
      ..write(obj.billingYear)
      ..writeByte(3)
      ..write(obj.billingMonth)
      ..writeByte(4)
      ..write(obj.breakfastCount)
      ..writeByte(5)
      ..write(obj.breakfastTotalPaisa)
      ..writeByte(6)
      ..write(obj.dinnerCount)
      ..writeByte(7)
      ..write(obj.dinnerTotalPaisa)
      ..writeByte(8)
      ..write(obj.additionalItemsTotalPaisa)
      ..writeByte(9)
      ..write(obj.adjustmentsTotalPaisa)
      ..writeByte(10)
      ..write(obj.previousBalancePaisa)
      ..writeByte(11)
      ..write(obj.paymentsReceivedPaisa)
      ..writeByte(12)
      ..write(obj.status)
      ..writeByte(13)
      ..write(obj.finalizedAt)
      ..writeByte(14)
      ..write(obj.createdAt)
      ..writeByte(15)
      ..write(obj.updatedAt)
      ..writeByte(16)
      ..write(obj.notes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MonthlyBillAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class BillStatusAdapter extends TypeAdapter<BillStatus> {
  @override
  final typeId = 12;

  @override
  BillStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return BillStatus.draft;
      case 1:
        return BillStatus.finalized;
      case 2:
        return BillStatus.amended;
      default:
        return BillStatus.draft;
    }
  }

  @override
  void write(BinaryWriter writer, BillStatus obj) {
    switch (obj) {
      case BillStatus.draft:
        writer.writeByte(0);
      case BillStatus.finalized:
        writer.writeByte(1);
      case BillStatus.amended:
        writer.writeByte(2);
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BillStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
