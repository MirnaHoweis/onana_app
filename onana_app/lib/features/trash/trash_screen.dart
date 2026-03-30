import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/loading_shimmer.dart';
import 'trash_providers.dart';

class TrashScreen extends ConsumerWidget {
  const TrashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trashAsync = ref.watch(trashProvider);

    return Scaffold(
      backgroundColor: AppColors.warmWhite,
      appBar: AppBar(
        backgroundColor: AppColors.warmWhite,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text('Trash', style: AppTypography.headingMedium),
        actions: [
          trashAsync.maybeWhen(
            data: (data) {
              final total = _totalCount(data);
              if (total == 0) return const SizedBox.shrink();
              return TextButton.icon(
                onPressed: () => _confirmEmptyTrash(context, ref, data),
                icon: const Icon(Icons.delete_forever_outlined, size: 18, color: AppColors.errorRed),
                label: Text('Empty all', style: AppTypography.labelSmall.copyWith(color: AppColors.errorRed)),
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: trashAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(24),
          child: LoadingShimmer(itemCount: 4),
        ),
        error: (e, _) => Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.cloud_off_outlined, size: 48, color: AppColors.mutedBlueGray),
            const SizedBox(height: 12),
            Text('Could not load trash', style: AppTypography.bodyMedium.copyWith(color: AppColors.mutedBlueGray)),
            TextButton(
              onPressed: () => ref.invalidate(trashProvider),
              child: Text('Retry', style: AppTypography.labelLarge.copyWith(color: AppColors.softGold)),
            ),
          ]),
        ),
        data: (data) {
          final total = _totalCount(data);
          if (total == 0) {
            return Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.delete_outline, size: 64, color: AppColors.mutedBlueGray),
                const SizedBox(height: 16),
                Text('Trash is empty', style: AppTypography.headingMedium),
                const SizedBox(height: 8),
                Text('Deleted items appear here', style: AppTypography.bodyMedium.copyWith(color: AppColors.mutedBlueGray)),
              ]),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _TrashSection(
                title: 'Projects',
                icon: Icons.apartment_outlined,
                items: (data['projects'] as List).cast<Map<String, dynamic>>(),
                onRestore: (item) => _restore(context, ref, item),
                onDeleteForever: (item) => _deleteForever(context, ref, item),
              ),
              _TrashSection(
                title: 'Requests',
                icon: Icons.assignment_outlined,
                items: (data['requests'] as List).cast<Map<String, dynamic>>(),
                onRestore: (item) => _restore(context, ref, item),
                onDeleteForever: (item) => _deleteForever(context, ref, item),
              ),
              _TrashSection(
                title: 'Notes',
                icon: Icons.note_outlined,
                items: (data['notes'] as List).cast<Map<String, dynamic>>(),
                onRestore: (item) => _restore(context, ref, item),
                onDeleteForever: (item) => _deleteForever(context, ref, item),
              ),
              _TrashSection(
                title: 'Emails',
                icon: Icons.mail_outline,
                items: (data['emails'] as List).cast<Map<String, dynamic>>(),
                onRestore: (item) => _restore(context, ref, item),
                onDeleteForever: (item) => _deleteForever(context, ref, item),
              ),
            ],
          );
        },
      ),
    );
  }

  int _totalCount(Map<String, dynamic> data) =>
      (data['projects'] as List).length +
      (data['requests'] as List).length +
      (data['notes'] as List).length +
      (data['emails'] as List).length;

  Future<void> _restore(BuildContext context, WidgetRef ref, Map<String, dynamic> item) async {
    try {
      await restoreTrashItem(item['type'] as String, item['id'] as String);
      ref.invalidate(trashProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('"${item['name']}" restored'),
          backgroundColor: AppColors.successGreen,
          duration: const Duration(seconds: 2),
        ));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to restore: $e'),
          backgroundColor: AppColors.errorRed,
        ));
      }
    }
  }

  Future<void> _deleteForever(BuildContext context, WidgetRef ref, Map<String, dynamic> item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.warmWhite,
        title: Text('Delete forever?', style: AppTypography.headingMedium),
        content: Text(
          '"${item['name']}" will be permanently deleted and cannot be recovered.',
          style: AppTypography.bodyMedium,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel', style: AppTypography.labelLarge.copyWith(color: AppColors.mutedBlueGray))),
          TextButton(onPressed: () => Navigator.pop(context, true),
              child: Text('Delete', style: AppTypography.labelLarge.copyWith(color: AppColors.errorRed))),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await permanentlyDelete(item['type'] as String, item['id'] as String);
      ref.invalidate(trashProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('"${item['name']}" permanently deleted'),
          backgroundColor: AppColors.deepCharcoal,
          duration: const Duration(seconds: 2),
        ));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed: $e'),
          backgroundColor: AppColors.errorRed,
        ));
      }
    }
  }

  void _confirmEmptyTrash(BuildContext context, WidgetRef ref, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.warmWhite,
        title: Text('Empty trash?', style: AppTypography.headingMedium),
        content: Text('All ${_totalCount(data)} items will be permanently deleted.',
            style: AppTypography.bodyMedium),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: AppTypography.labelLarge.copyWith(color: AppColors.mutedBlueGray))),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _emptyAll(context, ref, data);
            },
            child: Text('Empty', style: AppTypography.labelLarge.copyWith(color: AppColors.errorRed)),
          ),
        ],
      ),
    );
  }

  Future<void> _emptyAll(BuildContext context, WidgetRef ref, Map<String, dynamic> data) async {
    for (final section in ['projects', 'requests', 'notes', 'emails']) {
      for (final item in (data[section] as List).cast<Map<String, dynamic>>()) {
        await permanentlyDelete(item['type'] as String, item['id'] as String);
      }
    }
    ref.invalidate(trashProvider);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Trash emptied'),
        backgroundColor: AppColors.deepCharcoal,
        duration: Duration(seconds: 2),
      ));
    }
  }
}

