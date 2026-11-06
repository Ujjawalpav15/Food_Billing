import 'package:hive_ce_flutter/hive_flutter.dart';
import '../models/models.dart';
import '../../core/constants/app_constants.dart';

class ShopProfileRepository {
  Box<ShopProfile> get _box =>
      Hive.box<ShopProfile>(AppConstants.shopProfileBox);

  static const String _profileKey = 'profile';

  /// Returns the single shop profile, or null if not set up yet.
  ShopProfile? getProfile() {
    return _box.get(_profileKey);
  }

  /// Save or update the shop profile.
  Future<void> saveProfile(ShopProfile profile) async {
    await _box.put(_profileKey, profile);
  }

  /// Check if the app has been set up (profile exists).
  bool get isSetUp => _box.containsKey(_profileKey);

  /// Watch the profile box for changes.
  Stream<BoxEvent> watch() => _box.watch(key: _profileKey);
}
