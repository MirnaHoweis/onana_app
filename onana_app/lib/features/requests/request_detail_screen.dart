import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/enums.dart';
import '../../core/widgets/loading_shimmer.dart';
import '../../core/widgets/pipeline_stepper.dart';
import '../../core/widgets/section_header.dart';
import 'models/history_entry_model.dart';
import 'models/request_model.dart';
import 'requests_providers.dart';
import 'widgets/priority_badge.dart';

class RequestDetailScreen extends ConsumerWidget {
  const RequestDetailScreen({super.key, required this.requestId});

  final String requestId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestAsync = ref.watch(requestProvider(requestId));

    return Scaffold(
      backgroundColor: AppColors.warmWhite,
      body: requestAsync.when(
        loading: () => const _Shimmer(),
        error: (e, _) => _Error(
          onRetry: () => ref.invalidate(requestProvider(requestId)),
        ),
        data: (request) => CustomScrollView(
          slivers: [
            _AppBar(request: request),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: _InfoCard(request: request),
              ),
            ),
            const SliverPadding(
              padding: EdgeInsets.fromLTRB(16, 24, 16, 12),
              sliver: SliverToBoxAdapter(
                child: SectionHeader(title: 'Pipeline Stage'),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _PipelineCard(
                  request: request,
                  onStageTap: (stage) =>
                      _showStageUpdateSheet(context, ref, request, stage),
                ),
              ),
            ),
            if (request.poNumber != null || request.supplierName != null) ...[
              const SliverPadding(
                padding: EdgeInsets.fromLTRB(16, 24, 16, 12),
                sliver: SliverToBoxAdapter(
                  child: SectionHeader(title: 'Purchase Order'),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                  child: _PoCard(request: request),
                ),
              ),
            ],
            const SliverPadding(
              padding: EdgeInsets.fromLTRB(16, 24, 16, 12),
              sliver: SliverToBoxAdapter(
                child: SectionHeader(title: 'Status History'),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
              sliver: SliverToBoxAdapter(
                child: _HistoryTable(requestId: request.id),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showStageUpdateSheet(
    BuildContext context,
    WidgetRef ref,
    RequestModel request,
    PipelineStage tappedStage,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _StageUpdateSheet(
        request: request,
        targetStage: tappedStage,
        onConfirm: (stage, notes) async {
          await ref
              .read(requestProvider(request.id).notifier)
              .updateStatus(stage, notes: notes);
          ref.invalidate(requestsProvider);
          ref.invalidate(requestHistoryProvider(request.id));
        },
      ),
    );
  }
}

// ── App bar ────────────────────────────────────────────────────────────────

class _AppBar extends StatelessWidget {
  const _AppBar({required this.request});
  final RequestModel request;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      backgroundColor: AppColors.warmWhite,
      surfaceTintColor: Colors.transparent,
      pinned: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, size: 18),
        color: AppColors.deepCharcoal,
        onPressed: () => context.pop(),
      ),
      title: Text(request.title, style: AppTypography.headingMedium),
      actions: [
        PriorityBadge(priority: request.priority),
        const SizedBox(width: 16),
      ],
    );
  }
}

