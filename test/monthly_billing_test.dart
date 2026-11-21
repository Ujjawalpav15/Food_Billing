import 'package:flutter_test/flutter_test.dart';
import 'package:food_billing/data/models/models.dart';
import 'package:food_billing/data/repositories/additional_item_entry_repository.dart';
import 'package:food_billing/data/repositories/adjustment_repository.dart';
import 'package:food_billing/data/repositories/customer_repository.dart';
import 'package:food_billing/data/repositories/meal_entry_repository.dart';
import 'package:food_billing/data/repositories/monthly_bill_repository.dart';
import 'package:food_billing/data/repositories/payment_repository.dart';
import 'package:food_billing/data/repositories/shop_profile_repository.dart';
import 'package:food_billing/providers/monthly_bill_provider.dart';

class _FakeBillRepo implements MonthlyBillRepository {
  final Map<String, MonthlyBill> _storage = {};

  @override
  Future<void> saveBill(MonthlyBill bill) async {
    _storage[bill.id] = bill;
  }

  @override
  Future<void> updateBill(MonthlyBill bill) async {
    _storage[bill.id] = bill;
  }

  @override
  MonthlyBill? getBill(String id) => _storage[id];

  @override
  MonthlyBill? getBillForMonth(String customerId, int year, int month) {
    return _storage.values.cast<MonthlyBill?>().firstWhere(
          (b) =>
              b!.customerId == customerId &&
              b.billingYear == year &&
              b.billingMonth == month,
          orElse: () => null,
        );
  }

  @override
  List<MonthlyBill> getBillsForCustomer(String customerId) =>
      _storage.values.where((b) => b.customerId == customerId).toList();

  @override
  List<MonthlyBill> getAllBillsForMonth(int year, int month) => _storage.values
      .where((b) => b.billingYear == year && b.billingMonth == month)
      .toList();
}

class _FakeMealRepo implements MealEntryRepository {
  final List<MealEntry> _entries = [];
  void add(MealEntry e) => _entries.add(e);

  @override
  List<MealEntry> getMealEntriesForCustomer(String customerId) =>
      _entries.where((e) => e.customerId == customerId).toList();

