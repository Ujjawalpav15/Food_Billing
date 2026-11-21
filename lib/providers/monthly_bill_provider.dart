import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../data/models/models.dart';
import '../data/repositories/additional_item_entry_repository.dart';
import '../data/repositories/adjustment_repository.dart';
import '../data/repositories/customer_repository.dart';
import '../data/repositories/meal_entry_repository.dart';
import '../data/repositories/monthly_bill_repository.dart';
import '../data/repositories/payment_repository.dart';
import '../data/repositories/shop_profile_repository.dart';
import '../domain/billing_engine.dart';

class CustomerBillSummary {
  final Customer customer;
  final MonthlyBill bill;
  final bool hasActivity;

  CustomerBillSummary({
    required this.customer,
    required this.bill,
    required this.hasActivity,
  });
}

class MonthlyBillProvider extends ChangeNotifier {
  final MonthlyBillRepository _billRepo;
  final MealEntryRepository _mealRepo;
  final AdditionalItemEntryRepository _extraRepo;
  final AdjustmentRepository _adjustmentRepo;
  final PaymentRepository _paymentRepo;
  final CustomerRepository _customerRepo;
  final ShopProfileRepository _shopRepo;
  static const _uuid = Uuid();

  late int _selectedYear;
  late int _selectedMonth;

  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';
  BillStatus? _statusFilter;

  // Cached bill summaries for (selectedYear, selectedMonth)
  List<CustomerBillSummary> _summaries = [];

  MonthlyBillProvider({
    required MonthlyBillRepository billRepo,
    required MealEntryRepository mealRepo,
    required AdditionalItemEntryRepository extraRepo,
    required AdjustmentRepository adjustmentRepo,
    required PaymentRepository paymentRepo,
    required CustomerRepository customerRepo,
    required ShopProfileRepository shopRepo,
    int? initialYear,
    int? initialMonth,
  })  : _billRepo = billRepo,
        _mealRepo = mealRepo,
        _extraRepo = extraRepo,
        _adjustmentRepo = adjustmentRepo,
        _paymentRepo = paymentRepo,
        _customerRepo = customerRepo,
        _shopRepo = shopRepo {
    final now = DateTime.now();
    _selectedYear = initialYear ?? now.year;
    _selectedMonth = initialMonth ?? now.month;
    loadBills();
  }

  // ── Getters ──────────────────────────────────────────────────────────────

  int get selectedYear => _selectedYear;
  int get selectedMonth => _selectedMonth;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  BillStatus? get statusFilter => _statusFilter;

  ShopProfile? get shopProfile => _shopRepo.getProfile();

  List<CustomerBillSummary> get allSummaries => List.unmodifiable(_summaries);

