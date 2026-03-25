import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/loading_shimmer.dart';
import 'email_providers.dart';
import 'models/email_draft_model.dart';
import 'widgets/compose_email_sheet.dart';

class EmailScreen extends ConsumerWidget {
  const EmailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draftsAsync = ref.watch(emailDraftsProvider);

    return Scaffold(
      backgroundColor: AppColors.warmWhite,
      appBar: AppBar(
        backgroundColor: AppColors.warmWhite,
        elevation: 0,
        title: Text('Email Drafts', style: AppTypography.headingMedium),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            color: AppColors.mutedBlueGray,
            onPressed: () =>
                ref.read(emailDraftsProvider.notifier).refresh(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.softGold,
        foregroundColor: AppColors.deepCharcoal,
        onPressed: () => _openCompose(context),
        child: const Icon(Icons.edit_outlined),
      ),
      body: draftsAsync.when(
        loading: () => const LoadingShimmer(),
        error: (e, _) => Center(
          child: Text('Error: $e', style: AppTypography.bodyMedium),
        ),
        data: (drafts) {
          if (drafts.isEmpty) {
            return const EmptyState(
              icon: Icons.mail_outline,
              title: 'No drafts yet',
              subtitle: 'Tap + to compose your first email',
            );
          }
          final sent = drafts.where((d) => d.isSent).toList();
          final unsent = drafts.where((d) => !d.isSent).toList();
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
            children: [
              if (unsent.isNotEmpty) ...[
                _SectionLabel('Drafts (${unsent.length})'),
                const SizedBox(height: 8),
                ...unsent.map((d) => _DraftCard(draft: d)),
              ],
              if (sent.isNotEmpty) ...[
                const SizedBox(height: 20),
                _SectionLabel('Sent (${sent.length})'),
                const SizedBox(height: 8),
                ...sent.map((d) => _DraftCard(draft: d)),
              ],
            ],
          );
        },
      ),
    );
  }

  void _openCompose(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const ComposeEmailSheet(),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTypography.labelSmall.copyWith(color: AppColors.mutedBlueGray),
    );
  }
}

class _DraftCard extends ConsumerWidget {
  const _DraftCard({required this.draft});
  final EmailDraftModel draft;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _RecipientChip(draft.recipientTypeLabel),
                const Spacer(),
                if (draft.isSent)
                  const Icon(Icons.check_circle_outline,
                      size: 16, color: AppColors.successGreen)
                else
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert,
                        size: 18, color: AppColors.mutedBlueGray),
                    onSelected: (v) => _onMenu(context, ref, v),
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                          value: 'send', child: Text('Send')),
                      const PopupMenuItem(
                          value: 'delete', child: Text('Delete')),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(draft.subject, style: AppTypography.labelLarge),
            const SizedBox(height: 4),
            Text(
              draft.body,
              style: AppTypography.bodyMedium
                  .copyWith(color: AppColors.mutedBlueGray),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (draft.recipientEmail != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.email_outlined,
                      size: 14, color: AppColors.mutedBlueGray),
                  const SizedBox(width: 4),
                  Text(
                    draft.recipientEmail!,
                    style: AppTypography.bodyMedium
                        .copyWith(color: AppColors.mutedBlueGray),
                  ),
                ],
              ),
            ],
            if (draft.isSent && draft.sentAt != null) ...[
              const SizedBox(height: 6),
              Text(
                'Sent ${_formatDate(draft.sentAt!)}',
                style: AppTypography.bodyMedium
                    .copyWith(color: AppColors.successGreen),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _onMenu(
      BuildContext context, WidgetRef ref, String action) async {
    if (action == 'delete') {
      await ref.read(emailDraftsProvider.notifier).delete(draft.id);
    } else if (action == 'send') {
      _showSendDialog(context, ref);
    }
  }

  void _showSendDialog(BuildContext context, WidgetRef ref) {
    final ctrl = TextEditingController(text: draft.recipientEmail ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Send Email'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
            labelText: 'To',
            hintText: 'email@example.com',
          ),
          keyboardType: TextInputType.emailAddress,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref
                    .read(emailDraftsProvider.notifier)
                    .sendDraft(draft.id, toEmail: ctrl.text.trim());
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Send failed: $e')),
                  );
                }
              }
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

class _RecipientChip extends StatelessWidget {
  const _RecipientChip(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.softGold.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: AppTypography.labelSmall.copyWith(color: AppColors.softGold),
      ),
    );
  }
}
