import 'dart:io';
import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../core/utils/money_utils.dart';
import '../data/models/additional_item_entry.dart';
import '../data/models/adjustment.dart';
import '../data/models/customer.dart';
import '../data/models/monthly_bill.dart';
import '../data/models/payment.dart';
import '../data/models/shop_profile.dart';
import '../providers/customer_ledger_provider.dart';

/// Service for generating printable, itemized PDF statements and ledgers.
class PdfService {
  const PdfService();

  /// Generates a complete printable PDF statement for a customer's monthly bill.
  Future<Uint8List> generateMonthlyBillPdf({
    required ShopProfile? shop,
    required Customer customer,
    required MonthlyBill bill,
    List<AdditionalItemEntry> extraItems = const [],
    List<Adjustment> adjustments = const [],
    List<Payment> payments = const [],
  }) async {
    final pdf = pw.Document(
      title: 'Monthly Statement - ${customer.name}',
      author: shop?.shopName ?? 'Mess Billing Manager',
    );

    // Attempt to load shop logo if present
    pw.MemoryImage? logoImage;
    if (shop?.logoPath != null && shop!.logoPath!.isNotEmpty) {
      try {
        final logoFile = File(shop.logoPath!);
        if (logoFile.existsSync()) {
          final logoBytes = await logoFile.readAsBytes();
          logoImage = pw.MemoryImage(logoBytes);
        }
      } catch (_) {
        // Fall back gracefully if logo file cannot be read
      }
    }

    final monthDate = DateTime(bill.billingYear, bill.billingMonth);
    final monthStr = DateFormat('MMMM y').format(monthDate);
    final isFinalized = bill.status == BillStatus.finalized;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        build: (pw.Context context) => [
          // ── Header ────────────────────────────────────────────────────────
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    if (logoImage != null)
                      pw.Container(
                        height: 48,
                        width: 48,
                        margin: const pw.EdgeInsets.only(bottom: 8),
                        child: pw.Image(logoImage),
                      ),
                    pw.Text(
                      shop?.shopName ?? 'Mess Billing',
                      style: pw.TextStyle(
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blueGrey900,
                      ),
                    ),
                    if (shop?.phoneNumber != null && shop!.phoneNumber.isNotEmpty)
                      pw.Text(
                        'Phone: ${shop.phoneNumber}',
                        style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                      ),
                    if (shop?.address != null && shop!.address.isNotEmpty)
                      pw.Text(
                        shop.address,
                        style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                      ),
                    if (shop?.ownerName != null && shop!.ownerName.isNotEmpty)
                      pw.Text(
                        'Prop: ${shop.ownerName}',
                        style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                      ),
                  ],
                ),
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: pw.BoxDecoration(
                      color: isFinalized ? PdfColors.green800 : PdfColors.orange800,
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                    ),
                    child: pw.Text(
                      isFinalized ? 'FINALIZED STATEMENT' : 'DRAFT STATEMENT',
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 6),
                  pw.Text(
                    'Month: $monthStr',
                    style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text(
                    'Date: ${DateFormat('dd MMM yyyy').format(DateTime.now())}',
                    style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                  ),
                  pw.Text(
                    'Bill ID: ${bill.id.length > 8 ? bill.id.substring(0, 8).toUpperCase() : bill.id.toUpperCase()}',
                    style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
                  ),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 16),
          pw.Divider(thickness: 1.5, color: PdfColors.blueGrey800),
          pw.SizedBox(height: 12),

