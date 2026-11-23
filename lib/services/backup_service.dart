import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:hive_ce/hive.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../core/constants/app_constants.dart';
import '../data/models/additional_item_entry.dart';
import '../data/models/adjustment.dart';
import '../data/models/audit_entry.dart';
import '../data/models/customer.dart';
import '../data/models/meal_entry.dart';
import '../data/models/menu_item.dart';
import '../data/models/monthly_bill.dart';
import '../data/models/payment.dart';
import '../data/models/shop_profile.dart';

/// Metadata extracted from a validated backup file.
class BackupMetadata {
  final int schemaVersion;
  final DateTime exportedAt;
  final String? shopName;
  final int customerCount;
  final int menuItemCount;
  final int mealEntryCount;
  final int additionalItemCount;
  final int paymentCount;
  final int adjustmentCount;
  final int monthlyBillCount;
  final int auditEntryCount;

  const BackupMetadata({
    required this.schemaVersion,
    required this.exportedAt,
    this.shopName,
    required this.customerCount,
    required this.menuItemCount,
    required this.mealEntryCount,
    required this.additionalItemCount,
    required this.paymentCount,
    required this.adjustmentCount,
    required this.monthlyBillCount,
    required this.auditEntryCount,
  });

  int get totalRecords =>
      (shopName != null ? 1 : 0) +
      customerCount +
      menuItemCount +
      mealEntryCount +
      additionalItemCount +
      paymentCount +
      adjustmentCount +
      monthlyBillCount +
      auditEntryCount;
}

/// Result of backup file validation.
class BackupValidationResult {
  final bool isValid;
  final String? errorMessage;
  final BackupMetadata? metadata;
  final Map<String, dynamic>? parsedJson;

  const BackupValidationResult({
    required this.isValid,
    this.errorMessage,
    this.metadata,
    this.parsedJson,
  });

  factory BackupValidationResult.failure(String message) {
    return BackupValidationResult(isValid: false, errorMessage: message);
  }

  factory BackupValidationResult.success(BackupMetadata metadata, Map<String, dynamic> json) {
    return BackupValidationResult(
      isValid: true,
      metadata: metadata,
      parsedJson: json,
    );
  }
}

/// Service handling full offline database backups to structured JSON and validated restorations.
class BackupService {
  static const int currentSchemaVersion = 1;
  static const String appIdentifier = 'Mess Billing Manager';

  const BackupService();

  // ── Hive Box Helpers ──────────────────────────────────────────────────────

  Box<ShopProfile> get _shopBox => Hive.box<ShopProfile>(AppConstants.shopProfileBox);
  Box<Customer> get _customerBox => Hive.box<Customer>(AppConstants.customerBox);
  Box<MenuItem> get _menuBox => Hive.box<MenuItem>(AppConstants.menuItemBox);
  Box<MealEntry> get _mealBox => Hive.box<MealEntry>(AppConstants.mealEntryBox);
  Box<AdditionalItemEntry> get _extraBox => Hive.box<AdditionalItemEntry>(AppConstants.additionalItemEntryBox);
  Box<Payment> get _paymentBox => Hive.box<Payment>(AppConstants.paymentBox);
  Box<Adjustment> get _adjustmentBox => Hive.box<Adjustment>(AppConstants.adjustmentBox);
  Box<MonthlyBill> get _billBox => Hive.box<MonthlyBill>(AppConstants.monthlyBillBox);
  Box<AuditEntry> get _auditBox => Hive.box<AuditEntry>(AppConstants.auditEntryBox);

  // ── Backup Generation ─────────────────────────────────────────────────────

