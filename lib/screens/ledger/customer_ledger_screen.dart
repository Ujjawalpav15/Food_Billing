import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/money_utils.dart';
import '../../data/models/customer.dart';
import '../../data/repositories/additional_item_entry_repository.dart';
import '../../data/repositories/adjustment_repository.dart';
import '../../data/repositories/meal_entry_repository.dart';
import '../../data/repositories/payment_repository.dart';
import '../../providers/customer_ledger_provider.dart';
import '../../providers/shop_profile_provider.dart';
import '../../services/csv_export_service.dart';
import '../../services/pdf_service.dart';
import '../billing/pdf_preview_screen.dart';

class CustomerLedgerScreen extends StatelessWidget {
  final Customer customer;

  const CustomerLedgerScreen({super.key, required this.customer});

  static Route<void> route(Customer customer) {
    return MaterialPageRoute(
      builder: (_) => CustomerLedgerScreen(customer: customer),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CustomerLedgerProvider(
        customerId: customer.id,
        mealRepo: MealEntryRepository(),
        extraRepo: AdditionalItemEntryRepository(),
        adjustmentRepo: AdjustmentRepository(),
        paymentRepo: PaymentRepository(),
      ),
      child: _CustomerLedgerView(customer: customer),
    );
  }
}

class _CustomerLedgerView extends StatelessWidget {
  final Customer customer;

  const _CustomerLedgerView({required this.customer});

