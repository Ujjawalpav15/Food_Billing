import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../data/models/customer.dart';
import '../providers/customer_ledger_provider.dart';
import '../providers/monthly_bill_provider.dart';

/// Service for exporting mess billing data, statements, and ledgers into CSV format.
class CsvExportService {
  const CsvExportService();

  /// Escapes a CSV cell value according to RFC 4180 rules.
  static String escapeCsvCell(dynamic value) {
    if (value == null) return '';
    final str = value.toString();
    if (str.contains(',') || str.contains('"') || str.contains('\n') || str.contains('\r')) {
      return '"${str.replaceAll('"', '""')}"';
    }
    return str;
  }

  /// Converts integer Paisa into standard 2-decimal NPR string (e.g., 8500 -> "85.00").
  static String paisaToNprString(int paisa) {
    return (paisa / 100).toStringAsFixed(2);
  }

  /// Generates a CSV string representing all customer monthly bills for a given period.
  String generateMonthlyBillsCsv({
    required List<CustomerBillSummary> summaries,
    required int year,
    required int month,
  }) {
    final buffer = StringBuffer();

    // CSV Header
    final headers = [
      'Customer Name',
      'Phone Number',
      'Notes / Details',
      'Year',
      'Month',
      'Breakfast Count',
      'Breakfast Total (NPR)',
      'Dinner Count',
      'Dinner Total (NPR)',
      'Extras Total (NPR)',
      'Adjustments Total (NPR)',
      'Current Charges (NPR)',
      'Previous Balance (NPR)',
      'Payments Received (NPR)',
      'Net Outstanding Balance (NPR)',
      'Bill Status',
    ];
    buffer.writeln(headers.map(escapeCsvCell).join(','));

    // Data rows
    for (final s in summaries) {
      final bill = s.bill;
      final customer = s.customer;
      final row = [
        customer.name,
        customer.phoneNumber ?? '',
        customer.notes ?? '',
        bill.billingYear,
        bill.billingMonth,
        bill.breakfastCount,
        paisaToNprString(bill.breakfastTotalPaisa),
        bill.dinnerCount,
        paisaToNprString(bill.dinnerTotalPaisa),
        paisaToNprString(bill.additionalItemsTotalPaisa),
        paisaToNprString(bill.adjustmentsTotalPaisa),
        paisaToNprString(bill.totalChargesPaisa),
        paisaToNprString(bill.previousBalancePaisa),
        paisaToNprString(bill.paymentsReceivedPaisa),
        paisaToNprString(bill.outstandingBalancePaisa),
        bill.status.name.toUpperCase(),
      ];
      buffer.writeln(row.map(escapeCsvCell).join(','));
    }

    return buffer.toString();
  }

  /// Generates a CSV string of customer ledger entries.
  String generateCustomerLedgerCsv({
    required Customer customer,
    required List<LedgerItem> items,
    required int closingBalancePaisa,
  }) {
    final buffer = StringBuffer();

    // Customer metadata header comments
    buffer.writeln('# Customer Ledger: ${escapeCsvCell(customer.name)}');
    if (customer.phoneNumber != null) {
      buffer.writeln('# Phone: ${escapeCsvCell(customer.phoneNumber)}');
    }
    buffer.writeln('# Export Date: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}');
    buffer.writeln('# Closing Balance: NPR ${paisaToNprString(closingBalancePaisa)}');
    buffer.writeln();

    // Column Headers
    final headers = [
      'Date',
      'Type',
      'Description',
      'Subtitle',
      'Debit Charge (NPR)',
      'Credit Payment (NPR)',
      'Running Balance (NPR)',
    ];
    buffer.writeln(headers.map(escapeCsvCell).join(','));

    for (final item in items) {
      final isDebit = item.amountPaisa > 0;
      final isCredit = item.amountPaisa < 0;

      final row = [
        DateFormat('yyyy-MM-dd').format(item.date),
        item.type.name.toUpperCase(),
        item.title,
        item.subtitle,
        isDebit ? paisaToNprString(item.amountPaisa) : '0.00',
        isCredit ? paisaToNprString(item.amountPaisa.abs()) : '0.00',
        paisaToNprString(item.runningBalancePaisa),
      ];
      buffer.writeln(row.map(escapeCsvCell).join(','));
    }

    return buffer.toString();
  }

  /// Exports and shares CSV content via standard system share dialog (WhatsApp, Drive, Email, etc.).
  Future<String> shareCsv({
    required String csvContent,
    required String fileName,
    String? subject,
  }) async {
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsString(csvContent);

    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'text/csv')],
      text: subject ?? fileName,
      subject: subject,
    );

    return file.path;
  }
}
