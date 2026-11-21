import 'package:flutter/foundation.dart';
import '../data/models/models.dart';
import '../data/repositories/additional_item_entry_repository.dart';
import '../data/repositories/adjustment_repository.dart';
import '../data/repositories/meal_entry_repository.dart';
import '../data/repositories/payment_repository.dart';

enum LedgerItemType {
  meal,
  additionalItem,
  adjustment,
  payment,
}

class LedgerItem {
  final String id;
  final DateTime date;
  final LedgerItemType type;
  final String title;
  final String subtitle;
  /// Positive for charges (customer owes more), negative for payments/credits (customer owes less).
  final int amountPaisa;
  final int runningBalancePaisa;
  final dynamic originalObject;

  const LedgerItem({
    required this.id,
    required this.date,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.amountPaisa,
    required this.runningBalancePaisa,
    this.originalObject,
  });

  bool get isCharge => amountPaisa > 0;
  bool get isCreditOrPayment => amountPaisa < 0;
}

class CustomerLedgerProvider extends ChangeNotifier {
  final String customerId;
  final MealEntryRepository _mealRepo;
  final AdditionalItemEntryRepository _extraRepo;
  final AdjustmentRepository _adjustmentRepo;
  final PaymentRepository _paymentRepo;

  DateTime? _startDate;
  DateTime? _endDate;
  int? _filterYear;
  int? _filterMonth;

  bool _isLoading = false;
  String? _errorMessage;

  List<LedgerItem> _allItems = [];

  CustomerLedgerProvider({
    required this.customerId,
    required MealEntryRepository mealRepo,
    required AdditionalItemEntryRepository extraRepo,
    required AdjustmentRepository adjustmentRepo,
    required PaymentRepository paymentRepo,
    int? initialYear,
    int? initialMonth,
  })  : _mealRepo = mealRepo,
        _extraRepo = extraRepo,
        _adjustmentRepo = adjustmentRepo,
        _paymentRepo = paymentRepo,
        _filterYear = initialYear,
        _filterMonth = initialMonth {
    loadLedger();
  }

  // ── Getters ──────────────────────────────────────────────────────────────

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int? get filterYear => _filterYear;
  int? get filterMonth => _filterMonth;
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;

  bool get isFiltered =>
      _filterYear != null ||
      _filterMonth != null ||
      _startDate != null ||
      _endDate != null;

  /// All ledger items for the customer, filtered by the active period and sorted descending (newest first).
  List<LedgerItem> get filteredItems {
    if (!isFiltered) return List.unmodifiable(_allItems.reversed);

    return _allItems.where((item) {
      if (_filterYear != null && _filterMonth != null) {
        if (item.date.year != _filterYear || item.date.month != _filterMonth) {
          return false;
        }
      }
      if (_startDate != null) {
        final start = DateTime(_startDate!.year, _startDate!.month, _startDate!.day);
        if (item.date.isBefore(start)) return false;
      }
      if (_endDate != null) {
        final end = DateTime(_endDate!.year, _endDate!.month, _endDate!.day, 23, 59, 59);
        if (item.date.isAfter(end)) return false;
      }
      return true;
    }).toList().reversed.toList();
  }

  /// All-time running outstanding balance for this customer in Paisa.
  int get totalOutstandingBalancePaisa {
    if (_allItems.isEmpty) return 0;
    return _allItems.last.runningBalancePaisa;
  }

  /// Total charges in the active filtered view.
  int get filteredChargesPaisa =>
      filteredItems.where((i) => i.amountPaisa > 0).fold(0, (sum, i) => sum + i.amountPaisa);

  /// Total payments/credits in the active filtered view.
  int get filteredPaymentsPaisa =>
      filteredItems.where((i) => i.amountPaisa < 0).fold(0, (sum, i) => sum + (-i.amountPaisa));

  /// Breakfast count in the filtered view.
  int get filteredBreakfastCount {
    int count = 0;
    for (final item in filteredItems) {
      if (item.originalObject is MealEntry) {
        if ((item.originalObject as MealEntry).hadBreakfast) count++;
      }
    }
    return count;
  }

  /// Dinner count in the filtered view.
  int get filteredDinnerCount {
    int count = 0;
    for (final item in filteredItems) {
      if (item.originalObject is MealEntry) {
        if ((item.originalObject as MealEntry).hadDinner) count++;
      }
    }
    return count;
  }

