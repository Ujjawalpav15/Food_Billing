import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/customer.dart';
import '../../providers/customer_provider.dart';

/// Modal bottom sheet for adding a new customer or editing an existing one.
class AddEditCustomerDialog extends StatefulWidget {
  final Customer? customer;

  const AddEditCustomerDialog({super.key, this.customer});

  /// Static helper to display the sheet easily from any context.
  static Future<bool?> show(BuildContext context, {Customer? customer}) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddEditCustomerDialog(customer: customer),
    );
  }

  @override
  State<AddEditCustomerDialog> createState() => _AddEditCustomerDialogState();
}

class _AddEditCustomerDialogState extends State<AddEditCustomerDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _notesController;

  bool _isSubmitting = false;

  bool get _isEditing => widget.customer != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.customer?.name ?? '');
    _phoneController =
        TextEditingController(text: widget.customer?.phoneNumber ?? '');
    _notesController =
        TextEditingController(text: widget.customer?.notes ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final provider = context.read<CustomerProvider>();
    bool success;

    if (_isEditing) {
      success = await provider.updateCustomer(
        id: widget.customer!.id,
        name: _nameController.text,
        phoneNumber: _phoneController.text,
        notes: _notesController.text,
      );
    } else {
      success = await provider.addCustomer(
        name: _nameController.text,
        phoneNumber: _phoneController.text,
        notes: _notesController.text,
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
                ? 'Customer details updated'
                : 'Customer "${_nameController.text.trim()}" added',
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
                      _isEditing ? Icons.edit : Icons.person_add,
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
                          _isEditing ? 'Edit Customer' : 'Add New Customer',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        Text(
                          _isEditing
                              ? 'Update name, contact, or personal notes'
                              : 'Create a profile to start tracking meals',
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

              // Customer Name Field
              TextFormField(
                controller: _nameController,
                autofocus: !_isEditing,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Customer Name *',
                  hintText: 'e.g., Ram Sharma',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter customer name';
                  }
                  if (val.trim().length < 2) {
                    return 'Name is too short';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Phone Number Field
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone Number (Optional)',
                  hintText: 'e.g., 98XXXXXXXX',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return null;
                  final clean = val.trim().replaceAll(RegExp(r'[\s\-]'), '');
                  if (clean.length < 7 || clean.length > 15) {
                    return 'Enter a valid phone number (7–15 digits)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Notes Field
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Notes / Room No. / College (Optional)',
                  hintText: 'e.g., Room 102, KMC College, vegetarian only',
                  prefixIcon: Icon(Icons.notes_outlined),
                  alignLabelWithHint: true,
                ),
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
                        : Text(_isEditing ? 'Save Changes' : 'Add Customer'),
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
