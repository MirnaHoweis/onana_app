import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/enums.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/loading_shimmer.dart';
import 'models/project_model.dart';
import 'projects_providers.dart';
import 'widgets/create_project_sheet.dart';
import 'widgets/project_card.dart';
import 'widgets/project_filter_bar.dart';
import 'widgets/project_status_badge.dart';

// Local filter state provider
final _filterProvider = StateProvider<ProjectStatus?>((ref) => null);

class ProjectsScreen extends ConsumerWidget {
  const ProjectsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectsAsync = ref.watch(projectsProvider);
    final filter = ref.watch(_filterProvider);

    return Scaffold(
      backgroundColor: AppColors.warmWhite,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Header(filter: filter, ref: ref),
            const SizedBox(height: 8),
            ProjectFilterBar(
              selected: filter,
              onChanged: (v) =>
                  ref.read(_filterProvider.notifier).state = v,
            ),
            const SizedBox(height: 12),
            Expanded(
              child: projectsAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(16),
                  child: LoadingShimmer(itemCount: 5),
                ),
                error: (e, _) => _ProjectsError(
                  onRetry: () => ref.invalidate(projectsProvider),
                ),
                data: (projects) {
                  final filtered = filter == null
                      ? projects
                      : projects
                          .where((p) => p.status == filter)
                          .toList();

                  if (filtered.isEmpty) {
                    return EmptyState(
                      title: 'No projects yet',
                      subtitle: filter == null
                          ? 'Tap + to create your first project.'
                          : 'No projects match this filter.',
                      icon: Icons.apartment_outlined,
                    );
                  }

                  return kIsWeb
                      ? _WebTable(projects: filtered)
                      : _MobileList(projects: filtered);
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.softGold,
        foregroundColor: AppColors.deepCharcoal,
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: AppColors.cardSurface,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (_) => const CreateProjectSheet(),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.filter, required this.ref});
  final ProjectStatus? filter;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: Text('Projects', style: AppTypography.headingMedium),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            color: AppColors.mutedBlueGray,
            onPressed: () => ref.invalidate(projectsProvider),
          ),
        ],
      ),
    );
  }
}

// ── Mobile list ────────────────────────────────────────────────────────────

class _MobileList extends StatelessWidget {
  const _MobileList({required this.projects});
  final List<ProjectModel> projects;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.softGold,
      onRefresh: () async =>
          ProviderScope.containerOf(context).invalidate(projectsProvider),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
        itemCount: projects.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) => ProjectCard(
          project: projects[i],
          onTap: () => context.go('/projects/${projects[i].id}'),
        ),
      ),
    );
  }
}

// ── Web table ──────────────────────────────────────────────────────────────

class _WebTable extends StatelessWidget {
  const _WebTable({required this.projects});
  final List<ProjectModel> projects;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Table(
          columnWidths: const {
            0: FlexColumnWidth(3),
            1: FlexColumnWidth(2),
            2: FlexColumnWidth(2),
            3: FlexColumnWidth(1),
            4: FixedColumnWidth(120),
          },
          children: [
            _tableHeader(),
            ...projects.map(_tableRow),
          ],
        ),
      ),
    );
  }

  TableRow _tableHeader() {
    return TableRow(
      decoration: const BoxDecoration(color: AppColors.sandBeige),
      children: ['Name', 'Client', 'Location', 'Units', 'Status']
          .map(
            (h) => Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              child: Text(h, style: AppTypography.labelSmall),
            ),
          )
          .toList(),
    );
  }

  TableRow _tableRow(ProjectModel p) {
    return TableRow(
      decoration: const BoxDecoration(
        color: AppColors.cardSurface,
        border: Border(
          bottom: BorderSide(color: AppColors.divider),
        ),
      ),
      children: [
        _cell(Text(p.name, style: AppTypography.labelLarge)),
        _cell(Text(p.clientName ?? '—', style: AppTypography.bodyMedium)),
        _cell(Text(p.location ?? '—', style: AppTypography.bodyMedium)),
        _cell(Text('${p.unitCount}', style: AppTypography.bodyMedium)),
        _cell(ProjectStatusBadge(status: p.status)),
      ],
    );
  }

  Widget _cell(Widget child) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: child,
      );
}

class _ProjectsError extends StatelessWidget {
  const _ProjectsError({required this.onRetry});
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
          Text('Could not load projects',
              style: AppTypography.headingMedium),
          const SizedBox(height: 24),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, color: AppColors.softGold),
            label: Text(
              'Retry',
              style:
                  AppTypography.labelLarge.copyWith(color: AppColors.softGold),
            ),
          ),
        ],
      ),
    );
  }
}
