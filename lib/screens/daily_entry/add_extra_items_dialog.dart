import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/money_utils.dart';
import '../../data/models/customer.dart';
import '../../providers/daily_entry_provider.dart';
import '../../providers/menu_item_provider.dart';

class AddExtraItemsDialog extends StatelessWidget {
  final Customer customer;

  const AddExtraItemsDialog({super.key, required this.customer});

  static Future<void> show(BuildContext context, {required Customer customer}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddExtraItemsDialog(customer: customer),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dailyProvider = context.watch<DailyEntryProvider>();
    final menuProvider = context.watch<MenuItemProvider>();
    final dateStr = DateFormat('EEE, d MMM y').format(dailyProvider.selectedDate);
    final extras = dailyProvider.getExtrasForCustomer(customer.id);
    final activeMenuItems = menuProvider.activeItems;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomInset),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
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

          // Header
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.primary.withAlpha(25),
                radius: 20,
                child: const Icon(Icons.egg_outlined,
                    color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Extra Items — ${customer.name}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      dateStr,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
                tooltip: 'Close',
              ),
            ],
          ),
          const Divider(height: 24),

          // Expanded Content
          Expanded(
            child: ListView(
              children: [
                // ── Section 1: Today's Recorded Extras ──────────────────────
                Row(
                  children: [
                    Text(
                      'RECORDED ORDERS',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.1,
                          ),
                    ),
                    const Spacer(),
                    if (extras.isNotEmpty)
                      Text(
                        'Total: ${MoneyUtils.formatNprFromPaisa(extras.fold(0, (sum, e) => sum + e.totalPaisa))}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),

                if (extras.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: const Center(
                      child: Text(
                        'No extra items recorded for this date yet.\nTap an item below to add.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  )
                else
                  ...extras.map((entry) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: const BorderSide(color: AppColors.divider),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    entry.menuItemName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                    ),
                                  ),
                                  Text(
                                    '${MoneyUtils.formatNprFromPaisa(entry.unitPricePaisa)} each',
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Stepper (- [qty] +)
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline,
                                  size: 22),
                              color: AppColors.textSecondary,
                              onPressed: () {
                                dailyProvider.setExtraItemQuantity(
                                  customer.id,
                                  entry.id,
                                  entry.quantity - 1,
                                );
                              },
                            ),
                            Text(
                              '${entry.quantity}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline,
                                  size: 22),
                              color: AppColors.primary,
                              onPressed: () {
                                dailyProvider.setExtraItemQuantity(
                                  customer.id,
                                  entry.id,
                                  entry.quantity + 1,
                                );
                              },
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 65,
                              child: Text(
                                MoneyUtils.formatNprFromPaisa(entry.totalPaisa),
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  color: AppColors.error, size: 20),
                              tooltip: 'Remove',
                              onPressed: () {
                                dailyProvider.deleteExtraItem(
                                  customer.id,
                                  entry.id,
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  }),

                const SizedBox(height: 20),

                // ── Section 2: Available Menu Items ────────────────────────
                Text(
                  'AVAILABLE MENU ITEMS',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                      ),
                ),
                const SizedBox(height: 8),

                if (activeMenuItems.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(
                      child: Text(
                        'No menu items available.\nAdd items in Menu Management first.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  )
                else
                  ...activeMenuItems.map((item) {
                    return ListTile(
                      dense: true,
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      leading: CircleAvatar(
                        radius: 16,
                        backgroundColor: AppColors.primary.withAlpha(20),
                        child: Text(
                          item.name.isNotEmpty ? item.name[0] : '?',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      title: Text(item.name,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(
                        '${MoneyUtils.formatNprFromPaisa(item.pricePaisa)} / ${item.unit}',
                      ),
                      trailing: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          visualDensity: VisualDensity.compact,
                        ),
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Add'),
                        onPressed: () {
                          dailyProvider.addExtraItem(
                            customerId: customer.id,
                            item: item,
                            quantity: 1,
                          );
                        },
                      ),
                    );
                  }),
              ],
            ),
          ),

          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}
