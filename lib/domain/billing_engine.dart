import '../data/models/models.dart';

/// Pure business logic for billing calculations.
/// No Hive calls, no Flutter widget dependencies.
/// All monetary values in Paisa (integer).
class BillingEngine {
  BillingEngine._();

  // ─── Meal Charges ───────────────────────────────────────────────

  /// Count how many breakfasts a customer had in a given period.
  static int countBreakfasts(List<MealEntry> entries) =>
      entries.where((e) => e.hadBreakfast).length;

  /// Count how many dinners a customer had in a given period.
  static int countDinners(List<MealEntry> entries) =>
      entries.where((e) => e.hadDinner).length;

  /// Total breakfast charges for the period (uses price recorded at time of entry).
  static int totalBreakfastChargePaisa(List<MealEntry> entries) =>
      entries.fold(
          0, (sum, e) => sum + (e.hadBreakfast ? e.breakfastPricePaisa : 0));

  /// Total dinner charges for the period.
  static int totalDinnerChargePaisa(List<MealEntry> entries) =>
      entries.fold(
          0, (sum, e) => sum + (e.hadDinner ? e.dinnerPricePaisa : 0));

  /// Total meal charges (breakfast + dinner).
  static int totalMealChargePaisa(List<MealEntry> entries) =>
      totalBreakfastChargePaisa(entries) + totalDinnerChargePaisa(entries);

  // ─── Additional Item Charges ────────────────────────────────────

  /// Total charges for additional items (sum of quantity × unitPrice at time of recording).
  static int totalAdditionalItemChargePaisa(
          List<AdditionalItemEntry> entries) =>
      entries.fold(0, (sum, e) => sum + e.totalPaisa);

  // ─── Adjustments ────────────────────────────────────────────────

  /// Total adjustments (positive = charge added, negative = discount/credit).
  static int totalAdjustmentsPaisa(List<Adjustment> adjustments) =>
      adjustments
          .where((a) => !a.isVoided)
          .fold(0, (sum, a) => sum + a.amountPaisa);

  // ─── Payments ───────────────────────────────────────────────────

  /// Total payments received in a period.
  static int totalPaymentsPaisa(List<Payment> payments) => payments
      .where((p) => !p.isVoided)
      .fold(0, (sum, p) => sum + p.amountPaisa);

  // ─── Monthly Bill Calculation ────────────────────────────────────

  /// Calculate all components of a monthly bill.
  /// Returns a [MonthlyBillResult] with all computed fields.
  static MonthlyBillResult calculateMonthlyBill({
    required String customerId,
    required int year,
    required int month,
    required List<MealEntry> mealEntries,
    required List<AdditionalItemEntry> additionalEntries,
    required List<Adjustment> adjustments,
    required List<Payment> paymentsThisMonth,
    required int previousBalancePaisa,
  }) {
    final breakfastCount = countBreakfasts(mealEntries);
    final dinnerCount = countDinners(mealEntries);
    final breakfastTotal = totalBreakfastChargePaisa(mealEntries);
    final dinnerTotal = totalDinnerChargePaisa(mealEntries);
    final additionalTotal = totalAdditionalItemChargePaisa(additionalEntries);
    final adjustmentsTotal = totalAdjustmentsPaisa(adjustments);
    final paymentsTotal = totalPaymentsPaisa(paymentsThisMonth);

    final currentCharges =
        breakfastTotal + dinnerTotal + additionalTotal + adjustmentsTotal;
    final outstanding =
        previousBalancePaisa + currentCharges - paymentsTotal;

    return MonthlyBillResult(
      customerId: customerId,
      year: year,
      month: month,
      breakfastCount: breakfastCount,
      dinnerCount: dinnerCount,
      breakfastTotalPaisa: breakfastTotal,
      dinnerTotalPaisa: dinnerTotal,
      additionalItemsTotalPaisa: additionalTotal,
      adjustmentsTotalPaisa: adjustmentsTotal,
      currentChargesPaisa: currentCharges,
      previousBalancePaisa: previousBalancePaisa,
      paymentsReceivedPaisa: paymentsTotal,
      outstandingBalancePaisa: outstanding,
    );
  }

  // ─── Outstanding Balance ─────────────────────────────────────────

  /// Compute outstanding balance from all historical data for a customer.
  /// Useful for getting the running balance before a given month.
  static int computeOutstandingBalance({
    required List<MealEntry> allMealEntries,
    required List<AdditionalItemEntry> allAdditionalEntries,
    required List<Adjustment> allAdjustments,
    required List<Payment> allPayments,
  }) {
    final totalCharges = totalMealChargePaisa(allMealEntries) +
        totalAdditionalItemChargePaisa(allAdditionalEntries) +
        totalAdjustmentsPaisa(allAdjustments);
    final totalPaid = totalPaymentsPaisa(allPayments);
    return totalCharges - totalPaid;
  }
}

/// Immutable result of a monthly bill calculation.
class MonthlyBillResult {
  final String customerId;
  final int year;
  final int month;
  final int breakfastCount;
  final int dinnerCount;
  final int breakfastTotalPaisa;
  final int dinnerTotalPaisa;
  final int additionalItemsTotalPaisa;
  final int adjustmentsTotalPaisa;
  final int currentChargesPaisa;
  final int previousBalancePaisa;
  final int paymentsReceivedPaisa;
  final int outstandingBalancePaisa;

  const MonthlyBillResult({
    required this.customerId,
    required this.year,
    required this.month,
    required this.breakfastCount,
    required this.dinnerCount,
    required this.breakfastTotalPaisa,
    required this.dinnerTotalPaisa,
    required this.additionalItemsTotalPaisa,
    required this.adjustmentsTotalPaisa,
    required this.currentChargesPaisa,
    required this.previousBalancePaisa,
    required this.paymentsReceivedPaisa,
    required this.outstandingBalancePaisa,
  });
}
