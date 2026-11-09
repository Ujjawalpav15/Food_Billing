import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'data/hive_init.dart';
import 'data/repositories/shop_profile_repository.dart';
import 'providers/shop_profile_provider.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'widgets/main_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initHive();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ShopProfileProvider(ShopProfileRepository()),
        ),
      ],
      child: const MessBillingApp(),
    ),
  );
}

class MessBillingApp extends StatelessWidget {
  const MessBillingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mess Billing Manager',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const _AppRoot(),
    );
  }
}

/// Decides whether to show [OnboardingScreen] or [MainShell] based on
/// whether the shop profile has been set up.
class _AppRoot extends StatelessWidget {
  const _AppRoot();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ShopProfileProvider>();

    if (provider.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return provider.isSetUp ? const MainShell() : const OnboardingScreen();
  }
}
