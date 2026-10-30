import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'presentation/screens/admin/admin_main_screen.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/auth/register_screen.dart';
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
      onGenerateRoute: (settings) {
        final raw = settings.name ?? '/';
        final normalized = raw.replaceFirst('/#', '').replaceFirst('#', '');
        final path = Uri.tryParse(normalized)?.path ?? normalized;

        if (path == '/admin' || path == '/admin/dashboard' || path.endsWith('/admin/dashboard')) {
          return MaterialPageRoute(builder: (_) => const AdminMainScreen());
        }
        if (path == '/admin/attendance' || path.endsWith('/admin/attendance')) {
          return MaterialPageRoute(builder: (_) => const AdminMainScreen(initialIndex: 4));
        }
        if (path == '/staff/reservation-list' || path.endsWith('/staff/reservation-list')) {
          return MaterialPageRoute(builder: (_) => const StaffMainScreen(initialIndex: 1));
        }
        if (path == '/staff/work-schedule' || path.endsWith('/staff/work-schedule')) {
          return MaterialPageRoute(builder: (_) => const StaffMainScreen(initialIndex: 4));
        }
        if (path.startsWith('/staff')) {
          return MaterialPageRoute(builder: (_) => const StaffMainScreen());
        }
        if (path == '/login') {
          return MaterialPageRoute(builder: (_) => const LoginScreen());
        }
        if (path == '/register') {
          return MaterialPageRoute(builder: (_) => const RegisterScreen());
        }

        return MaterialPageRoute(
          builder: (_) => authState.isAdmin
              ? const AdminMainScreen()
              : (authState.isStaff ? const StaffMainScreen() : const CustomerMainScreen()),
        );
      },
    );
  }
}
