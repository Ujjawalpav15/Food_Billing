import 'package:hive_ce/hive.dart';
import '../../core/constants/app_constants.dart';

part 'payment.g.dart';

@HiveType(typeId: AppConstants.paymentTypeId)
class Payment extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String customerId;

  @HiveField(2)
  DateTime paymentDate;

  @HiveField(3)
  int amountPaisa;

  @HiveField(4)
  PaymentMethod method;

  @HiveField(5)
  String? notes;

  @HiveField(6)
  String? referenceNumber;

  @HiveField(7)
  DateTime createdAt;

  @HiveField(8)
  DateTime updatedAt;

  @HiveField(9)
  bool isVoided; // soft delete — never hard-delete payment records

  Payment({
    required this.id,
    required this.customerId,
    required this.paymentDate,
    required this.amountPaisa,
    this.method = PaymentMethod.cash,
    this.notes,
    this.referenceNumber,
    required this.createdAt,
    required this.updatedAt,
    this.isVoided = false,
  });
}

@HiveType(typeId: AppConstants.paymentMethodTypeId)
enum PaymentMethod {
  @HiveField(0)
  cash,
  @HiveField(1)
  esewa,
  @HiveField(2)
  khalti,
  @HiveField(3)
  bankTransfer,
  @HiveField(4)
  other,
}
