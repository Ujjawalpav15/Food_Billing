import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/customer_provider.dart';
import '../ledger/customer_ledger_screen.dart';
import '../payments/record_payment_dialog.dart';
import 'add_edit_customer_dialog.dart';

class CustomerDetailScreen extends StatelessWidget {
  final String customerId;

  const CustomerDetailScreen({super.key, required this.customerId});

  static Route<void> route(String customerId) {
    return MaterialPageRoute(
      builder: (_) => CustomerDetailScreen(customerId: customerId),
    );
  }

  void _confirmToggleStatus(BuildContext context, bool currentActive) {
    final provider = context.read<CustomerProvider>();
    final customer = provider.getCustomer(customerId);
    if (customer == null) return;

    final actionText = currentActive ? 'Deactivate' : 'Reactivate';

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('$actionText Customer?'),
        content: Text(
          currentActive
              ? 'Deactivating "${customer.name}" hides them from daily meal attendance, but strictly preserves all historical meal logs, payments, and statements.'
              : 'Reactivating "${customer.name}" will make them visible again for daily meal entry.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  currentActive ? AppColors.warning : AppColors.success,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              if (currentActive) {
                await provider.deactivateCustomer(customerId);
              } else {
                await provider.activateCustomer(customerId);
              }
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      currentActive
                          ? 'Customer deactivated'
                          : 'Customer reactivated',
                    ),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: Text(actionText),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    final provider = context.read<CustomerProvider>();
    final customer = provider.getCustomer(customerId);
    if (customer == null) return;

    final hasHistory = provider.hasHistory(customerId);

    if (hasHistory) {
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          icon: const Icon(Icons.shield_outlined,
              color: AppColors.primary, size: 40),
          title: const Text('Cannot Delete Customer'),
          content: Text(
            '"${customer.name}" has historical meal logs, payments, or billing statements recorded.\n\n'
            'To maintain reliable financial accounts and history integrity, customers with records cannot be deleted. You can deactivate them instead.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                if (customer.isActive) {
                  _confirmToggleStatus(context, true);
                }
              },
              child: const Text('Deactivate Instead'),
            ),
          ],
        ),
      );
      return;
    }

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Customer?'),
        content: Text(
          'Are you sure you want to permanently delete "${customer.name}"? '
          'This customer has no recorded meals or payments.',
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
              final success = await provider.deleteCustomer(customerId);
              if (context.mounted) {
                if (success) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Customer deleted'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        provider.errorMessage ?? 'Failed to delete customer',
                      ),
                      backgroundColor: AppColors.error,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CustomerProvider>();
    final customer = provider.getCustomer(customerId);

    if (customer == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Customer Details')),
        body: const Center(child: Text('Customer not found')),
      );
    }

    final dateFormat = DateFormat('d MMMM y');
    final initials = customer.name.trim().isNotEmpty
        ? customer.name
            .trim()
            .split(' ')
            .where((w) => w.isNotEmpty)
            .take(2)
            .map((w) => w[0].toUpperCase())
            .join()
        : '?';

    return Scaffold(
      appBar: AppBar(
        title: Text(customer.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit Customer',
            onPressed: () =>
                AddEditCustomerDialog.show(context, customer: customer),
          ),
          PopupMenuButton<String>(
            onSelected: (val) {
              if (val == 'toggle_status') {
                _confirmToggleStatus(context, customer.isActive);
              } else if (val == 'delete') {
                _confirmDelete(context);
              }
            },
            itemBuilder: (ctx) => [
              PopupMenuItem(
                value: 'toggle_status',
                child: Row(
                  children: [
                    Icon(
                      customer.isActive
                          ? Icons.person_off_outlined
                          : Icons.person_outline,
                      size: 20,
                      color: customer.isActive
                          ? AppColors.warning
                          : AppColors.success,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      customer.isActive
                          ? 'Deactivate Customer'
                          : 'Reactivate Customer',
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, size: 20, color: AppColors.error),
                    const SizedBox(width: 12),
                    Text('Delete Customer',
                        style: TextStyle(color: AppColors.error)),
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
          // ── Profile Card ──────────────────────────────────────────
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 34,
                        backgroundColor: customer.isActive
                            ? AppColors.primary
                            : AppColors.textHint,
                        child: Text(
                          initials,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              customer.name,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: customer.isActive
                                    ? AppColors.success.withAlpha(25)
                                    : AppColors.error.withAlpha(25),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    customer.isActive
                                        ? Icons.check_circle
                                        : Icons.cancel,
                                    size: 14,
                                    color: customer.isActive
                                        ? AppColors.success
                                        : AppColors.error,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    customer.isActive ? 'Active' : 'Inactive',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: customer.isActive
                                          ? AppColors.success
                                          : AppColors.error,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 32),
                  // Phone Row
                  _DetailRow(
                    icon: Icons.phone_outlined,
                    label: 'Phone',
                    value: customer.phoneNumber ?? 'Not provided',
                    trailing: customer.phoneNumber != null
                        ? IconButton(
                            icon: const Icon(Icons.copy, size: 18),
                            tooltip: 'Copy Phone',
                            onPressed: () {
                              Clipboard.setData(
                                ClipboardData(text: customer.phoneNumber!),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Phone number copied to clipboard'),
                                  duration: Duration(seconds: 2),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                          )
                        : null,
                  ),
                  const SizedBox(height: 12),
                  // Joined Date Row
                  _DetailRow(
                    icon: Icons.calendar_today_outlined,
                    label: 'Joined Date',
                    value: dateFormat.format(customer.createdAt),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Notes Card ────────────────────────────────────────────
          if (customer.notes != null && customer.notes!.trim().isNotEmpty) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.notes_outlined,
                            size: 20, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Notes / Details',
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      customer.notes!,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // ── Quick Actions ─────────────────────────────────────────
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quick Actions',
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(20),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.menu_book_outlined,
                          color: AppColors.primary),
                    ),
                    title: const Text('Customer Ledger & Statements'),
                    subtitle: const Text('View meal history, balance, bills'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.of(context).push(
                        CustomerLedgerScreen.route(customer),
                      );
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withAlpha(20),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.payments_outlined,
                          color: AppColors.accent),
                    ),
                    title: const Text('Record Payment'),
                    subtitle: const Text('Log partial, full, or advance cash'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      RecordPaymentDialog.show(context, customer: customer);
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Widget? trailing;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.textSecondary),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.textSecondary),
            ),
            Text(
              value,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        if (trailing != null) ...[
          const Spacer(),
          trailing!,
        ],
      ],
    );
  }
}
