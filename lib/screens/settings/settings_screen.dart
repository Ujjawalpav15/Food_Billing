import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/money_utils.dart';
import '../../providers/customer_provider.dart';
import '../../providers/daily_entry_provider.dart';
import '../../providers/menu_item_provider.dart';
import '../../providers/monthly_bill_provider.dart';
import '../../providers/payment_provider.dart';
import '../../providers/shop_profile_provider.dart';
import '../../services/backup_service.dart';
import '../menu/menu_screen.dart';
import '../payments/payments_screen.dart';
import 'edit_shop_profile_screen.dart';

/// Settings screen — shows shop info and links to editing sub-screens.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ShopProfileProvider>();
    final profile = provider.shopProfile;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: [
          // ── Shop Profile Card ─────────────────────────────────────────
          _SectionHeader(label: 'Shop Profile'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Logo + name row
                  Row(
                    children: [
                      _LogoAvatar(logoPath: profile?.logoPath),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              profile?.shopName ?? '—',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              profile?.ownerName ?? '—',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => _openEdit(context),
                        icon: const Icon(Icons.edit_outlined),
                        tooltip: 'Edit Profile',
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  // Detail rows
                  _ProfileRow(
                    icon: Icons.phone_outlined,
                    label: 'Phone',
                    value: (profile?.phoneNumber.isEmpty ?? true)
                        ? '—'
                        : profile!.phoneNumber,
                  ),
                  const SizedBox(height: 10),
                  _ProfileRow(
                    icon: Icons.location_on_outlined,
                    label: 'Address',
                    value: (profile?.address.isEmpty ?? true)
                        ? '—'
                        : profile!.address,
                  ),
                ],
              ),
            ),
          ),

          // ── Default Meal Prices ───────────────────────────────────────
          _SectionHeader(label: 'Default Meal Prices'),
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  _PriceRow(
                    icon: Icons.wb_sunny_outlined,
                    iconColor: AppColors.breakfast,
                    label: 'Breakfast',
                    pricePaisa:
                        profile?.defaultBreakfastPricePaisa ?? 0,
                    onEdit: () => _openEdit(context),
                  ),
                  const Divider(height: 1),
                  _PriceRow(
                    icon: Icons.nights_stay_outlined,
                    iconColor: AppColors.dinner,
                    label: 'Dinner',
                    pricePaisa:
                        profile?.defaultDinnerPricePaisa ?? 0,
                    onEdit: () => _openEdit(context),
                  ),
                ],
              ),
            ),
          ),

          // ── Menu & Additional Items ───────────────────────────────────
          _SectionHeader(label: 'Menu & Additional Items'),
          Card(
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.restaurant_menu,
                    color: AppColors.primary),
              ),
              title: const Text('Manage Menu Items & Prices'),
              subtitle:
                  const Text('Extra items like eggs, curd, tea, milk & snacks'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).push(MenuScreen.route());
              },
            ),
          ),

          // ── Payments & Transactions ───────────────────────────────────
          _SectionHeader(label: 'Transactions'),
          Card(
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.success.withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.payments_outlined,
                    color: AppColors.success),
              ),
              title: const Text('Payments & Collections History'),
              subtitle:
                  const Text('View all cash and digital payments received'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).push(PaymentsScreen.route());
              },
            ),
          ),

          // ── Data Backup & Restore ─────────────────────────────────────
          _SectionHeader(label: 'Data & Backup'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(20),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.backup_outlined,
                        color: AppColors.primary),
                  ),
                  title: const Text('Backup Database'),
                  subtitle: const Text(
                      'Export all shop records, meals, and bills to a JSON file'),
                  trailing: const Icon(Icons.share_outlined, size: 20),
                  onTap: () => _handleBackup(context),
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withAlpha(20),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.settings_backup_restore_outlined,
                        color: AppColors.warning),
                  ),
                  title: const Text('Restore Database'),
                  subtitle: const Text(
                      'Import data from a previous backup file (overwrites current records)'),
                  trailing: const Icon(Icons.file_open_outlined, size: 20),
                  onTap: () => _handleRestore(context),
                ),
              ],
            ),
          ),

          // ── App Info ──────────────────────────────────────────────────
          _SectionHeader(label: 'App'),
          Card(
            child: Column(
              children: [
                _InfoTile(
                  icon: Icons.info_outline,
                  label: 'Version',
                  trailing: '1.0.0',
                ),
                const Divider(height: 1, indent: 56),
                _InfoTile(
                  icon: Icons.currency_rupee,
                  label: 'Currency',
                  trailing: profile?.currencyCode ?? 'NPR',
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _openEdit(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const EditShopProfileScreen(),
      ),
    );
  }

  Future<void> _handleBackup(BuildContext context) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preparing database backup...'),
          duration: Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
      await const BackupService().shareBackup();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Backup failed: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _handleRestore(BuildContext context) async {
    try {
      final jsonContent = await const BackupService().pickBackupFileContent();
      if (jsonContent == null) return; // user cancelled

      final validation = const BackupService().validateBackup(jsonContent);
      if (!validation.isValid) {
        if (context.mounted) {
          showDialog<void>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.error_outline, color: AppColors.error),
                  SizedBox(width: 8),
                  Text('Invalid Backup File'),
                ],
              ),
              content: Text(validation.errorMessage ?? 'The selected file is not a valid backup.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
        return;
      }

      final meta = validation.metadata!;

      // Confirm with owner before replacing database
      if (!context.mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppColors.error),
              SizedBox(width: 8),
              Text('Restore Database?'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'This will REPLACE all current data in the application with records from the selected backup file.',
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Shop: ${meta.shopName ?? 'Mess Billing'}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text('Backup Date: ${DateFormat('dd MMM yyyy, HH:mm').format(meta.exportedAt)}'),
                    Text('Customers: ${meta.customerCount}'),
                    Text('Menu Items: ${meta.menuItemCount}'),
                    Text('Meal Attendance: ${meta.mealEntryCount}'),
                    Text('Payments: ${meta.paymentCount}'),
                    Text('Monthly Bills: ${meta.monthlyBillCount}'),
                    const Divider(height: 12),
                    Text(
                      'Total Records: ${meta.totalRecords}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Are you sure you want to proceed? Any current data not included in this backup will be permanently lost.',
                style: TextStyle(
                  color: AppColors.error,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Restore & Replace'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      // Perform restore
      await const BackupService().restoreFromJson(jsonContent);

      // Reload all providers to update UI immediately
      if (context.mounted) {
        context.read<ShopProfileProvider>().reload();
        context.read<CustomerProvider>().loadCustomers();
        context.read<MenuItemProvider>().loadMenuItems();
        context.read<DailyEntryProvider>().reload();
        context.read<MonthlyBillProvider>().loadBills();
        context.read<PaymentProvider>().loadPayments();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Database restored successfully (${meta.totalRecords} records).'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to restore database: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

// ── Section Header ─────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 6),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
            ),
      ),
    );
  }
}

// ── Logo Avatar ─────────────────────────────────────────────────────────────

class _LogoAvatar extends StatelessWidget {
  final String? logoPath;
  const _LogoAvatar({this.logoPath});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: AppColors.primary.withAlpha(20),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      clipBehavior: Clip.antiAlias,
      child: logoPath != null && logoPath!.isNotEmpty
          ? Image.file(File(logoPath!), fit: BoxFit.cover)
          : const Icon(Icons.store, size: 36, color: AppColors.primary),
    );
  }
}

// ── Profile Row ─────────────────────────────────────────────────────────────

class _ProfileRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ProfileRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 10),
        Text(
          '$label: ',
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: AppColors.textSecondary),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ── Price Row ───────────────────────────────────────────────────────────────

class _PriceRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final int pricePaisa;
  final VoidCallback onEdit;

  const _PriceRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.pricePaisa,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Text(label,
                style: Theme.of(context).textTheme.bodyLarge),
          ),
          Text(
            MoneyUtils.formatNprFromPaisa(pricePaisa),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onEdit,
            child: const Icon(Icons.edit_outlined,
                size: 18, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

// ── Info Tile ───────────────────────────────────────────────────────────────

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String trailing;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textSecondary, size: 22),
      title: Text(label, style: Theme.of(context).textTheme.bodyLarge),
      trailing: Text(
        trailing,
        style: Theme.of(context)
            .textTheme
            .bodyMedium
            ?.copyWith(color: AppColors.textSecondary),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
    );
  }
}
