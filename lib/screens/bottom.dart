import 'package:flutter/material.dart';
import 'package:whatshoppy2/theme/app_theme.dart';
import 'package:whatshoppy2/screens/dashboard_screens.dart';
import 'package:whatshoppy2/screens/clients_screen.dart';
import 'package:whatshoppy2/screens/order_list_screen.dart';
import 'package:whatshoppy2/screens/stock_screen.dart';

class Bottom extends StatelessWidget {
  final int currentIndex;

  const Bottom({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.white,
        border: Border(
          top: BorderSide(
            color: AppTheme.borderGrey.withValues(alpha: 0.8),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              _NavItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home_rounded,
                label: 'Home',
                index: 0,
                currentIndex: currentIndex,
                onTap: () => _navigate(context, 0),
              ),
              _NavItem(
                icon: Icons.people_outline_rounded,
                activeIcon: Icons.people_rounded,
                label: 'Clients',
                index: 1,
                currentIndex: currentIndex,
                onTap: () => _navigate(context, 1),
              ),
              _NavItem(
                icon: Icons.receipt_long_outlined,
                activeIcon: Icons.receipt_long_rounded,
                label: 'Orders',
                index: 2,
                currentIndex: currentIndex,
                onTap: () => _navigate(context, 2),
              ),
              _NavItem(
                icon: Icons.inventory_2_outlined,
                activeIcon: Icons.inventory_2_rounded,
                label: 'Stock',
                index: 3,
                currentIndex: currentIndex,
                onTap: () => _navigate(context, 3),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigate(BuildContext context, int index) {
    if (index == currentIndex) return;

    Widget screen;
    switch (index) {
      case 0:
        screen = const DashboardScreens();
        break;
      case 1:
        screen = const ClientsScreen();
        break;
      case 2:
        screen = const OrdersListScreen();
        break;
      case 3:
        screen = const StockScreen();
        break;
      default:
        screen = const DashboardScreens();
    }

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => screen,
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOut,
            ),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 200),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int index;
  final int currentIndex;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.index,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = index == currentIndex;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isActive
                      ? AppTheme.primaryGreen.withValues(alpha: 0.12)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isActive ? activeIcon : icon,
                  size: 22,
                  color: isActive ? AppTheme.primaryGreen : AppTheme.greyText,
                ),
              ),
              const SizedBox(height: 2),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight:
                      isActive ? FontWeight.w700 : FontWeight.w500,
                  color: isActive ? AppTheme.primaryGreen : AppTheme.greyText,
                ),
                child: Text(label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
