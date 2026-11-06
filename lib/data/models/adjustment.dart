import 'package:hive_ce/hive.dart';
import '../../core/constants/app_constants.dart';

part 'adjustment.g.dart';

/// Manual adjustments applied to a customer's bill (discount, correction, credit, etc.)
@HiveType(typeId: AppConstants.adjustmentTypeId)
class Adjustment extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String customerId;

  @HiveField(2)
  DateTime adjustmentDate;

  @HiveField(3)
  int amountPaisa; // positive = charge, negative = credit/discount

  @HiveField(4)
  String reason;

  @HiveField(5)
  DateTime createdAt;

  @HiveField(6)
  DateTime updatedAt;

  @HiveField(7)
  bool isVoided;

  Adjustment({
    required this.id,
    required this.customerId,
    required this.adjustmentDate,
    required this.amountPaisa,
    required this.reason,
    required this.createdAt,
    required this.updatedAt,
    this.isVoided = false,
  });
}
