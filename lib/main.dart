import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'presentation/screens/admin/admin_main_screen.dart';
import 'presentation/screens/admin/feedback/admin_feedback_screen.dart';
import 'presentation/screens/admin/payment/admin_payment_screen.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/auth/register_screen.dart';
import 'presentation/screens/customer/customer_main_screen.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'presentation/screens/staff/staff_main_screen.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await initializeDateFormatting('vi_VN', null);
    await initializeDateFormatting('vi', null);
  } catch (_) {}
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

        if (path == '/admin' ||
            path == '/admin/dashboard' ||
            path.endsWith('/admin/dashboard')) {
          return MaterialPageRoute(
              builder: (_) =>
                  const _RoleGate(admin: true, child: AdminMainScreen()));
        }
        if (path == '/admin/work-schedule' ||
            path.endsWith('/admin/work-schedule')) {
          return MaterialPageRoute(
              builder: (_) => const _RoleGate(
                  admin: true, child: AdminMainScreen(initialIndex: 4)));
        }
        if (path == '/admin/attendance' || path.endsWith('/admin/attendance')) {
          return MaterialPageRoute(
              builder: (_) => const _RoleGate(
                  admin: true, child: AdminMainScreen(initialIndex: 5)));
        }
        if (path == '/admin/feedback' || path.endsWith('/admin/feedback')) {
          return MaterialPageRoute(
              builder: (_) =>
                  const _RoleGate(admin: true, child: AdminFeedbackScreen()));
        }
        if (path == '/admin/payment' || path.endsWith('/admin/payment')) {
          return MaterialPageRoute(
              builder: (_) =>
                  const _RoleGate(admin: true, child: AdminPaymentScreen()));
        }
        if (path == '/staff/reservation-list' ||
            path.endsWith('/staff/reservation-list')) {
          return MaterialPageRoute(
              builder: (_) =>
                  const _RoleGate(child: StaffMainScreen(initialIndex: 1)));
        }
        if (path == '/staff/work-schedule' ||
            path.endsWith('/staff/work-schedule')) {
          return MaterialPageRoute(
              builder: (_) =>
                  const _RoleGate(child: StaffMainScreen(initialIndex: 4)));
        }
        if (path.startsWith('/staff')) {
          return MaterialPageRoute(
              builder: (_) => const _RoleGate(child: StaffMainScreen()));
        }
        if (path == '/login') {
          return MaterialPageRoute(builder: (_) => const LoginScreen());
        }
        if (path == '/register') {
          return MaterialPageRoute(builder: (_) => const RegisterScreen());
        }

        return MaterialPageRoute(builder: (_) => const _HomeGate());
      },
    );
  }
}

class _HomeGate extends ConsumerWidget {
  const _HomeGate();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    if (auth.isChecking)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (auth.isAdmin) return const AdminMainScreen();
    if (auth.isStaff) return const StaffMainScreen();
    return const CustomerMainScreen();
  }
}

class _RoleGate extends ConsumerWidget {
  final bool admin;
  final Widget child;
  const _RoleGate({this.admin = false, required this.child});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    if (auth.isChecking)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (!auth.isAuthenticated) return const LoginScreen();
    if (admin
        ? auth.user?.role.name == 'admin'
        : auth.user?.role.name == 'admin' || auth.user?.role.name == 'staff')
      return child;
    return Scaffold(
        appBar: AppBar(title: const Text('Không có quyền truy cập')),
        body: Center(
            child: FilledButton(
                onPressed: () => Navigator.of(context)
                    .pushNamedAndRemoveUntil('/', (_) => false),
                child: const Text('Về trang chủ'))));
  }
}
