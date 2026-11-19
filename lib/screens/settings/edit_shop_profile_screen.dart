import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/shop_profile_provider.dart';

/// Full-page form to edit all shop profile fields including logo.
class EditShopProfileScreen extends StatefulWidget {
  const EditShopProfileScreen({super.key});

  @override
  State<EditShopProfileScreen> createState() => _EditShopProfileScreenState();
}

class _EditShopProfileScreenState extends State<EditShopProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _shopNameCtrl;
  late final TextEditingController _ownerNameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _breakfastCtrl;
  late final TextEditingController _dinnerCtrl;

  String? _logoPath;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final profile =
        context.read<ShopProfileProvider>().shopProfile;

    _shopNameCtrl =
        TextEditingController(text: profile?.shopName ?? '');
    _ownerNameCtrl =
        TextEditingController(text: profile?.ownerName ?? '');
    _phoneCtrl =
        TextEditingController(text: profile?.phoneNumber ?? '');
    _addressCtrl =
        TextEditingController(text: profile?.address ?? '');
    _breakfastCtrl = TextEditingController(
      text:
          ((profile?.defaultBreakfastPricePaisa ?? AppConstants.defaultBreakfastPricePaisa) ~/
                  100)
              .toString(),
    );
    _dinnerCtrl = TextEditingController(
      text:
          ((profile?.defaultDinnerPricePaisa ?? AppConstants.defaultDinnerPricePaisa) ~/
                  100)
              .toString(),
    );
    _logoPath = profile?.logoPath;
  }

  @override
  void dispose() {
    _shopNameCtrl.dispose();
    _ownerNameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _breakfastCtrl.dispose();
    _dinnerCtrl.dispose();
    super.dispose();
  }

  // ── Logo picker ─────────────────────────────────────────────────────────

  Future<void> _pickLogo() async {
    final picker = ImagePicker();
    final source = await _showImageSourceDialog();
    if (source == null) return;

    final picked = await picker.pickImage(
      source: source,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (picked != null) {
      setState(() => _logoPath = picked.path);
    }
  }

  Future<ImageSource?> _showImageSourceDialog() {
    return showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take a Photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            if (_logoPath != null)
              ListTile(
                leading:
                    const Icon(Icons.delete_outline, color: AppColors.error),
                title: const Text('Remove Logo',
                    style: TextStyle(color: AppColors.error)),
                onTap: () {
                  setState(() => _logoPath = null);
                  Navigator.pop(context);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ── Save ─────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final bpNpr = int.tryParse(_breakfastCtrl.text.trim()) ?? 0;
    final dpNpr = int.tryParse(_dinnerCtrl.text.trim()) ?? 0;

    if (bpNpr <= 0 || dpNpr <= 0) {
      _showSnack('Please enter valid prices greater than 0.');
      return;
    }

    setState(() => _isSaving = true);

    final provider = context.read<ShopProfileProvider>();
    final success = await provider.updateProfile(
      shopName: _shopNameCtrl.text,
      ownerName: _ownerNameCtrl.text,
      phoneNumber: _phoneCtrl.text,
      address: _addressCtrl.text,
      breakfastPricePaisa: bpNpr * 100,
      dinnerPricePaisa: dpNpr * 100,
      logoPath: _logoPath,
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      _showSnack('Profile saved successfully!', isError: false);
      Navigator.of(context).pop();
    } else {
      _showSnack(provider.errorMessage ?? 'Failed to save. Please try again.');
    }
  }

  void _showSnack(String msg, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppColors.error : AppColors.success,
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Shop Profile'),
        actions: [
          _isSaving
              ? const Padding(
                  padding: EdgeInsets.all(14),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  ),
                )
              : TextButton(
                  onPressed: _save,
                  child: const Text('Save',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16)),
                ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // ── Logo Section ────────────────────────────────────────────
            _buildLogoSection(),
            const SizedBox(height: 28),

            // ── Shop Details ─────────────────────────────────────────────
            _SectionLabel(label: 'Shop Details'),
            const SizedBox(height: 12),
            _buildField(
              controller: _shopNameCtrl,
              label: 'Shop / Mess Name *',
              hint: "e.g. Ram's Mess",
              icon: Icons.store_outlined,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Shop name is required' : null,
            ),
            const SizedBox(height: 14),
            _buildField(
              controller: _ownerNameCtrl,
              label: 'Owner Name *',
              hint: 'e.g. Ram Bahadur',
              icon: Icons.person_outline,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Owner name is required' : null,
            ),
            const SizedBox(height: 14),
            _buildField(
              controller: _phoneCtrl,
              label: 'Phone Number',
              hint: 'e.g. 9800000000',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 14),
            _buildField(
              controller: _addressCtrl,
              label: 'Address',
              hint: 'e.g. Kathmandu, Nepal',
              icon: Icons.location_on_outlined,
              maxLines: 2,
            ),

            const SizedBox(height: 28),

            // ── Default Meal Prices ──────────────────────────────────────
            _SectionLabel(label: 'Default Meal Prices'),
            const SizedBox(height: 6),
            _buildInfoBanner(
              'These are the default prices used when recording meals. '
              'Changing them here does NOT affect already-recorded entries.',
            ),
            const SizedBox(height: 12),
            _buildPriceField(
              controller: _breakfastCtrl,
              label: 'Breakfast Price (Rs.)',
              icon: Icons.wb_sunny_outlined,
              iconColor: AppColors.breakfast,
            ),
            const SizedBox(height: 14),
            _buildPriceField(
              controller: _dinnerCtrl,
              label: 'Dinner Price (Rs.)',
              icon: Icons.nights_stay_outlined,
              iconColor: AppColors.dinner,
            ),

            const SizedBox(height: 32),

            // ── Save button ──────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _save,
                icon: const Icon(Icons.save_outlined),
                label: Text(_isSaving ? 'Saving…' : 'Save Changes'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ── Logo Section Widget ──────────────────────────────────────────────────

  Widget _buildLogoSection() {
    return Center(
      child: Column(
        children: [
          GestureDetector(
            onTap: _pickLogo,
            child: Stack(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(20),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: AppColors.primary.withAlpha(80), width: 2),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _logoPath != null && _logoPath!.isNotEmpty
                      ? Image.file(File(_logoPath!), fit: BoxFit.cover)
                      : const Icon(Icons.store,
                          size: 48, color: AppColors.primary),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.camera_alt,
                        size: 16, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap to change logo',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.primary),
      ),
    );
  }

  Widget _buildPriceField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color iconColor,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      validator: (v) {
        final n = int.tryParse(v?.trim() ?? '');
        if (n == null || n <= 0) return 'Enter a valid price';
        return null;
      },
      decoration: InputDecoration(
        labelText: label,
        prefixText: 'Rs. ',
        prefixIcon: Icon(icon, color: iconColor),
      ),
    );
  }

  Widget _buildInfoBanner(String text) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.info.withAlpha(15),
        border: Border.all(color: AppColors.info.withAlpha(60)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: AppColors.info, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.info),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section Label ─────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.headlineSmall,
    );
  }
}
