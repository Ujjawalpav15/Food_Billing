import 'package:hive_ce_flutter/hive_flutter.dart';
import '../models/models.dart';
import '../../core/constants/app_constants.dart';

class MealEntryRepository {
  Box<MealEntry> get _box => Hive.box<MealEntry>(AppConstants.mealEntryBox);

  Future<void> addMealEntry(MealEntry entry) async {
    await _box.put(entry.id, entry);
  }

  Future<void> updateMealEntry(MealEntry entry) async {
    entry.updatedAt = DateTime.now();
    await _box.put(entry.id, entry);
  }

  Future<void> deleteMealEntry(String id) async {
    await _box.delete(id);
  }

  MealEntry? getMealEntry(String id) => _box.get(id);

  /// Find meal entry for a specific customer on a specific date (normalized to date-only).
  /// Returns null if not found.
  MealEntry? findMealEntryForDate(String customerId, DateTime date) {
    final dateOnly = DateTime(date.year, date.month, date.day);
    final matches = _box.values.where(
      (e) =>
          e.customerId == customerId &&
          DateTime(e.date.year, e.date.month, e.date.day) == dateOnly,
    );
    return matches.isEmpty ? null : matches.first;
  }

  /// Get all meal entries for a customer, sorted by date ascending.
  List<MealEntry> getMealEntriesForCustomer(String customerId) =>
      _box.values.where((e) => e.customerId == customerId).toList()
        ..sort((a, b) => a.date.compareTo(b.date));

  /// Get all meal entries for a customer within a given month.
  List<MealEntry> getMealEntriesForMonth(
      String customerId, int year, int month) {
    return _box.values
        .where((e) =>
            e.customerId == customerId &&
            e.date.year == year &&
            e.date.month == month)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  /// Get all entries for a specific date across all customers.
  List<MealEntry> getMealEntriesForDay(DateTime date) {
    final dateOnly = DateTime(date.year, date.month, date.day);
    return _box.values
        .where((e) =>
            DateTime(e.date.year, e.date.month, e.date.day) == dateOnly)
        .toList();
  }

  Stream<BoxEvent> watchAll() => _box.watch();
}