// ── Info card ──────────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.request});
  final RequestModel request;

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('MMM d, yyyy');
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            blurRadius: 16,
            offset: Offset(0, 4),
            color: Color(0x0A000000),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (request.projectName != null || request.unitName != null)
            _Row(
              icon: Icons.apartment_outlined,
              label: [
                if (request.projectName != null) request.projectName!,
                if (request.unitName != null) request.unitName!,
              ].join(' › '),
            ),
          if (request.description != null) ...[
            const SizedBox(height: 8),
            Text(
              request.description!,
              style: AppTypography.bodyMedium
                  .copyWith(color: AppColors.mutedBlueGray),
            ),
          ],
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          _Row(
            icon: Icons.category_outlined,
            label: request.category.name[0].toUpperCase() +
                request.category.name.substring(1),
          ),
          const SizedBox(height: 6),
          _Row(
            icon: Icons.calendar_today_outlined,
            label: 'Created ${fmt.format(request.createdAt)}',
          ),
          if (request.expectedDeliveryDate != null) ...[
            const SizedBox(height: 6),
            _Row(
              icon: Icons.local_shipping_outlined,
              label:
                  'Expected delivery: ${fmt.format(request.expectedDeliveryDate!)}',
            ),
          ],
          if (request.actualDeliveryDate != null) ...[
            const SizedBox(height: 6),
            _Row(
              icon: Icons.check_circle_outline,
              label:
                  'Delivered: ${fmt.format(request.actualDeliveryDate!)}',
              color: AppColors.successGreen,
            ),
          ],
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.icon, required this.label, this.color});
  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.mutedBlueGray;
    return Row(
      children: [
        Icon(icon, size: 14, color: c),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: AppTypography.bodyMedium.copyWith(color: c),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ── Pipeline card ──────────────────────────────────────────────────────────

class _PipelineCard extends StatelessWidget {
  const _PipelineCard({required this.request, required this.onStageTap});
  final RequestModel request;
  final void Function(PipelineStage) onStageTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            blurRadius: 16,
            offset: Offset(0, 4),
            color: Color(0x0A000000),
          ),
        ],
      ),
      child: PipelineStepper(
        currentStage: request.status,
        onStageTap: onStageTap,
      ),
    );
  }
}

// ── PO card ────────────────────────────────────────────────────────────────

class _PoCard extends StatelessWidget {
  const _PoCard({required this.request});
  final RequestModel request;

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('MMM d, yyyy');
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            blurRadius: 16,
            offset: Offset(0, 4),
            color: Color(0x0A000000),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (request.supplierName != null)
            _Row(icon: Icons.storefront_outlined, label: request.supplierName!),
          if (request.poNumber != null) ...[
            const SizedBox(height: 8),
            _Row(icon: Icons.receipt_outlined, label: 'PO# ${request.poNumber!}'),
          ],
          if (request.poDate != null) ...[
            const SizedBox(height: 8),
            _Row(
              icon: Icons.calendar_today_outlined,
              label: 'PO Date: ${fmt.format(request.poDate!)}',
            ),
          ],
        ],
      ),
    );
  }
}

// ── Stage update sheet ─────────────────────────────────────────────────────

class _StageUpdateSheet extends ConsumerStatefulWidget {
  const _StageUpdateSheet({
    required this.request,
    required this.targetStage,
    required this.onConfirm,
  });
  final RequestModel request;
  final PipelineStage targetStage;
  final Future<void> Function(PipelineStage stage, String? notes) onConfirm;

  @override
  ConsumerState<_StageUpdateSheet> createState() => _StageUpdateSheetState();
}

class _StageUpdateSheetState extends ConsumerState<_StageUpdateSheet> {
  late PipelineStage _selected;
  final _notesController = TextEditingController();
  bool _loading = false;

  static const _stageLabels = {
    PipelineStage.materialRequest: 'Material Request',
    PipelineStage.poRequested: 'PO Requested',
    PipelineStage.poCreated: 'PO Created',
    PipelineStage.delivery: 'Delivery',
    PipelineStage.storekeeperConfirmed: 'Storekeeper Confirmed',
    PipelineStage.installationInProgress: 'Installation In Progress',
    PipelineStage.installationComplete: 'Installation Complete',
  };

