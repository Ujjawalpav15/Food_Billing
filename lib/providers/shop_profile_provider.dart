import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../data/models/models.dart';
import '../data/repositories/shop_profile_repository.dart';
import '../core/constants/app_constants.dart';

class ShopProfileProvider extends ChangeNotifier {
  final ShopProfileRepository _repository;
  static const _uuid = Uuid();

  ShopProfile? _shopProfile;
  bool _isLoading = false;
  String? _errorMessage;

  ShopProfileProvider(this._repository) {
    _load();
  }

  // ── Getters ──────────────────────────────────────────────────────────────

  ShopProfile? get shopProfile => _shopProfile;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Whether the user has completed the onboarding setup.
  bool get isSetUp => _repository.isSetUp;

  // ── Methods ──────────────────────────────────────────────────────────────

  void _load() {
    _shopProfile = _repository.getProfile();
    notifyListeners();
  }

  Future<void> reload() async {
    _shopProfile = _repository.getProfile();
    notifyListeners();
  }

  /// Create a new shop profile (called from OnboardingScreen).
  Future<bool> createProfile({
    required String shopName,
    required String ownerName,
    required String phoneNumber,
    required String address,
    int breakfastPricePaisa = AppConstants.defaultBreakfastPricePaisa,
    int dinnerPricePaisa = AppConstants.defaultDinnerPricePaisa,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final now = DateTime.now();
      final profile = ShopProfile(
        id: _uuid.v4(),
        shopName: shopName.trim(),
        ownerName: ownerName.trim(),
        phoneNumber: phoneNumber.trim(),
        address: address.trim(),
        defaultBreakfastPricePaisa: breakfastPricePaisa,
        defaultDinnerPricePaisa: dinnerPricePaisa,
        createdAt: now,
        updatedAt: now,
      );

      await _repository.saveProfile(profile);
      _shopProfile = profile;
      return true;
    } catch (e) {
      _errorMessage = 'Failed to save profile: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update an existing shop profile (called from SettingsScreen).
  Future<bool> updateProfile({
    required String shopName,
    required String ownerName,
    required String phoneNumber,
    required String address,
    int? breakfastPricePaisa,
    int? dinnerPricePaisa,
    String? logoPath,
  }) async {
    final current = _shopProfile;
    if (current == null) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updated = ShopProfile(
        id: current.id,
        shopName: shopName.trim(),
        ownerName: ownerName.trim(),
        phoneNumber: phoneNumber.trim(),
        address: address.trim(),
        logoPath: logoPath ?? current.logoPath,
        defaultBreakfastPricePaisa:
            breakfastPricePaisa ?? current.defaultBreakfastPricePaisa,
        defaultDinnerPricePaisa:
            dinnerPricePaisa ?? current.defaultDinnerPricePaisa,
        createdAt: current.createdAt,
        updatedAt: DateTime.now(),
      );

      await _repository.saveProfile(updated);
      _shopProfile = updated;
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update profile: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
