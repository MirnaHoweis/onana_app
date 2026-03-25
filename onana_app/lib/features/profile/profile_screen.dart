import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../auth/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.warmWhite,
      appBar: AppBar(
        backgroundColor: AppColors.warmWhite,
        elevation: 0,
        title: Text('Profile', style: AppTypography.headingMedium),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Avatar
          Center(
            child: CircleAvatar(
              radius: 40,
              backgroundColor: AppColors.softGold,
              child: Text(
                _initials(auth.fullName),
                style: AppTypography.headingLarge.copyWith(
                  color: AppColors.deepCharcoal,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              auth.fullName ?? '—',
              style: AppTypography.headingMedium,
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              auth.email ?? '—',
              style: AppTypography.bodyMedium
                  .copyWith(color: AppColors.mutedBlueGray),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: _RoleBadge(auth.role ?? 'ENGINEER'),
          ),
          const SizedBox(height: 32),
          // Info card
          AppCard(
            child: Column(
              children: [
                _InfoRow(
                  icon: Icons.email_outlined,
                  label: 'Email',
                  value: auth.email ?? '—',
                ),
                const Divider(color: AppColors.divider, height: 24),
                _InfoRow(
                  icon: Icons.badge_outlined,
                  label: 'Role',
                  value: (auth.role ?? 'ENGINEER')
                      .replaceAll('_', ' ')
                      .toLowerCase()
                      .split(' ')
                      .map((w) => w.isEmpty
                          ? w
                          : '${w[0].toUpperCase()}${w.substring(1)}')
                      .join(' '),
                ),
                const Divider(color: AppColors.divider, height: 24),
                _InfoRow(
                  icon: Icons.fingerprint_outlined,
                  label: 'User ID',
                  value: auth.userId != null
                      ? '${auth.userId!.substring(0, 8)}…'
                      : '—',
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          AppButton(
            label: 'Sign Out',
            variant: AppButtonVariant.secondary,
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
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

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.mutedBlueGray),
        const SizedBox(width: 12),
        Text(label,
            style: AppTypography.bodyMedium
                .copyWith(color: AppColors.mutedBlueGray)),
        const Spacer(),
        Text(value, style: AppTypography.labelLarge),
      ],
    );
  }
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge(this.role);
  final String role;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.softGold.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        role.replaceAll('_', ' '),
        style: AppTypography.labelSmall.copyWith(color: AppColors.softGold),
      ),
    );
  }
}
