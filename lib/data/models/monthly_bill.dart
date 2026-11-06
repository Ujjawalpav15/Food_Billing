import 'package:hive_ce/hive.dart';
import '../../core/constants/app_constants.dart';

part 'monthly_bill.g.dart';

/// A finalized or draft monthly bill for one customer.
/// Once finalized, fields are locked. To amend, set status back to draft explicitly.
@HiveType(typeId: AppConstants.monthlyBillTypeId)
class MonthlyBill extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String customerId;

  @HiveField(2)
  int billingYear;

  @HiveField(3)
  int billingMonth; // 1-12

  @HiveField(4)
  int breakfastCount;

  @HiveField(5)
  int breakfastTotalPaisa;

  @HiveField(6)
  int dinnerCount;

  @HiveField(7)
  int dinnerTotalPaisa;

  @HiveField(8)
  int additionalItemsTotalPaisa;

  @HiveField(9)
  int adjustmentsTotalPaisa;

  @HiveField(10)
  int previousBalancePaisa; // outstanding from previous month (positive = owed by customer)

  @HiveField(11)
  int paymentsReceivedPaisa; // payments made during this billing period

  @HiveField(12)
  BillStatus status;

  @HiveField(13)
  DateTime? finalizedAt;

  @HiveField(14)
  DateTime createdAt;

  @HiveField(15)
  DateTime updatedAt;

  @HiveField(16)
  String? notes;

  MonthlyBill({
    required this.id,
    required this.customerId,
    required this.billingYear,
    required this.billingMonth,
    required this.breakfastCount,
    required this.breakfastTotalPaisa,
    required this.dinnerCount,
    required this.dinnerTotalPaisa,
    required this.additionalItemsTotalPaisa,
    required this.adjustmentsTotalPaisa,
    required this.previousBalancePaisa,
    required this.paymentsReceivedPaisa,
    this.status = BillStatus.draft,
    this.finalizedAt,
    required this.createdAt,
    required this.updatedAt,
    this.notes,
  });

  /// Total charges for this month.
  int get totalChargesPaisa =>
      breakfastTotalPaisa +
      dinnerTotalPaisa +
      additionalItemsTotalPaisa +
      adjustmentsTotalPaisa;

  /// Amount still owed after payments.
  int get outstandingBalancePaisa =>
      previousBalancePaisa + totalChargesPaisa - paymentsReceivedPaisa;
}

@HiveType(typeId: AppConstants.billStatusTypeId)
enum BillStatus {
  @HiveField(0)
  draft,
  @HiveField(1)
  finalized,
  @HiveField(2)
  amended,
}
