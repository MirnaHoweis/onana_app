import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../../features/auth/auth_provider.dart';

class WebShell extends StatelessWidget {
  const WebShell({super.key, required this.child});

  final Widget child;

  static const List<_NavItem> _items = [
    _NavItem(icon: Icons.grid_view_outlined, path: '/dashboard', label: 'Dashboard'),
    _NavItem(icon: Icons.apartment_outlined, path: '/projects', label: 'Projects'),
    _NavItem(icon: Icons.account_tree_outlined, path: '/pipeline', label: 'Pipeline'),
    _NavItem(icon: Icons.assignment_outlined, path: '/requests', label: 'Requests'),
    _NavItem(icon: Icons.build_outlined, path: '/installations', label: 'Installations'),
    _NavItem(icon: Icons.email_outlined, path: '/email', label: 'Email'),
    _NavItem(icon: Icons.auto_awesome_outlined, path: '/ai', label: 'AI Assistant'),
    _NavItem(icon: Icons.notes_outlined, path: '/notes', label: 'Notes'),
    _NavItem(icon: Icons.settings_outlined, path: '/settings', label: 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          const _Sidebar(items: _items),
          const VerticalDivider(width: 1, color: AppColors.divider),
          Expanded(
            child: Column(
              children: [
                const _TopBar(),
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({required this.items});

  final List<_NavItem> items;

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    return Container(
      width: 240,
      color: AppColors.sandBeige,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
              child: Text(
                'PreSales Pro',
                style: AppTypography.headingLarge.copyWith(
                  color: AppColors.softGold,
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: items.map((item) {
                  final isActive = location.startsWith(item.path);
                  return _SidebarItem(item: item, isActive: isActive);
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({required this.item, required this.isActive});

  final _NavItem item;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go(item.path),
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        decoration: isActive
            ? BoxDecoration(
                color: AppColors.cardSurface,
                borderRadius: BorderRadius.circular(8),
                border: const Border(
                  left: BorderSide(color: AppColors.softGold, width: 3),
                ),
              )
            : null,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(
              item.icon,
              size: 18,
              color: isActive ? AppColors.softGold : AppColors.mutedBlueGray,
            ),
            const SizedBox(width: 12),
            Text(
              item.label,
              style: AppTypography.bodyMedium.copyWith(
                color: isActive ? AppColors.deepCharcoal : AppColors.mutedBlueGray,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends ConsumerWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final initials = _initials(auth.fullName);

    return Container(
      height: 64,
      color: AppColors.warmWhite,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.sandBeige,
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  const Icon(Icons.search, size: 18, color: AppColors.mutedBlueGray),
                  const SizedBox(width: 8),
                  Text(
                    'Search…',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.mutedBlueGray,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            color: AppColors.mutedBlueGray,
            onPressed: () => context.go('/notifications'),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => context.go('/profile'),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.softGold,
              child: Text(
                initials,
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.deepCharcoal,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _initials(String? fullName) {
    if (fullName == null || fullName.isEmpty) return '?';
    final parts = fullName.trim().split(' ');
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }
}

class _NavItem {
  const _NavItem({
    required this.icon,
    required this.path,
    required this.label,
  });

  final IconData icon;
  final String path;
  final String label;
}
