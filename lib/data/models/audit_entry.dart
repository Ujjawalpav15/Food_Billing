import 'package:hive_ce/hive.dart';
import '../../core/constants/app_constants.dart';

part 'audit_entry.g.dart';

/// Immutable audit log entry for tracking important corrections.
@HiveType(typeId: AppConstants.auditEntryTypeId)
class AuditEntry extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  AuditAction action;

  @HiveField(2)
  String entityType; // e.g. "MealEntry", "Payment"

  @HiveField(3)
  String entityId;

  @HiveField(4)
  String? customerId;

  @HiveField(5)
  String? originalValue; // JSON-serialized snapshot before change

  @HiveField(6)
  String? newValue; // JSON-serialized snapshot after change

  @HiveField(7)
  String? reason;

  @HiveField(8)
  DateTime createdAt;

  AuditEntry({
    required this.id,
    required this.action,
    required this.entityType,
    required this.entityId,
    this.customerId,
    this.originalValue,
    this.newValue,
    this.reason,
    required this.createdAt,
  });
}

@HiveType(typeId: AppConstants.auditActionTypeId)
enum AuditAction {
  @HiveField(0)
  created,
  @HiveField(1)
  updated,
  @HiveField(2)
  deleted,
  @HiveField(3)
  voided,
  @HiveField(4)
  finalized,
  @HiveField(5)
  reopened,
}