          // ── Customer Details Box ──────────────────────────────────────────
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
              border: pw.Border.all(color: PdfColors.grey300),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'BILLED TO:',
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blueGrey700,
                      ),
                    ),
                    pw.SizedBox(height: 3),
                    pw.Text(
                      customer.name,
                      style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
                    ),
                    if (customer.phoneNumber != null && customer.phoneNumber!.isNotEmpty)
                      pw.Text(
                        'Phone: ${customer.phoneNumber}',
                        style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey800),
                      ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    if (customer.notes != null && customer.notes!.isNotEmpty)
                      pw.Text(
                        'Notes: ${customer.notes}',
                        style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey800),
                      ),
                    pw.Text(
                      'Customer ID: ${customer.id.length > 8 ? customer.id.substring(0, 8).toUpperCase() : customer.id.toUpperCase()}',
                      style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
                    ),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 16),

          // ── Itemized Breakdown Table ──────────────────────────────────────
          pw.Text(
            'CHARGES BREAKDOWN',
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blueGrey800,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.TableHelper.fromTextArray(
            headers: ['Description', 'Qty / Details', 'Amount (NPR)'],
            headerStyle: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
            cellStyle: const pw.TextStyle(fontSize: 9),
            cellAlignment: pw.Alignment.centerLeft,
            cellAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.center,
              2: pw.Alignment.centerRight,
            },
            data: [
              [
                'Breakfast Meals',
                '${bill.breakfastCount} meals',
                MoneyUtils.formatNprFromPaisa(bill.breakfastTotalPaisa),
              ],
              [
                'Dinner Meals',
                '${bill.dinnerCount} meals',
                MoneyUtils.formatNprFromPaisa(bill.dinnerTotalPaisa),
              ],
              if (extraItems.isNotEmpty)
                ...extraItems.map((e) => [
                      'Extra: ${e.menuItemName}',
                      '${e.quantity} @ ${MoneyUtils.formatNprFromPaisa(e.unitPricePaisa)}',
                      MoneyUtils.formatNprFromPaisa(e.totalPaisa),
                    ])
              else if (bill.additionalItemsTotalPaisa > 0)
                [
                  'Additional Canteen Items',
                  'Itemized orders',
                  MoneyUtils.formatNprFromPaisa(bill.additionalItemsTotalPaisa),
                ],
              if (adjustments.isNotEmpty)
                ...adjustments.map((a) => [
                      'Adjustment: ${a.reason}',
                      DateFormat('dd MMM').format(a.adjustmentDate),
                      '${a.amountPaisa >= 0 ? '+' : '-'} ${MoneyUtils.formatNprFromPaisa(a.amountPaisa.abs())}',
                    ])
              else if (bill.adjustmentsTotalPaisa != 0)
                [
                  'Manual Adjustments',
                  'Period adjustments',
                  '${bill.adjustmentsTotalPaisa >= 0 ? '+' : '-'} ${MoneyUtils.formatNprFromPaisa(bill.adjustmentsTotalPaisa.abs())}',
                ],
            ],
          ),
          pw.SizedBox(height: 16),

          // ── Financial Summary Box ─────────────────────────────────────────
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.Container(
                width: 250,
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                  border: pw.Border.all(color: PdfColors.grey300),
                ),
                child: pw.Column(
                  children: [
                    _buildSummaryPdfRow(
                      'This Month Charges:',
                      MoneyUtils.formatNprFromPaisa(bill.totalChargesPaisa),
                    ),
                    pw.SizedBox(height: 4),
                    _buildSummaryPdfRow(
                      'Previous Balance:',
                      MoneyUtils.formatNprFromPaisa(bill.previousBalancePaisa),
                    ),
                    pw.SizedBox(height: 4),
                    _buildSummaryPdfRow(
                      'Payments Received:',
                      '- ${MoneyUtils.formatNprFromPaisa(bill.paymentsReceivedPaisa)}',
                      valueColor: PdfColors.green800,
                    ),
                    pw.SizedBox(height: 6),
                    pw.Divider(thickness: 1, color: PdfColors.grey400),
                    pw.SizedBox(height: 4),
                    _buildSummaryPdfRow(
                      bill.outstandingBalancePaisa >= 0 ? 'NET DUE AMOUNT:' : 'STORE CREDIT:',
                      MoneyUtils.formatNprFromPaisa(bill.outstandingBalancePaisa.abs()),
                      isBold: true,
                      valueColor: bill.outstandingBalancePaisa > 0 ? PdfColors.red800 : PdfColors.green800,
                      fontSize: 12,
                    ),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 24),

          // ── Payments Audit (if any) ────────────────────────────────────────
          if (payments.isNotEmpty) ...[
            pw.Text(
              'PAYMENTS RECORDED THIS MONTH',
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blueGrey800,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.TableHelper.fromTextArray(
              headers: ['Date', 'Method', 'Notes', 'Amount (NPR)'],
              headerStyle: pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.grey700),
              cellStyle: const pw.TextStyle(fontSize: 8),
              cellAlignment: pw.Alignment.centerLeft,
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.centerLeft,
                2: pw.Alignment.centerLeft,
                3: pw.Alignment.centerRight,
              },
              data: payments
                  .map((p) => [
                        DateFormat('dd MMM yyyy').format(p.paymentDate),
                        p.method.name.toUpperCase(),
                        p.notes ?? '-',
                        MoneyUtils.formatNprFromPaisa(p.amountPaisa),
                      ])
                  .toList(),
            ),
            pw.SizedBox(height: 16),
          ],

          // ── Footer & Signatures ───────────────────────────────────────────
          pw.Spacer(),
          pw.Divider(thickness: 0.5, color: PdfColors.grey400),
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Thank you for your patronage!',
                    style: pw.TextStyle(fontSize: 9, fontStyle: pw.FontStyle.italic),
                  ),
                  pw.Text(
                    'Please clear dues by the specified date.',
                    style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                  ),
                  pw.Text(
                    'Generated offline via Mess Billing Manager',
                    style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey500),
                  ),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Container(
                    width: 120,
                    height: 1,
                    color: PdfColors.grey700,
                    margin: const pw.EdgeInsets.only(top: 24, bottom: 4),
                  ),
                  pw.Text(
                    'Authorized Signature',
                    style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );

    return pdf.save();
  }

  /// Generates a customer transaction ledger PDF across a selected date range.
  Future<Uint8List> generateCustomerLedgerPdf({
    required ShopProfile? shop,
    required Customer customer,
    required List<LedgerItem> items,
    required int currentBalancePaisa,
    String? periodDescription,
  }) async {
    final pdf = pw.Document(
      title: 'Customer Ledger - ${customer.name}',
      author: shop?.shopName ?? 'Mess Billing Manager',
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        build: (pw.Context context) => [
          // ── Header ────────────────────────────────────────────────────────
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    shop?.shopName ?? 'Mess Billing',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blueGrey900,
                    ),
                  ),
                  if (shop?.phoneNumber != null && shop!.phoneNumber.isNotEmpty)
                    pw.Text('Phone: ${shop.phoneNumber}', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                  if (shop?.address != null && shop!.address.isNotEmpty)
                    pw.Text(shop.address, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    'CUSTOMER LEDGER',
                    style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey800),
                  ),
                  if (periodDescription != null)
                    pw.Text('Period: $periodDescription', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                  pw.Text(
                    'Generated: ${DateFormat('dd MMM yyyy, HH:mm').format(DateTime.now())}',
                    style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                  ),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 12),
          pw.Divider(thickness: 1, color: PdfColors.blueGrey800),
          pw.SizedBox(height: 8),

          // ── Customer & Balance Banner ─────────────────────────────────────
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Customer: ${customer.name}${customer.phoneNumber != null ? ' (${customer.phoneNumber})' : ''}',
                  style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
                ),
                pw.Text(
                  'Closing Balance: ${MoneyUtils.formatNprFromPaisa(currentBalancePaisa)}',
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                    color: currentBalancePaisa > 0 ? PdfColors.red800 : PdfColors.green800,
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 12),

          // ── Ledger Table ──────────────────────────────────────────────────
          pw.TableHelper.fromTextArray(
            headers: ['Date', 'Description', 'Category', 'Debit (+)', 'Credit (-)', 'Balance (NPR)'],
            headerStyle: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
            cellStyle: const pw.TextStyle(fontSize: 8),
            cellAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.centerLeft,
              2: pw.Alignment.center,
              3: pw.Alignment.centerRight,
              4: pw.Alignment.centerRight,
              5: pw.Alignment.centerRight,
            },
            data: items.map((item) {
              final isDebit = item.amountPaisa > 0;
              final isCredit = item.amountPaisa < 0;
              return [
                DateFormat('dd/MM/yyyy').format(item.date),
                item.title,
                item.type.name.toUpperCase(),
                isDebit ? MoneyUtils.formatNprFromPaisa(item.amountPaisa) : '-',
                isCredit ? MoneyUtils.formatNprFromPaisa(item.amountPaisa.abs()) : '-',
                MoneyUtils.formatNprFromPaisa(item.runningBalancePaisa),
              ];
            }).toList(),
          ),
          pw.SizedBox(height: 16),

          // ── Footer ────────────────────────────────────────────────────────
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Total Entries: ${items.length}',
                style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
              ),
              pw.Text(
                'Generated offline via Mess Billing Manager',
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
              ),
            ],
          ),
        ],
      ),
    );

    return pdf.save();
  }

  // ── Print & Share Actions ─────────────────────────────────────────────────

  /// Launches the system print dialog or print preview.
  Future<void> printPdf({
    required Uint8List bytes,
    required String title,
  }) async {
    await Printing.layoutPdf(
      name: title,
      onLayout: (PdfPageFormat format) async => bytes,
    );
  }

  /// Shares the PDF file with WhatsApp, email, or other installed apps.
  Future<void> sharePdf({
    required Uint8List bytes,
    required String filename,
  }) async {
    await Printing.sharePdf(bytes: bytes, filename: filename);
  }

  // ── Helper ────────────────────────────────────────────────────────────────

  static pw.Widget _buildSummaryPdfRow(
    String label,
    String value, {
    bool isBold = false,
    PdfColor? valueColor,
    double fontSize = 9,
  }) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: fontSize,
            fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            color: PdfColors.blueGrey800,
          ),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: fontSize,
            fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            color: valueColor ?? (isBold ? PdfColors.blueGrey900 : PdfColors.grey800),
          ),
        ),
      ],
    );
  }
}
