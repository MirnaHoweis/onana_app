import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/enums.dart';
import '../../core/api/api_client.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/loading_shimmer.dart';
import '../../core/widgets/swipe_to_delete.dart';
import '../trash/trash_providers.dart';
import '../projects/models/project_model.dart';
import '../projects/models/unit_model.dart';
import '../projects/projects_providers.dart';
import 'models/request_model.dart';
import 'requests_providers.dart';
import 'widgets/request_card.dart';
import 'widgets/stage_filter_tabs.dart';

final _stageFilterProvider = StateProvider<PipelineStage?>((ref) => null);

class RequestsScreen extends ConsumerWidget {
  const RequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(requestsProvider);
    final stageFilter = ref.watch(_stageFilterProvider);

    return Scaffold(
      backgroundColor: AppColors.warmWhite,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text('Requests', style: AppTypography.headingMedium),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh_outlined),
                    color: AppColors.mutedBlueGray,
                    onPressed: () => ref.invalidate(requestsProvider),
                  ),
                ],
              ),
            ),
            requestsAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (requests) => StageFilterTabs(
                selected: stageFilter,
                onChanged: (s) =>
                    ref.read(_stageFilterProvider.notifier).state = s,
                counts: _buildCounts(requests),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: requestsAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(16),
                  child: LoadingShimmer(itemCount: 5),
                ),
                error: (e, _) => _RequestsError(
                  onRetry: () => ref.invalidate(requestsProvider),
                ),
                data: (requests) {
                  final filtered = stageFilter == null
                      ? requests
                      : requests
                          .where((r) => r.status == stageFilter)
                          .toList();

                  if (filtered.isEmpty) {
                    return EmptyState(
                      title: 'No requests',
                      subtitle: stageFilter == null
                          ? 'Tap + to create a request.'
                          : 'No requests at this stage.',
                      icon: Icons.assignment_outlined,
                    );
                  }

                  return RefreshIndicator(
                    color: AppColors.softGold,
                    onRefresh: () =>
                        ref.read(requestsProvider.notifier).refresh(),
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, i) {
                        final r = filtered[i];
                        return SwipeToDelete(
                          itemKey: ValueKey(r.id),
                          onDelete: () async {
                            final container = ProviderScope.containerOf(context);
                            final messenger = ScaffoldMessenger.of(context);
                            await ApiClient.instance.delete('/requests/${r.id}');
                            container.invalidate(requestsProvider);
                            messenger.showSnackBar(SnackBar(
                              content: Text('"${r.title}" moved to Trash'),
                              backgroundColor: AppColors.deepCharcoal,
                              duration: const Duration(seconds: 3),
                              action: SnackBarAction(
                                label: 'Undo',
                                textColor: AppColors.softGold,
                                onPressed: () async {
                                  await restoreTrashItem('request', r.id);
                                  container.invalidate(requestsProvider);
                                },
                              ),
                            ));
                          },
                          child: RequestCard(
                            request: r,
                            onTap: () => context.go('/requests/${r.id}'),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.softGold,
        foregroundColor: AppColors.deepCharcoal,
        onPressed: () => _showCreateSheet(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  Map<PipelineStage?, int> _buildCounts(List<RequestModel> requests) {
    final counts = <PipelineStage?, int>{null: requests.length};
    for (final r in requests) {
      counts[r.status] = (counts[r.status] ?? 0) + 1;
    }
    return counts;
  }

  void _showCreateSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _CreateRequestSheet(),
    );
  }
}

// ── Create request sheet ───────────────────────────────────────────────────

class _CreateRequestSheet extends ConsumerStatefulWidget {
  const _CreateRequestSheet();

  @override
  ConsumerState<_CreateRequestSheet> createState() =>
      _CreateRequestSheetState();
}

class _CreateRequestSheetState extends ConsumerState<_CreateRequestSheet> {
  final _titleController = TextEditingController();
  ProjectModel? _selectedProject;
  UnitModel? _selectedUnit;
  RequestCategory _category = RequestCategory.furniture;
  RequestPriority _priority = RequestPriority.medium;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final projectsAsync = ref.watch(projectsProvider);
    final unitsAsync = _selectedProject != null
        ? ref.watch(unitsProvider(_selectedProject!.id))
        : null;

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
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('New Request', style: AppTypography.headingMedium),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Project picker ──────────────────────────────────────────
            projectsAsync.when(
              loading: () => const LinearProgressIndicator(
                  color: AppColors.softGold, minHeight: 2),
              error: (e, _) => Text('Could not load projects',
                  style: AppTypography.bodyMedium
                      .copyWith(color: AppColors.errorRed)),
              data: (projects) {
                if (projects.isEmpty) {
                  return Text(
                    'No projects found. Create a project first.',
                    style: AppTypography.bodyMedium
                        .copyWith(color: AppColors.mutedBlueGray),
                  );
                }
                return _PickerRow(
                  label: 'Project',
                  hint: 'Select project',
                  value: _selectedProject,
                  items: projects,
                  labelOf: (p) => p.name,
                  onChanged: (p) => setState(() {
                    _selectedProject = p;
                    _selectedUnit = null;
                  }),
                );
              },
            ),

            // ── Unit picker (appears once project is chosen) ───────────
            if (_selectedProject != null) ...[
              const SizedBox(height: 12),
              unitsAsync!.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: LinearProgressIndicator(
                      color: AppColors.softGold, minHeight: 2),
                ),
                error: (e, _) => Text('Could not load units',
                    style: AppTypography.bodyMedium
                        .copyWith(color: AppColors.errorRed)),
                data: (units) {
                  if (units.isEmpty) {
                    return Text(
                      'No units in this project. Add a unit first.',
                      style: AppTypography.bodyMedium
                          .copyWith(color: AppColors.mutedBlueGray),
                    );
                  }
                  return _PickerRow(
                    label: 'Unit',
                    hint: 'Select unit',
                    value: _selectedUnit,
                    items: units,
                    labelOf: (u) => u.name,
                    onChanged: (u) => setState(() => _selectedUnit = u),
                  );
                },
              ),
            ],

            const SizedBox(height: 12),
            TextField(
              controller: _titleController,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Title'),
              style: AppTypography.bodyMedium,
            ),
            const SizedBox(height: 12),
            _DropdownRow<RequestCategory>(
              label: 'Category',
              value: _category,
              items: RequestCategory.values,
              labelOf: (c) => c.name[0].toUpperCase() + c.name.substring(1),
              onChanged: (v) => setState(() => _category = v),
            ),
            const SizedBox(height: 12),
            _DropdownRow<RequestPriority>(
              label: 'Priority',
              value: _priority,
              items: RequestPriority.values,
              labelOf: (p) => p.name[0].toUpperCase() + p.name.substring(1),
              onChanged: (v) => setState(() => _priority = v),
            ),

            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!,
                  style: AppTypography.bodyMedium
                      .copyWith(color: AppColors.errorRed)),
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
                    : Text('Create', style: AppTypography.labelLarge),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      setState(() => _error = 'Please enter a title.');
      return;
    }
    if (_selectedProject == null) {
      setState(() => _error = 'Please select a project.');
      return;
    }
    if (_selectedUnit == null) {
      setState(() => _error = 'Please select a unit.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(requestsProvider.notifier).create(
            unitId: _selectedUnit!.id,
            title: title,
            category: _category,
            priority: _priority,
          );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Failed to create request. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

class _DropdownRow<T> extends StatelessWidget {
  const _DropdownRow({
    required this.label,
    required this.value,
    required this.items,
    required this.labelOf,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<T> items;
  final String Function(T) labelOf;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(label, style: AppTypography.labelSmall),
        ),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.sandBeige,
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<T>(
                value: value,
                isExpanded: true,
                style: AppTypography.bodyMedium,
                items: items
                    .map((i) => DropdownMenuItem(
                          value: i,
                          child: Text(labelOf(i)),
                        ))
                    .toList(),
                onChanged: (v) {
                  if (v != null) onChanged(v);
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Nullable-value dropdown used for project and unit pickers.
class _PickerRow<T> extends StatelessWidget {
  const _PickerRow({
    required this.label,
    required this.hint,
    required this.value,
    required this.items,
    required this.labelOf,
    required this.onChanged,
  });

  final String label;
  final String hint;
  final T? value;
  final List<T> items;
  final String Function(T) labelOf;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(label, style: AppTypography.labelSmall),
        ),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.sandBeige,
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<T>(
                value: value,
                hint: Text(hint, style: AppTypography.bodyMedium
                    .copyWith(color: AppColors.mutedBlueGray)),
                isExpanded: true,
                style: AppTypography.bodyMedium,
                items: items
                    .map((i) => DropdownMenuItem(
                          value: i,
                          child: Text(labelOf(i)),
                        ))
                    .toList(),
                onChanged: (v) {
                  if (v != null) onChanged(v);
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _RequestsError extends StatelessWidget {
  const _RequestsError({required this.onRetry});
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
          Text('Could not load requests',
              style: AppTypography.headingMedium),
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
