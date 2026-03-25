import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';

class MobileShell extends StatelessWidget {
  const MobileShell({super.key, required this.child});

  final Widget child;

  static const List<_NavItem> _items = [
    _NavItem(icon: Icons.grid_view_outlined, activeIcon: Icons.grid_view, path: '/dashboard', label: 'Dashboard'),
    _NavItem(icon: Icons.apartment_outlined, activeIcon: Icons.apartment, path: '/projects', label: 'Projects'),
    _NavItem(icon: Icons.assignment_outlined, activeIcon: Icons.assignment, path: '/requests', label: 'Requests'),
    _NavItem(icon: Icons.notes_outlined, activeIcon: Icons.notes, path: '/notes', label: 'Notes'),
    _NavItem(icon: Icons.person_outline, activeIcon: Icons.person, path: '/profile', label: 'Profile'),
  ];

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    for (int i = 0; i < _items.length; i++) {
      if (location.startsWith(_items[i].path)) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _currentIndex(context);
    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.cardSurface,
          border: Border(top: BorderSide(color: AppColors.divider, width: 1)),
        ),
        child: SafeArea(
          child: SizedBox(
            height: 60,
            child: Row(
              children: List.generate(_items.length, (i) {
                final item = _items[i];
                final isActive = i == currentIndex;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => context.go(item.path),
                    behavior: HitTestBehavior.opaque,
                    child: _NavItemWidget(
                      item: item,
                      isActive: isActive,
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItemWidget extends StatelessWidget {
  const _NavItemWidget({required this.item, required this.isActive});

  final _NavItem item;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isActive)
          Container(
            width: 4,
            height: 4,
            margin: const EdgeInsets.only(bottom: 6),
            decoration: const BoxDecoration(
              color: AppColors.softGold,
              shape: BoxShape.circle,
            ),
          )
        else
          const SizedBox(height: 10),
        Icon(
          isActive ? item.activeIcon : item.icon,
          color: isActive ? AppColors.softGold : AppColors.mutedBlueGray,
          size: 24,
        ),
      ],
    );
  }
}

class _NavItem {
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.path,
    required this.label,
  });

  final IconData icon;
  final IconData activeIcon;
  final String path;
  final String label;
}