  /// Serializes all 9 Hive boxes into a structured JSON string.
  String createBackupJson({DateTime? exportTime}) {
    final now = exportTime ?? DateTime.now();

    final shopProfile = _shopBox.get('profile');
    final customers = _customerBox.values.toList();
    final menuItems = _menuBox.values.toList();
    final mealEntries = _mealBox.values.toList();
    final additionalItems = _extraBox.values.toList();
    final payments = _paymentBox.values.toList();
    final adjustments = _adjustmentBox.values.toList();
    final monthlyBills = _billBox.values.toList();
    final auditEntries = _auditBox.values.toList();

    final dataMap = <String, dynamic>{
      'shopProfile': shopProfile != null ? _shopProfileToMap(shopProfile) : null,
      'customers': customers.map(_customerToMap).toList(),
      'menuItems': menuItems.map(_menuItemToMap).toList(),
      'mealEntries': mealEntries.map(_mealEntryToMap).toList(),
      'additionalItemEntries': additionalItems.map(_additionalItemToMap).toList(),
      'payments': payments.map(_paymentToMap).toList(),
      'adjustments': adjustments.map(_adjustmentToMap).toList(),
      'monthlyBills': monthlyBills.map(_monthlyBillToMap).toList(),
      'auditEntries': auditEntries.map(_auditEntryToMap).toList(),
    };

    final root = {
      'app': appIdentifier,
      'schemaVersion': currentSchemaVersion,
      'exportedAt': now.toIso8601String(),
      'counts': {
        'shopProfile': shopProfile != null ? 1 : 0,
        'customers': customers.length,
        'menuItems': menuItems.length,
        'mealEntries': mealEntries.length,
        'additionalItemEntries': additionalItems.length,
        'payments': payments.length,
        'adjustments': adjustments.length,
        'monthlyBills': monthlyBills.length,
        'auditEntries': auditEntries.length,
      },
      'data': dataMap,
    };

    return const JsonEncoder.withIndent('  ').convert(root);
  }

  /// Exports database backup to a local JSON file in application documents directory.
  Future<File> exportBackupToFile() async {
    final jsonContent = createBackupJson();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final fileName = 'mess_billing_backup_$timestamp.json';

    final appDir = await getApplicationDocumentsDirectory();
    final file = File('${appDir.path}/$fileName');
    await file.writeAsString(jsonContent, flush: true);
    return file;
  }

