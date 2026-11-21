import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/money_utils.dart';
import '../../data/models/additional_item_entry.dart';
import '../../data/models/adjustment.dart';
import '../../data/models/customer.dart';
import '../../data/models/monthly_bill.dart';
import '../../data/models/payment.dart';
import '../../data/models/shop_profile.dart';
import '../../providers/monthly_bill_provider.dart';
import '../../providers/shop_profile_provider.dart';
import '../../services/csv_export_service.dart';
import '../../services/pdf_service.dart';
import '../ledger/customer_ledger_screen.dart';
import 'pdf_preview_screen.dart';

class MonthlyStatementScreen extends StatelessWidget {
  final Customer customer;
  final MonthlyBill bill;

  const MonthlyStatementScreen({
    super.key,
    required this.customer,
    required this.bill,
  });

  static Route<void> route({required Customer customer, required MonthlyBill bill}) {
    return MaterialPageRoute(
      builder: (_) => MonthlyStatementScreen(customer: customer, bill: bill),
    );
  }

  void _confirmFinalize(BuildContext context, MonthlyBillProvider provider) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Finalize Monthly Bill?'),
        content: Text(
          'Finalizing locks this statement for "${customer.name}". '
          'Future changes to menu prices or settings will not alter this finalized historical bill.\n\n'
          'You can still reopen or amend it explicitly if needed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await provider.finalizeBill(bill);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Monthly statement finalized and locked'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Finalize Bill'),
          ),
        ],
      ),
    );
  }

  void _confirmReopen(BuildContext context, MonthlyBillProvider provider) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reopen / Amend Bill?'),
        content: Text(
          'Reopening unlocks this statement for "${customer.name}". '
          'It will recalculate totals based on the latest meal attendance and pricing records.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warning,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await provider.reopenBill(bill);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Bill reopened for editing'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Reopen Bill'),
          ),
        ],
      ),
    );
  }

  void _openPdfPreview(
    BuildContext context,
    ShopProfile? shop,
    MonthlyBill currentBill,
    List<AdditionalItemEntry> extraItems,
    List<Adjustment> adjustments,
    List<Payment> payments,
  ) {
    final fileName = 'Statement_${customer.name.replaceAll(' ', '_')}_${currentBill.billingYear}_${currentBill.billingMonth}.pdf';
    Navigator.of(context).push(
      PdfPreviewScreen.route(
        title: 'Bill: ${customer.name}',
        fileName: fileName,
        pdfDataBuilder: () => const PdfService().generateMonthlyBillPdf(
          shop: shop,
          customer: customer,
          bill: currentBill,
          extraItems: extraItems,
          adjustments: adjustments,
          payments: payments,
        ),
      ),
    );
  }

  Future<void> _sharePdf(
    BuildContext context,
    ShopProfile? shop,
    MonthlyBill currentBill,
    List<AdditionalItemEntry> extraItems,
    List<Adjustment> adjustments,
    List<Payment> payments,
  ) async {
    try {
      final fileName = 'Statement_${customer.name.replaceAll(' ', '_')}_${currentBill.billingYear}_${currentBill.billingMonth}.pdf';
      final bytes = await const PdfService().generateMonthlyBillPdf(
        shop: shop,
        customer: customer,
        bill: currentBill,
        extraItems: extraItems,
        adjustments: adjustments,
        payments: payments,
      );
      await const PdfService().sharePdf(bytes: bytes, filename: fileName);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to share PDF: $e')),
        );
      }
    }
  }

  Future<void> _exportCsv(
    BuildContext context,
    CustomerBillSummary summary,
  ) async {
    try {
      final csvContent = const CsvExportService().generateMonthlyBillsCsv(
        summaries: [summary],
        year: summary.bill.billingYear,
        month: summary.bill.billingMonth,
      );
      final fileName = 'Bill_${customer.name.replaceAll(' ', '_')}_${summary.bill.billingYear}_${summary.bill.billingMonth}.csv';
      await const CsvExportService().shareCsv(
        csvContent: csvContent,
        fileName: fileName,
        subject: 'Monthly Bill Statement - ${customer.name}',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to export CSV: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final billProvider = context.watch<MonthlyBillProvider>();
    final shopProvider = context.watch<ShopProfileProvider>();
    final shop = shopProvider.shopProfile;

    // Use current updated copy from provider if present
    final currentSummary = billProvider.allSummaries.firstWhere(
      (s) => s.customer.id == customer.id,
      orElse: () => CustomerBillSummary(customer: customer, bill: bill, hasActivity: true),
    );
    final currentBill = currentSummary.bill;

    final monthDate = DateTime(currentBill.billingYear, currentBill.billingMonth);
    final monthStr = DateFormat('MMMM y').format(monthDate);
    final isFinalized = currentBill.status == BillStatus.finalized;

    final extraItems = billProvider.getExtraItemsForBill(customer.id);
    final adjustments = billProvider.getAdjustmentsForBill(customer.id);
    final payments = billProvider.getPaymentsForBill(customer.id);

    return Scaffold(
      appBar: AppBar(
        title: Text('${customer.name} — $monthStr'),
        actions: [
          IconButton(
            icon: const Icon(Icons.print_outlined),
            tooltip: 'Print / Preview PDF',
            onPressed: () => _openPdfPreview(context, shop, currentBill, extraItems, adjustments, payments),
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Share PDF',
            onPressed: () => _sharePdf(context, shop, currentBill, extraItems, adjustments, payments),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            tooltip: 'More actions',
            onSelected: (val) {
              if (val == 'ledger') {
                Navigator.of(context).push(CustomerLedgerScreen.route(customer));
              } else if (val == 'csv') {
                _exportCsv(context, currentSummary);
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'csv',
                child: Row(
                  children: [
                    Icon(Icons.table_chart_outlined, size: 20),
                    SizedBox(width: 8),
                    Text('Export CSV'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'ledger',
                child: Row(
                  children: [
                    Icon(Icons.menu_book_outlined, size: 20),
                    SizedBox(width: 8),
                    Text('View Ledger'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Statement Header Card ──────────────────────────────────────
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            shop?.shopName ?? 'Mess Billing',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          if (shop?.phoneNumber != null && shop!.phoneNumber.isNotEmpty)
                            Text(
                              'Phone: ${shop.phoneNumber}',
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          if (shop?.address != null && shop!.address.isNotEmpty)
                            Text(
                              shop.address,
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                        ],
                      ),
                      _StatusBadge(status: currentBill.status, finalizedAt: currentBill.finalizedAt),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('BILLED TO',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary)),
                          const SizedBox(height: 2),
                          Text(customer.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          if (customer.phoneNumber != null)
                            Text(customer.phoneNumber!, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('BILLING MONTH',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary)),
                          const SizedBox(height: 2),
                          Text(monthStr, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                          Text(
                            isFinalized ? 'Status: LOCKED' : 'Status: DRAFT',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isFinalized ? AppColors.success : AppColors.warning,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ── Meals Section ──────────────────────────────────────────────
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('MEAL CHARGES',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary, letterSpacing: 1.1)),
                  const SizedBox(height: 12),
                  _ItemRow(
                    label: 'Breakfast (${currentBill.breakfastCount} meals)',
                    amount: MoneyUtils.formatNprFromPaisa(currentBill.breakfastTotalPaisa),
                  ),
                  const SizedBox(height: 6),
                  _ItemRow(
                    label: 'Dinner (${currentBill.dinnerCount} meals)',
                    amount: MoneyUtils.formatNprFromPaisa(currentBill.dinnerTotalPaisa),
                  ),
                  const Divider(height: 16),
                  _ItemRow(
                    label: 'Total Meals Subtotal',
                    amount: MoneyUtils.formatNprFromPaisa(currentBill.breakfastTotalPaisa + currentBill.dinnerTotalPaisa),
                    isBold: true,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ── Additional Items Section ───────────────────────────────────
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('ADDITIONAL ITEMS & EXTRAS',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary, letterSpacing: 1.1)),
                  const SizedBox(height: 12),
                  if (extraItems.isEmpty)
                    const Text('No additional extra items recorded for this month.',
                        style: TextStyle(fontSize: 13, color: AppColors.textSecondary))
                  else
                    ...extraItems.map((e) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: _ItemRow(
                          label: '${e.quantity}x ${e.menuItemName} (@ ${MoneyUtils.formatNprFromPaisa(e.unitPricePaisa)})',
                          amount: MoneyUtils.formatNprFromPaisa(e.totalPaisa),
                        ),
                      );
                    }),
                  const Divider(height: 16),
                  _ItemRow(
                    label: 'Total Extras Subtotal',
                    amount: MoneyUtils.formatNprFromPaisa(currentBill.additionalItemsTotalPaisa),
                    isBold: true,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ── Adjustments Section ────────────────────────────────────────
          if (adjustments.isNotEmpty || currentBill.adjustmentsTotalPaisa != 0) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('ADJUSTMENTS & DISCOUNTS',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary, letterSpacing: 1.1)),
                    const SizedBox(height: 12),
                    ...adjustments.map((a) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: _ItemRow(
                          label: a.reason,
                          amount: a.amountPaisa > 0
                              ? '+${MoneyUtils.formatNprFromPaisa(a.amountPaisa)}'
                              : '-${MoneyUtils.formatNprFromPaisa(-a.amountPaisa)}',
                        ),
                      );
                    }),
                    const Divider(height: 16),
                    _ItemRow(
                      label: 'Total Adjustments',
                      amount: currentBill.adjustmentsTotalPaisa > 0
                          ? '+${MoneyUtils.formatNprFromPaisa(currentBill.adjustmentsTotalPaisa)}'
                          : '-${MoneyUtils.formatNprFromPaisa(-currentBill.adjustmentsTotalPaisa)}',
                      isBold: true,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // ── Total Summary Statement Card ───────────────────────────────
          Card(
            color: AppColors.primary.withAlpha(10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('STATEMENT BALANCE SUMMARY',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary, letterSpacing: 1.1)),
                  const SizedBox(height: 12),
                  _ItemRow(
                    label: 'Previous Balance (Brought Forward)',
                    amount: MoneyUtils.formatNprFromPaisa(currentBill.previousBalancePaisa),
                  ),
                  const SizedBox(height: 6),
                  _ItemRow(
                    label: 'Current Month Charges',
                    amount: '+${MoneyUtils.formatNprFromPaisa(currentBill.totalChargesPaisa)}',
                  ),
                  const SizedBox(height: 6),
                  _ItemRow(
                    label: 'Payments Applied (${payments.length} payments)',
                    amount: '-${MoneyUtils.formatNprFromPaisa(currentBill.paymentsReceivedPaisa)}',
                    color: AppColors.success,
                  ),
                  const Divider(height: 20, thickness: 1.5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'TOTAL AMOUNT DUE',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      Text(
                        MoneyUtils.formatNprFromPaisa(currentBill.outstandingBalancePaisa),
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: currentBill.outstandingBalancePaisa > 0
                              ? AppColors.error
                              : AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ── Export & Print Actions ────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.print_outlined),
                  label: const Text('Preview / Print'),
                  onPressed: () => _openPdfPreview(context, shop, currentBill, extraItems, adjustments, payments),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.share_outlined),
                  label: const Text('Share PDF'),
                  onPressed: () => _sharePdf(context, shop, currentBill, extraItems, adjustments, payments),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Status Lock Actions ────────────────────────────────────────
          if (isFinalized)
            OutlinedButton.icon(
              icon: const Icon(Icons.lock_open, color: AppColors.warning),
              label: const Text('Reopen / Amend This Bill'),
              onPressed: () => _confirmReopen(context, billProvider),
            )
          else
            ElevatedButton.icon(
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Finalize Statement'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () => _confirmFinalize(context, billProvider),
            ),
        ],
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  final String label;
  final String amount;
  final bool isBold;
  final Color? color;

  const _ItemRow({
    required this.label,
    required this.amount,
    this.isBold = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: isBold ? 14 : 13,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        Text(
          amount,
          style: TextStyle(
            fontSize: isBold ? 15 : 13,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: color ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final BillStatus status;
  final DateTime? finalizedAt;

  const _StatusBadge({required this.status, this.finalizedAt});

  @override
  Widget build(BuildContext context) {
    final isFinalized = status == BillStatus.finalized;
    final color = isFinalized
        ? AppColors.success
        : status == BillStatus.amended
            ? AppColors.primary
            : AppColors.warning;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(50)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isFinalized ? Icons.lock : Icons.edit_note, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            status.name.toUpperCase(),
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }
}
