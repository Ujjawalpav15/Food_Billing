import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/money_utils.dart';
import '../../data/models/monthly_bill.dart';
import '../../providers/monthly_bill_provider.dart';
import '../../services/csv_export_service.dart';
import '../ledger/customer_ledger_screen.dart';
import 'monthly_statement_screen.dart';

class BillingScreen extends StatefulWidget {
  const BillingScreen({super.key});

  @override
  State<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _confirmFinalizeAll(BuildContext context, MonthlyBillProvider provider) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Generate All Statements?'),
        content: const Text(
          'This will generate and save current monthly statements for all active customers with recorded attendance or balances.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await provider.generateAllBills();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Monthly statements generated for all customers'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Generate All'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportAllCsv(BuildContext context, MonthlyBillProvider provider) async {
    final summaries = provider.allSummaries;
    if (summaries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No customer monthly bills to export for this month.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    try {
      final csvContent = const CsvExportService().generateMonthlyBillsCsv(
        summaries: summaries,
        year: provider.selectedYear,
        month: provider.selectedMonth,
      );
      final fileName = 'All_Bills_${provider.selectedYear}_${provider.selectedMonth}.csv';
      await const CsvExportService().shareCsv(
        csvContent: csvContent,
        fileName: fileName,
        subject: 'Monthly Bills Summary - ${provider.selectedYear}/${provider.selectedMonth}',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to export CSV: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MonthlyBillProvider>();
    final summaries = provider.filteredSummaries;

    final monthDate = DateTime(provider.selectedYear, provider.selectedMonth);
    final monthStr = DateFormat('MMMM y').format(monthDate);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Monthly Billing'),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            tooltip: 'Export CSV',
            onPressed: () => _exportAllCsv(context, provider),
          ),
          IconButton(
            icon: const Icon(Icons.playlist_add_check),
            tooltip: 'Generate All Bills',
            onPressed: () => _confirmFinalizeAll(context, provider),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reload',
            onPressed: provider.loadBills,
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Month Selector Bar ──────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(bottom: BorderSide(color: AppColors.divider)),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  tooltip: 'Previous Month',
                  onPressed: provider.goToPreviousMonth,
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      monthStr,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  tooltip: 'Next Month',
                  onPressed: provider.goToNextMonth,
                ),
              ],
            ),
          ),