  /// Exports backup and opens system share dialog (to send via WhatsApp, Drive, Email, or save to files).
  Future<void> shareBackup() async {
    final file = await exportBackupToFile();
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/json')],
      text: 'Mess Billing Manager Backup (${DateFormat('dd MMM yyyy, HH:mm').format(DateTime.now())})',
      subject: 'Mess Billing Data Backup',
    );
  }

  // ── Validation ────────────────────────────────────────────────────────────

  /// Validates an imported backup JSON string for structural and schema integrity.
  BackupValidationResult validateBackup(String jsonString) {
    if (jsonString.trim().isEmpty) {
      return BackupValidationResult.failure('The selected file is empty.');
    }

    dynamic decoded;
    try {
      decoded = jsonDecode(jsonString);
    } catch (e) {
      return BackupValidationResult.failure('Invalid JSON file format: $e');
    }

    if (decoded is! Map<String, dynamic>) {
      return BackupValidationResult.failure('Backup file root must be a JSON object.');
    }

    // App identity check
    final app = decoded['app'];
    if (app != appIdentifier) {
      return BackupValidationResult.failure(
        'Unrecognized backup source. Expected "$appIdentifier", found "${app ?? 'none'}".',
      );
    }

    // Schema version check
    final schema = decoded['schemaVersion'];
    if (schema is! int || schema > currentSchemaVersion) {
      return BackupValidationResult.failure(
        'Unsupported backup schema version: $schema (App supports up to $currentSchemaVersion).',
      );
    }

    // Export date check
    final exportedAtStr = decoded['exportedAt'] as String?;
    final exportedAt = exportedAtStr != null ? DateTime.tryParse(exportedAtStr) : null;
    if (exportedAt == null) {
      return BackupValidationResult.failure('Missing or invalid export timestamp in backup file.');
    }

    // Data payload check
    final data = decoded['data'];
    if (data is! Map<String, dynamic>) {
      return BackupValidationResult.failure('Missing "data" collection payload in backup.');
    }

    // Inspect counts and structure
    final customers = data['customers'] as List? ?? [];
    final menuItems = data['menuItems'] as List? ?? [];
    final mealEntries = data['mealEntries'] as List? ?? [];
    final additionalItems = data['additionalItemEntries'] as List? ?? [];
    final payments = data['payments'] as List? ?? [];
    final adjustments = data['adjustments'] as List? ?? [];
    final monthlyBills = data['monthlyBills'] as List? ?? [];
    final auditEntries = data['auditEntries'] as List? ?? [];
    final shopMap = data['shopProfile'] as Map<String, dynamic>?;

    final metadata = BackupMetadata(
      schemaVersion: schema,
      exportedAt: exportedAt,
      shopName: shopMap?['shopName'] as String?,
      customerCount: customers.length,
      menuItemCount: menuItems.length,
      mealEntryCount: mealEntries.length,
      additionalItemCount: additionalItems.length,
      paymentCount: payments.length,
      adjustmentCount: adjustments.length,
      monthlyBillCount: monthlyBills.length,
      auditEntryCount: auditEntries.length,
    );

    return BackupValidationResult.success(metadata, decoded);
  }

  // ── Restoration ───────────────────────────────────────────────────────────

  /// Selects a JSON backup file using the platform file picker.
  Future<String?> pickBackupFileContent() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result == null || result.files.isEmpty) {
      return null;
    }

    final path = result.files.single.path;
    if (path == null) {
      // Memory bytes fallback
      final bytes = result.files.single.bytes;
      if (bytes != null) return utf8.decode(bytes);
      return null;
    }

    final file = File(path);
    return file.readAsString();
  }

  /// Restores the database from a validated JSON string.
  /// Overwrites all existing records safely and atomic-style across Hive boxes.
  Future<BackupMetadata> restoreFromJson(String jsonString) async {
    final validation = validateBackup(jsonString);
    if (!validation.isValid || validation.parsedJson == null || validation.metadata == null) {
      throw FormatException(validation.errorMessage ?? 'Validation failed.');
    }

    final data = validation.parsedJson!['data'] as Map<String, dynamic>;

    // 1. Clear all current boxes
    await _shopBox.clear();
    await _customerBox.clear();
    await _menuBox.clear();
    await _mealBox.clear();
    await _extraBox.clear();
    await _paymentBox.clear();
    await _adjustmentBox.clear();
    await _billBox.clear();
    await _auditBox.clear();

    // 2. Restore ShopProfile
    final shopMap = data['shopProfile'] as Map<String, dynamic>?;
    if (shopMap != null) {
      final shop = _shopProfileFromMap(shopMap);
      await _shopBox.put('profile', shop);
    }

    // 3. Restore Customers
    final customersList = (data['customers'] as List? ?? []).cast<Map<String, dynamic>>();
    for (final map in customersList) {
      final customer = _customerFromMap(map);
      await _customerBox.put(customer.id, customer);
    }

    // 4. Restore Menu Items
    final menuList = (data['menuItems'] as List? ?? []).cast<Map<String, dynamic>>();
    for (final map in menuList) {
      final item = _menuItemFromMap(map);
      await _menuBox.put(item.id, item);
    }

    // 5. Restore Meal Entries
    final mealList = (data['mealEntries'] as List? ?? []).cast<Map<String, dynamic>>();
    for (final map in mealList) {
      final entry = _mealEntryFromMap(map);
      await _mealBox.put(entry.id, entry);
    }

    // 6. Restore Additional Item Entries
    final extraList = (data['additionalItemEntries'] as List? ?? []).cast<Map<String, dynamic>>();
    for (final map in extraList) {
      final extra = _additionalItemFromMap(map);
      await _extraBox.put(extra.id, extra);
    }

    // 7. Restore Payments
    final paymentList = (data['payments'] as List? ?? []).cast<Map<String, dynamic>>();
    for (final map in paymentList) {
      final payment = _paymentFromMap(map);
      await _paymentBox.put(payment.id, payment);
    }

    // 8. Restore Adjustments
    final adjustmentList = (data['adjustments'] as List? ?? []).cast<Map<String, dynamic>>();
    for (final map in adjustmentList) {
      final adjustment = _adjustmentFromMap(map);
      await _adjustmentBox.put(adjustment.id, adjustment);
    }

    // 9. Restore Monthly Bills
    final billList = (data['monthlyBills'] as List? ?? []).cast<Map<String, dynamic>>();
    for (final map in billList) {
      final bill = _monthlyBillFromMap(map);
      await _billBox.put(bill.id, bill);
    }

    // 10. Restore Audit Entries
    final auditList = (data['auditEntries'] as List? ?? []).cast<Map<String, dynamic>>();
    for (final map in auditList) {
      final audit = _auditEntryFromMap(map);
      await _auditBox.put(audit.id, audit);
    }

    // 11. Record restoration in Audit Log
    final restoreAudit = AuditEntry(
      id: 'audit-restore-${DateTime.now().millisecondsSinceEpoch}',
      action: AuditAction.updated,
      entityType: 'DatabaseBackup',
      entityId: 'backup-${validation.metadata!.exportedAt.toIso8601String()}',
      reason: 'Database restored from backup created at ${validation.metadata!.exportedAt.toIso8601String()}',
      createdAt: DateTime.now(),
    );
    await _auditBox.put(restoreAudit.id, restoreAudit);

    return validation.metadata!;
  }

  // ── Serializers: Models -> Map ────────────────────────────────────────────

  Map<String, dynamic> _shopProfileToMap(ShopProfile s) => {
        'id': s.id,
        'ownerName': s.ownerName,
        'shopName': s.shopName,
        'address': s.address,
        'phoneNumber': s.phoneNumber,
        'logoPath': s.logoPath,
        'currencyCode': s.currencyCode,
        'currencySymbol': s.currencySymbol,
        'defaultBreakfastPricePaisa': s.defaultBreakfastPricePaisa,
        'defaultDinnerPricePaisa': s.defaultDinnerPricePaisa,
        'createdAt': s.createdAt.toIso8601String(),
        'updatedAt': s.updatedAt.toIso8601String(),
      };

  Map<String, dynamic> _customerToMap(Customer c) => {
        'id': c.id,
        'name': c.name,
        'phoneNumber': c.phoneNumber,
        'isActive': c.isActive,
        'notes': c.notes,
        'createdAt': c.createdAt.toIso8601String(),
        'updatedAt': c.updatedAt.toIso8601String(),
      };

  Map<String, dynamic> _menuItemToMap(MenuItem m) => {
        'id': m.id,
        'name': m.name,
        'category': m.category.name,
        'unit': m.unit,
        'pricePaisa': m.pricePaisa,
        'isActive': m.isActive,
        'createdAt': m.createdAt.toIso8601String(),
        'updatedAt': m.updatedAt.toIso8601String(),
      };

  Map<String, dynamic> _mealEntryToMap(MealEntry m) => {
        'id': m.id,
        'customerId': m.customerId,
        'date': m.date.toIso8601String(),
        'hadBreakfast': m.hadBreakfast,
        'hadDinner': m.hadDinner,
        'breakfastPricePaisa': m.breakfastPricePaisa,
        'dinnerPricePaisa': m.dinnerPricePaisa,
        'notes': m.notes,
        'createdAt': m.createdAt.toIso8601String(),
        'updatedAt': m.updatedAt.toIso8601String(),
      };

  Map<String, dynamic> _additionalItemToMap(AdditionalItemEntry a) => {
        'id': a.id,
        'customerId': a.customerId,
        'menuItemId': a.menuItemId,
        'menuItemName': a.menuItemName,
        'date': a.date.toIso8601String(),
        'quantity': a.quantity,
        'unitPricePaisa': a.unitPricePaisa,
        'notes': a.notes,
        'createdAt': a.createdAt.toIso8601String(),
        'updatedAt': a.updatedAt.toIso8601String(),
      };

  Map<String, dynamic> _paymentToMap(Payment p) => {
        'id': p.id,
        'customerId': p.customerId,
        'paymentDate': p.paymentDate.toIso8601String(),
        'amountPaisa': p.amountPaisa,
        'method': p.method.name,
        'notes': p.notes,
        'referenceNumber': p.referenceNumber,
        'createdAt': p.createdAt.toIso8601String(),
        'updatedAt': p.updatedAt.toIso8601String(),
        'isVoided': p.isVoided,
      };

  Map<String, dynamic> _adjustmentToMap(Adjustment a) => {
        'id': a.id,
        'customerId': a.customerId,
        'adjustmentDate': a.adjustmentDate.toIso8601String(),
        'amountPaisa': a.amountPaisa,
        'reason': a.reason,
        'createdAt': a.createdAt.toIso8601String(),
        'updatedAt': a.updatedAt.toIso8601String(),
        'isVoided': a.isVoided,
      };

  Map<String, dynamic> _monthlyBillToMap(MonthlyBill b) => {
        'id': b.id,
        'customerId': b.customerId,
        'billingYear': b.billingYear,
        'billingMonth': b.billingMonth,
        'breakfastCount': b.breakfastCount,
        'breakfastTotalPaisa': b.breakfastTotalPaisa,
        'dinnerCount': b.dinnerCount,
        'dinnerTotalPaisa': b.dinnerTotalPaisa,
        'additionalItemsTotalPaisa': b.additionalItemsTotalPaisa,
        'adjustmentsTotalPaisa': b.adjustmentsTotalPaisa,
        'previousBalancePaisa': b.previousBalancePaisa,
        'paymentsReceivedPaisa': b.paymentsReceivedPaisa,
        'status': b.status.name,
        'finalizedAt': b.finalizedAt?.toIso8601String(),
        'createdAt': b.createdAt.toIso8601String(),
        'updatedAt': b.updatedAt.toIso8601String(),
        'notes': b.notes,
      };

  Map<String, dynamic> _auditEntryToMap(AuditEntry a) => {
        'id': a.id,
        'action': a.action.name,
        'entityType': a.entityType,
        'entityId': a.entityId,
        'customerId': a.customerId,
        'originalValue': a.originalValue,
        'newValue': a.newValue,
        'reason': a.reason,
        'createdAt': a.createdAt.toIso8601String(),
      };

  // ── Deserializers: Map -> Models ──────────────────────────────────────────

  ShopProfile _shopProfileFromMap(Map<String, dynamic> m) => ShopProfile(
        id: m['id'] as String,
        ownerName: m['ownerName'] as String,
        shopName: m['shopName'] as String,
        address: m['address'] as String,
        phoneNumber: m['phoneNumber'] as String,
        logoPath: m['logoPath'] as String?,
        currencyCode: m['currencyCode'] as String? ?? AppConstants.currencyCode,
        currencySymbol: m['currencySymbol'] as String? ?? AppConstants.currencySymbol,
        defaultBreakfastPricePaisa: m['defaultBreakfastPricePaisa'] as int? ?? AppConstants.defaultBreakfastPricePaisa,
        defaultDinnerPricePaisa: m['defaultDinnerPricePaisa'] as int? ?? AppConstants.defaultDinnerPricePaisa,
        createdAt: DateTime.parse(m['createdAt'] as String),
        updatedAt: DateTime.parse(m['updatedAt'] as String),
      );

  Customer _customerFromMap(Map<String, dynamic> m) => Customer(
        id: m['id'] as String,
        name: m['name'] as String,
        phoneNumber: m['phoneNumber'] as String?,
        isActive: m['isActive'] as bool? ?? true,
        notes: m['notes'] as String?,
        createdAt: DateTime.parse(m['createdAt'] as String),
        updatedAt: DateTime.parse(m['updatedAt'] as String),
      );

  MenuItem _menuItemFromMap(Map<String, dynamic> m) => MenuItem(
        id: m['id'] as String,
        name: m['name'] as String,
        category: MenuCategory.values.firstWhere(
          (c) => c.name == m['category'],
          orElse: () => MenuCategory.extra,
        ),
        unit: m['unit'] as String? ?? 'item',
        pricePaisa: m['pricePaisa'] as int,
        isActive: m['isActive'] as bool? ?? true,
        createdAt: DateTime.parse(m['createdAt'] as String),
        updatedAt: DateTime.parse(m['updatedAt'] as String),
      );

  MealEntry _mealEntryFromMap(Map<String, dynamic> m) => MealEntry(
        id: m['id'] as String,
        customerId: m['customerId'] as String,
        date: DateTime.parse(m['date'] as String),
        hadBreakfast: m['hadBreakfast'] as bool? ?? false,
        hadDinner: m['hadDinner'] as bool? ?? false,
        breakfastPricePaisa: m['breakfastPricePaisa'] as int,
        dinnerPricePaisa: m['dinnerPricePaisa'] as int,
        notes: m['notes'] as String?,
        createdAt: DateTime.parse(m['createdAt'] as String),
        updatedAt: DateTime.parse(m['updatedAt'] as String),
      );

  AdditionalItemEntry _additionalItemFromMap(Map<String, dynamic> m) => AdditionalItemEntry(
        id: m['id'] as String,
        customerId: m['customerId'] as String,
        menuItemId: m['menuItemId'] as String,
        menuItemName: m['menuItemName'] as String,
        date: DateTime.parse(m['date'] as String),
        quantity: m['quantity'] as int,
        unitPricePaisa: m['unitPricePaisa'] as int,
        notes: m['notes'] as String?,
        createdAt: DateTime.parse(m['createdAt'] as String),
        updatedAt: DateTime.parse(m['updatedAt'] as String),
      );

  Payment _paymentFromMap(Map<String, dynamic> m) => Payment(
        id: m['id'] as String,
        customerId: m['customerId'] as String,
        paymentDate: DateTime.parse(m['paymentDate'] as String),
        amountPaisa: m['amountPaisa'] as int,
        method: PaymentMethod.values.firstWhere(
          (meth) => meth.name == m['method'],
          orElse: () => PaymentMethod.cash,
        ),
        notes: m['notes'] as String?,
        referenceNumber: m['referenceNumber'] as String?,
        createdAt: DateTime.parse(m['createdAt'] as String),
        updatedAt: DateTime.parse(m['updatedAt'] as String),
        isVoided: m['isVoided'] as bool? ?? false,
      );

  Adjustment _adjustmentFromMap(Map<String, dynamic> m) => Adjustment(
        id: m['id'] as String,
        customerId: m['customerId'] as String,
        adjustmentDate: DateTime.parse(m['adjustmentDate'] as String),
        amountPaisa: m['amountPaisa'] as int,
        reason: m['reason'] as String,
        createdAt: DateTime.parse(m['createdAt'] as String),
        updatedAt: DateTime.parse(m['updatedAt'] as String),
        isVoided: m['isVoided'] as bool? ?? false,
      );

  MonthlyBill _monthlyBillFromMap(Map<String, dynamic> m) => MonthlyBill(
        id: m['id'] as String,
        customerId: m['customerId'] as String,
        billingYear: m['billingYear'] as int,
        billingMonth: m['billingMonth'] as int,
        breakfastCount: m['breakfastCount'] as int,
        breakfastTotalPaisa: m['breakfastTotalPaisa'] as int,
        dinnerCount: m['dinnerCount'] as int,
        dinnerTotalPaisa: m['dinnerTotalPaisa'] as int,
        additionalItemsTotalPaisa: m['additionalItemsTotalPaisa'] as int,
        adjustmentsTotalPaisa: m['adjustmentsTotalPaisa'] as int,
        previousBalancePaisa: m['previousBalancePaisa'] as int,
        paymentsReceivedPaisa: m['paymentsReceivedPaisa'] as int,
        status: BillStatus.values.firstWhere(
          (s) => s.name == m['status'],
          orElse: () => BillStatus.draft,
        ),
        finalizedAt: m['finalizedAt'] != null ? DateTime.parse(m['finalizedAt'] as String) : null,
        createdAt: DateTime.parse(m['createdAt'] as String),
        updatedAt: DateTime.parse(m['updatedAt'] as String),
        notes: m['notes'] as String?,
      );

  AuditEntry _auditEntryFromMap(Map<String, dynamic> m) => AuditEntry(
        id: m['id'] as String,
        action: AuditAction.values.firstWhere(
          (a) => a.name == m['action'],
          orElse: () => AuditAction.updated,
        ),
        entityType: m['entityType'] as String,
        entityId: m['entityId'] as String,
        customerId: m['customerId'] as String?,
        originalValue: m['originalValue'] as String?,
        newValue: m['newValue'] as String?,
        reason: m['reason'] as String?,
        createdAt: DateTime.parse(m['createdAt'] as String),
      );
}
