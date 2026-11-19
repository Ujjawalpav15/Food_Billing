import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/money_utils.dart';
import '../../providers/shop_profile_provider.dart';
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