          // ── Shop-Wide Summary Card ──────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.cardBackground,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _SummaryBox(
                        title: 'CHARGES',
                        amount: MoneyUtils.formatNprFromPaisa(provider.totalBilledChargesPaisa),
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _SummaryBox(
                        title: 'COLLECTED',
                        amount: MoneyUtils.formatNprFromPaisa(provider.totalPaymentsReceivedPaisa),
                        color: AppColors.success,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _SummaryBox(
                        title: 'OUTSTANDING',
                        amount: MoneyUtils.formatNprFromPaisa(provider.totalOutstandingDuePaisa),
                        color: provider.totalOutstandingDuePaisa > 0 ? AppColors.error : AppColors.success,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${provider.finalizedCount} Finalized • ${provider.draftCount} Draft',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      ),
                      icon: const Icon(Icons.auto_stories, size: 14),
                      label: const Text('Save / Update All', style: TextStyle(fontSize: 12)),
                      onPressed: () => _confirmFinalizeAll(context, provider),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // ── Filter & Search Bar ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search customer...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.divider),
                      ),
                      suffixIcon: provider.searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                provider.setSearchQuery('');
                              },
                            )
                          : null,
                    ),
                    onChanged: provider.setSearchQuery,
                  ),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<BillStatus?>(
                  icon: const Icon(Icons.filter_list),
                  tooltip: 'Filter Status',
                  onSelected: provider.setStatusFilter,
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(
                      value: null,
                      child: Text('All Statuses'),
                    ),
                    const PopupMenuItem(
                      value: BillStatus.finalized,
                      child: Text('Finalized Only'),
                    ),
                    const PopupMenuItem(
                      value: BillStatus.draft,
                      child: Text('Draft Only'),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Customer Statements List ────────────────────────────────────
          Expanded(
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : summaries.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.receipt_long_outlined, size: 64, color: AppColors.textHint),
                              const SizedBox(height: 16),
                              Text(
                                'No bills found for $monthStr',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Tap "Save / Update All" or record daily meals to generate monthly bills.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 88),
                        itemCount: summaries.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final summary = summaries[index];
                          final customer = summary.customer;
                          final bill = summary.bill;
                          final isFinalized = bill.status == BillStatus.finalized;

                          return Card(
                            elevation: 0.5,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: const BorderSide(color: AppColors.divider),
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () {
                                Navigator.of(context).push(
                                  MonthlyStatementScreen.route(
                                    customer: customer,
                                    bill: bill,
                                  ),
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundColor: AppColors.primary.withAlpha(20),
                                      child: Text(
                                        customer.name.isNotEmpty ? customer.name[0].toUpperCase() : '?',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  customer.name,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 15,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: isFinalized
                                                      ? AppColors.success.withAlpha(15)
                                                      : AppColors.warning.withAlpha(15),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  bill.status.name.toUpperCase(),
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                    color: isFinalized ? AppColors.success : AppColors.warning,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${bill.breakfastCount} B • ${bill.dinnerCount} D • ${MoneyUtils.formatNprFromPaisa(bill.additionalItemsTotalPaisa)} extras',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          MoneyUtils.formatNprFromPaisa(bill.outstandingBalancePaisa),
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: bill.outstandingBalancePaisa > 0
                                                ? AppColors.error
                                                : AppColors.success,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Charges: ${MoneyUtils.formatNprFromPaisa(bill.totalChargesPaisa)}',
                                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                        ),
                                      ],
                                    ),
                                    PopupMenuButton<String>(
                                      icon: const Icon(Icons.more_vert, size: 20, color: AppColors.textSecondary),
                                      onSelected: (action) {
                                        if (action == 'view') {
                                          Navigator.of(context).push(
                                            MonthlyStatementScreen.route(customer: customer, bill: bill),
                                          );
                                        } else if (action == 'ledger') {
                                          Navigator.of(context).push(
                                            CustomerLedgerScreen.route(customer),
                                          );
                                        } else if (action == 'finalize') {
                                          provider.finalizeBill(bill);
                                        } else if (action == 'reopen') {
                                          provider.reopenBill(bill);
                                        }
                                      },
                                      itemBuilder: (ctx) => [
                                        const PopupMenuItem(
                                          value: 'view',
                                          child: Row(
                                            children: [
                                              Icon(Icons.visibility_outlined, size: 18),
                                              SizedBox(width: 10),
                                              Text('View Statement'),
                                            ],
                                          ),
                                        ),
                                        const PopupMenuItem(
                                          value: 'ledger',
                                          child: Row(
                                            children: [
                                              Icon(Icons.menu_book_outlined, size: 18, color: AppColors.primary),
                                              SizedBox(width: 10),
                                              Text('View Ledger'),
                                            ],
                                          ),
                                        ),
                                        PopupMenuItem(
                                          value: isFinalized ? 'reopen' : 'finalize',
                                          child: Row(
                                            children: [
                                              Icon(
                                                isFinalized ? Icons.lock_open : Icons.check_circle_outline,
                                                size: 18,
                                                color: isFinalized ? AppColors.warning : AppColors.success,
                                              ),
                                              const SizedBox(width: 10),
                                              Text(isFinalized ? 'Reopen Bill' : 'Finalize Bill'),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _SummaryBox extends StatelessWidget {
  final String title;
  final String amount;
  final Color color;

  const _SummaryBox({
    required this.title,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withAlpha(40)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: color,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            amount,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
