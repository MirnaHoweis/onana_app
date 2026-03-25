import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_card.dart';
import '../auth/auth_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.warmWhite,
      appBar: AppBar(
        backgroundColor: AppColors.warmWhite,
        elevation: 0,
        title: Text('Settings', style: AppTypography.headingMedium),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const _SectionLabel('Account'),
          const SizedBox(height: 8),
          AppCard(
            child: Column(
              children: [
                _SettingsTile(
                  icon: Icons.person_outline,
                  title: 'Profile',
                  subtitle: 'View your account details',
                  onTap: () => context.go('/profile'),
                ),
                const Divider(color: AppColors.divider, height: 1),
                _SettingsTile(
                  icon: Icons.lock_outline,
                  title: 'Change Password',
                  subtitle: 'Update your password',
                  onTap: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const _SectionLabel('Notifications'),
          const SizedBox(height: 8),
          const AppCard(
            child: Column(
              children: [
                _SettingsToggle(
                  icon: Icons.notifications_outlined,
                  title: 'Push Notifications',
                  subtitle: 'Alerts for delays and actions',
                ),
                Divider(color: AppColors.divider, height: 1),
                _SettingsToggle(
                  icon: Icons.email_outlined,
                  title: 'Email Digests',
                  subtitle: 'Daily summary emails',
                  initialValue: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const _SectionLabel('About'),
          const SizedBox(height: 8),
          const AppCard(
            child: Column(
              children: [
                _SettingsTile(
                  icon: Icons.info_outline,
                  title: 'Version',
                  subtitle: '1.0.0 (Phase 4)',
                  onTap: null,
                ),
                Divider(color: AppColors.divider, height: 1),
                _SettingsTile(
                  icon: Icons.description_outlined,
                  title: 'API',
                  subtitle: 'http://localhost:8000',
                  onTap: null,
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          _SettingsTile(
            icon: Icons.logout,
            title: 'Sign Out',
            subtitle: 'Log out of your account',
            titleColor: AppColors.errorRed,
            onTap: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: AppTypography.labelSmall.copyWith(
        color: AppColors.mutedBlueGray,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.titleColor,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Color? titleColor;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Icon(icon,
          size: 22,
          color: titleColor ?? AppColors.mutedBlueGray),
      title: Text(
        title,
        style: AppTypography.labelLarge.copyWith(
          color: titleColor ?? AppColors.deepCharcoal,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: AppTypography.bodyMedium
            .copyWith(color: AppColors.mutedBlueGray, fontSize: 12),
      ),
      trailing: onTap != null
          ? const Icon(Icons.chevron_right,
              size: 18, color: AppColors.mutedBlueGray)
          : null,
      onTap: onTap,
    );
  }
}

class _SettingsToggle extends StatefulWidget {
  const _SettingsToggle({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.initialValue = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool initialValue;

  @override
  State<_SettingsToggle> createState() => _SettingsToggleState();
}

class _SettingsToggleState extends State<_SettingsToggle> {
  late bool _value;

  @override
  void initState() {
    super.initState();
    _value = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Icon(widget.icon,
          size: 22, color: AppColors.mutedBlueGray),
      title: Text(widget.title, style: AppTypography.labelLarge),
      subtitle: Text(
        widget.subtitle,
        style: AppTypography.bodyMedium
            .copyWith(color: AppColors.mutedBlueGray, fontSize: 12),
      ),
      trailing: Switch(
        value: _value,
        onChanged: (v) => setState(() => _value = v),
        activeColor: AppColors.softGold,
      ),
    );
  }
}
