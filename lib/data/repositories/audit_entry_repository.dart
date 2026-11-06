import 'package:hive_ce_flutter/hive_flutter.dart';
import '../models/models.dart';
import '../../core/constants/app_constants.dart';

class AuditEntryRepository {
  Box<AuditEntry> get _box =>
      Hive.box<AuditEntry>(AppConstants.auditEntryBox);

  Future<void> addEntry(AuditEntry entry) async {
    await _box.put(entry.id, entry);
  }

  List<AuditEntry> getEntriesForEntity(String entityType, String entityId) =>
      _box.values
          .where(
              (e) => e.entityType == entityType && e.entityId == entityId)
          .toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

  List<AuditEntry> getEntriesForCustomer(String customerId) =>
      _box.values
          .where((e) => e.customerId == customerId)
          .toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
}
