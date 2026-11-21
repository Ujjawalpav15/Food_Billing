import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/money_utils.dart';
import '../../data/models/customer.dart';
import '../../data/models/payment.dart';
import '../../providers/customer_provider.dart';
import '../../providers/payment_provider.dart';

class RecordPaymentDialog extends StatefulWidget {
  final Customer? preselectedCustomer;

  const RecordPaymentDialog({super.key, this.preselectedCustomer});

  static Future<bool?> show(BuildContext context, {Customer? customer}) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => RecordPaymentDialog(preselectedCustomer: customer),
    );
  }

  @override
  State<RecordPaymentDialog> createState() => _RecordPaymentDialogState();
}

class _RecordPaymentDialogState extends State<RecordPaymentDialog> {
  final _formKey = GlobalKey<FormState>();

  Customer? _selectedCustomer;
  DateTime _paymentDate = DateTime.now();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _refController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  PaymentMethod _selectedMethod = PaymentMethod.cash;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedCustomer = widget.preselectedCustomer;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _refController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String _methodLabel(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return 'Cash';
      case PaymentMethod.esewa:
        return 'eSewa';
      case PaymentMethod.khalti:
        return 'Khalti';
      case PaymentMethod.bankTransfer:
        return 'Bank Transfer';
      case PaymentMethod.other:
        return 'Other';
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _paymentDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _paymentDate = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a customer')),
      );
      return;
    }

    final amountNpr = int.tryParse(_amountController.text.trim()) ?? 0;
    if (amountNpr <= 0) return;

    setState(() => _isSubmitting = true);

    final provider = context.read<PaymentProvider>();
    final success = await provider.recordPayment(
      customerId: _selectedCustomer!.id,
      date: _paymentDate,
      amountPaisa: amountNpr * 100,
      method: _selectedMethod,
      referenceNumber: _refController.text,
      notes: _notesController.text,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (success) {
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Payment of Rs. $amountNpr recorded for ${_selectedCustomer!.name}',
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Failed to record payment'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final customerProvider = context.watch<CustomerProvider>();
    final paymentProvider = context.watch<PaymentProvider>();
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final allCustomers = customerProvider.allCustomers;

    final customerBalancePaisa = _selectedCustomer != null
        ? paymentProvider.getCustomerBalancePaisa(_selectedCustomer!.id)
        : 0;
    final currentDueNpr = customerBalancePaisa > 0 ? customerBalancePaisa ~/ 100 : 0;

    final enteredAmountNpr = int.tryParse(_amountController.text.trim()) ?? 0;
    final isOverpayment = customerBalancePaisa > 0 && enteredAmountNpr > currentDueNpr;
    final excessCreditNpr = isOverpayment ? enteredAmountNpr - currentDueNpr : 0;

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
              // Drag Handle
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
                    backgroundColor: AppColors.success.withAlpha(20),
                    radius: 20,
                    child: const Icon(Icons.payments, color: AppColors.success, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Record Payment',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const Text(
                          'Log cash, digital, or bank collections',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Customer Selector
              if (widget.preselectedCustomer != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('CUSTOMER',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary)),
                          Text(widget.preselectedCustomer!.name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('CURRENT DUE',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                          Text(
                            MoneyUtils.formatNprFromPaisa(customerBalancePaisa),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: customerBalancePaisa > 0 ? AppColors.error : AppColors.success,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                )
              else
                DropdownButtonFormField<Customer>(
                  value: _selectedCustomer,
                  decoration: const InputDecoration(
                    labelText: 'Select Customer *',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  items: allCustomers.map((c) {
                    final duePaisa = paymentProvider.getCustomerBalancePaisa(c.id);
                    return DropdownMenuItem<Customer>(
                      value: c,
                      child: Text('${c.name} (${MoneyUtils.formatNprFromPaisa(duePaisa)})'),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedCustomer = val;
                      if (val != null) {
                        final due = paymentProvider.getCustomerBalancePaisa(val.id);
                        if (due > 0) {
                          _amountController.text = (due ~/ 100).toString();
                        }
                      }
                    });
                  },
                  validator: (val) => val == null ? 'Please select a customer' : null,
                ),
              const SizedBox(height: 14),

              // Payment Date Row
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.divider),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined, size: 20, color: AppColors.primary),
                      const SizedBox(width: 12),
                      Text(
                        'Date: ${DateFormat('d MMMM y').format(_paymentDate)}',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      const Spacer(),
                      const Icon(Icons.edit, size: 16, color: AppColors.textSecondary),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Amount Field
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Amount Received (in NPR) *',
                  hintText: 'e.g., 1500',
                  prefixText: 'Rs. ',
                  prefixIcon: Icon(Icons.currency_rupee),
                ),
                onChanged: (_) => setState(() {}),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Enter amount';
                  final n = int.tryParse(val.trim());
                  if (n == null || n <= 0) return 'Enter a valid amount';
                  return null;
                },
              ),
              const SizedBox(height: 8),

              // Quick Fill Chips
              Wrap(
                spacing: 8,
                children: [
                  if (currentDueNpr > 0)
                    ActionChip(
                      avatar: const Icon(Icons.check_circle_outline, size: 14, color: AppColors.success),
                      label: Text('Pay Full Due (Rs. $currentDueNpr)', style: const TextStyle(fontSize: 12)),
                      onPressed: () {
                        setState(() => _amountController.text = currentDueNpr.toString());
                      },
                    ),
                  ActionChip(
                    label: const Text('Rs. 500', style: TextStyle(fontSize: 12)),
                    onPressed: () => setState(() => _amountController.text = '500'),
                  ),
                  ActionChip(
                    label: const Text('Rs. 1,000', style: TextStyle(fontSize: 12)),
                    onPressed: () => setState(() => _amountController.text = '1000'),
                  ),
                  ActionChip(
                    label: const Text('Rs. 2,000', style: TextStyle(fontSize: 12)),
                    onPressed: () => setState(() => _amountController.text = '2000'),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Overpayment Banner
              if (isOverpayment)
                Container(
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.primary.withAlpha(50)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, size: 18, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Rs. $currentDueNpr clears the balance. Excess Rs. $excessCreditNpr will be stored as customer credit.',
                          style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),

              // Payment Method Dropdown
              DropdownButtonFormField<PaymentMethod>(
                value: _selectedMethod,
                decoration: const InputDecoration(
                  labelText: 'Payment Method',
                  prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                ),
                items: PaymentMethod.values.map((m) {
                  return DropdownMenuItem(
                    value: m,
                    child: Text(_methodLabel(m)),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedMethod = val);
                },
              ),
              const SizedBox(height: 14),

              // Reference Number Field
              TextFormField(
                controller: _refController,
                decoration: const InputDecoration(
                  labelText: 'Reference / Trans ID (Optional)',
                  hintText: 'e.g. eSewa Txn ID, Cheque #',
                  prefixIcon: Icon(Icons.tag),
                ),
              ),
              const SizedBox(height: 14),

              // Notes Field
              TextFormField(
                controller: _notesController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Notes (Optional)',
                  hintText: 'e.g. Advance payment for next month',
                  prefixIcon: Icon(Icons.notes_outlined),
                ),
              ),
              const SizedBox(height: 20),

              // Submit Button
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Record Payment', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
