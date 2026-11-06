import 'package:hive_ce_flutter/hive_flutter.dart';
import '../models/models.dart';
import '../../core/constants/app_constants.dart';

class AdditionalItemEntryRepository {
  Box<AdditionalItemEntry> get _box =>
      Hive.box<AdditionalItemEntry>(AppConstants.additionalItemEntryBox);

  Future<void> addEntry(AdditionalItemEntry entry) async {
    await _box.put(entry.id, entry);
  }

  Future<void> updateEntry(AdditionalItemEntry entry) async {
    entry.updatedAt = DateTime.now();
    await _box.put(entry.id, entry);
  }

  Future<void> deleteEntry(String id) async {
    await _box.delete(id);
  }

  AdditionalItemEntry? getEntry(String id) => _box.get(id);

  List<AdditionalItemEntry> getEntriesForCustomer(String customerId) =>
      _box.values.where((e) => e.customerId == customerId).toList()
        ..sort((a, b) => a.date.compareTo(b.date));

  List<AdditionalItemEntry> getEntriesForMonth(
      String customerId, int year, int month) {
    return _box.values
        .where((e) =>
            e.customerId == customerId &&
            e.date.year == year &&
            e.date.month == month)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  List<AdditionalItemEntry> getEntriesForDay(
      String customerId, DateTime date) {
    final dateOnly = DateTime(date.year, date.month, date.day);
    return _box.values
        .where((e) =>
            e.customerId == customerId &&
            DateTime(e.date.year, e.date.month, e.date.day) == dateOnly)
        .toList();
  }

  Stream<BoxEvent> watchAll() => _box.watch();
}
