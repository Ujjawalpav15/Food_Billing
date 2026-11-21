import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../data/models/models.dart';
import '../data/repositories/additional_item_entry_repository.dart';
import '../data/repositories/adjustment_repository.dart';
import '../data/repositories/customer_repository.dart';
import '../data/repositories/meal_entry_repository.dart';
import '../data/repositories/payment_repository.dart';
import '../domain/billing_engine.dart';

class PaymentWithCustomer {
  final Payment payment;
  final Customer? customer;

  PaymentWithCustomer({required this.payment, this.customer});
}

class PaymentProvider extends ChangeNotifier {
  final PaymentRepository _paymentRepo;
  final CustomerRepository _customerRepo;
  final MealEntryRepository _mealRepo;
  final AdditionalItemEntryRepository _extraRepo;
  final AdjustmentRepository _adjustmentRepo;
  static const _uuid = Uuid();

  List<PaymentWithCustomer> _payments = [];
  PaymentMethod? _methodFilter;
  String? _customerFilterId;
  String _searchQuery = '';
  int? _filterYear;
  int? _filterMonth;
  bool _isLoading = false;
  String? _errorMessage;

  PaymentProvider({
    required PaymentRepository paymentRepo,
    required CustomerRepository customerRepo,
    required MealEntryRepository mealRepo,
    required AdditionalItemEntryRepository extraRepo,
    required AdjustmentRepository adjustmentRepo,
  })  : _paymentRepo = paymentRepo,
        _customerRepo = customerRepo,
        _mealRepo = mealRepo,
        _extraRepo = extraRepo,
        _adjustmentRepo = adjustmentRepo {
    loadPayments();
  }

  // ── Getters ──────────────────────────────────────────────────────────────

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  PaymentMethod? get methodFilter => _methodFilter;
  String? get customerFilterId => _customerFilterId;
  String get searchQuery => _searchQuery;
  int? get filterYear => _filterYear;
  int? get filterMonth => _filterMonth;

  List<PaymentWithCustomer> get allPayments => List.unmodifiable(_payments);

  List<PaymentWithCustomer> get filteredPayments {
    return _payments.where((item) {
      final p = item.payment;
      if (_methodFilter != null && p.method != _methodFilter) {
        return false;
      }
      if (_customerFilterId != null && p.customerId != _customerFilterId) {
        return false;
      }
      if (_filterYear != null && _filterMonth != null) {
        if (p.paymentDate.year != _filterYear || p.paymentDate.month != _filterMonth) {
          return false;
        }
      }
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final custName = item.customer?.name.toLowerCase() ?? '';
        final ref = p.referenceNumber?.toLowerCase() ?? '';
        final notes = p.notes?.toLowerCase() ?? '';
        return custName.contains(q) || ref.contains(q) || notes.contains(q);
      }
      return true;
    }).toList();
  }

  int get totalCollectedPaisa =>
      filteredPayments.fold(0, (sum, i) => sum + i.payment.amountPaisa);

  int getMethodTotalPaisa(PaymentMethod method) =>
      filteredPayments
          .where((i) => i.payment.method == method)
          .fold(0, (sum, i) => sum + i.payment.amountPaisa);

  // ── Customer Balance Calculation ─────────────────────────────────────────

  /// Calculates the customer's current all-time outstanding balance in Paisa.
  /// (Positive = customer owes money; Negative = store credit)
  int getCustomerBalancePaisa(String customerId) {
    final meals = _mealRepo.getMealEntriesForCustomer(customerId);
    final extras = _extraRepo.getEntriesForCustomer(customerId);
    final adjustments = _adjustmentRepo.getAdjustmentsForCustomer(customerId);
    final payments = _paymentRepo.getPaymentsForCustomer(customerId);

    return BillingEngine.computeOutstandingBalance(
      allMealEntries: meals,
      allAdditionalEntries: extras,
      allAdjustments: adjustments,
      allPayments: payments,
    );
  }

  // ── Filters ──────────────────────────────────────────────────────────────

  void setMethodFilter(PaymentMethod? method) {
    _methodFilter = method;
    notifyListeners();
  }

  void setCustomerFilter(String? customerId) {
    _customerFilterId = customerId;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query.trim();
    notifyListeners();
  }

  void setMonthFilter(int? year, int? month) {
    _filterYear = year;
    _filterMonth = month;
    notifyListeners();
  }

  void clearFilters() {
    _methodFilter = null;
    _customerFilterId = null;
    _searchQuery = '';
    _filterYear = null;
    _filterMonth = null;
    notifyListeners();
  }

  // ── Data Operations ──────────────────────────────────────────────────────

  void loadPayments() {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final rawPayments = _paymentRepo.getAllPayments();
      final customersMap = {
        for (final c in _customerRepo.getAllCustomers()) c.id: c
      };

      _payments = rawPayments.map((p) {
        return PaymentWithCustomer(
          payment: p,
          customer: customersMap[p.customerId],
        );
      }).toList();
    } catch (e) {
      _errorMessage = 'Failed to load payments: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Record a new payment. Supports partial and full payments, and overpayments.
  Future<bool> recordPayment({
    required String customerId,
    required DateTime date,
    required int amountPaisa,
    PaymentMethod method = PaymentMethod.cash,
    String? notes,
    String? referenceNumber,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final now = DateTime.now();
      final payment = Payment(
        id: _uuid.v4(),
        customerId: customerId,
        paymentDate: date,
        amountPaisa: amountPaisa,
        method: method,
        notes: notes?.trim().isEmpty == true ? null : notes?.trim(),
        referenceNumber: referenceNumber?.trim().isEmpty == true ? null : referenceNumber?.trim(),
        createdAt: now,
        updatedAt: now,
        isVoided: false,
      );

      await _paymentRepo.addPayment(payment);
      loadPayments();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to record payment: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Soft-delete (void) a payment to preserve the audit trail.
  Future<bool> voidPayment(String paymentId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _paymentRepo.voidPayment(paymentId);
      loadPayments();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to void payment: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