  @override
  List<MealEntry> getMealEntriesForMonth(
          String customerId, int year, int month) =>
      _entries
          .where((e) =>
              e.customerId == customerId &&
              e.date.year == year &&
              e.date.month == month)
          .toList();

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
  List<AdditionalItemEntry> getEntriesForMonth(
          String customerId, int year, int month) =>
      _entries
          .where((e) =>
              e.customerId == customerId &&
              e.date.year == year &&
              e.date.month == month)
          .toList();

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
  List<Adjustment> getAdjustmentsForMonth(
          String customerId, int year, int month) =>
      _entries
          .where((a) =>
              a.customerId == customerId &&
              !a.isVoided &&
              a.adjustmentDate.year == year &&
              a.adjustmentDate.month == month)
          .toList();

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
  List<Payment> getPaymentsForMonth(String customerId, int year, int month) =>
      _entries
          .where((p) =>
              p.customerId == customerId &&
              !p.isVoided &&
              p.paymentDate.year == year &&
              p.paymentDate.month == month)
          .toList();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeCustomerRepo implements CustomerRepository {
  final List<Customer> _customers = [];
  void add(Customer c) => _customers.add(c);

  @override
  List<Customer> getAllCustomers() => List.from(_customers);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeShopRepo implements ShopProfileRepository {
  ShopProfile? _profile;

  _FakeShopRepo([this._profile]);

  @override
  ShopProfile? getProfile() => _profile;

  @override
  bool get isSetUp => _profile != null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('MonthlyBillProvider Tests', () {
    late _FakeBillRepo billRepo;
    late _FakeMealRepo mealRepo;
    late _FakeExtraRepo extraRepo;
    late _FakeAdjustmentRepo adjustmentRepo;
    late _FakePaymentRepo paymentRepo;
    late _FakeCustomerRepo customerRepo;
    late _FakeShopRepo shopRepo;

    setUp(() {
      billRepo = _FakeBillRepo();
      mealRepo = _FakeMealRepo();
      extraRepo = _FakeExtraRepo();
      adjustmentRepo = _FakeAdjustmentRepo();
      paymentRepo = _FakePaymentRepo();
      customerRepo = _FakeCustomerRepo();

      final now = DateTime.now();
      shopRepo = _FakeShopRepo(
        ShopProfile(
          id: 'shop1',
          shopName: 'Everest Mess',
          ownerName: 'Shyam',
          phoneNumber: '9841000000',
          address: 'Pokhara',
          createdAt: now,
          updatedAt: now,
        ),
      );

      customerRepo.add(
        Customer(
          id: 'c1',
          name: 'Nabin',
          phoneNumber: '9800000001',
          createdAt: now,
          updatedAt: now,
        ),
      );
    });

    test('Monthly bill calculates accurately for meals, extras, payments and previous balance', () {
      final now = DateTime.now();

      // October prior meal: Rs. 170
      mealRepo.add(
        MealEntry(
          id: 'm_oct',
          customerId: 'c1',
          date: DateTime(2026, 10, 15),
          hadBreakfast: true,
          hadDinner: true,
          breakfastPricePaisa: 8500,
          dinnerPricePaisa: 8500,
          createdAt: now,
          updatedAt: now,
        ),
      );

      // November: 20 Breakfasts @ Rs. 85 = Rs. 1700
      for (int day = 1; day <= 20; day++) {
        mealRepo.add(
          MealEntry(
            id: 'm_nov_$day',
            customerId: 'c1',
            date: DateTime(2026, 11, day),
            hadBreakfast: true,
            hadDinner: false,
            breakfastPricePaisa: 8500,
            dinnerPricePaisa: 8500,
            createdAt: now,
            updatedAt: now,
          ),
        );
      }

      // November extras: 5x Tea @ Rs. 20 = Rs. 100
      extraRepo.add(
        AdditionalItemEntry(
          id: 'e1',
          customerId: 'c1',
          menuItemId: 'tea',
          menuItemName: 'Tea / Chiya',
          date: DateTime(2026, 11, 5),
          quantity: 5,
          unitPricePaisa: 2000,
          createdAt: now,
          updatedAt: now,
        ),
      );

      // November payment: Rs. 1000 paid
      paymentRepo.add(
        Payment(
          id: 'p1',
          customerId: 'c1',
          paymentDate: DateTime(2026, 11, 10),
          amountPaisa: 100000,
          method: PaymentMethod.esewa,
          createdAt: now,
          updatedAt: now,
        ),
      );

      final provider = MonthlyBillProvider(
        billRepo: billRepo,
        mealRepo: mealRepo,
        extraRepo: extraRepo,
        adjustmentRepo: adjustmentRepo,
        paymentRepo: paymentRepo,
        customerRepo: customerRepo,
        shopRepo: shopRepo,
        initialYear: 2026,
        initialMonth: 11,
      );

      expect(provider.allSummaries.length, 1);
      final bill = provider.allSummaries.first.bill;

      expect(bill.breakfastCount, 20);
      expect(bill.dinnerCount, 0);
      expect(bill.breakfastTotalPaisa, 170000); // Rs. 1700
      expect(bill.additionalItemsTotalPaisa, 10000); // Rs. 100
      expect(bill.totalChargesPaisa, 180000); // Rs. 1800
      expect(bill.previousBalancePaisa, 17000); // Rs. 170 brought forward from Oct
      expect(bill.paymentsReceivedPaisa, 100000); // Rs. 1000 paid
      // Outstanding: 170 + 1800 - 1000 = 970 (in Paisa: 97000)
      expect(bill.outstandingBalancePaisa, 97000);
      expect(bill.status, BillStatus.draft);
    });

    test('Finalizing a bill locks it and reopening unlocks it', () async {
      final provider = MonthlyBillProvider(
        billRepo: billRepo,
        mealRepo: mealRepo,
        extraRepo: extraRepo,
        adjustmentRepo: adjustmentRepo,
        paymentRepo: paymentRepo,
        customerRepo: customerRepo,
        shopRepo: shopRepo,
        initialYear: 2026,
        initialMonth: 11,
      );

      final bill = provider.allSummaries.first.bill;
      expect(bill.status, BillStatus.draft);

      // Finalize
      await provider.finalizeBill(bill);
      expect(provider.allSummaries.first.bill.status, BillStatus.finalized);
      expect(provider.finalizedCount, 1);
      expect(provider.draftCount, 0);

      // Reopen
      await provider.reopenBill(bill);
      expect(provider.allSummaries.first.bill.status, BillStatus.amended);
      expect(provider.finalizedCount, 0);
      expect(provider.draftCount, 1);
    });
  });
}
