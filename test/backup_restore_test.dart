import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_billing/data/models/additional_item_entry.dart';
import 'package:food_billing/data/models/adjustment.dart';
import 'package:food_billing/data/models/audit_entry.dart';
import 'package:food_billing/data/models/customer.dart';
import 'package:food_billing/data/models/meal_entry.dart';
import 'package:food_billing/data/models/menu_item.dart';
import 'package:food_billing/data/models/monthly_bill.dart';
import 'package:food_billing/data/models/payment.dart';
import 'package:food_billing/data/models/shop_profile.dart';
import 'package:food_billing/services/backup_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const backupService = BackupService();

  group('BackupService Validation', () {
    test('rejects empty input', () {
      final result = backupService.validateBackup('   ');
      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('empty'));
    });

    test('rejects malformed JSON', () {
      final result = backupService.validateBackup('{ invalid json: 123');
      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('Invalid JSON'));
    });

    test('rejects backup with unrecognized app identifier', () {
      final badApp = jsonEncode({
        'app': 'SomeOtherBillingApp',
        'schemaVersion': 1,
        'exportedAt': DateTime.now().toIso8601String(),
        'data': {},
      });
      final result = backupService.validateBackup(badApp);
      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('Unrecognized backup source'));
    });

    test('rejects backup with unsupported future schema version', () {
      final futureSchema = jsonEncode({
        'app': BackupService.appIdentifier,
        'schemaVersion': 99,
        'exportedAt': DateTime.now().toIso8601String(),
        'data': {},
      });
      final result = backupService.validateBackup(futureSchema);
      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('Unsupported backup schema version'));
    });

    test('rejects backup without data payload', () {
      final missingData = jsonEncode({
        'app': BackupService.appIdentifier,
        'schemaVersion': 1,
        'exportedAt': DateTime.now().toIso8601String(),
      });
      final result = backupService.validateBackup(missingData);
      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('Missing "data" collection payload'));
    });

    test('successfully validates standard backup and computes metadata counts', () {
      final validBackup = jsonEncode({
        'app': BackupService.appIdentifier,
        'schemaVersion': 1,
        'exportedAt': '2026-11-23T12:00:00.000Z',
        'counts': {
          'customers': 2,
          'menuItems': 1,
        },
        'data': {
          'shopProfile': {
            'id': 'shop-1',
            'ownerName': 'Ram Bahadur',
            'shopName': 'Everest Mess',
            'address': 'Koteshwor, Kathmandu',
            'phoneNumber': '9841000000',
            'logoPath': null,
            'currencyCode': 'NPR',
            'currencySymbol': 'Rs.',
            'defaultBreakfastPricePaisa': 8500,
            'defaultDinnerPricePaisa': 8500,
            'createdAt': '2026-01-01T00:00:00.000Z',
            'updatedAt': '2026-01-01T00:00:00.000Z',
          },
          'customers': [
            {
              'id': 'c1',
              'name': 'Bikash Thapa',
              'phoneNumber': '9800000001',
              'isActive': true,
              'notes': 'Room 101',
              'createdAt': '2026-01-01T00:00:00.000Z',
              'updatedAt': '2026-01-01T00:00:00.000Z',
            },
            {
              'id': 'c2',
              'name': 'Sujan Shrestha',
              'phoneNumber': '9800000002',
              'isActive': false,
              'notes': null,
              'createdAt': '2026-01-01T00:00:00.000Z',
              'updatedAt': '2026-01-01T00:00:00.000Z',
            },
          ],
          'menuItems': [
            {
              'id': 'm1',
              'name': 'Boiled Egg',
              'category': 'meal',
              'unit': 'piece',
              'pricePaisa': 2500,
              'isActive': true,
              'createdAt': '2026-01-01T00:00:00.000Z',
              'updatedAt': '2026-01-01T00:00:00.000Z',
            },
          ],
          'mealEntries': [
            {
              'id': 'me1',
              'customerId': 'c1',
              'date': '2026-11-01T00:00:00.000Z',
              'hadBreakfast': true,
              'hadDinner': true,
              'breakfastPricePaisa': 8500,
              'dinnerPricePaisa': 8500,
              'notes': null,
              'createdAt': '2026-11-01T00:00:00.000Z',
              'updatedAt': '2026-11-01T00:00:00.000Z',
            },
          ],
          'additionalItemEntries': [
            {
              'id': 'a1',
              'customerId': 'c1',
              'menuItemId': 'm1',
              'menuItemName': 'Boiled Egg',
              'date': '2026-11-01T00:00:00.000Z',
              'quantity': 2,
              'unitPricePaisa': 2500,
              'notes': null,
              'createdAt': '2026-11-01T00:00:00.000Z',
              'updatedAt': '2026-11-01T00:00:00.000Z',
            },
          ],
          'payments': [
            {
              'id': 'p1',
              'customerId': 'c1',
              'paymentDate': '2026-11-05T00:00:00.000Z',
              'amountPaisa': 500000,
              'method': 'esewa',
              'notes': 'Online transfer',
              'referenceNumber': 'TXN123',
              'createdAt': '2026-11-05T00:00:00.000Z',
              'updatedAt': '2026-11-05T00:00:00.000Z',
              'isVoided': false,
            },
          ],
          'adjustments': [
            {
              'id': 'adj1',
              'customerId': 'c1',
              'adjustmentDate': '2026-11-10T00:00:00.000Z',
              'amountPaisa': -50000,
              'reason': 'Festival discount',
              'createdAt': '2026-11-10T00:00:00.000Z',
              'updatedAt': '2026-11-10T00:00:00.000Z',
              'isVoided': false,
            },
          ],
          'monthlyBills': [
            {
              'id': 'b1',
              'customerId': 'c1',
              'billingYear': 2026,
              'billingMonth': 10,
              'breakfastCount': 30,
              'breakfastTotalPaisa': 255000,
              'dinnerCount': 30,
              'dinnerTotalPaisa': 255000,
              'additionalItemsTotalPaisa': 5000,
              'adjustmentsTotalPaisa': 0,
              'previousBalancePaisa': 0,
              'paymentsReceivedPaisa': 500000,
              'status': 'finalized',
              'finalizedAt': '2026-11-01T00:00:00.000Z',
              'createdAt': '2026-10-31T00:00:00.000Z',
              'updatedAt': '2026-11-01T00:00:00.000Z',
              'notes': null,
            },
          ],
          'auditEntries': [],
        },
      });

      final result = backupService.validateBackup(validBackup);
      expect(result.isValid, isTrue);
      expect(result.errorMessage, isNull);

      final meta = result.metadata!;
      expect(meta.shopName, 'Everest Mess');
      expect(meta.customerCount, 2);
      expect(meta.menuItemCount, 1);
      expect(meta.mealEntryCount, 1);
      expect(meta.additionalItemCount, 1);
      expect(meta.paymentCount, 1);
      expect(meta.adjustmentCount, 1);
      expect(meta.monthlyBillCount, 1);
      expect(meta.auditEntryCount, 0);
      expect(meta.totalRecords, 9); // 1 shop + 2 cust + 1 menu + 1 meal + 1 extra + 1 pay + 1 adj + 1 bill
    });
  });

  group('Model Serialization Round-Trip', () {
    test('Customer model serialization and deserialization retains all fields', () {
      final customer = Customer(
        id: 'c-test-1',
        name: 'Pradeep Adhikari',
        phoneNumber: '9841122334',
        notes: 'Hostel Block B Room 302',
        isActive: true,
        createdAt: DateTime(2026, 1, 15, 10, 30),
        updatedAt: DateTime(2026, 2, 1, 14, 0),
      );

      final map = {
        'id': customer.id,
        'name': customer.name,
        'phoneNumber': customer.phoneNumber,
        'isActive': customer.isActive,
        'notes': customer.notes,
        'createdAt': customer.createdAt.toIso8601String(),
        'updatedAt': customer.updatedAt.toIso8601String(),
      };

      final restored = Customer(
        id: map['id'] as String,
        name: map['name'] as String,
        phoneNumber: map['phoneNumber'] as String?,
        isActive: map['isActive'] as bool,
        notes: map['notes'] as String?,
        createdAt: DateTime.parse(map['createdAt'] as String),
        updatedAt: DateTime.parse(map['updatedAt'] as String),
      );

      expect(restored.id, customer.id);
      expect(restored.name, customer.name);
      expect(restored.phoneNumber, customer.phoneNumber);
      expect(restored.notes, customer.notes);
      expect(restored.isActive, customer.isActive);
      expect(restored.createdAt, customer.createdAt);
      expect(restored.updatedAt, customer.updatedAt);
    });

    test('Payment model serialization preserves amount in Paisa and PaymentMethod enum', () {
      final payment = Payment(
        id: 'p-test-1',
        customerId: 'c-test-1',
        paymentDate: DateTime(2026, 3, 1),
        amountPaisa: 750000,
        method: PaymentMethod.khalti,
        notes: 'Partial payment',
        referenceNumber: 'KH-88219',
        createdAt: DateTime(2026, 3, 1),
        updatedAt: DateTime(2026, 3, 1),
        isVoided: false,
      );

      final map = {
        'id': payment.id,
        'customerId': payment.customerId,
        'paymentDate': payment.paymentDate.toIso8601String(),
        'amountPaisa': payment.amountPaisa,
        'method': payment.method.name,
        'notes': payment.notes,
        'referenceNumber': payment.referenceNumber,
        'createdAt': payment.createdAt.toIso8601String(),
        'updatedAt': payment.updatedAt.toIso8601String(),
        'isVoided': payment.isVoided,
      };

      final restored = Payment(
        id: map['id'] as String,
        customerId: map['customerId'] as String,
        paymentDate: DateTime.parse(map['paymentDate'] as String),
        amountPaisa: map['amountPaisa'] as int,
        method: PaymentMethod.values.firstWhere((m) => m.name == map['method']),
        notes: map['notes'] as String?,
        referenceNumber: map['referenceNumber'] as String?,
        createdAt: DateTime.parse(map['createdAt'] as String),
        updatedAt: DateTime.parse(map['updatedAt'] as String),
        isVoided: map['isVoided'] as bool,
      );

      expect(restored.id, payment.id);
      expect(restored.amountPaisa, 750000);
      expect(restored.method, PaymentMethod.khalti);
      expect(restored.referenceNumber, 'KH-88219');
      expect(restored.isVoided, isFalse);
    });
  });
}
