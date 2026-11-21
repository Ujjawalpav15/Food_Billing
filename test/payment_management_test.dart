import 'package:flutter_test/flutter_test.dart';
import 'package:food_billing/data/models/models.dart';
import 'package:food_billing/data/repositories/additional_item_entry_repository.dart';
import 'package:food_billing/data/repositories/adjustment_repository.dart';
import 'package:food_billing/data/repositories/customer_repository.dart';
import 'package:food_billing/data/repositories/meal_entry_repository.dart';
import 'package:food_billing/data/repositories/payment_repository.dart';
import 'package:food_billing/providers/payment_provider.dart';

class _FakePaymentRepo implements PaymentRepository {
  final Map<String, Payment> _storage = {};

  @override
  Future<void> addPayment(Payment payment) async {
    _storage[payment.id] = payment;
  }

  @override
  Future<void> updatePayment(Payment payment) async {
    _storage[payment.id] = payment;
  }

  @override
  Future<void> voidPayment(String id) async {
    final p = _storage[id];
    if (p != null) {
      p.isVoided = true;
    }
  }

  @override
  Payment? getPayment(String id) => _storage[id];

  @override
  List<Payment> getPaymentsForCustomer(String customerId) =>
      _storage.values.where((p) => p.customerId == customerId && !p.isVoided).toList();

  @override
  List<Payment> getPaymentsForMonth(String customerId, int year, int month) =>
      _storage.values
          .where((p) =>
              p.customerId == customerId &&
              !p.isVoided &&
              p.paymentDate.year == year &&
              p.paymentDate.month == month)
          .toList();

  @override
  List<Payment> getAllPayments() =>
      _storage.values.where((p) => !p.isVoided).toList()
        ..sort((a, b) => b.paymentDate.compareTo(a.paymentDate));

  @override
  List<Payment> getAllPaymentsForMonth(int year, int month) =>
      _storage.values
          .where((p) =>
              !p.isVoided &&
              p.paymentDate.year == year &&
              p.paymentDate.month == month)
          .toList();

  @override
  int getTotalPaymentsPaisa(String customerId) =>
      _storage.values
          .where((p) => p.customerId == customerId && !p.isVoided)
          .fold(0, (sum, p) => sum + p.amountPaisa);

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

class _FakeMealRepo implements MealEntryRepository {
  final List<MealEntry> _entries = [];
  void add(MealEntry m) => _entries.add(m);

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

void main() {
  group('PaymentProvider Tests', () {
    late _FakePaymentRepo paymentRepo;
    late _FakeCustomerRepo customerRepo;
    late _FakeMealRepo mealRepo;
    late _FakeExtraRepo extraRepo;
    late _FakeAdjustmentRepo adjustmentRepo;

    setUp(() {
      paymentRepo = _FakePaymentRepo();
      customerRepo = _FakeCustomerRepo();
      mealRepo = _FakeMealRepo();
      extraRepo = _FakeExtraRepo();
      adjustmentRepo = _FakeAdjustmentRepo();

      final now = DateTime.now();
      customerRepo.add(
        Customer(
          id: 'cust1',
          name: 'Rohan Sharma',
          phoneNumber: '9841234567',
          createdAt: now,
          updatedAt: now,
        ),
      );
    });

    test('Record payment persists and updates collection totals', () async {
      final provider = PaymentProvider(
        paymentRepo: paymentRepo,
        customerRepo: customerRepo,
        mealRepo: mealRepo,
        extraRepo: extraRepo,
        adjustmentRepo: adjustmentRepo,
      );

      expect(provider.allPayments, isEmpty);
      expect(provider.totalCollectedPaisa, 0);

      // Record Rs. 1,000 cash payment
      final success = await provider.recordPayment(
        customerId: 'cust1',
        date: DateTime(2026, 11, 20),
        amountPaisa: 100000,
        method: PaymentMethod.cash,
        notes: 'Monthly advance',
      );

      expect(success, isTrue);
      expect(provider.allPayments.length, 1);
      expect(provider.totalCollectedPaisa, 100000); // Rs. 1000
      expect(provider.allPayments.first.customer?.name, 'Rohan Sharma');
      expect(provider.allPayments.first.payment.method, PaymentMethod.cash);
    });

    test('Payment methods filter correctly isolates payments', () async {
      final provider = PaymentProvider(
        paymentRepo: paymentRepo,
        customerRepo: customerRepo,
        mealRepo: mealRepo,
        extraRepo: extraRepo,
        adjustmentRepo: adjustmentRepo,
      );

      await provider.recordPayment(
        customerId: 'cust1',
        date: DateTime(2026, 11, 20),
        amountPaisa: 50000,
        method: PaymentMethod.cash,
      );

      await provider.recordPayment(
        customerId: 'cust1',
        date: DateTime(2026, 11, 21),
        amountPaisa: 150000,
        method: PaymentMethod.esewa,
        referenceNumber: 'ESEWA-1234',
      );

      expect(provider.allPayments.length, 2);
      expect(provider.getMethodTotalPaisa(PaymentMethod.cash), 50000);
      expect(provider.getMethodTotalPaisa(PaymentMethod.esewa), 150000);

      // Filter by eSewa
      provider.setMethodFilter(PaymentMethod.esewa);
      expect(provider.filteredPayments.length, 1);
      expect(provider.filteredPayments.first.payment.referenceNumber, 'ESEWA-1234');

      // Clear filter
      provider.clearFilters();
      expect(provider.filteredPayments.length, 2);
    });

    test('Voiding payment soft-deletes and removes from active totals', () async {
      final provider = PaymentProvider(
        paymentRepo: paymentRepo,
        customerRepo: customerRepo,
        mealRepo: mealRepo,
        extraRepo: extraRepo,
        adjustmentRepo: adjustmentRepo,
      );

      await provider.recordPayment(
        customerId: 'cust1',
        date: DateTime(2026, 11, 20),
        amountPaisa: 80000,
        method: PaymentMethod.khalti,
      );

      expect(provider.allPayments.length, 1);
      final paymentId = provider.allPayments.first.payment.id;

      final voidSuccess = await provider.voidPayment(paymentId);
      expect(voidSuccess, isTrue);
      expect(provider.allPayments, isEmpty);
      expect(provider.totalCollectedPaisa, 0);

      // Verify in raw storage that isVoided is true (audit trail preserved)
      final raw = paymentRepo.getPayment(paymentId);
      expect(raw, isNotNull);
      expect(raw!.isVoided, isTrue);
    });

    test('Customer balance calculates charges minus payments', () async {
      final now = DateTime.now();

      // Meal charge: Rs. 170 (17000 paisa)
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

      final provider = PaymentProvider(
        paymentRepo: paymentRepo,
        customerRepo: customerRepo,
        mealRepo: mealRepo,
        extraRepo: extraRepo,
        adjustmentRepo: adjustmentRepo,
      );

      // Initially owes Rs. 170
      expect(provider.getCustomerBalancePaisa('cust1'), 17000);

      // Customer pays Rs. 200 (overpayment)
      await provider.recordPayment(
        customerId: 'cust1',
        date: DateTime(2026, 11, 2),
        amountPaisa: 20000,
        method: PaymentMethod.cash,
      );

      // Outstanding balance is -3000 paisa (-Rs. 30, store credit!)
      expect(provider.getCustomerBalancePaisa('cust1'), -3000);
    });
  });
}
