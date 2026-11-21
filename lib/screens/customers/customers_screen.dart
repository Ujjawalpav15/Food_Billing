import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/customer.dart';
import '../../providers/customer_provider.dart';
import '../ledger/customer_ledger_screen.dart';
import 'add_edit_customer_dialog.dart';
import 'customer_detail_screen.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearchExpanded = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _openAddCustomer() {
    AddEditCustomerDialog.show(context);
  }

  void _confirmToggleStatus(
      BuildContext context, Customer customer, CustomerProvider provider) {
    final actionText = customer.isActive ? 'Deactivate' : 'Reactivate';

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('$actionText Customer?'),
        content: Text(
          customer.isActive
              ? 'Deactivating "${customer.name}" hides them from daily meal recording, but keeps all past meal logs and billing statements safe.'
              : 'Reactivating "${customer.name}" will make them active again for daily meal entries.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  customer.isActive ? AppColors.warning : AppColors.success,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              if (customer.isActive) {
                await provider.deactivateCustomer(customer.id);
              } else {
                await provider.activateCustomer(customer.id);
              }
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      customer.isActive
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

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CustomerProvider>();
    final activeCount = provider.totalActiveCount;
    final inactiveCount = provider.totalInactiveCount;

    return Scaffold(
      appBar: AppBar(
        title: _isSearchExpanded
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                cursorColor: Colors.white,
                decoration: InputDecoration(
                  hintText: 'Search by name or phone...',
                  hintStyle: const TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear, color: Colors.white),
                    onPressed: () {
                      _searchController.clear();
                      provider.clearSearch();
                      setState(() => _isSearchExpanded = false);
                    },
                  ),
                ),
                onChanged: provider.setSearchQuery,
              )
            : const Text('Customers'),
        actions: [
          if (!_isSearchExpanded)
            IconButton(
              icon: const Icon(Icons.search),
              tooltip: 'Search customers',
              onPressed: () {
                setState(() => _isSearchExpanded = true);
              },
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle:
              const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          tabs: [
            Tab(text: 'Active ($activeCount)'),
            Tab(text: 'Inactive ($inactiveCount)'),
          ],
        ),
      ),
      body: provider.isLoading && provider.allCustomers.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _CustomerListView(
                  customers: provider.activeCustomers,
                  isActiveTab: true,
                  searchQuery: provider.searchQuery,
                  onRefresh: () async => provider.loadCustomers(),
                  onAddCustomer: _openAddCustomer,
                  onToggleStatus: (c) =>
                      _confirmToggleStatus(context, c, provider),
                ),
                _CustomerListView(
                  customers: provider.inactiveCustomers,
                  isActiveTab: false,
                  searchQuery: provider.searchQuery,
                  onRefresh: () async => provider.loadCustomers(),
                  onAddCustomer: _openAddCustomer,
                  onToggleStatus: (c) =>
                      _confirmToggleStatus(context, c, provider),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddCustomer,
        icon: const Icon(Icons.person_add),
        label: const Text('Add Customer'),
      ),
    );
  }
}

class _CustomerListView extends StatelessWidget {
  final List<Customer> customers;
  final bool isActiveTab;
  final String searchQuery;
  final Future<void> Function() onRefresh;
  final VoidCallback onAddCustomer;
  final void Function(Customer) onToggleStatus;

  const _CustomerListView({
    required this.customers,
    required this.isActiveTab,
    required this.searchQuery,
    required this.onRefresh,
    required this.onAddCustomer,
    required this.onToggleStatus,
  });

  @override
  Widget build(BuildContext context) {
    if (customers.isEmpty) {
      return _EmptyStateView(
        isActiveTab: isActiveTab,
        searchQuery: searchQuery,
        onAddCustomer: onAddCustomer,
      );
    }

    final dateFormat = DateFormat('MMM d, y');

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
        itemCount: customers.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final customer = customers[index];
          final initials = customer.name.trim().isNotEmpty
              ? customer.name
                  .trim()
                  .split(' ')
                  .where((w) => w.isNotEmpty)
                  .take(2)
                  .map((w) => w[0].toUpperCase())
                  .join()
              : '?';

          return Card(
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: customer.isActive
                    ? AppColors.divider
                    : AppColors.divider.withAlpha(100),
              ),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                Navigator.of(context).push(
                  CustomerDetailScreen.route(customer.id),
                );
              },
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: customer.isActive
                          ? AppColors.primary
                          : AppColors.textHint,
                      child: Text(
                        initials,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  customer.name,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: customer.isActive
                                            ? AppColors.textPrimary
                                            : AppColors.textSecondary,
                                      ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (!customer.isActive)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.error.withAlpha(20),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'Inactive',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.error,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              if (customer.phoneNumber != null) ...[
                                const Icon(
                                  Icons.phone_outlined,
                                  size: 14,
                                  color: AppColors.textSecondary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  customer.phoneNumber!,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                ),
                                const SizedBox(width: 12),
                              ],
                              const Icon(
                                Icons.calendar_today_outlined,
                                size: 14,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                dateFormat.format(customer.createdAt),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(
                        Icons.more_vert,
                        color: AppColors.textSecondary,
                      ),
                      onSelected: (action) {
                        if (action == 'details') {
                          Navigator.of(context).push(
                            CustomerDetailScreen.route(customer.id),
                          );
                        } else if (action == 'ledger') {
                          Navigator.of(context).push(
                            CustomerLedgerScreen.route(customer),
                          );
                        } else if (action == 'edit') {
                          AddEditCustomerDialog.show(
                            context,
                            customer: customer,
                          );
                        } else if (action == 'toggle') {
                          onToggleStatus(customer);
                        }
                      },
                      itemBuilder: (ctx) => [
                        const PopupMenuItem(
                          value: 'details',
                          child: Row(
                            children: [
                              Icon(Icons.visibility_outlined, size: 18),
                              SizedBox(width: 10),
                              Text('View Profile'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'ledger',
                          child: Row(
                            children: [
                              Icon(Icons.menu_book_outlined,
                                  size: 18, color: AppColors.primary),
                              SizedBox(width: 10),
                              Text('View Ledger'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit_outlined, size: 18),
                              SizedBox(width: 10),
                              Text('Edit Details'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'toggle',
                          child: Row(
                            children: [
                              Icon(
                                customer.isActive
                                    ? Icons.person_off_outlined
                                    : Icons.person_outline,
                                size: 18,
                                color: customer.isActive
                                    ? AppColors.warning
                                    : AppColors.success,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                customer.isActive
                                    ? 'Deactivate'
                                    : 'Reactivate',
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
          );
        },
      ),
    );
  }
}

class _EmptyStateView extends StatelessWidget {
  final bool isActiveTab;
  final String searchQuery;
  final VoidCallback onAddCustomer;

  const _EmptyStateView({
    required this.isActiveTab,
    required this.searchQuery,
    required this.onAddCustomer,
  });

  @override
  Widget build(BuildContext context) {
    if (searchQuery.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.search_off,
                size: 64,
                color: AppColors.textHint,
              ),
              const SizedBox(height: 16),
              Text(
                'No customers found',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                'No match for "$searchQuery"',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    if (isActiveTab) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(20),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.people_outline,
                  size: 56,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'No active customers yet',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Add student and mess customers to start recording daily meals and generating monthly bills.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onAddCustomer,
                icon: const Icon(Icons.person_add),
                label: const Text('Add First Customer'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.person_off_outlined,
              size: 56,
              color: AppColors.textHint,
            ),
            const SizedBox(height: 16),
            Text(
              'No inactive customers',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 6),
            const Text(
              'When you deactivate a customer, they appear here with all historical records preserved.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