  void _showFilterDialog(BuildContext context, CustomerLedgerProvider provider) {
    final now = DateTime.now();

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              'Filter Ledger Period',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.all_inclusive, color: AppColors.primary),
              title: const Text('All Time'),
              onTap: () {
                provider.clearFilter();
                Navigator.of(ctx).pop();
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today, color: AppColors.primary),
              title: Text('This Month (${DateFormat('MMMM y').format(now)})'),
              onTap: () {
                provider.filterByMonth(now.year, now.month);
                Navigator.of(ctx).pop();
              },
            ),
            ListTile(
              leading: const Icon(Icons.history, color: AppColors.primary),
              title: Text(
                'Last Month (${DateFormat('MMMM y').format(DateTime(now.year, now.month - 1))})',
              ),
              onTap: () {
                final lastMonth = DateTime(now.year, now.month - 1);
                provider.filterByMonth(lastMonth.year, lastMonth.month);
                Navigator.of(ctx).pop();
              },
            ),
            ListTile(
              leading: const Icon(Icons.date_range, color: AppColors.primary),
              title: const Text('Custom Date Range...'),
              onTap: () async {
                Navigator.of(ctx).pop();
                final pickedRange = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                  initialDateRange: provider.startDate != null && provider.endDate != null
                      ? DateTimeRange(start: provider.startDate!, end: provider.endDate!)
                      : DateTimeRange(
                          start: DateTime(now.year, now.month, 1),
                          end: now,
                        ),
                );
                if (pickedRange != null) {
                  provider.filterByDateRange(pickedRange.start, pickedRange.end);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _openPdfPreview(
    BuildContext context,
    CustomerLedgerProvider provider,
    String periodTitle,
  ) {
    final shop = context.read<ShopProfileProvider?>()?.shopProfile;
    final items = provider.filteredItems;
    final balancePaisa = provider.totalOutstandingBalancePaisa;
    final fileName = 'Ledger_${customer.name.replaceAll(' ', '_')}.pdf';

    Navigator.of(context).push(
      PdfPreviewScreen.route(
        title: 'Ledger: ${customer.name}',
        fileName: fileName,
        pdfDataBuilder: () => const PdfService().generateCustomerLedgerPdf(
          shop: shop,
          customer: customer,
          items: items,
          currentBalancePaisa: balancePaisa,
          periodDescription: periodTitle,
        ),
      ),
    );
  }

  Future<void> _sharePdf(
    BuildContext context,
    CustomerLedgerProvider provider,
    String periodTitle,
  ) async {
    final shop = context.read<ShopProfileProvider?>()?.shopProfile;
    final items = provider.filteredItems;
    final balancePaisa = provider.totalOutstandingBalancePaisa;
    final fileName = 'Ledger_${customer.name.replaceAll(' ', '_')}.pdf';

    try {
      final bytes = await const PdfService().generateCustomerLedgerPdf(
        shop: shop,
        customer: customer,
        items: items,
        currentBalancePaisa: balancePaisa,
        periodDescription: periodTitle,
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
    CustomerLedgerProvider provider,
  ) async {
    final items = provider.filteredItems;
    final balancePaisa = provider.totalOutstandingBalancePaisa;
    final fileName = 'Ledger_${customer.name.replaceAll(' ', '_')}.csv';

    try {
      final csv = const CsvExportService().generateCustomerLedgerCsv(
        customer: customer,
        items: items,
        closingBalancePaisa: balancePaisa,
      );
      await const CsvExportService().shareCsv(
        csvContent: csv,
        fileName: fileName,
        subject: 'Customer Ledger - ${customer.name}',
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
    final provider = context.watch<CustomerLedgerProvider>();
    final items = provider.filteredItems;
    final balancePaisa = provider.totalOutstandingBalancePaisa;

    String periodTitle = 'All Time';
    if (provider.filterYear != null && provider.filterMonth != null) {
      periodTitle = DateFormat('MMMM y').format(
        DateTime(provider.filterYear!, provider.filterMonth!),
      );
    } else if (provider.startDate != null && provider.endDate != null) {
      periodTitle =
          '${DateFormat('d MMM').format(provider.startDate!)} – ${DateFormat('d MMM y').format(provider.endDate!)}';
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('${customer.name}’s Ledger'),
        actions: [
          IconButton(
            icon: const Icon(Icons.print_outlined),
            tooltip: 'Preview / Print PDF',
            onPressed: () => _openPdfPreview(context, provider, periodTitle),
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Share PDF',
            onPressed: () => _sharePdf(context, provider, periodTitle),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            tooltip: 'More actions',
            onSelected: (val) {
              if (val == 'csv') {
                _exportCsv(context, provider);
              } else if (val == 'filter') {
                _showFilterDialog(context, provider);
              } else if (val == 'reload') {
                provider.loadLedger();
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
                value: 'filter',
                child: Row(
                  children: [
                    Icon(Icons.filter_list, size: 20),
                    SizedBox(width: 8),
                    Text('Filter Period'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'reload',
                child: Row(
                  children: [
                    Icon(Icons.refresh, size: 20),
                    SizedBox(width: 8),
                    Text('Reload'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // ── Summary Card ───────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(16),
                  color: AppColors.cardBackground,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withAlpha(20),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_month,
                                    size: 14, color: AppColors.primary),
                                const SizedBox(width: 6),
                                Text(
                                  periodTitle,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          if (provider.isFiltered)
                            TextButton.icon(
                              style: TextButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.symmetric(horizontal: 6),
                              ),
                              icon: const Icon(Icons.clear, size: 14),
                              label: const Text('Reset'),
                              onPressed: provider.clearFilter,
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  balancePaisa > 0
                                      ? 'OUTSTANDING DUE'
                                      : balancePaisa < 0
                                          ? 'CUSTOMER STORE CREDIT'
                                          : 'ACCOUNT SETTLED',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.1,
                                    color: balancePaisa > 0
                                        ? AppColors.error
                                        : balancePaisa < 0
                                            ? AppColors.primary
                                            : AppColors.success,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  MoneyUtils.formatNprFromPaisa(balancePaisa.abs()),
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: balancePaisa > 0
                                        ? AppColors.error
                                        : balancePaisa < 0
                                            ? AppColors.primary
                                            : AppColors.success,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Row(
                                children: [
                                  const Text('Charges: ',
                                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                  Text(
                                    MoneyUtils.formatNprFromPaisa(provider.filteredChargesPaisa),
                                    style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Text('Paid: ',
                                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                  Text(
                                    MoneyUtils.formatNprFromPaisa(provider.filteredPaymentsPaisa),
                                    style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.success),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Stats chips row
                      Row(
                        children: [
                          _MiniChip(
                            icon: Icons.wb_sunny,
                            color: AppColors.breakfast,
                            label: '${provider.filteredBreakfastCount} Breakfast',
                          ),
                          const SizedBox(width: 8),
                          _MiniChip(
                            icon: Icons.nights_stay,
                            color: AppColors.dinner,
                            label: '${provider.filteredDinnerCount} Dinner',
                          ),
                          const SizedBox(width: 8),
                          _MiniChip(
                            icon: Icons.egg_outlined,
                            color: AppColors.accent,
                            label: '${provider.filteredExtrasCount} Extras',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),

                // ── Chronological Transactions List ────────────────────────
                Expanded(
                  child: items.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.receipt_long_outlined,
                                    size: 64, color: AppColors.textHint),
                                const SizedBox(height: 16),
                                Text(
                                  'No transactions recorded',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  provider.isFiltered
                                      ? 'No meals, extra items, or payments in $periodTitle.'
                                      : 'When daily meals, orders, or payments are entered, they will show chronologically here.',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                          itemCount: items.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final item = items[index];
                            return _LedgerCard(item: item);
                          },
                        ),
                ),
              ],
            ),
    );
  }
}

class _LedgerCard extends StatelessWidget {
  final LedgerItem item;

  const _LedgerCard({required this.item});

  IconData _iconForType(LedgerItemType type) {
    switch (type) {
      case LedgerItemType.meal:
        return Icons.restaurant;
      case LedgerItemType.additionalItem:
        return Icons.egg_outlined;
      case LedgerItemType.adjustment:
        return Icons.tune;
      case LedgerItemType.payment:
        return Icons.payments;
    }
  }

  Color _colorForType(LedgerItemType type) {
    switch (type) {
      case LedgerItemType.meal:
        return AppColors.dinner;
      case LedgerItemType.additionalItem:
        return AppColors.breakfast;
      case LedgerItemType.adjustment:
        return AppColors.warning;
      case LedgerItemType.payment:
        return AppColors.success;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, y');
    final color = _colorForType(item.type);

    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.divider),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Date + Icon Container
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withAlpha(20),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(_iconForType(item.type), color: color, size: 22),
            ),
            const SizedBox(width: 12),
            // Middle Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        dateFormat.format(item.date),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: color.withAlpha(15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          item.type.name.toUpperCase(),
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  if (item.subtitle.isNotEmpty)
                    Text(
                      item.subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
            // Right Amount + Running Balance
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  item.amountPaisa > 0
                      ? '+${MoneyUtils.formatNprFromPaisa(item.amountPaisa)}'
                      : '-${MoneyUtils.formatNprFromPaisa(-item.amountPaisa)}',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: item.amountPaisa > 0 ? AppColors.textPrimary : AppColors.success,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Bal: ${MoneyUtils.formatNprFromPaisa(item.runningBalancePaisa)}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;

  const _MiniChip({
    required this.icon,
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
