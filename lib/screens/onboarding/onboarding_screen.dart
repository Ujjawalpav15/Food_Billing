import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/money_utils.dart';
import '../../providers/shop_profile_provider.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();
  int _currentPage = 0;

  // Form controllers
  final _shopNameCtrl = TextEditingController();
  final _ownerNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();

  // Prices in NPR (displayed), stored as Paisa
  int _breakfastPricePaisa = AppConstants.defaultBreakfastPricePaisa;
  int _dinnerPricePaisa = AppConstants.defaultDinnerPricePaisa;

  final _breakfastPriceCtrl = TextEditingController();
  final _dinnerPriceCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Show default prices in NPR (paisa ÷ 100)
    _breakfastPriceCtrl.text =
        (AppConstants.defaultBreakfastPricePaisa ~/ 100).toString();
    _dinnerPriceCtrl.text =
        (AppConstants.defaultDinnerPricePaisa ~/ 100).toString();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _shopNameCtrl.dispose();
    _ownerNameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _breakfastPriceCtrl.dispose();
    _dinnerPriceCtrl.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage == 0) {
      // Validate first page fields
      if (_shopNameCtrl.text.trim().isEmpty ||
          _ownerNameCtrl.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill in all required fields.')),
        );
        return;
      }
    }
    _pageController.nextPage(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  void _prevPage() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _submit() async {
    // Parse prices
    final bpNpr = int.tryParse(_breakfastPriceCtrl.text.trim()) ?? 0;
    final dpNpr = int.tryParse(_dinnerPriceCtrl.text.trim()) ?? 0;

    if (bpNpr <= 0 || dpNpr <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid prices.')),
      );
      return;
    }

    _breakfastPricePaisa = bpNpr * 100;
    _dinnerPricePaisa = dpNpr * 100;

    final provider = context.read<ShopProfileProvider>();
    final success = await provider.createProfile(
      shopName: _shopNameCtrl.text,
      ownerName: _ownerNameCtrl.text,
      phoneNumber: _phoneCtrl.text,
      address: _addressCtrl.text,
      breakfastPricePaisa: _breakfastPricePaisa,
      dinnerPricePaisa: _dinnerPricePaisa,
    );

    if (!mounted) return;

    if (success) {
      // Navigate to main shell — handled by rebuilding MaterialApp home
      // The parent rebuilds when provider notifies (isSetUp → true)
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              provider.errorMessage ?? 'Failed to save. Please try again.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            _buildProgressBar(),

            // Pages
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (page) =>
                    setState(() => _currentPage = page),
                children: [
                  _buildPage1(),
                  _buildPage2(),
                  _buildPage3(),
                ],
              ),
            ),

            // Navigation buttons
            _buildNavButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    return Container(
      color: AppColors.primary,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.restaurant_menu,
                  color: Colors.white, size: 28),
              const SizedBox(width: 10),
              const Text(
                'Mess Billing Manager',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Step ${_currentPage + 1} of 3',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(3, (i) {
              return Expanded(
                child: Container(
                  margin: EdgeInsets.only(right: i < 2 ? 6 : 0),
                  height: 4,
                  decoration: BoxDecoration(
                    color: i <= _currentPage
                        ? Colors.white
                        : Colors.white38,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // ── Page 1: Shop Info ──────────────────────────────────────────────────

  Widget _buildPage1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text('Shop Information',
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 4),
            Text('Enter your mess or shop details.',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 28),
            _buildTextField(
              controller: _shopNameCtrl,
              label: 'Shop / Mess Name *',
              hint: "e.g. Ram's Mess",
              icon: Icons.store,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _ownerNameCtrl,
              label: 'Owner Name *',
              hint: 'e.g. Ram Bahadur',
              icon: Icons.person,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _phoneCtrl,
              label: 'Phone Number',
              hint: 'e.g. 9800000000',
              icon: Icons.phone,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _addressCtrl,
              label: 'Address',
              hint: 'e.g. Kathmandu, Nepal',
              icon: Icons.location_on,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  // ── Page 2: Default Prices ─────────────────────────────────────────────

  Widget _buildPage2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text('Default Meal Prices',
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 4),
          Text(
            'Set the default price per meal. You can change these later in Settings.',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 28),
          _PriceCard(
            icon: Icons.wb_sunny_outlined,
            iconColor: AppColors.breakfast,
            label: 'Breakfast Price (Rs.)',
            controller: _breakfastPriceCtrl,
          ),
          const SizedBox(height: 16),
          _PriceCard(
            icon: Icons.nights_stay_outlined,
            iconColor: AppColors.dinner,
            label: 'Dinner Price (Rs.)',
            controller: _dinnerPriceCtrl,
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.info.withAlpha(15),
              border: Border.all(color: AppColors.info.withAlpha(60)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline,
                    color: AppColors.info, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Prices are stored in Paisa (1 NPR = 100 Paisa). '
                    'Historical meal prices are always preserved.',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.info),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Page 3: Review & Confirm ───────────────────────────────────────────

  Widget _buildPage3() {
    final bpNpr =
        int.tryParse(_breakfastPriceCtrl.text.trim()) ?? 0;
    final dpNpr =
        int.tryParse(_dinnerPriceCtrl.text.trim()) ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text('Review & Confirm',
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 4),
          Text(
            'Please verify your details before finishing setup.',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _ReviewRow(
                      icon: Icons.store,
                      label: 'Shop Name',
                      value: _shopNameCtrl.text.trim().isEmpty
                          ? '—'
                          : _shopNameCtrl.text.trim()),
                  const Divider(height: 20),
                  _ReviewRow(
                      icon: Icons.person,
                      label: 'Owner',
                      value: _ownerNameCtrl.text.trim().isEmpty
                          ? '—'
                          : _ownerNameCtrl.text.trim()),
                  const Divider(height: 20),
                  _ReviewRow(
                      icon: Icons.phone,
                      label: 'Phone',
                      value: _phoneCtrl.text.trim().isEmpty
                          ? '—'
                          : _phoneCtrl.text.trim()),
                  const Divider(height: 20),
                  _ReviewRow(
                      icon: Icons.location_on,
                      label: 'Address',
                      value: _addressCtrl.text.trim().isEmpty
                          ? '—'
                          : _addressCtrl.text.trim()),
                  const Divider(height: 20),
                  _ReviewRow(
                      icon: Icons.wb_sunny_outlined,
                      iconColor: AppColors.breakfast,
                      label: 'Breakfast',
                      value: MoneyUtils.formatNprFromPaisa(bpNpr * 100)),
                  const Divider(height: 20),
                  _ReviewRow(
                      icon: Icons.nights_stay_outlined,
                      iconColor: AppColors.dinner,
                      label: 'Dinner',
                      value: MoneyUtils.formatNprFromPaisa(dpNpr * 100)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Consumer<ShopProfileProvider>(
            builder: (context, provider, _) {
              if (provider.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              return SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _submit,
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Start Using App'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ── Navigation Buttons ─────────────────────────────────────────────────

  Widget _buildNavButtons() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        border:
            Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          if (_currentPage > 0)
            OutlinedButton.icon(
              onPressed: _prevPage,
              icon: const Icon(Icons.arrow_back),
              label: const Text('Back'),
            ),
          const Spacer(),
          if (_currentPage < 2)
            ElevatedButton.icon(
              onPressed: _nextPage,
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Next'),
            ),
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.primary),
      ),
    );
  }
}

// ── Supporting widgets ───────────────────────────────────────────────────────

class _PriceCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final TextEditingController controller;

  const _PriceCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: controller,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: label,
                  prefixText: 'Rs. ',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewRow extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String label;
  final String value;

  const _ReviewRow({
    required this.icon,
    this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: iconColor ?? AppColors.primary, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppColors.textSecondary)),
              Text(value,
                  style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
        ),
      ],
    );
  }
}
