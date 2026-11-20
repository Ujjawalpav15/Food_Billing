import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../data/models/models.dart';
import '../data/repositories/additional_item_entry_repository.dart';
import '../data/repositories/meal_entry_repository.dart';
import '../data/repositories/shop_profile_repository.dart';

class DailyEntryProvider extends ChangeNotifier {
  final MealEntryRepository _mealRepo;
  final AdditionalItemEntryRepository _extraRepo;
  final ShopProfileRepository _shopRepo;
  static const _uuid = Uuid();

  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  String? _errorMessage;

  // Cache for the selected day:
  // customerId -> MealEntry
  final Map<String, MealEntry> _mealEntriesMap = {};
  // customerId -> List<AdditionalItemEntry>
  final Map<String, List<AdditionalItemEntry>> _extraEntriesMap = {};

  DailyEntryProvider({
    required MealEntryRepository mealRepo,
    required AdditionalItemEntryRepository extraRepo,
    required ShopProfileRepository shopRepo,
  })  : _mealRepo = mealRepo,
        _extraRepo = extraRepo,
        _shopRepo = shopRepo {
    _loadDayEntries();
  }

  // ── Getters ──────────────────────────────────────────────────────────────

  DateTime get selectedDate => _selectedDate;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  bool get isToday {
    final now = DateTime.now();
    return _selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day;
  }

  /// Total breakfast count served on the selected date.
  int get totalBreakfastCount =>
      _mealEntriesMap.values.where((e) => e.hadBreakfast).length;

  /// Total dinner count served on the selected date.
  int get totalDinnerCount =>
      _mealEntriesMap.values.where((e) => e.hadDinner).length;

  /// Total count of additional extra items recorded on the selected date.
  int get totalExtraItemsCount {
    int sum = 0;
    for (final entries in _extraEntriesMap.values) {
      for (final e in entries) {
        sum += e.quantity;
      }
    }
    return sum;
  }

  /// Get meal entry for a specific customer on the selected date.
  MealEntry? getMealEntryForCustomer(String customerId) =>
      _mealEntriesMap[customerId];

  /// Get list of extra items ordered by a customer on the selected date.
  List<AdditionalItemEntry> getExtrasForCustomer(String customerId) =>
      _extraEntriesMap[customerId] ?? [];

  // ── Date Navigation ──────────────────────────────────────────────────────

  void setSelectedDate(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    if (_selectedDate != normalized) {
      _selectedDate = normalized;
      _loadDayEntries();
    }
  }

  void goToPreviousDay() {
    setSelectedDate(_selectedDate.subtract(const Duration(days: 1)));
  }

  void goToNextDay() {
    setSelectedDate(_selectedDate.add(const Duration(days: 1)));
  }

  void goToToday() {
    setSelectedDate(DateTime.now());
  }

  // ── Data Loading ─────────────────────────────────────────────────────────

