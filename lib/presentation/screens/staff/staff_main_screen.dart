import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import 'floor_plan/floor_plan_screen.dart';
import 'kitchen/kitchen_display_screen.dart';
import 'orders/order_management_screen.dart';

class StaffMainScreen extends StatefulWidget {
  final int initialIndex;

  const StaffMainScreen({super.key, this.initialIndex = 0});

  @override
  State<StaffMainScreen> createState() => _StaffMainScreenState();
}

class _StaffMainScreenState extends State<StaffMainScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    final screens = const [
      FloorPlanScreen(),
      OrderManagementScreen(),
      KitchenDisplayScreen(),
    ];

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: isDark ? AppColors.textLightSecondary : AppColors.textSecondary,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.table_restaurant_outlined),
              activeIcon: Icon(Icons.table_restaurant),
              label: 'Sơ đồ bàn',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_outlined),
              activeIcon: Icon(Icons.receipt_long),
              label: 'Đơn gọi món',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.soup_kitchen_outlined),
              activeIcon: Icon(Icons.soup_kitchen),
              label: 'Bếp KDS',
            ),
          ],
        ),
      ),
    );
  }
}