  List<CustomerBillSummary> get filteredSummaries {
    return _summaries.where((s) {
      if (_statusFilter != null && s.bill.status != _statusFilter) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final nameMatches = s.customer.name.toLowerCase().contains(q);
        final phoneMatches = s.customer.phoneNumber != null &&
            s.customer.phoneNumber!.toLowerCase().contains(q);
        return nameMatches || phoneMatches;
      }
      return true;
    }).toList();
  }

  int get totalBilledChargesPaisa =>
      _summaries.fold(0, (sum, s) => sum + s.bill.totalChargesPaisa);

  int get totalPaymentsReceivedPaisa =>
      _summaries.fold(0, (sum, s) => sum + s.bill.paymentsReceivedPaisa);

  int get totalOutstandingDuePaisa =>
      _summaries.fold(0, (sum, s) => sum + s.bill.outstandingBalancePaisa);

  int get finalizedCount =>
      _summaries.where((s) => s.bill.status == BillStatus.finalized).length;

  int get draftCount =>
      _summaries.where((s) => s.bill.status != BillStatus.finalized).length;

  // ── Period Controls ──────────────────────────────────────────────────────

  void setSelectedMonth(int year, int month) {
    if (_selectedYear != year || _selectedMonth != month) {
      _selectedYear = year;
      _selectedMonth = month;
      loadBills();
    }
  }

  void goToPreviousMonth() {
    if (_selectedMonth == 1) {
      setSelectedMonth(_selectedYear - 1, 12);
    } else {
      setSelectedMonth(_selectedYear, _selectedMonth - 1);
    }
  }

  void goToNextMonth() {
    if (_selectedMonth == 12) {
      setSelectedMonth(_selectedYear + 1, 1);
    } else {
      setSelectedMonth(_selectedYear, _selectedMonth + 1);
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query.trim();
    notifyListeners();
  }

  void setStatusFilter(BillStatus? status) {
    _statusFilter = status;
    notifyListeners();
  }

  // ── Calculation & Loading ────────────────────────────────────────────────

  int computePreviousBalance(String customerId, int year, int month) {
    final firstDayOfMonth = DateTime(year, month, 1);
    final priorMeals = _mealRepo
        .getMealEntriesForCustomer(customerId)
        .where((m) => m.date.isBefore(firstDayOfMonth))
        .toList();
    final priorExtras = _extraRepo
        .getEntriesForCustomer(customerId)
        .where((e) => e.date.isBefore(firstDayOfMonth))
        .toList();
    final priorAdjustments = _adjustmentRepo
        .getAdjustmentsForCustomer(customerId)
        .where((a) => a.adjustmentDate.isBefore(firstDayOfMonth))
        .toList();
    final priorPayments = _paymentRepo
        .getPaymentsForCustomer(customerId)
        .where((p) => p.paymentDate.isBefore(firstDayOfMonth))
        .toList();

    return BillingEngine.computeOutstandingBalance(
      allMealEntries: priorMeals,
      allAdditionalEntries: priorExtras,
      allAdjustments: priorAdjustments,
      allPayments: priorPayments,
    );
  }

  MonthlyBill computeBillForCustomer(String customerId, int year, int month) {
    // 1. Check if finalized bill already exists; if so, preserve it!
    final existing = _billRepo.getBillForMonth(customerId, year, month);
    if (existing != null && existing.status == BillStatus.finalized) {
      return existing;
    }

    // 2. Otherwise calculate current charges from data layer
    final meals = _mealRepo.getMealEntriesForMonth(customerId, year, month);
    final extras = _extraRepo.getEntriesForMonth(customerId, year, month);
    final adjustments =
        _adjustmentRepo.getAdjustmentsForMonth(customerId, year, month);
    final payments =
        _paymentRepo.getPaymentsForMonth(customerId, year, month);

    final previousBalance = computePreviousBalance(customerId, year, month);

    final result = BillingEngine.calculateMonthlyBill(
      customerId: customerId,
      year: year,
      month: month,
      mealEntries: meals,
      additionalEntries: extras,
      adjustments: adjustments,
      paymentsThisMonth: payments,
      previousBalancePaisa: previousBalance,
    );

    final now = DateTime.now();

    if (existing != null) {
      existing.breakfastCount = result.breakfastCount;
      existing.breakfastTotalPaisa = result.breakfastTotalPaisa;
      existing.dinnerCount = result.dinnerCount;
      existing.dinnerTotalPaisa = result.dinnerTotalPaisa;
      existing.additionalItemsTotalPaisa = result.additionalItemsTotalPaisa;
      existing.adjustmentsTotalPaisa = result.adjustmentsTotalPaisa;
      existing.previousBalancePaisa = result.previousBalancePaisa;
      existing.paymentsReceivedPaisa = result.paymentsReceivedPaisa;
      existing.updatedAt = now;
      return existing;
    }

    return MonthlyBill(
      id: _uuid.v4(),
      customerId: customerId,
      billingYear: year,
      billingMonth: month,
      breakfastCount: result.breakfastCount,
      breakfastTotalPaisa: result.breakfastTotalPaisa,
      dinnerCount: result.dinnerCount,
      dinnerTotalPaisa: result.dinnerTotalPaisa,
      additionalItemsTotalPaisa: result.additionalItemsTotalPaisa,
      adjustmentsTotalPaisa: result.adjustmentsTotalPaisa,
      previousBalancePaisa: result.previousBalancePaisa,
      paymentsReceivedPaisa: result.paymentsReceivedPaisa,
      status: BillStatus.draft,
      createdAt: now,
      updatedAt: now,
    );
  }

  void loadBills() {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final customers = _customerRepo.getAllCustomers();
      customers.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

      final list = <CustomerBillSummary>[];

      for (final customer in customers) {
        final bill = computeBillForCustomer(customer.id, _selectedYear, _selectedMonth);
        final hasActivity = bill.breakfastCount > 0 ||
            bill.dinnerCount > 0 ||
            bill.additionalItemsTotalPaisa > 0 ||
            bill.previousBalancePaisa != 0 ||
            bill.paymentsReceivedPaisa > 0 ||
            customer.isActive;

        if (hasActivity) {
          list.add(
            CustomerBillSummary(
              customer: customer,
              bill: bill,
              hasActivity: hasActivity,
            ),
          );
        }
      }

      _summaries = list;
    } catch (e) {
      _errorMessage = 'Failed to load monthly bills: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Actions ──────────────────────────────────────────────────────────────

  /// Save or finalize a single bill.
  Future<void> finalizeBill(MonthlyBill bill) async {
    bill.status = BillStatus.finalized;
    bill.finalizedAt = DateTime.now();
    bill.updatedAt = DateTime.now();
    await _billRepo.saveBill(bill);
    loadBills();
  }

  /// Reopen an already finalized bill for corrections.
  Future<void> reopenBill(MonthlyBill bill) async {
    bill.status = BillStatus.amended;
    bill.updatedAt = DateTime.now();
    await _billRepo.saveBill(bill);
    loadBills();
  }

  /// Generate & save draft statements for all customers with activity this month.
  Future<void> generateAllBills() async {
    _isLoading = true;
    notifyListeners();

    try {
      for (final s in _summaries) {
        if (s.bill.status != BillStatus.finalized) {
          await _billRepo.saveBill(s.bill);
        }
      }
      loadBills();
    } catch (e) {
      _errorMessage = 'Failed to generate all bills: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<AdditionalItemEntry> getExtraItemsForBill(String customerId) {
    return _extraRepo.getEntriesForMonth(customerId, _selectedYear, _selectedMonth);
  }

  List<Adjustment> getAdjustmentsForBill(String customerId) {
    return _adjustmentRepo.getAdjustmentsForMonth(customerId, _selectedYear, _selectedMonth);
  }

  List<Payment> getPaymentsForBill(String customerId) {
    return _paymentRepo.getPaymentsForMonth(customerId, _selectedYear, _selectedMonth);
  }
}
