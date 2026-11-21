import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_billing/data/models/additional_item_entry.dart';
import 'package:food_billing/data/models/adjustment.dart';
import 'package:food_billing/data/models/customer.dart';
import 'package:food_billing/data/models/monthly_bill.dart';
import 'package:food_billing/data/models/payment.dart';
import 'package:food_billing/data/models/shop_profile.dart';
import 'package:food_billing/providers/customer_ledger_provider.dart';
import 'package:food_billing/providers/monthly_bill_provider.dart';
import 'package:food_billing/services/csv_export_service.dart';
import 'package:food_billing/services/pdf_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final mockShop = ShopProfile(
    id: 'shop-1',
    ownerName: 'Ujjawal Paudel',
    shopName: 'Green Mess & Food Station',
    address: 'Kathmandu, Nepal',
    phoneNumber: '9800000000',
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );

  final mockCustomer = Customer(
    id: 'cust-101',
    name: 'Aayush Shrestha',
    phoneNumber: '9841234567',
    notes: 'Room 204, Everest Hostel',
    isActive: true,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );

  final mockBill = MonthlyBill(
    id: 'bill-2026-10-101',
    customerId: 'cust-101',
    billingYear: 2026,
    billingMonth: 10,
    breakfastCount: 25,
    breakfastTotalPaisa: 212500, // 25 * 85.00 = 2,125.00
    dinnerCount: 28,
    dinnerTotalPaisa: 238000, // 28 * 85.00 = 2,380.00
    additionalItemsTotalPaisa: 45000, // 450.00
    adjustmentsTotalPaisa: -10000, // -100.00 discount
    previousBalancePaisa: 50000, // 500.00 carried over
    paymentsReceivedPaisa: 400000, // 4,000.00 paid
    status: BillStatus.finalized,
    finalizedAt: DateTime(2026, 11, 1),
    createdAt: DateTime(2026, 10, 31),
    updatedAt: DateTime(2026, 11, 1),
  );

  group('CsvExportService', () {
    const csvService = CsvExportService();

    test('RFC 4180 escaping works properly', () {
      expect(CsvExportService.escapeCsvCell('Hello'), 'Hello');
      expect(CsvExportService.escapeCsvCell(null), '');
      expect(CsvExportService.escapeCsvCell('Green, Mess'), '"Green, Mess"');
      expect(CsvExportService.escapeCsvCell('He said "Hello"'), '"He said ""Hello"""');
      expect(CsvExportService.escapeCsvCell('Line1\nLine2'), '"Line1\nLine2"');
    });

    test('Paisa to NPR string formatting is exact to two decimal places', () {
      expect(CsvExportService.paisaToNprString(0), '0.00');
      expect(CsvExportService.paisaToNprString(8500), '85.00');
      expect(CsvExportService.paisaToNprString(125), '1.25');
      expect(CsvExportService.paisaToNprString(1000000), '10000.00');
    });

    test('generateMonthlyBillsCsv exports headers and itemized records', () {
      final summary = CustomerBillSummary(
        customer: mockCustomer,
        bill: mockBill,
        hasActivity: true,
      );

      final csv = csvService.generateMonthlyBillsCsv(
        summaries: [summary],
        year: 2026,
        month: 10,
      );

      // Verify headers
      expect(csv, contains('Customer Name,Phone Number,Notes / Details'));
      expect(csv, contains('Breakfast Count,Breakfast Total (NPR)'));
      expect(csv, contains('Net Outstanding Balance (NPR),Bill Status'));

      // Verify row values
      expect(csv, contains('Aayush Shrestha,9841234567,"Room 204, Everest Hostel",2026,10,25,2125.00,28,2380.00,450.00,-100.00'));
      // Outstanding balance: 500.00 prev + (2125 + 2380 + 450 - 100 = 4855.00) - 4000 = 1355.00
      expect(csv, contains('1355.00,FINALIZED'));
    });

    test('generateCustomerLedgerCsv exports ledger comments, headers, and transaction rows', () {
      final ledgerItems = [
        LedgerItem(
          id: 'item-1',
          date: DateTime(2026, 10, 1),
          type: LedgerItemType.meal,
          title: 'Breakfast',
          subtitle: 'Mess meal entry',
          amountPaisa: 8500,
          runningBalancePaisa: 8500,
        ),
        LedgerItem(
          id: 'item-2',
          date: DateTime(2026, 10, 2),
          type: LedgerItemType.additionalItem,
          title: 'Cold Drink',
          subtitle: 'Qty: 1',
          amountPaisa: 6000,
          runningBalancePaisa: 14500,
        ),
        LedgerItem(
          id: 'item-3',
          date: DateTime(2026, 10, 5),
          type: LedgerItemType.payment,
          title: 'Payment Received',
          subtitle: 'E-Sewa',
          amountPaisa: -10000,
          runningBalancePaisa: 4500,
        ),
      ];

      final csv = csvService.generateCustomerLedgerCsv(
        customer: mockCustomer,
        items: ledgerItems,
        closingBalancePaisa: 4500,
      );

      expect(csv, contains('# Customer Ledger: Aayush Shrestha'));
      expect(csv, contains('# Closing Balance: NPR 45.00'));
      expect(csv, contains('Date,Type,Description,Subtitle,Debit Charge (NPR),Credit Payment (NPR),Running Balance (NPR)'));
      expect(csv, contains('2026-10-01,MEAL,Breakfast,Mess meal entry,85.00,0.00,85.00'));
      expect(csv, contains('2026-10-02,ADDITIONALITEM,Cold Drink,Qty: 1,60.00,0.00,145.00'));
      expect(csv, contains('2026-10-05,PAYMENT,Payment Received,E-Sewa,0.00,100.00,45.00'));
    });
  });

  group('PdfService', () {
    const pdfService = PdfService();

    test('generateMonthlyBillPdf generates valid PDF binary data starting with %PDF-', () async {
      final extraItems = [
        AdditionalItemEntry(
          id: 'extra-1',
          customerId: 'cust-101',
          menuItemId: 'menu-1',
          menuItemName: 'Milk Tea & Biscuit',
          unitPricePaisa: 4500,
          quantity: 10,
          date: DateTime(2026, 10, 15),
          createdAt: DateTime(2026, 10, 15),
          updatedAt: DateTime(2026, 10, 15),
        ),
      ];

      final payments = [
        Payment(
          id: 'pay-1',
          customerId: 'cust-101',
          amountPaisa: 400000,
          paymentDate: DateTime(2026, 10, 25),
          method: PaymentMethod.esewa,
          notes: 'Txn #98721',
          createdAt: DateTime(2026, 10, 25),
          updatedAt: DateTime(2026, 10, 25),
        ),
      ];

      final bytes = await pdfService.generateMonthlyBillPdf(
        shop: mockShop,
        customer: mockCustomer,
        bill: mockBill,
        extraItems: extraItems,
        payments: payments,
      );

      expect(bytes, isNotEmpty);
      // Valid PDF document begins with ASCII "%PDF-"
      final magicHeader = utf8.decode(bytes.sublist(0, 5));
      expect(magicHeader, '%PDF-');
    });

    test('generateCustomerLedgerPdf generates valid PDF bytes', () async {
      final ledgerItems = [
        LedgerItem(
          id: 'item-1',
          date: DateTime(2026, 10, 1),
          type: LedgerItemType.meal,
          title: 'Breakfast & Dinner',
          subtitle: 'Day 1 meals',
          amountPaisa: 17000,
          runningBalancePaisa: 17000,
        ),
        LedgerItem(
          id: 'item-2',
          date: DateTime(2026, 10, 10),
          type: LedgerItemType.payment,
          title: 'Cash Payment',
          subtitle: 'Receipt #04',
          amountPaisa: -15000,
          runningBalancePaisa: 2000,
        ),
      ];

      final bytes = await pdfService.generateCustomerLedgerPdf(
        shop: mockShop,
        customer: mockCustomer,
        items: ledgerItems,
        currentBalancePaisa: 2000,
        periodDescription: 'October 2026',
      );

      expect(bytes, isNotEmpty);
      final magicHeader = utf8.decode(bytes.sublist(0, 5));
      expect(magicHeader, '%PDF-');
    });
  });
}
