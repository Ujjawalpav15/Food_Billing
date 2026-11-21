import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/money_utils.dart';
import '../../providers/customer_provider.dart';
import '../../providers/daily_entry_provider.dart';
import '../../providers/monthly_bill_provider.dart';
import '../../providers/payment_provider.dart';
import '../../providers/shop_profile_provider.dart';
import '../customers/add_edit_customer_dialog.dart';
import '../ledger/customer_ledger_screen.dart';
import '../menu/menu_screen.dart';
import '../payments/record_payment_dialog.dart';

class DashboardScreen extends StatelessWidget {
  final void Function(int tabIndex)? onNavigateToTab;

  const DashboardScreen({super.key, this.onNavigateToTab});

  @override
  Widget build(BuildContext context) {
    final shopProvider = context.watch<ShopProfileProvider>();
    final customerProvider = context.watch<CustomerProvider>();
    final dailyProvider = context.watch<DailyEntryProvider>();
    final billProvider = context.watch<MonthlyBillProvider>();
    final paymentProvider = context.watch<PaymentProvider>();

    final shop = shopProvider.shopProfile;
    final now = DateTime.now();
    final todayStr = DateFormat('EEEE, d MMMM y').format(now);

    final activeCustomers = customerProvider.activeCustomers;
    final totalActiveCount = activeCustomers.length;

    // Today's attendance
    final breakfasts = dailyProvider.totalBreakfastCount;
    final dinners = dailyProvider.totalDinnerCount;
    final extras = dailyProvider.totalExtraItemsCount;

    // Financial overview for current month
    final currentMonthCharges = billProvider.totalBilledChargesPaisa;
    final currentMonthCollected = billProvider.totalPaymentsReceivedPaisa;
    final totalOutstanding = billProvider.totalOutstandingDuePaisa;

    // Top customers with outstanding dues
    final customerDues = activeCustomers.map((c) {
      final due = paymentProvider.getCustomerBalancePaisa(c.id);
      return (customer: c, duePaisa: due);
    }).where((item) => item.duePaisa > 0).toList()
      ..sort((a, b) => b.duePaisa.compareTo(a.duePaisa));

    final topDebtors = customerDues.take(5).toList();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              shop?.shopName ?? 'Mess Billing Manager',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              todayStr,
              style: const TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_outlined),
            tooltip: 'Add Customer',
            onPressed: () => AddEditCustomerDialog.show(context),
          ),
          IconButton(
            icon: const Icon(Icons.payments_outlined),
            tooltip: 'Record Payment',
            onPressed: () => RecordPaymentDialog.show(context),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          dailyProvider.reload();
          billProvider.loadBills();
          paymentProvider.loadPayments();
          customerProvider.loadCustomers();
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Hero Financial Overview Card ──────────────────────────────
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary,
                      AppColors.primaryDark,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'TOTAL OUTSTANDING MARKET DUE',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.1,
                            color: Colors.white70,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(35),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$totalActiveCount Active Students',
                            style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      MoneyUtils.formatNprFromPaisa(totalOutstanding),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: Colors.white24, height: 1),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Month Billed', style: TextStyle(color: Colors.white70, fontSize: 11)),
                              const SizedBox(height: 2),
                              Text(
                                MoneyUtils.formatNprFromPaisa(currentMonthCharges),
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                            ],
                          ),
                        ),
                        Container(height: 28, width: 1, color: Colors.white24),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Collected', style: TextStyle(color: Colors.white70, fontSize: 11)),
                              const SizedBox(height: 2),
                              Text(
                                MoneyUtils.formatNprFromPaisa(currentMonthCollected),
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Today's Attendance Progress ───────────────────────────────
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withAlpha(20),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.edit_calendar, color: AppColors.primary, size: 20),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'Today’s Meal Attendance',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ],
                        ),
                        TextButton(
                          onPressed: () => onNavigateToTab?.call(1),
                          child: const Text('Open Daily Entry →'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _MealStatPill(
                            icon: Icons.wb_sunny,
                            color: AppColors.breakfast,
                            label: 'Breakfast',
                            count: breakfasts,
                            total: totalActiveCount,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _MealStatPill(
                            icon: Icons.nights_stay,
                            color: AppColors.dinner,
                            label: 'Dinner',
                            count: dinners,
                            total: totalActiveCount,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _MealStatPill(
                            icon: Icons.egg_outlined,
                            color: AppColors.accent,
                            label: 'Extras',
                            count: extras,
                            total: null,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Quick Actions ─────────────────────────────────────────────
            const Text(
              'QUICK ACTIONS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _QuickActionCard(
                    icon: Icons.edit_calendar,
                    color: AppColors.primary,
                    title: 'Daily Meals',
                    subtitle: 'Take attendance',
                    onTap: () => onNavigateToTab?.call(1),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _QuickActionCard(
                    icon: Icons.person_add_alt_1,
                    color: AppColors.dinner,
                    title: 'New Customer',
                    subtitle: 'Add member',
                    onTap: () => AddEditCustomerDialog.show(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _QuickActionCard(
                    icon: Icons.payments,
                    color: AppColors.success,
                    title: 'Record Pay',
                    subtitle: 'Log collections',
                    onTap: () => RecordPaymentDialog.show(context),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _QuickActionCard(
                    icon: Icons.restaurant_menu,
                    color: AppColors.breakfast,
                    title: 'Menu & Rates',
                    subtitle: 'Manage items',
                    onTap: () => Navigator.of(context).push(MenuScreen.route()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Top Pending Dues ──────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'TOP PENDING BALANCES',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (customerDues.isNotEmpty)
                  InkWell(
                    onTap: () => onNavigateToTab?.call(3), // Bills tab
                    child: const Text(
                      'View All Bills →',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),

            if (topDebtors.isEmpty)
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.success.withAlpha(20),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check_circle_outline, color: AppColors.success, size: 24),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Text(
                          'All customer accounts are fully settled! No pending dues.',
                          style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: topDebtors.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = topDebtors[index];
                    final customer = item.customer;
                    final due = item.duePaisa;

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      leading: CircleAvatar(
                        backgroundColor: AppColors.primary.withAlpha(20),
                        child: Text(
                          customer.name.isNotEmpty ? customer.name[0].toUpperCase() : '?',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                      ),
                      title: Text(customer.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      subtitle: Text(
                        customer.phoneNumber ?? 'No contact',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            MoneyUtils.formatNprFromPaisa(due),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: AppColors.error,
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.payment, size: 20, color: AppColors.success),
                            tooltip: 'Pay',
                            onPressed: () {
                              RecordPaymentDialog.show(context, customer: customer);
                            },
                          ),
                        ],
                      ),
                      onTap: () {
                        Navigator.of(context).push(CustomerLedgerScreen.route(customer));
                      },
                    );
                  },
                ),
              ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _MealStatPill extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final int count;
  final int? total;

  const _MealStatPill({
    required this.icon,
    required this.color,
    required this.label,
    required this.count,
    this.total,
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
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
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

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.divider),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