  @override
  void initState() {
    super.initState();
    _selected = widget.targetStage;
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.warmWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Update Stage', style: AppTypography.headingMedium),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            widget.request.title,
            style: AppTypography.bodyMedium
                .copyWith(color: AppColors.mutedBlueGray),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.sandBeige,
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<PipelineStage>(
                value: _selected,
                isExpanded: true,
                style: AppTypography.bodyMedium,
                items: PipelineStage.values
                    .map((s) => DropdownMenuItem(
                          value: s,
                          child: Text(_stageLabels[s]!),
                        ))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _selected = v);
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notesController,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Notes (optional)',
            ),
            style: AppTypography.bodyMedium,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _loading ? null : _confirm,
              child: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.deepCharcoal,
                      ),
                    )
                  : Text('Confirm', style: AppTypography.labelLarge),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirm() async {
    setState(() => _loading = true);
    try {
      final notes = _notesController.text.trim();
      await widget.onConfirm(_selected, notes.isEmpty ? null : notes);
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

// ── Status history table ────────────────────────────────────────────────────

class _HistoryTable extends ConsumerWidget {
  const _HistoryTable({required this.requestId});
  final String requestId;

  static const _cols = ['Date & Time', 'From', 'To', 'Changed By', 'Notes'];
  static const _flex  = [3, 2, 2, 2, 3];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(requestHistoryProvider(requestId));

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            blurRadius: 16,
            offset: Offset(0, 4),
            color: Color(0x0A000000),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header row
          Container(
            color: AppColors.sandBeige,
            child: Row(
              children: List.generate(_cols.length, (i) => Expanded(
                flex: _flex[i],
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 10),
                  child: Text(
                    _cols[i],
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.mutedBlueGray,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              )),
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),
          historyAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(20),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.softGold,
                  ),
                ),
              ),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(20),
              child: Text('Could not load history',
                  style: AppTypography.bodyMedium
                      .copyWith(color: AppColors.mutedBlueGray)),
            ),
            data: (entries) {
              if (entries.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    'No status changes recorded yet.',
                    style: AppTypography.bodyMedium
                        .copyWith(color: AppColors.mutedBlueGray),
                  ),
                );
              }
              return Column(
                children: List.generate(entries.length, (i) {
                  final e = entries[i];
                  final isEven = i.isEven;
                  return Container(
                    color: isEven
                        ? AppColors.cardSurface
                        : AppColors.warmWhite,
                    child: Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Date & Time
                            Expanded(
                              flex: _flex[0],
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 10),
                                child: Text(
                                  _fmt(e.createdAt),
                                  style: AppTypography.labelSmall,
                                ),
                              ),
                            ),
                            // From
                            Expanded(
                              flex: _flex[1],
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 10),
                                child: Text(
                                  e.fromStatus ?? '—',
                                  style: AppTypography.bodyMedium.copyWith(
                                    fontSize: 11,
                                    color: AppColors.mutedBlueGray,
                                  ),
                                ),
                              ),
                            ),
                            // To
                            Expanded(
                              flex: _flex[2],
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 10),
                                child: Text(
                                  e.toStatus,
                                  style: AppTypography.labelSmall.copyWith(
                                    color: AppColors.softGold,
                                  ),
                                ),
                              ),
                            ),
                            // Changed By
                            Expanded(
                              flex: _flex[3],
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 10),
                                child: Text(
                                  e.changedByName,
                                  style: AppTypography.labelSmall,
                                ),
                              ),
                            ),
                            // Notes
                            Expanded(
                              flex: _flex[4],
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 10),
                                child: Text(
                                  e.notes ?? '—',
                                  style: AppTypography.bodyMedium.copyWith(
                                    fontSize: 11,
                                    color: AppColors.mutedBlueGray,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (i < entries.length - 1)
                          const Divider(
                              height: 1, color: AppColors.divider),
                      ],
                    ),
                  );
                }),
              );
            },
          ),
        ],
      ),
    );
  }

  String _fmt(DateTime dt) {
    final d = dt.toLocal();
    final date =
        '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    final time =
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    return '$date\n$time';
  }
}

// ── Loading / error ────────────────────────────────────────────────────────

class _Shimmer extends StatelessWidget {
  const _Shimmer();

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.all(16),
        child: LoadingShimmer(itemCount: 5),
      );
}

class _Error extends StatelessWidget {
  const _Error({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_outlined,
              size: 48, color: AppColors.mutedBlueGray),
          const SizedBox(height: 16),
          Text('Could not load request',
              style: AppTypography.headingMedium),
          const SizedBox(height: 24),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, color: AppColors.softGold),
            label: Text('Retry',
                style: AppTypography.labelLarge
                    .copyWith(color: AppColors.softGold)),
          ),
        ],
      ),
    );
  }
}
