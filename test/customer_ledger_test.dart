import 'package:flutter_test/flutter_test.dart';
import 'package:food_billing/data/models/models.dart';
import 'package:food_billing/data/repositories/additional_item_entry_repository.dart';
import 'package:food_billing/data/repositories/adjustment_repository.dart';
import 'package:food_billing/data/repositories/meal_entry_repository.dart';
import 'package:food_billing/data/repositories/payment_repository.dart';
import 'package:food_billing/providers/customer_ledger_provider.dart';

class _FakeMealRepo implements MealEntryRepository {
  final List<MealEntry> _entries = [];
  void add(MealEntry e) => _entries.add(e);

  @override
  List<MealEntry> getMealEntriesForCustomer(String customerId) =>
      _entries.where((e) => e.customerId == customerId).toList();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeExtraRepo implements AdditionalItemEntryRepository {
  final List<AdditionalItemEntry> _entries = [];
  void add(AdditionalItemEntry e) => _entries.add(e);

  @override
  List<AdditionalItemEntry> getEntriesForCustomer(String customerId) =>
      _entries.where((e) => e.customerId == customerId).toList();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeAdjustmentRepo implements AdjustmentRepository {
  final List<Adjustment> _entries = [];
  void add(Adjustment a) => _entries.add(a);

  @override
  List<Adjustment> getAdjustmentsForCustomer(String customerId) =>
      _entries.where((a) => a.customerId == customerId && !a.isVoided).toList();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakePaymentRepo implements PaymentRepository {
  final List<Payment> _entries = [];
  void add(Payment p) => _entries.add(p);

  @override
  List<Payment> getPaymentsForCustomer(String customerId) =>
      _entries.where((p) => p.customerId == customerId && !p.isVoided).toList();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('CustomerLedgerProvider Tests', () {
    late _FakeMealRepo mealRepo;
    late _FakeExtraRepo extraRepo;
    late _FakeAdjustmentRepo adjustmentRepo;
    late _FakePaymentRepo paymentRepo;

    setUp(() {
      mealRepo = _FakeMealRepo();
      extraRepo = _FakeExtraRepo();
      adjustmentRepo = _FakeAdjustmentRepo();
      paymentRepo = _FakePaymentRepo();
    });

    test('Ledger computes running balance chronologically across meals, extras, adjustments, and payments', () {
      final now = DateTime.now();

      // Day 1: Breakfast (Rs. 85) + Dinner (Rs. 85) = Rs. 170
      mealRepo.add(
        MealEntry(
          id: 'm1',
          customerId: 'cust1',
          date: DateTime(2026, 11, 1),
          hadBreakfast: true,
          hadDinner: true,
          breakfastPricePaisa: 8500,
          dinnerPricePaisa: 8500,
          createdAt: now,
          updatedAt: now,
        ),
      );

      // Day 2: 2x Boiled Egg (Rs. 30 each = Rs. 60)
      extraRepo.add(
        AdditionalItemEntry(
          id: 'e1',
          customerId: 'cust1',
          menuItemId: 'egg1',
          menuItemName: 'Boiled Egg',
          date: DateTime(2026, 11, 2),
          quantity: 2,
          unitPricePaisa: 3000,
          createdAt: now,
          updatedAt: now,
        ),
      );

      // Day 3: Adjustment discount -Rs. 30
      adjustmentRepo.add(
        Adjustment(
          id: 'a1',
          customerId: 'cust1',
          adjustmentDate: DateTime(2026, 11, 3),
          amountPaisa: -3000,
          reason: 'Promotional discount',
          createdAt: now,
          updatedAt: now,
        ),
      );

      // Day 4: Payment of Rs. 150
      paymentRepo.add(
        Payment(
          id: 'p1',
          customerId: 'cust1',
          paymentDate: DateTime(2026, 11, 4),
          amountPaisa: 15000,
          method: PaymentMethod.cash,
          createdAt: now,
          updatedAt: now,
        ),
      );

      final provider = CustomerLedgerProvider(
        customerId: 'cust1',
        mealRepo: mealRepo,
        extraRepo: extraRepo,
        adjustmentRepo: adjustmentRepo,
        paymentRepo: paymentRepo,
      );

      // Total Charges: 170 (meals) + 60 (extras) - 30 (discount) = 200 (in Paisa: 20000)
      // Total Paid: 150 (in Paisa: 15000)
      // Outstanding: 50 (in Paisa: 5000)
      expect(provider.totalOutstandingBalancePaisa, 5000);
      expect(provider.filteredItems.length, 4);

      // Items are sorted descending (newest first)
      final items = provider.filteredItems;
      expect(items[0].type, LedgerItemType.payment);
      expect(items[0].amountPaisa, -15000);
      expect(items[0].runningBalancePaisa, 5000);

      expect(items[1].type, LedgerItemType.adjustment);
      expect(items[1].amountPaisa, -3000);
      expect(items[1].runningBalancePaisa, 20000);

      expect(items[2].type, LedgerItemType.additionalItem);
      expect(items[2].amountPaisa, 6000);
      expect(items[2].runningBalancePaisa, 23000);

      expect(items[3].type, LedgerItemType.meal);
      expect(items[3].amountPaisa, 17000);
      expect(items[3].runningBalancePaisa, 17000);
    });

    test('Month filter isolates transactions to selected month', () {
      final now = DateTime.now();

      // November transaction
      mealRepo.add(
        MealEntry(
          id: 'm1',
          customerId: 'cust1',
          date: DateTime(2026, 11, 15),
          hadBreakfast: true,
          hadDinner: false,
          breakfastPricePaisa: 8500,
          dinnerPricePaisa: 8500,
          createdAt: now,
          updatedAt: now,
        ),
      );

      // October transaction
      mealRepo.add(
        MealEntry(
          id: 'm2',
          customerId: 'cust1',
          date: DateTime(2026, 10, 20),
          hadBreakfast: false,
          hadDinner: true,
          breakfastPricePaisa: 8500,
          dinnerPricePaisa: 8500,
          createdAt: now,
          updatedAt: now,
        ),
      );

      final provider = CustomerLedgerProvider(
        customerId: 'cust1',
        mealRepo: mealRepo,
        extraRepo: extraRepo,
        adjustmentRepo: adjustmentRepo,
        paymentRepo: paymentRepo,
      );

      expect(provider.filteredItems.length, 2);

      // Filter November 2026
      provider.filterByMonth(2026, 11);
      expect(provider.filteredItems.length, 1);
      expect(provider.filteredItems.first.date.month, 11);

      // Filter October 2026
      provider.filterByMonth(2026, 10);
      expect(provider.filteredItems.length, 1);
      expect(provider.filteredItems.first.date.month, 10);

      // Clear filter
      provider.clearFilter();
      expect(provider.filteredItems.length, 2);
    });
  });
}
