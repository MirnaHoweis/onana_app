import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/enums.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/loading_shimmer.dart';
import '../../core/widgets/section_header.dart';
import 'models/project_model.dart';
import 'projects_providers.dart';
import 'widgets/project_status_badge.dart';
import 'widgets/unit_list_tile.dart';

class ProjectDetailScreen extends ConsumerWidget {
  const ProjectDetailScreen({super.key, required this.projectId});

  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectAsync = ref.watch(projectProvider(projectId));
    final unitsAsync = ref.watch(unitsProvider(projectId));

    return Scaffold(
      backgroundColor: AppColors.warmWhite,
      body: projectAsync.when(
        loading: () => const _DetailShimmer(),
        error: (e, _) => _DetailError(
          onRetry: () => ref.invalidate(projectProvider(projectId)),
        ),
        data: (project) => CustomScrollView(
          slivers: [
            SliverAppBar(
              backgroundColor: AppColors.warmWhite,
              surfaceTintColor: Colors.transparent,
              pinned: true,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                color: AppColors.deepCharcoal,
                onPressed: () => context.pop(),
              ),
              title: Text(project.name, style: AppTypography.headingMedium),
              actions: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  color: AppColors.mutedBlueGray,
                  onPressed: () {},
                ),
                const SizedBox(width: 4),
              ],
            ),
            SliverToBoxAdapter(
              child: _ProjectInfoCard(project: project),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
              sliver: SliverToBoxAdapter(
                child: SectionHeader(
                  title: 'Units',
                  subtitle: unitsAsync.maybeWhen(
                    data: (u) => '${u.length} unit${u.length == 1 ? '' : 's'}',
                    orElse: () => null,
                  ),
                  trailing: TextButton.icon(
                    onPressed: () => _showAddUnitSheet(context, ref, projectId),
                    icon: const Icon(Icons.add, size: 16,
                        color: AppColors.softGold),
                    label: Text(
                      'Add',
                      style: AppTypography.labelLarge
                          .copyWith(color: AppColors.softGold),
                    ),
                  ),
                ),
              ),
            ),
            unitsAsync.when(
              loading: () => const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: LoadingShimmer(itemCount: 3),
                ),
              ),
              error: (e, _) => SliverToBoxAdapter(
                child: _DetailError(
                  onRetry: () => ref.invalidate(unitsProvider(projectId)),
                ),
              ),
              data: (units) => units.isEmpty
                  ? const SliverToBoxAdapter(
                      child: EmptyState(
                        title: 'No units yet',
                        subtitle: 'Add a unit to start tracking requests.',
                        icon: Icons.apartment_outlined,
                      ),
                    )
                  : SliverPadding(
                      padding:
                          const EdgeInsets.fromLTRB(16, 0, 16, 80),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, i) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: UnitListTile(
                              unit: units[i],
                              onTap: () => context.go(
                                '/projects/$projectId/units/${units[i].id}',
                              ),
                              onDelete: () async {
                                await ref
                                    .read(unitsProvider(projectId).notifier)
                                    .delete(units[i].id);
                              },
                            ),
                          ),
                          childCount: units.length,
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

void _showAddUnitSheet(BuildContext context, WidgetRef ref, String projectId) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _AddUnitSheet(projectId: projectId),
  );
}

class _AddUnitSheet extends ConsumerStatefulWidget {
  const _AddUnitSheet({required this.projectId});
  final String projectId;

  @override
  ConsumerState<_AddUnitSheet> createState() => _AddUnitSheetState();
}

class _AddUnitSheetState extends ConsumerState<_AddUnitSheet> {
  final _nameCtrl = TextEditingController();
  final _floorCtrl = TextEditingController();
  final _blockCtrl = TextEditingController();
  UnitType _type = UnitType.apartment;
  bool _loading = false;
  String? _error;

  static const _typeLabels = {
    UnitType.villa: 'Villa',
    UnitType.apartment: 'Apartment',
    UnitType.commercial: 'Commercial',
  };

  static String _typeApi(UnitType t) {
    const map = {
      UnitType.villa: 'VILLA',
      UnitType.apartment: 'APARTMENT',
      UnitType.commercial: 'COMMERCIAL',
    };
    return map[t]!;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _floorCtrl.dispose();
    _blockCtrl.dispose();
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
        24, 24, 24,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Add Unit', style: AppTypography.headingMedium),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameCtrl,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Unit Name *'),
              style: AppTypography.bodyMedium,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                SizedBox(
                  width: 80,
                  child: Text('Type', style: AppTypography.labelSmall),
                ),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.sandBeige,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<UnitType>(
                        value: _type,
                        isExpanded: true,
                        style: AppTypography.bodyMedium,
                        items: UnitType.values
                            .map((t) => DropdownMenuItem(
                                  value: t,
                                  child: Text(_typeLabels[t]!),
                                ))
                            .toList(),
                        onChanged: (v) {
                          if (v != null) setState(() => _type = v);
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _floorCtrl,
              decoration: const InputDecoration(labelText: 'Floor (optional)'),
              style: AppTypography.bodyMedium,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _blockCtrl,
              decoration: const InputDecoration(labelText: 'Block (optional)'),
              style: AppTypography.bodyMedium,
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(
                _error!,
                style: AppTypography.bodyMedium
                    .copyWith(color: AppColors.errorRed),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.deepCharcoal,
                        ),
                      )
                    : Text('Add Unit', style: AppTypography.labelLarge),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Unit name is required.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(unitsProvider(widget.projectId).notifier).create(
            name: name,
            type: _typeApi(_type),
            floor: _floorCtrl.text.trim(),
            block: _blockCtrl.text.trim(),
          );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) setState(() => _error = 'Failed to add unit. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

class _ProjectInfoCard extends StatelessWidget {
  const _ProjectInfoCard({required this.project});

  final ProjectModel project;

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('MMM d, yyyy');
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
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
          Row(
            children: [
              Expanded(
                child: Text(project.name, style: AppTypography.headingLarge),
              ),
              ProjectStatusBadge(status: project.status),
            ],
          ),
          if (project.clientName != null) ...[
            const SizedBox(height: 8),
            _InfoRow(
              icon: Icons.person_outline,
              label: project.clientName!,
            ),
          ],
          if (project.location != null) ...[
            const SizedBox(height: 4),
            _InfoRow(
              icon: Icons.location_on_outlined,
              label: project.location!,
            ),
          ],
          if (project.startDate != null || project.endDate != null) ...[
            const SizedBox(height: 4),
            _InfoRow(
              icon: Icons.calendar_today_outlined,
              label: [
                if (project.startDate != null) fmt.format(project.startDate!),
                if (project.endDate != null) fmt.format(project.endDate!),
              ].join(' → '),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.mutedBlueGray),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            style: AppTypography.bodyMedium
                .copyWith(color: AppColors.mutedBlueGray),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _DetailShimmer extends StatelessWidget {
  const _DetailShimmer();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: LoadingShimmer(itemCount: 5),
    );
  }
}

class _DetailError extends StatelessWidget {
  const _DetailError({required this.onRetry});
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
          Text('Could not load data', style: AppTypography.headingMedium),
          const SizedBox(height: 24),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, color: AppColors.softGold),
            label: Text(
              'Retry',
              style: AppTypography.labelLarge
                  .copyWith(color: AppColors.softGold),
            ),
          ),
        ],
      ),
    );
  }
}
