import 'package:flutter_test/flutter_test.dart';
import 'package:food_billing/data/models/models.dart';
import 'package:food_billing/domain/billing_engine.dart';

/// Helper: creates a MealEntry with the given parameters.
MealEntry makeMealEntry({
  required String id,
  required String customerId,
  required DateTime date,
  bool hadBreakfast = false,
  bool hadDinner = false,
  int breakfastPricePaisa = 8500,
  int dinnerPricePaisa = 8500,
}) {
  final now = DateTime.now();
  return MealEntry(
    id: id,
    customerId: customerId,
    date: date,
    hadBreakfast: hadBreakfast,
    hadDinner: hadDinner,
    breakfastPricePaisa: breakfastPricePaisa,
    dinnerPricePaisa: dinnerPricePaisa,
    createdAt: now,
    updatedAt: now,
  );
}

/// Helper: creates an AdditionalItemEntry.
AdditionalItemEntry makeAdditionalEntry({
  required String id,
  required String customerId,
  required DateTime date,
  required int quantity,
  required int unitPricePaisa,
  String menuItemId = 'item1',
  String menuItemName = 'Egg',
}) {
  final now = DateTime.now();
  return AdditionalItemEntry(
    id: id,
    customerId: customerId,
    menuItemId: menuItemId,
    menuItemName: menuItemName,
    date: date,
    quantity: quantity,
    unitPricePaisa: unitPricePaisa,
    createdAt: now,
    updatedAt: now,
  );
}

/// Helper: creates a Payment.
Payment makePayment({
  required String id,
  required String customerId,
  required DateTime paymentDate,
  required int amountPaisa,
  bool isVoided = false,
}) {
  final now = DateTime.now();
  return Payment(
    id: id,
    customerId: customerId,
    paymentDate: paymentDate,
    amountPaisa: amountPaisa,
    createdAt: now,
    updatedAt: now,
    isVoided: isVoided,
  );
}

/// Helper: creates an Adjustment.
Adjustment makeAdjustment({
  required String id,
  required String customerId,
  required int amountPaisa,
  String reason = 'Manual adjustment',
  bool isVoided = false,
}) {
  final now = DateTime.now();
  return Adjustment(
    id: id,
    customerId: customerId,
    adjustmentDate: DateTime(2026, 11, 1),
    amountPaisa: amountPaisa,
    reason: reason,
    createdAt: now,
    updatedAt: now,
    isVoided: isVoided,
  );
}

