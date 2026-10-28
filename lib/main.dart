import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'presentation/screens/admin/admin_main_screen.dart';
import 'presentation/screens/customer/customer_main_screen.dart';
import 'presentation/screens/staff/staff_main_screen.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: CrownDineApp(),
    ),
  );
}

class CrownDineApp extends ConsumerWidget {
  const CrownDineApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final authState = ref.watch(authProvider);

    return MaterialApp(
      title: 'CrownDine - Luxury Restaurant',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: authState.isAdmin
          ? const AdminMainScreen()
          : (authState.isStaff ? const StaffMainScreen() : const CustomerMainScreen()),
    );
  }
}
