import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/customer.dart';
import '../../providers/customer_provider.dart';
import '../../providers/daily_entry_provider.dart';
import '../customers/add_edit_customer_dialog.dart';
import 'add_extra_items_dialog.dart';

class DailyEntryScreen extends StatefulWidget {
  const DailyEntryScreen({super.key});

  @override
  State<DailyEntryScreen> createState() => _DailyEntryScreenState();
}

class _DailyEntryScreenState extends State<DailyEntryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(BuildContext context, DailyEntryProvider provider) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: provider.selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      provider.setSelectedDate(picked);
    }
  }

  void _confirmClearDay(
      BuildContext context, DailyEntryProvider dailyProvider, List<Customer> customers) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear All Meals?'),
        content: Text(
          'This will unmark all breakfast and dinner records for all ${customers.length} customers on ${DateFormat('d MMMM y').format(dailyProvider.selectedDate)}.\n\nExtra item orders will not be removed.',
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
            onPressed: () {
              Navigator.of(ctx).pop();
              dailyProvider.clearDayMeals(customers);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('All meals cleared for selected day'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final customerProvider = context.watch<CustomerProvider>();
    final dailyProvider = context.watch<DailyEntryProvider>();

    final allActiveCustomers = customerProvider.activeCustomers;
    final filteredCustomers = allActiveCustomers.where((c) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return c.name.toLowerCase().contains(q) ||
          (c.phoneNumber != null && c.phoneNumber!.toLowerCase().contains(q));
    }).toList();

    final dateFormatted =
        DateFormat('EEE, d MMM y').format(dailyProvider.selectedDate);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Meal Entry'),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Bulk Actions',
            icon: const Icon(Icons.playlist_add_check),
            onSelected: (val) {
              if (allActiveCustomers.isEmpty) return;

              switch (val) {
                case 'mark_all_breakfast':
                  dailyProvider.bulkSetBreakfast(allActiveCustomers, true);
                  break;
                case 'unmark_all_breakfast':
                  dailyProvider.bulkSetBreakfast(allActiveCustomers, false);
                  break;
                case 'mark_all_dinner':
                  dailyProvider.bulkSetDinner(allActiveCustomers, true);
                  break;
                case 'unmark_all_dinner':
                  dailyProvider.bulkSetDinner(allActiveCustomers, false);
                  break;
                case 'clear_all':
                  _confirmClearDay(context, dailyProvider, allActiveCustomers);
                  break;
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'mark_all_breakfast',
                child: Row(
                  children: [
                    Icon(Icons.wb_sunny, color: AppColors.breakfast, size: 18),
                    SizedBox(width: 10),
                    Text('Mark All Breakfast'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'unmark_all_breakfast',
                child: Row(
                  children: [
                    Icon(Icons.wb_sunny_outlined, size: 18),
                    SizedBox(width: 10),
                    Text('Unmark All Breakfast'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'mark_all_dinner',
                child: Row(
                  children: [
                    Icon(Icons.nights_stay, color: AppColors.dinner, size: 18),
                    SizedBox(width: 10),
                    Text('Mark All Dinner'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'unmark_all_dinner',
                child: Row(
                  children: [
                    Icon(Icons.nights_stay_outlined, size: 18),
                    SizedBox(width: 10),
                    Text('Unmark All Dinner'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'clear_all',
                child: Row(
                  children: [
                    Icon(Icons.clear_all, color: AppColors.error, size: 18),
                    SizedBox(width: 10),
                    Text('Clear All Meals',
                        style: TextStyle(color: AppColors.error)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Date Navigation Bar ─────────────────────────────────────────
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
                  tooltip: 'Previous Day',
                  onPressed: dailyProvider.goToPreviousDay,
                ),
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => _pickDate(context, dailyProvider),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.calendar_month,
                              size: 18, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Text(
                            dailyProvider.isToday
                                ? 'Today ($dateFormatted)'
                                : dateFormatted,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (!dailyProvider.isToday)
                  TextButton(
                    onPressed: dailyProvider.goToToday,
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    child: const Text('Today'),
                  ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  tooltip: 'Next Day',
                  onPressed: dailyProvider.goToNextDay,
                ),
              ],
            ),
          ),

          // ── Summary Cards ───────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: AppColors.cardBackground,
            child: Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.wb_sunny,
                    iconColor: AppColors.breakfast,
                    label: 'Breakfast',
                    count: dailyProvider.totalBreakfastCount,
                    total: allActiveCustomers.length,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatCard(
                    icon: Icons.nights_stay,
                    iconColor: AppColors.dinner,
                    label: 'Dinner',
                    count: dailyProvider.totalDinnerCount,
                    total: allActiveCustomers.length,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatCard(
                    icon: Icons.egg_outlined,
                    iconColor: AppColors.accent,
                    label: 'Extras',
                    count: dailyProvider.totalExtraItemsCount,
                    total: null,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // ── Fast Filter / Search ────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Filter customers...',
                prefixIcon: const Icon(Icons.search, size: 20),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.divider),
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
              ),
              onChanged: (val) {
                setState(() => _searchQuery = val.trim());
              },
            ),
          ),

          // ── Customer Attendance List ────────────────────────────────────
          Expanded(
            child: allActiveCustomers.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.people_outline,
                              size: 64, color: AppColors.textHint),
                          const SizedBox(height: 16),
                          Text(
                            'No active customers',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Add customers to start recording daily breakfast and dinner.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () =>
                                AddEditCustomerDialog.show(context),
                            icon: const Icon(Icons.person_add),
                            label: const Text('Add Customer'),
                          ),
                        ],
                      ),
                    ),
                  )
                : filteredCustomers.isEmpty
                    ? Center(
                        child: Text(
                          'No customers match "$_searchQuery"',
                          style:
                              const TextStyle(color: AppColors.textSecondary),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 88),
                        itemCount: filteredCustomers.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final customer = filteredCustomers[index];
                          final mealEntry = dailyProvider
                              .getMealEntryForCustomer(customer.id);
                          final hadBreakfast =
                              mealEntry?.hadBreakfast ?? false;
                          final hadDinner = mealEntry?.hadDinner ?? false;
                          final extras = dailyProvider
                              .getExtrasForCustomer(customer.id);
                          final extraCount =
                              extras.fold(0, (sum, e) => sum + e.quantity);

                          return Card(
                            elevation: 1,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: const BorderSide(
                                  color: AppColors.divider),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                children: [
                                  // Customer Info Row
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 18,
                                        backgroundColor:
                                            AppColors.primary.withAlpha(25),
                                        child: Text(
                                          customer.name.isNotEmpty
                                              ? customer.name[0].toUpperCase()
                                              : '?',
                                          style: const TextStyle(
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              customer.name,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            if (customer.notes != null &&
                                                customer.notes!.isNotEmpty)
                                              Text(
                                                customer.notes!,
                                                style: const TextStyle(
                                                  color:
                                                      AppColors.textSecondary,
                                                  fontSize: 12,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                          ],
                                        ),
                                      ),
                                      // Extras Badge / Button
                                      InkWell(
                                        borderRadius:
                                            BorderRadius.circular(8),
                                        onTap: () {
                                          AddExtraItemsDialog.show(
                                            context,
                                            customer: customer,
                                          );
                                        },
                                        child: Container(
                                          padding:
                                              const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: extraCount > 0
                                                ? AppColors.accent.withAlpha(25)
                                                : AppColors.surface,
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            border: Border.all(
                                              color: extraCount > 0
                                                  ? AppColors.accent
                                                  : AppColors.divider,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.egg_outlined,
                                                size: 16,
                                                color: extraCount > 0
                                                    ? AppColors.accent
                                                    : AppColors.textSecondary,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                extraCount > 0
                                                    ? '+$extraCount Extra'
                                                    : '+ Extra',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: extraCount > 0
                                                      ? AppColors.accent
                                                      : AppColors.textSecondary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),

                                  // Quick Meal Toggle Buttons
                                  Row(
                                    children: [
                                      // Breakfast Button
                                      Expanded(
                                        child: _MealToggleButton(
                                          label: 'Breakfast',
                                          icon: Icons.wb_sunny,
                                          isActive: hadBreakfast,
                                          activeColor: AppColors.breakfast,
                                          onTap: () {
                                            dailyProvider.toggleBreakfast(
                                                customer.id);
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      // Dinner Button
                                      Expanded(
                                        child: _MealToggleButton(
                                          label: 'Dinner',
                                          icon: Icons.nights_stay,
                                          isActive: hadDinner,
                                          activeColor: AppColors.dinner,
                                          onTap: () {
                                            dailyProvider
                                                .toggleDinner(customer.id);
                                          },
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
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final int count;
  final int? total;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.count,
    this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: iconColor.withAlpha(15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: iconColor.withAlpha(40)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: iconColor),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: iconColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            total != null ? '$count / $total' : '$count items',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _MealToggleButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final Color activeColor;
  final VoidCallback onTap;

  const _MealToggleButton({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isActive ? activeColor : Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isActive ? activeColor : AppColors.divider,
          width: 1.5,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isActive ? Colors.white : AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isActive ? Colors.white : AppColors.textPrimary,
                ),
              ),
              if (isActive) ...[
                const SizedBox(width: 6),
                const Icon(Icons.check, size: 14, color: Colors.white),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
