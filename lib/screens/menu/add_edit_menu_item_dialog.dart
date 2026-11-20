import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/menu_item.dart';
import '../../providers/menu_item_provider.dart';

/// Modal bottom sheet for adding or editing a menu item.
class AddEditMenuItemDialog extends StatefulWidget {
  final MenuItem? item;

  const AddEditMenuItemDialog({super.key, this.item});

  static Future<bool?> show(BuildContext context, {MenuItem? item}) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddEditMenuItemDialog(item: item),
    );
  }

  @override
  State<AddEditMenuItemDialog> createState() => _AddEditMenuItemDialogState();
}

class _AddEditMenuItemDialogState extends State<AddEditMenuItemDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _unitController;
  late final TextEditingController _priceController;

  late MenuCategory _selectedCategory;
  bool _isSubmitting = false;

  bool get _isEditing => widget.item != null;

  static const List<String> _suggestedUnits = [
    'piece',
    'plate',
    'cup',
    'glass',
    'serving',
    'bowl',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item?.name ?? '');
    _unitController = TextEditingController(text: widget.item?.unit ?? 'piece');
    _priceController = TextEditingController(
      text: widget.item != null
          ? (widget.item!.pricePaisa ~/ 100).toString()
          : '',
    );
    _selectedCategory = widget.item?.category ?? MenuCategory.extra;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _unitController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  String _categoryLabel(MenuCategory category) {
    switch (category) {
      case MenuCategory.meal:
        return 'Meal';
      case MenuCategory.extra:
        return 'Extra';
      case MenuCategory.dairy:
        return 'Dairy';
      case MenuCategory.beverage:
        return 'Beverage';
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final priceNpr = int.tryParse(_priceController.text.trim()) ?? 0;
    final pricePaisa = priceNpr * 100;

    setState(() => _isSubmitting = true);

    final provider = context.read<MenuItemProvider>();
    bool success;

    if (_isEditing) {
      success = await provider.updateMenuItem(
        id: widget.item!.id,
        name: _nameController.text,
        category: _selectedCategory,
        unit: _unitController.text,
        pricePaisa: pricePaisa,
      );
    } else {
      success = await provider.addMenuItem(
        name: _nameController.text,
        category: _selectedCategory,
        unit: _unitController.text,
        pricePaisa: pricePaisa,
      );
    }

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (success) {
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing
                ? 'Menu item "${_nameController.text.trim()}" updated'
                : 'Menu item "${_nameController.text.trim()}" added',
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      final error = provider.errorMessage ?? 'An error occurred';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomInset),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
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

              // Title Row
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.primary.withAlpha(25),
                    radius: 20,
                    child: Icon(
                      _isEditing ? Icons.edit : Icons.restaurant_menu,
                      color: AppColors.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isEditing ? 'Edit Menu Item' : 'Add Menu Item',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        Text(
                          _isEditing
                              ? 'Update pricing, category, or serving unit'
                              : 'Add extra items customers can order',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
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
              const SizedBox(height: 20),

              // Item Name Field
              TextFormField(
                controller: _nameController,
                autofocus: !_isEditing,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Item Name *',
                  hintText: 'e.g., Boiled Egg, Chiya, Dahi',
                  prefixIcon: Icon(Icons.fastfood_outlined),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter item name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Category Selector
              Text(
                'Category',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: 6),
              SegmentedButton<MenuCategory>(
                segments: MenuCategory.values.map((cat) {
                  return ButtonSegment<MenuCategory>(
                    value: cat,
                    label: Text(
                      _categoryLabel(cat),
                      style: const TextStyle(fontSize: 12),
                    ),
                    icon: Icon(_categoryIcon(cat), size: 16),
                  );
                }).toList(),
                selected: {_selectedCategory},
                onSelectionChanged: (newSelection) {
                  setState(() => _selectedCategory = newSelection.first);
                },
              ),
              const SizedBox(height: 16),

              // Price Field
              TextFormField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Price (in NPR) *',
                  hintText: 'e.g., 35',
                  prefixText: 'Rs. ',
                  prefixIcon: Icon(Icons.currency_rupee),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter price';
                  }
                  final n = int.tryParse(val.trim());
                  if (n == null || n <= 0) {
                    return 'Enter a valid price greater than 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Serving Unit Field
              TextFormField(
                controller: _unitController,
                textCapitalization: TextCapitalization.none,
                decoration: const InputDecoration(
                  labelText: 'Unit / Portion *',
                  hintText: 'e.g., piece, cup, plate',
                  prefixIcon: Icon(Icons.straighten_outlined),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter unit (e.g. piece, plate)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),

              // Unit Quick Chips
              Wrap(
                spacing: 6,
                children: _suggestedUnits.map((u) {
                  final isSelected =
                      _unitController.text.trim().toLowerCase() == u;
                  return ActionChip(
                    label: Text(u, style: const TextStyle(fontSize: 12)),
                    backgroundColor: isSelected
                        ? AppColors.primary.withAlpha(30)
                        : null,
                    side: BorderSide(
                      color: isSelected ? AppColors.primary : AppColors.divider,
                    ),
                    onPressed: () {
                      setState(() => _unitController.text = u);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: _isSubmitting
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isSubmitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(_isEditing ? 'Save Changes' : 'Add Item'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