// ── Section ──────────────────────────────────────────────────────────────────

class _TrashSection extends StatelessWidget {
  const _TrashSection({
    required this.title,
    required this.icon,
    required this.items,
    required this.onRestore,
    required this.onDeleteForever,
  });

  final String title;
  final IconData icon;
  final List<Map<String, dynamic>> items;
  final void Function(Map<String, dynamic>) onRestore;
  final void Function(Map<String, dynamic>) onDeleteForever;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.only(bottom: 8, top: 8),
        child: Row(children: [
          Icon(icon, size: 16, color: AppColors.mutedBlueGray),
          const SizedBox(width: 6),
          Text(title.toUpperCase(),
              style: AppTypography.labelSmall.copyWith(letterSpacing: 1.2)),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.sandBeige,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text('${items.length}', style: AppTypography.labelSmall),
          ),
        ]),
      ),
      ...items.map((item) => _TrashItem(
        item: item,
        onRestore: () => onRestore(item),
        onDeleteForever: () => onDeleteForever(item),
      )),
      const SizedBox(height: 8),
    ]);
  }
}

// ── Item card ─────────────────────────────────────────────────────────────────

class _TrashItem extends StatelessWidget {
  const _TrashItem({required this.item, required this.onRestore, required this.onDeleteForever});

  final Map<String, dynamic> item;
  final VoidCallback onRestore;
  final VoidCallback onDeleteForever;

  @override
  Widget build(BuildContext context) {
    final deletedAt = item['deleted_at'] != null
        ? DateTime.tryParse(item['deleted_at'] as String)
        : null;
    final subtitle = item['client_name'] as String? ??
        item['unit_name'] as String? ??
        item['content'] as String? ??
        item['recipient_email'] as String? ??
        '';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(blurRadius: 8, offset: Offset(0, 2), color: Color(0x08000000))],
      ),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(item['name'] as String? ?? '',
              style: AppTypography.labelLarge,
              maxLines: 1, overflow: TextOverflow.ellipsis),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(subtitle,
                style: AppTypography.bodyMedium.copyWith(color: AppColors.mutedBlueGray, fontSize: 12),
                maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
          if (deletedAt != null) ...[
            const SizedBox(height: 4),
            Text('Deleted ${DateFormat('MMM d, yyyy').format(deletedAt)}',
                style: AppTypography.labelSmall.copyWith(color: AppColors.mutedBlueGray)),
          ],
        ])),
        const SizedBox(width: 8),
        // Restore button
        IconButton(
          tooltip: 'Restore',
          icon: const Icon(Icons.restore_outlined, size: 20, color: AppColors.successGreen),
          onPressed: onRestore,
        ),
        // Delete forever button
        IconButton(
          tooltip: 'Delete forever',
          icon: const Icon(Icons.delete_forever_outlined, size: 20, color: AppColors.errorRed),
          onPressed: onDeleteForever,
        ),
      ]),
    );
  }
}