void main() {
  final customerId = 'cust_001';
  final nov1 = DateTime(2026, 11, 1);
  final nov2 = DateTime(2026, 11, 2);
  final nov3 = DateTime(2026, 11, 3);

  // ═══════════════════════════════════════════════════════════════
  // MEAL CHARGE TESTS
  // ═══════════════════════════════════════════════════════════════

  group('BillingEngine — Meal Counts', () {
    test('counts breakfasts correctly', () {
      final entries = [
        makeMealEntry(id: 'e1', customerId: customerId, date: nov1, hadBreakfast: true),
        makeMealEntry(id: 'e2', customerId: customerId, date: nov2, hadBreakfast: true, hadDinner: true),
        makeMealEntry(id: 'e3', customerId: customerId, date: nov3, hadDinner: true),
      ];
      expect(BillingEngine.countBreakfasts(entries), 2);
    });

    test('counts dinners correctly', () {
      final entries = [
        makeMealEntry(id: 'e1', customerId: customerId, date: nov1, hadBreakfast: true),
        makeMealEntry(id: 'e2', customerId: customerId, date: nov2, hadBreakfast: true, hadDinner: true),
        makeMealEntry(id: 'e3', customerId: customerId, date: nov3, hadDinner: true),
      ];
      expect(BillingEngine.countDinners(entries), 2);
    });

    test('zero counts when no meals consumed', () {
      final entries = [
        makeMealEntry(id: 'e1', customerId: customerId, date: nov1),
      ];
      expect(BillingEngine.countBreakfasts(entries), 0);
      expect(BillingEngine.countDinners(entries), 0);
    });
  });

  group('BillingEngine — Meal Charges (Paisa)', () {
    test('customer consumes both meals for one day', () {
      final entries = [
        makeMealEntry(
          id: 'e1',
          customerId: customerId,
          date: nov1,
          hadBreakfast: true,
          hadDinner: true,
          breakfastPricePaisa: 8500,
          dinnerPricePaisa: 8500,
        ),
      ];
      // 85 + 85 = Rs. 170 = 17000 paisa
      expect(BillingEngine.totalMealChargePaisa(entries), 17000);
    });

    test('customer consumes only breakfast', () {
      final entries = [
        makeMealEntry(
          id: 'e1',
          customerId: customerId,
          date: nov1,
          hadBreakfast: true,
          breakfastPricePaisa: 8500,
          dinnerPricePaisa: 8500,
        ),
      ];
      expect(BillingEngine.totalMealChargePaisa(entries), 8500);
    });

    test('customer consumes only dinner', () {
      final entries = [
        makeMealEntry(
          id: 'e1',
          customerId: customerId,
          date: nov1,
          hadDinner: true,
          breakfastPricePaisa: 8500,
          dinnerPricePaisa: 8500,
        ),
      ];
      expect(BillingEngine.totalMealChargePaisa(entries), 8500);
    });

    test('customer skips a day — zero charge', () {
      final entries = [
        makeMealEntry(
          id: 'e1',
          customerId: customerId,
          date: nov1,
          hadBreakfast: false,
          hadDinner: false,
        ),
      ];
      expect(BillingEngine.totalMealChargePaisa(entries), 0);
    });

    test('customer skips multiple days — only charged for consumed meals', () {
      final entries = [
        makeMealEntry(id: 'e1', customerId: customerId, date: nov1, hadBreakfast: true, breakfastPricePaisa: 8500, dinnerPricePaisa: 8500),
        makeMealEntry(id: 'e2', customerId: customerId, date: nov2), // skipped
        makeMealEntry(id: 'e3', customerId: customerId, date: nov3, hadDinner: true, breakfastPricePaisa: 8500, dinnerPricePaisa: 8500),
      ];
      // 8500 + 8500 = 17000 paisa (Rs. 170)
      expect(BillingEngine.totalMealChargePaisa(entries), 17000);
    });

    test('meal charge uses price recorded at time of entry — not current price', () {
      // Even if prices change later, historical entries retain original price
      final entries = [
        makeMealEntry(
          id: 'e1',
          customerId: customerId,
          date: nov1,
          hadBreakfast: true,
          hadDinner: true,
          breakfastPricePaisa: 7500, // old price Rs. 75
          dinnerPricePaisa: 7500,
        ),
      ];
      // Should compute with Rs. 75 not any current price
      expect(BillingEngine.totalBreakfastChargePaisa(entries), 7500);
      expect(BillingEngine.totalDinnerChargePaisa(entries), 7500);
      expect(BillingEngine.totalMealChargePaisa(entries), 15000);
    });
  });

  // ═══════════════════════════════════════════════════════════════
  // ADDITIONAL ITEM TESTS
  // ═══════════════════════════════════════════════════════════════

  group('BillingEngine — Additional Items', () {
    test('single additional item', () {
      final entries = [
        makeAdditionalEntry(
          id: 'a1', customerId: customerId, date: nov1,
          quantity: 2, unitPricePaisa: 2000, // 2 eggs @ Rs. 20 each = Rs. 40
        ),
      ];
      expect(BillingEngine.totalAdditionalItemChargePaisa(entries), 4000);
    });

    test('multiple additional items with different quantities', () {
      final entries = [
        makeAdditionalEntry(id: 'a1', customerId: customerId, date: nov1, quantity: 2, unitPricePaisa: 2000), // 2 × Rs.20 = Rs.40
        makeAdditionalEntry(id: 'a2', customerId: customerId, date: nov1, quantity: 1, unitPricePaisa: 5000, menuItemName: 'Curd'), // 1 × Rs.50 = Rs.50
        makeAdditionalEntry(id: 'a3', customerId: customerId, date: nov2, quantity: 3, unitPricePaisa: 2000), // 3 × Rs.20 = Rs.60
      ];
      // Total: 4000 + 5000 + 6000 = 15000 paisa (Rs. 150)
      expect(BillingEngine.totalAdditionalItemChargePaisa(entries), 15000);
    });

    test('additional item price preserved at time of entry', () {
      // Unit price was Rs. 20 at time of entry; even if menu changes to Rs. 25, bill stays Rs. 20
      final entries = [
        makeAdditionalEntry(id: 'a1', customerId: customerId, date: nov1, quantity: 1, unitPricePaisa: 2000),
      ];
      expect(BillingEngine.totalAdditionalItemChargePaisa(entries), 2000);
    });

    test('zero total when no additional items', () {
      expect(BillingEngine.totalAdditionalItemChargePaisa([]), 0);
    });
  });

  // ═══════════════════════════════════════════════════════════════
  // PAYMENT TESTS
  // ═══════════════════════════════════════════════════════════════

  group('BillingEngine — Payments', () {
    test('full payment zeroes balance', () {
      final payments = [
        makePayment(id: 'p1', customerId: customerId, paymentDate: nov1, amountPaisa: 50000), // Rs. 500
      ];
      expect(BillingEngine.totalPaymentsPaisa(payments), 50000);
    });

    test('partial payment reduces balance correctly', () {
      final payments = [
        makePayment(id: 'p1', customerId: customerId, paymentDate: nov1, amountPaisa: 25000), // Rs. 250
      ];
      expect(BillingEngine.totalPaymentsPaisa(payments), 25000);
    });

    test('multiple partial payments sum correctly', () {
      final payments = [
        makePayment(id: 'p1', customerId: customerId, paymentDate: nov1, amountPaisa: 10000),
        makePayment(id: 'p2', customerId: customerId, paymentDate: nov2, amountPaisa: 15000),
      ];
      expect(BillingEngine.totalPaymentsPaisa(payments), 25000);
    });

    test('voided payments are excluded from total', () {
      final payments = [
        makePayment(id: 'p1', customerId: customerId, paymentDate: nov1, amountPaisa: 20000),
        makePayment(id: 'p2', customerId: customerId, paymentDate: nov2, amountPaisa: 10000, isVoided: true),
      ];
      expect(BillingEngine.totalPaymentsPaisa(payments), 20000);
    });
  });

  // ═══════════════════════════════════════════════════════════════
  // ADJUSTMENT TESTS
  // ═══════════════════════════════════════════════════════════════

  group('BillingEngine — Adjustments', () {
    test('positive adjustment increases charges', () {
      final adjustments = [
        makeAdjustment(id: 'adj1', customerId: customerId, amountPaisa: 5000),
      ];
      expect(BillingEngine.totalAdjustmentsPaisa(adjustments), 5000);
    });

    test('negative adjustment acts as discount', () {
      final adjustments = [
        makeAdjustment(id: 'adj1', customerId: customerId, amountPaisa: -3000),
      ];
      expect(BillingEngine.totalAdjustmentsPaisa(adjustments), -3000);
    });

    test('voided adjustments excluded', () {
      final adjustments = [
        makeAdjustment(id: 'adj1', customerId: customerId, amountPaisa: 5000),
        makeAdjustment(id: 'adj2', customerId: customerId, amountPaisa: 3000, isVoided: true),
      ];
      expect(BillingEngine.totalAdjustmentsPaisa(adjustments), 5000);
    });
  });

  // ═══════════════════════════════════════════════════════════════
  // MONTHLY BILL CALCULATION TESTS
  // ═══════════════════════════════════════════════════════════════

  group('BillingEngine — Monthly Bill Calculation', () {
    test('full month calculation — no previous balance, no adjustments', () {
      final mealEntries = [
        makeMealEntry(id: 'e1', customerId: customerId, date: nov1, hadBreakfast: true, hadDinner: true, breakfastPricePaisa: 8500, dinnerPricePaisa: 8500),
        makeMealEntry(id: 'e2', customerId: customerId, date: nov2, hadBreakfast: true, breakfastPricePaisa: 8500, dinnerPricePaisa: 8500),
      ];
      final additionalEntries = [
        makeAdditionalEntry(id: 'a1', customerId: customerId, date: nov1, quantity: 2, unitPricePaisa: 2000),
      ];
      final payments = [
        makePayment(id: 'p1', customerId: customerId, paymentDate: nov1, amountPaisa: 20000),
      ];

      final result = BillingEngine.calculateMonthlyBill(
        customerId: customerId,
        year: 2026,
        month: 11,
        mealEntries: mealEntries,
        additionalEntries: additionalEntries,
        adjustments: [],
        paymentsThisMonth: payments,
        previousBalancePaisa: 0,
      );

      // Breakfast: 2 × 8500 = 17000
      expect(result.breakfastCount, 2);
      expect(result.breakfastTotalPaisa, 17000);

      // Dinner: 1 × 8500 = 8500
      expect(result.dinnerCount, 1);
      expect(result.dinnerTotalPaisa, 8500);

      // Additional: 2 × 2000 = 4000
      expect(result.additionalItemsTotalPaisa, 4000);

      // Total charges = 17000 + 8500 + 4000 = 29500
      expect(result.currentChargesPaisa, 29500);

      // Outstanding = 0 + 29500 - 20000 = 9500
      expect(result.outstandingBalancePaisa, 9500);
    });

    test('previous balance carries over correctly', () {
      final mealEntries = [
        makeMealEntry(id: 'e1', customerId: customerId, date: nov1, hadBreakfast: true, hadDinner: true, breakfastPricePaisa: 8500, dinnerPricePaisa: 8500),
      ];
      final result = BillingEngine.calculateMonthlyBill(
        customerId: customerId,
        year: 2026,
        month: 11,
        mealEntries: mealEntries,
        additionalEntries: [],
        adjustments: [],
        paymentsThisMonth: [],
        previousBalancePaisa: 50000, // Rs. 500 owed from last month
      );

      // Current charges = 8500 + 8500 = 17000
      expect(result.currentChargesPaisa, 17000);
      // Outstanding = 50000 + 17000 - 0 = 67000
      expect(result.outstandingBalancePaisa, 67000);
    });

    test('overpayment creates credit (negative outstanding balance)', () {
      final mealEntries = [
        makeMealEntry(id: 'e1', customerId: customerId, date: nov1, hadDinner: true, breakfastPricePaisa: 8500, dinnerPricePaisa: 8500),
      ];
      final payments = [
        makePayment(id: 'p1', customerId: customerId, paymentDate: nov1, amountPaisa: 20000), // Rs. 200
      ];
      final result = BillingEngine.calculateMonthlyBill(
        customerId: customerId,
        year: 2026,
        month: 11,
        mealEntries: mealEntries,
        additionalEntries: [],
        adjustments: [],
        paymentsThisMonth: payments,
        previousBalancePaisa: 0,
      );

      // Charges = 8500 (dinner only)
      expect(result.currentChargesPaisa, 8500);
      // Outstanding = 0 + 8500 - 20000 = -11500 (credit)
      expect(result.outstandingBalancePaisa, -11500);
    });

    test('month-end totals with discount adjustment', () {
      final mealEntries = [
        makeMealEntry(id: 'e1', customerId: customerId, date: nov1, hadBreakfast: true, hadDinner: true, breakfastPricePaisa: 8500, dinnerPricePaisa: 8500),
      ];
      final adjustments = [
        makeAdjustment(id: 'adj1', customerId: customerId, amountPaisa: -5000), // Rs. 50 discount
      ];
      final result = BillingEngine.calculateMonthlyBill(
        customerId: customerId,
        year: 2026,
        month: 11,
        mealEntries: mealEntries,
        additionalEntries: [],
        adjustments: adjustments,
        paymentsThisMonth: [],
        previousBalancePaisa: 0,
      );

      // Meal = 8500 + 8500 = 17000; adjustment = -5000; total = 12000
      expect(result.currentChargesPaisa, 12000);
      expect(result.outstandingBalancePaisa, 12000);
    });

    test('empty month — no charges, no balance', () {
      final result = BillingEngine.calculateMonthlyBill(
        customerId: customerId,
        year: 2026,
        month: 11,
        mealEntries: [],
        additionalEntries: [],
        adjustments: [],
        paymentsThisMonth: [],
        previousBalancePaisa: 0,
      );
      expect(result.currentChargesPaisa, 0);
      expect(result.outstandingBalancePaisa, 0);
    });
  });

  // ═══════════════════════════════════════════════════════════════
  // OUTSTANDING BALANCE TESTS
  // ═══════════════════════════════════════════════════════════════

  group('BillingEngine — Overall Outstanding Balance', () {
    test('computes overall outstanding from all history', () {
      final meals = [
        makeMealEntry(id: 'e1', customerId: customerId, date: nov1, hadBreakfast: true, hadDinner: true, breakfastPricePaisa: 8500, dinnerPricePaisa: 8500),
      ];
      final additional = [
        makeAdditionalEntry(id: 'a1', customerId: customerId, date: nov1, quantity: 2, unitPricePaisa: 2000),
      ];
      final payments = [
        makePayment(id: 'p1', customerId: customerId, paymentDate: nov1, amountPaisa: 10000),
      ];

      final balance = BillingEngine.computeOutstandingBalance(
        allMealEntries: meals,
        allAdditionalEntries: additional,
        allAdjustments: [],
        allPayments: payments,
      );

      // 17000 + 4000 - 10000 = 11000
      expect(balance, 11000);
    });
  });

  // ═══════════════════════════════════════════════════════════════
  // MEAL ENTRY MODEL TESTS
  // ═══════════════════════════════════════════════════════════════

  group('MealEntry model', () {
    test('totalPaisa computed correctly for both meals', () {
      final entry = makeMealEntry(
        id: 'e1', customerId: customerId, date: nov1,
        hadBreakfast: true, hadDinner: true,
        breakfastPricePaisa: 8500, dinnerPricePaisa: 8500,
      );
      expect(entry.totalPaisa, 17000);
    });

    test('totalPaisa is zero when no meals consumed', () {
      final entry = makeMealEntry(id: 'e1', customerId: customerId, date: nov1);
      expect(entry.totalPaisa, 0);
    });
  });

  group('AdditionalItemEntry model', () {
    test('totalPaisa = quantity × unitPrice', () {
      final entry = makeAdditionalEntry(
        id: 'a1', customerId: customerId, date: nov1,
        quantity: 3, unitPricePaisa: 2000,
      );
      expect(entry.totalPaisa, 6000);
    });
  });
}
