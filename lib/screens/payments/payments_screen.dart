import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/money_utils.dart';
import '../../data/models/payment.dart';
import '../../providers/payment_provider.dart';
import '../ledger/customer_ledger_screen.dart';
import 'record_payment_dialog.dart';

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});

  static Route<void> route() {
    return MaterialPageRoute(builder: (_) => const PaymentsScreen());
  }

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _methodName(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return 'Cash';
      case PaymentMethod.esewa:
        return 'eSewa';
      case PaymentMethod.khalti:
        return 'Khalti';
      case PaymentMethod.bankTransfer:
        return 'Bank Transfer';
      case PaymentMethod.other:
        return 'Other';
    }
  }

  Color _methodColor(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return AppColors.success;
      case PaymentMethod.esewa:
        return Colors.green.shade700;
      case PaymentMethod.khalti:
        return Colors.purple;
      case PaymentMethod.bankTransfer:
        return AppColors.primary;
      case PaymentMethod.other:
        return Colors.blueGrey;
    }
  }

  void _confirmVoid(BuildContext context, PaymentWithCustomer item, PaymentProvider provider) {
    final customerName = item.customer?.name ?? 'Customer';
    final amountFormatted = MoneyUtils.formatNprFromPaisa(item.payment.amountPaisa);

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Void Payment?'),
        content: Text(
          'Are you sure you want to void this payment of $amountFormatted for $customerName?\n\n'
          'Voided payments are marked as invalid and do not count toward customer balances, but are kept in the database to maintain an audit trail.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await provider.voidPayment(item.payment.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Payment voided successfully'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Void Payment'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PaymentProvider>();
    final payments = provider.filteredPayments;
    final totalCollected = provider.totalCollectedPaisa;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payments & Collections'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reload',
            onPressed: provider.loadPayments,
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Collection Overview Card ────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.cardBackground,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'TOTAL COLLECTED',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.1,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          MoneyUtils.formatNprFromPaisa(totalCollected),
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${payments.length} Payments',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Payment Method Breakdown Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: PaymentMethod.values.map((method) {
                      final methodTotal = provider.getMethodTotalPaisa(method);
                      if (methodTotal <= 0 && provider.methodFilter != method) {
                        return const SizedBox.shrink();
                      }
                      final isSelected = provider.methodFilter == method;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(
                            '${_methodName(method)}: ${MoneyUtils.formatNprFromPaisa(methodTotal)}',
                            style: const TextStyle(fontSize: 11),
                          ),
                          selected: isSelected,
                          onSelected: (_) {
                            provider.setMethodFilter(isSelected ? null : method);
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // ── Search & Filter Bar ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by customer, ref #, or notes...',
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

          // ── Payments List ───────────────────────────────────────────────
          Expanded(
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : payments.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.payments_outlined, size: 64, color: AppColors.textHint),
                              const SizedBox(height: 16),
                              Text(
                                'No payments recorded',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Record student and customer meal collections to track outstanding balances accurately.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 88),
                        itemCount: payments.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final item = payments[index];
                          final p = item.payment;
                          final customer = item.customer;
                          final dateFormat = DateFormat('MMM d, y');
                          final methodColor = _methodColor(p.method);

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
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: methodColor.withAlpha(20),
                                    child: Icon(Icons.payments, color: methodColor, size: 20),
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
                                                customer?.name ?? 'Unknown Customer',
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
                                                color: methodColor.withAlpha(15),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                _methodName(p.method),
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: methodColor,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 3),
                                        Row(
                                          children: [
                                            Text(
                                              dateFormat.format(p.paymentDate),
                                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                            ),
                                            if (p.referenceNumber != null && p.referenceNumber!.isNotEmpty) ...[
                                              const SizedBox(width: 6),
                                              const Text('•', style: TextStyle(color: AppColors.textHint)),
                                              const SizedBox(width: 6),
                                              Expanded(
                                                child: Text(
                                                  'Ref: ${p.referenceNumber}',
                                                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        if (p.notes != null && p.notes!.isNotEmpty)
                                          Text(
                                            p.notes!,
                                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        MoneyUtils.formatNprFromPaisa(p.amountPaisa),
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.success,
                                        ),
                                      ),
                                    ],
                                  ),
                                  PopupMenuButton<String>(
                                    icon: const Icon(Icons.more_vert, size: 20, color: AppColors.textSecondary),
                                    onSelected: (action) {
                                      if (action == 'ledger' && customer != null) {
                                        Navigator.of(context).push(CustomerLedgerScreen.route(customer));
                                      } else if (action == 'void') {
                                        _confirmVoid(context, item, provider);
                                      }
                                    },
                                    itemBuilder: (ctx) => [
                                      if (customer != null)
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
                                      const PopupMenuItem(
                                        value: 'void',
                                        child: Row(
                                          children: [
                                            Icon(Icons.remove_circle_outline, size: 18, color: AppColors.error),
                                            SizedBox(width: 10),
                                            Text('Void Payment', style: TextStyle(color: AppColors.error)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => RecordPaymentDialog.show(context),
        icon: const Icon(Icons.add),
        label: const Text('Record Payment'),
      ),
    );
  }
}
