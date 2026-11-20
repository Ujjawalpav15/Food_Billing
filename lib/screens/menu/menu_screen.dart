import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/money_utils.dart';
import '../../data/models/menu_item.dart';
import '../../providers/menu_item_provider.dart';
import 'add_edit_menu_item_dialog.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  static Route<void> route() {
    return MaterialPageRoute(builder: (_) => const MenuScreen());
  }

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen>
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

  void _openAddItem() {
    AddEditMenuItemDialog.show(context);
  }

  String _categoryName(MenuCategory category) {
    switch (category) {
      case MenuCategory.meal:
        return 'Meals';
      case MenuCategory.extra:
        return 'Extras';
      case MenuCategory.dairy:
        return 'Dairy';
      case MenuCategory.beverage:
        return 'Beverages';
    }
  }

  IconData _categoryIcon(MenuCategory category) {
    switch (category) {
      case MenuCategory.meal:
        return Icons.restaurant;
      case MenuCategory.extra:
        return Icons.egg_outlined;
      case MenuCategory.dairy:
        return Icons.coffee_outlined;
      case MenuCategory.beverage:
        return Icons.local_cafe_outlined;
    }
  }

  Color _categoryColor(MenuCategory category) {
    switch (category) {
      case MenuCategory.meal:
        return AppColors.dinner;
      case MenuCategory.extra:
        return AppColors.breakfast;
      case MenuCategory.dairy:
        return AppColors.accent;
      case MenuCategory.beverage:
        return Colors.brown;
    }
  }

  void _confirmToggleStatus(
      BuildContext context, MenuItem item, MenuItemProvider provider) {
    final actionText = item.isActive ? 'Deactivate' : 'Reactivate';

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('$actionText "${item.name}"?'),
        content: Text(
          item.isActive
              ? 'Deactivating hides this item from future daily extra meal logs. All past recorded orders retain this item and its recorded price.'
              : 'Reactivating makes this item available again for daily customer orders.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  item.isActive ? AppColors.warning : AppColors.success,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              if (item.isActive) {
                await provider.deactivateMenuItem(item.id);
              } else {
                await provider.activateMenuItem(item.id);
              }
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      item.isActive
                          ? 'Menu item deactivated'
                          : 'Menu item reactivated',
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

  void _confirmDelete(
      BuildContext context, MenuItem item, MenuItemProvider provider) {
    final hasHistory = provider.hasHistory(item.id);

    if (hasHistory) {
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          icon: const Icon(Icons.shield_outlined,
              color: AppColors.primary, size: 40),
          title: const Text('Cannot Delete Menu Item'),
          content: Text(
            '"${item.name}" has been recorded in past customer orders.\n\n'
            'To preserve historical accounting accuracy, items with order history cannot be deleted. You can deactivate it instead.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                if (item.isActive) {
                  _confirmToggleStatus(context, item, provider);
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
        title: const Text('Delete Menu Item?'),
        content: Text(
          'Are you sure you want to delete "${item.name}"? '
          'This item has never been ordered by any customer.',
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
              final success = await provider.deleteMenuItem(item.id);
              if (context.mounted) {
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Menu item deleted'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        provider.errorMessage ?? 'Failed to delete menu item',
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
    final provider = context.watch<MenuItemProvider>();
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
                  hintText: 'Search items or units...',
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
            : const Text('Menu Management'),
        actions: [
          if (!_isSearchExpanded)
            IconButton(
              icon: const Icon(Icons.search),
              tooltip: 'Search menu',
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
      body: Column(
        children: [
          // ── Category Filter Bar ──────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: const BoxDecoration(
              color: AppColors.cardBackground,
              border: Border(
                bottom: BorderSide(color: AppColors.divider),
              ),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  FilterChip(
                    label: const Text('All Categories'),
                    selected: provider.selectedCategory == null,
                    onSelected: (_) => provider.setSelectedCategory(null),
                  ),
                  const SizedBox(width: 8),
                  ...MenuCategory.values.map((cat) {
                    final isSelected = provider.selectedCategory == cat;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        avatar: Icon(
                          _categoryIcon(cat),
                          size: 16,
                          color: isSelected ? Colors.white : _categoryColor(cat),
                        ),
                        label: Text(_categoryName(cat)),
                        selected: isSelected,
                        onSelected: (_) {
                          provider.setSelectedCategory(
                            isSelected ? null : cat,
                          );
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),

          // ── Items List ───────────────────────────────────────────
          Expanded(
            child: provider.isLoading && provider.allItems.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _MenuItemListView(
                        items: provider.activeItems,
                        isActiveTab: true,
                        searchQuery: provider.searchQuery,
                        selectedCategory: provider.selectedCategory,
                        onRefresh: () async => provider.loadMenuItems(),
                        onAddItem: _openAddItem,
                        onEditItem: (item) =>
                            AddEditMenuItemDialog.show(context, item: item),
                        onToggleStatus: (item) =>
                            _confirmToggleStatus(context, item, provider),
                        onDeleteItem: (item) =>
                            _confirmDelete(context, item, provider),
                        categoryColor: _categoryColor,
                        categoryIcon: _categoryIcon,
                      ),
                      _MenuItemListView(
                        items: provider.inactiveItems,
                        isActiveTab: false,
                        searchQuery: provider.searchQuery,
                        selectedCategory: provider.selectedCategory,
                        onRefresh: () async => provider.loadMenuItems(),
                        onAddItem: _openAddItem,
                        onEditItem: (item) =>
                            AddEditMenuItemDialog.show(context, item: item),
                        onToggleStatus: (item) =>
                            _confirmToggleStatus(context, item, provider),
                        onDeleteItem: (item) =>
                            _confirmDelete(context, item, provider),
                        categoryColor: _categoryColor,
                        categoryIcon: _categoryIcon,
                      ),
                    ],
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddItem,
        icon: const Icon(Icons.add),
        label: const Text('Add Menu Item'),
      ),
    );
  }
}

class _MenuItemListView extends StatelessWidget {
  final List<MenuItem> items;
  final bool isActiveTab;
  final String searchQuery;
  final MenuCategory? selectedCategory;
  final Future<void> Function() onRefresh;
  final VoidCallback onAddItem;
  final void Function(MenuItem) onEditItem;
  final void Function(MenuItem) onToggleStatus;
  final void Function(MenuItem) onDeleteItem;
  final Color Function(MenuCategory) categoryColor;
  final IconData Function(MenuCategory) categoryIcon;

  const _MenuItemListView({
    required this.items,
    required this.isActiveTab,
    required this.searchQuery,
    required this.selectedCategory,
    required this.onRefresh,
    required this.onAddItem,
    required this.onEditItem,
    required this.onToggleStatus,
    required this.onDeleteItem,
    required this.categoryColor,
    required this.categoryIcon,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                searchQuery.isNotEmpty
                    ? Icons.search_off
                    : (isActiveTab
                        ? Icons.restaurant_menu
                        : Icons.disabled_by_default_outlined),
                size: 64,
                color: AppColors.textHint,
              ),
              const SizedBox(height: 16),
              Text(
                searchQuery.isNotEmpty
                    ? 'No matching menu items'
                    : (isActiveTab
                        ? 'No active menu items'
                        : 'No inactive menu items'),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                searchQuery.isNotEmpty
                    ? 'No results matching "$searchQuery"'
                    : (isActiveTab
                        ? 'Add custom menu items (eggs, curd, tea, snacks) to track extra student orders.'
                        : 'Items you deactivate will appear here.'),
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              if (isActiveTab && searchQuery.isEmpty) ...[
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: onAddItem,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Item'),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final item = items[index];
          final color = categoryColor(item.category);

          return Card(
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: item.isActive
                    ? AppColors.divider
                    : AppColors.divider.withAlpha(100),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: color.withAlpha(25),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      categoryIcon(item.category),
                      color: color,
                      size: 22,
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
                                item.name,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: item.isActive
                                          ? AppColors.textPrimary
                                          : AppColors.textSecondary,
                                    ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (!item.isActive)
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
                            Text(
                              'per ${item.unit}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: AppColors.textSecondary),
                            ),
                            const SizedBox(width: 8),
                            const Text('•',
                                style: TextStyle(color: AppColors.textHint)),
                            const SizedBox(width: 8),
                            Text(
                              MoneyUtils.formatNprFromPaisa(item.pricePaisa),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: item.isActive
                                        ? AppColors.primary
                                        : AppColors.textSecondary,
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
                      if (action == 'edit') {
                        onEditItem(item);
                      } else if (action == 'toggle') {
                        onToggleStatus(item);
                      } else if (action == 'delete') {
                        onDeleteItem(item);
                      }
                    },
                    itemBuilder: (ctx) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined, size: 18),
                            SizedBox(width: 10),
                            Text('Edit Item'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'toggle',
                        child: Row(
                          children: [
                            Icon(
                              item.isActive
                                  ? Icons.remove_circle_outline
                                  : Icons.check_circle_outline,
                              size: 18,
                              color: item.isActive
                                  ? AppColors.warning
                                  : AppColors.success,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              item.isActive ? 'Deactivate' : 'Reactivate',
                            ),
                          ],
                        ),
                      ),
                      const PopupMenuDivider(),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline,
                                size: 18, color: AppColors.error),
                            const SizedBox(width: 10),
                            Text(
                              'Delete Item',
                              style: TextStyle(color: AppColors.error),
                            ),
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
    );
  }
}