  void _loadDayEntries() {
    _isLoading = true;
    _errorMessage = null;
    _mealEntriesMap.clear();
    _extraEntriesMap.clear();
    notifyListeners();

    try {
      final meals = _mealRepo.getMealEntriesForDay(_selectedDate);
      for (final m in meals) {
        _mealEntriesMap[m.customerId] = m;
      }

      final extras = _extraRepo.getAllEntriesForDay(_selectedDate);
      for (final e in extras) {
        _extraEntriesMap.putIfAbsent(e.customerId, () => []).add(e);
      }
    } catch (e) {
      _errorMessage = 'Failed to load entries: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> reload() async {
    _loadDayEntries();
  }

  // ── Meal Operations ──────────────────────────────────────────────────────

  /// Toggle breakfast for a customer on the selected date.
  Future<void> toggleBreakfast(String customerId) async {
    final existing = _mealEntriesMap[customerId];
    final profile = _shopRepo.getProfile();
    final defaultBreakfast = profile?.defaultBreakfastPricePaisa ?? 8500;
    final defaultDinner = profile?.defaultDinnerPricePaisa ?? 8500;
    final now = DateTime.now();

    if (existing != null) {
      existing.hadBreakfast = !existing.hadBreakfast;
      existing.updatedAt = now;

      // If price was 0 or unrecorded, update to snapshot price
      if (existing.hadBreakfast && existing.breakfastPricePaisa <= 0) {
        existing.breakfastPricePaisa = defaultBreakfast;
      }

      await _mealRepo.updateMealEntry(existing);
      _mealEntriesMap[customerId] = existing;
    } else {
      final newEntry = MealEntry(
        id: _uuid.v4(),
        customerId: customerId,
        date: _selectedDate,
        hadBreakfast: true,
        hadDinner: false,
        breakfastPricePaisa: defaultBreakfast,
        dinnerPricePaisa: defaultDinner,
        createdAt: now,
        updatedAt: now,
      );

      await _mealRepo.addMealEntry(newEntry);
      _mealEntriesMap[customerId] = newEntry;
    }
    notifyListeners();
  }

  /// Toggle dinner for a customer on the selected date.
  Future<void> toggleDinner(String customerId) async {
    final existing = _mealEntriesMap[customerId];
    final profile = _shopRepo.getProfile();
    final defaultBreakfast = profile?.defaultBreakfastPricePaisa ?? 8500;
    final defaultDinner = profile?.defaultDinnerPricePaisa ?? 8500;
    final now = DateTime.now();

    if (existing != null) {
      existing.hadDinner = !existing.hadDinner;
      existing.updatedAt = now;

      // If price was 0 or unrecorded, update to snapshot price
      if (existing.hadDinner && existing.dinnerPricePaisa <= 0) {
        existing.dinnerPricePaisa = defaultDinner;
      }

      await _mealRepo.updateMealEntry(existing);
      _mealEntriesMap[customerId] = existing;
    } else {
      final newEntry = MealEntry(
        id: _uuid.v4(),
        customerId: customerId,
        date: _selectedDate,
        hadBreakfast: false,
        hadDinner: true,
        breakfastPricePaisa: defaultBreakfast,
        dinnerPricePaisa: defaultDinner,
        createdAt: now,
        updatedAt: now,
      );

      await _mealRepo.addMealEntry(newEntry);
      _mealEntriesMap[customerId] = newEntry;
    }
    notifyListeners();
  }

  /// Bulk action: mark all provided active customers as hadBreakfast = true/false.
  Future<void> bulkSetBreakfast(
      List<Customer> customers, bool hadBreakfast) async {
    final profile = _shopRepo.getProfile();
    final defaultBreakfast = profile?.defaultBreakfastPricePaisa ?? 8500;
    final defaultDinner = profile?.defaultDinnerPricePaisa ?? 8500;
    final now = DateTime.now();

    for (final customer in customers) {
      final existing = _mealEntriesMap[customer.id];
      if (existing != null) {
        if (existing.hadBreakfast != hadBreakfast) {
          existing.hadBreakfast = hadBreakfast;
          existing.updatedAt = now;
          if (hadBreakfast && existing.breakfastPricePaisa <= 0) {
            existing.breakfastPricePaisa = defaultBreakfast;
          }
          await _mealRepo.updateMealEntry(existing);
        }
      } else if (hadBreakfast) {
        final newEntry = MealEntry(
          id: _uuid.v4(),
          customerId: customer.id,
          date: _selectedDate,
          hadBreakfast: true,
          hadDinner: false,
          breakfastPricePaisa: defaultBreakfast,
          dinnerPricePaisa: defaultDinner,
          createdAt: now,
          updatedAt: now,
        );
        await _mealRepo.addMealEntry(newEntry);
        _mealEntriesMap[customer.id] = newEntry;
      }
    }
    notifyListeners();
  }

  /// Bulk action: mark all provided active customers as hadDinner = true/false.
  Future<void> bulkSetDinner(List<Customer> customers, bool hadDinner) async {
    final profile = _shopRepo.getProfile();
    final defaultBreakfast = profile?.defaultBreakfastPricePaisa ?? 8500;
    final defaultDinner = profile?.defaultDinnerPricePaisa ?? 8500;
    final now = DateTime.now();

    for (final customer in customers) {
      final existing = _mealEntriesMap[customer.id];
      if (existing != null) {
        if (existing.hadDinner != hadDinner) {
          existing.hadDinner = hadDinner;
          existing.updatedAt = now;
          if (hadDinner && existing.dinnerPricePaisa <= 0) {
            existing.dinnerPricePaisa = defaultDinner;
          }
          await _mealRepo.updateMealEntry(existing);
        }
      } else if (hadDinner) {
        final newEntry = MealEntry(
          id: _uuid.v4(),
          customerId: customer.id,
          date: _selectedDate,
          hadBreakfast: false,
          hadDinner: true,
          breakfastPricePaisa: defaultBreakfast,
          dinnerPricePaisa: defaultDinner,
          createdAt: now,
          updatedAt: now,
        );
        await _mealRepo.addMealEntry(newEntry);
        _mealEntriesMap[customer.id] = newEntry;
      }
    }
    notifyListeners();
  }

  /// Bulk action: clear all meal records for the selected day for these customers.
  Future<void> clearDayMeals(List<Customer> customers) async {
    final now = DateTime.now();
    for (final customer in customers) {
      final existing = _mealEntriesMap[customer.id];
      if (existing != null) {
        existing.hadBreakfast = false;
        existing.hadDinner = false;
        existing.updatedAt = now;
        await _mealRepo.updateMealEntry(existing);
      }
    }
    notifyListeners();
  }

  // ── Extra Items Operations ───────────────────────────────────────────────

  /// Add or increment an extra menu item order for a customer on selected date.
  Future<void> addExtraItem({
    required String customerId,
    required MenuItem item,
    int quantity = 1,
    String? notes,
  }) async {
    final existingList = _extraEntriesMap[customerId] ?? [];
    final matchingIndex =
        existingList.indexWhere((e) => e.menuItemId == item.id);
    final now = DateTime.now();

    if (matchingIndex != -1) {
      final entry = existingList[matchingIndex];
      entry.quantity += quantity;
      entry.updatedAt = now;
      if (notes != null && notes.isNotEmpty) entry.notes = notes;
      await _extraRepo.updateEntry(entry);
    } else {
      final newEntry = AdditionalItemEntry(
        id: _uuid.v4(),
        customerId: customerId,
        menuItemId: item.id,
        menuItemName: item.name,
        date: _selectedDate,
        quantity: quantity,
        unitPricePaisa: item.pricePaisa, // Snapshot current menu price
        notes: notes,
        createdAt: now,
        updatedAt: now,
      );
      await _extraRepo.addEntry(newEntry);
      _extraEntriesMap.putIfAbsent(customerId, () => []).add(newEntry);
    }
    notifyListeners();
  }

  /// Update the quantity of an existing extra item entry. If <= 0, deletes it.
  Future<void> setExtraItemQuantity(
      String customerId, String entryId, int newQuantity) async {
    final list = _extraEntriesMap[customerId];
    if (list == null) return;

    final index = list.indexWhere((e) => e.id == entryId);
    if (index == -1) return;

    if (newQuantity <= 0) {
      await _extraRepo.deleteEntry(entryId);
      list.removeAt(index);
    } else {
      final entry = list[index];
      entry.quantity = newQuantity;
      entry.updatedAt = DateTime.now();
      await _extraRepo.updateEntry(entry);
    }
    notifyListeners();
  }

  /// Remove an extra item entry completely.
  Future<void> deleteExtraItem(String customerId, String entryId) async {
    await _extraRepo.deleteEntry(entryId);
    _extraEntriesMap[customerId]?.removeWhere((e) => e.id == entryId);
    notifyListeners();
  }
}