  /// Extra items quantity in the filtered view.
  int get filteredExtrasCount {
    int count = 0;
    for (final item in filteredItems) {
      if (item.originalObject is AdditionalItemEntry) {
        count += (item.originalObject as AdditionalItemEntry).quantity;
      }
    }
    return count;
  }

  // ── Filter Controls ──────────────────────────────────────────────────────

  void filterByMonth(int year, int month) {
    _filterYear = year;
    _filterMonth = month;
    _startDate = null;
    _endDate = null;
    notifyListeners();
  }

  void filterByDateRange(DateTime start, DateTime end) {
    _startDate = start;
    _endDate = end;
    _filterYear = null;
    _filterMonth = null;
    notifyListeners();
  }

  void clearFilter() {
    _filterYear = null;
    _filterMonth = null;
    _startDate = null;
    _endDate = null;
    notifyListeners();
  }

  // ── Ledger Computation ───────────────────────────────────────────────────

  void loadLedger() {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final meals = _mealRepo.getMealEntriesForCustomer(customerId);
      final extras = _extraRepo.getEntriesForCustomer(customerId);
      final adjustments = _adjustmentRepo.getAdjustmentsForCustomer(customerId);
      final payments = _paymentRepo.getPaymentsForCustomer(customerId);

      // Temporary list of un-ordered raw transaction entries
      final rawList = <_RawLedgerEntry>[];

      for (final m in meals) {
        if (m.hadBreakfast || m.hadDinner) {
          final parts = <String>[];
          if (m.hadBreakfast) parts.add('Breakfast');
          if (m.hadDinner) parts.add('Dinner');
          rawList.add(
            _RawLedgerEntry(
              id: m.id,
              date: m.date,
              type: LedgerItemType.meal,
              title: parts.join(' & '),
              subtitle: 'Daily attendance',
              amountPaisa: m.totalPaisa,
              originalObject: m,
            ),
          );
        }
      }

      for (final e in extras) {
        rawList.add(
          _RawLedgerEntry(
            id: e.id,
            date: e.date,
            type: LedgerItemType.additionalItem,
            title: '${e.quantity}x ${e.menuItemName}',
            subtitle: e.notes ?? 'Extra order',
            amountPaisa: e.totalPaisa,
            originalObject: e,
          ),
        );
      }

      for (final a in adjustments) {
        rawList.add(
          _RawLedgerEntry(
            id: a.id,
            date: a.adjustmentDate,
            type: LedgerItemType.adjustment,
            title: a.amountPaisa < 0 ? 'Discount / Credit' : 'Adjustment Surcharge',
            subtitle: a.reason,
            amountPaisa: a.amountPaisa,
            originalObject: a,
          ),
        );
      }

      for (final p in payments) {
        rawList.add(
          _RawLedgerEntry(
            id: p.id,
            date: p.paymentDate,
            type: LedgerItemType.payment,
            title: 'Payment (${p.method.name.toUpperCase()})',
            subtitle: p.notes ?? (p.referenceNumber != null ? 'Ref: ${p.referenceNumber}' : 'Payment received'),
            amountPaisa: -p.amountPaisa, // negative reduces balance
            originalObject: p,
          ),
        );
      }

      // Sort chronological ascending (oldest first) to compute running balances correctly
      rawList.sort((a, b) => a.date.compareTo(b.date));

      int runningBalance = 0;
      final computed = <LedgerItem>[];

      for (final r in rawList) {
        runningBalance += r.amountPaisa;
        computed.add(
          LedgerItem(
            id: r.id,
            date: r.date,
            type: r.type,
            title: r.title,
            subtitle: r.subtitle,
            amountPaisa: r.amountPaisa,
            runningBalancePaisa: runningBalance,
            originalObject: r.originalObject,
          ),
        );
      }

      _allItems = computed;
    } catch (e) {
      _errorMessage = 'Failed to load ledger: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

class _RawLedgerEntry {
  final String id;
  final DateTime date;
  final LedgerItemType type;
  final String title;
  final String subtitle;
  final int amountPaisa;
  final dynamic originalObject;

  _RawLedgerEntry({
    required this.id,
    required this.date,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.amountPaisa,
    this.originalObject,
  });
}
