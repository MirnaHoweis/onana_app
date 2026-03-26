import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/enums.dart';
import '../../core/widgets/loading_shimmer.dart';
import 'projects_providers.dart';

class ProjectDashboardScreen extends ConsumerWidget {
  const ProjectDashboardScreen({super.key, required this.projectId});
  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(projectDashboardProvider(projectId));

    return async.when(
      loading: () => const Scaffold(
        backgroundColor: AppColors.warmWhite,
        body: Padding(
          padding: EdgeInsets.all(24),
          child: LoadingShimmer(itemCount: 6),
        ),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: AppColors.warmWhite,
        appBar: AppBar(backgroundColor: AppColors.warmWhite, elevation: 0),
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.cloud_off_outlined, size: 48, color: AppColors.mutedBlueGray),
            const SizedBox(height: 16),
            Text('Could not load dashboard', style: AppTypography.headingMedium),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => ref.invalidate(projectDashboardProvider(projectId)),
              child: Text('Retry', style: AppTypography.labelLarge.copyWith(color: AppColors.softGold)),
            ),
          ]),
        ),
      ),
      data: (data) => _DashboardView(projectId: projectId, data: data),
    );
  }
}

// ── Main view ────────────────────────────────────────────────────────────────

class _DashboardView extends ConsumerStatefulWidget {
  const _DashboardView({required this.projectId, required this.data});
  final String projectId;
  final Map<String, dynamic> data;

  @override
  ConsumerState<_DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends ConsumerState<_DashboardView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final project = widget.data['project'] as Map<String, dynamic>;
    final stats = widget.data['stats'] as Map<String, dynamic>;
    final requests = (widget.data['requests'] as List).cast<Map<String, dynamic>>();
    final installations = (widget.data['installations'] as List).cast<Map<String, dynamic>>();
    final notes = (widget.data['notes'] as List).cast<Map<String, dynamic>>();
    final emails = (widget.data['emails'] as List).cast<Map<String, dynamic>>();

    final status = _parseProjectStatus(project['status'] as String?);

    return Scaffold(
      backgroundColor: AppColors.warmWhite,
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverAppBar(
            backgroundColor: AppColors.warmWhite,
            surfaceTintColor: Colors.transparent,
            pinned: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: AppColors.deepCharcoal),
              onPressed: () => context.pop(),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(project['name'] as String, style: AppTypography.headingMedium),
                if (project['client_name'] != null)
                  Text(project['client_name'] as String,
                      style: AppTypography.bodyMedium.copyWith(color: AppColors.mutedBlueGray, fontSize: 12)),
              ],
            ),
            actions: [
              _StatusChanger(projectId: widget.projectId, current: status),
              const SizedBox(width: 8),
            ],
            bottom: TabBar(
              controller: _tabs,
              labelColor: AppColors.softGold,
              unselectedLabelColor: AppColors.mutedBlueGray,
              indicatorColor: AppColors.softGold,
              indicatorSize: TabBarIndicatorSize.label,
              labelStyle: AppTypography.labelLarge,
              unselectedLabelStyle: AppTypography.bodyMedium,
              tabs: const [
                Tab(text: 'Overview'),
                Tab(text: 'Requests'),
                Tab(text: 'Installs'),
                Tab(text: 'Notes'),
                Tab(text: 'Emails'),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabs,
          children: [
            _OverviewTab(project: project, stats: stats),
            _RequestsTab(requests: requests, projectId: widget.projectId),
            _InstallationsTab(installations: installations),
            _NotesTab(notes: notes),
            _EmailsTab(emails: emails),
          ],
        ),
      ),
    );
  }
}

// ── Status changer ───────────────────────────────────────────────────────────

class _StatusChanger extends ConsumerWidget {
  const _StatusChanger({required this.projectId, required this.current});
  final String projectId;
  final ProjectStatus current;

  static const _statuses = [
    ProjectStatus.planning,
    ProjectStatus.active,
    ProjectStatus.onHold,
    ProjectStatus.completed,
  ];

  static const _labels = {
    ProjectStatus.planning: 'Planning',
    ProjectStatus.active: 'Active',
    ProjectStatus.onHold: 'On Hold',
    ProjectStatus.completed: 'Completed',
  };

  static const _colors = {
    ProjectStatus.planning: AppColors.mutedBlueGray,
    ProjectStatus.active: AppColors.successGreen,
    ProjectStatus.onHold: AppColors.warningAmber,
    ProjectStatus.completed: AppColors.softGold,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => _showPicker(context, ref),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: (_colors[current] ?? AppColors.mutedBlueGray).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(_labels[current] ?? '', style: AppTypography.labelSmall.copyWith(color: _colors[current])),
          const SizedBox(width: 4),
          Icon(Icons.expand_more, size: 14, color: _colors[current]),
        ]),
      ),
    );
  }

  void _showPicker(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.warmWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 40, height: 4,
            decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 20),
          Text('Change Status', style: AppTypography.headingMedium),
          const SizedBox(height: 16),
          ..._statuses.map((s) => ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              width: 12, height: 12,
              decoration: BoxDecoration(color: _colors[s], shape: BoxShape.circle),
            ),
            title: Text(_labels[s]!, style: AppTypography.labelLarge),
            trailing: s == current ? const Icon(Icons.check, color: AppColors.softGold, size: 18) : null,
            onTap: () async {
              Navigator.pop(context);
              await ref.read(projectsProvider.notifier).updateStatus(projectId, s);
              ref.invalidate(projectDashboardProvider(projectId));
            },
          )),
        ]),
      ),
    );
  }
}

// ── Overview tab ─────────────────────────────────────────────────────────────

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({required this.project, required this.stats});
  final Map<String, dynamic> project;
  final Map<String, dynamic> stats;

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('MMM d, yyyy');
    final startDate = project['start_date'] != null ? DateTime.tryParse(project['start_date'] as String) : null;
    final endDate = project['end_date'] != null ? DateTime.tryParse(project['end_date'] as String) : null;
    final byStatus = (stats['requests_by_status'] as Map?)?.cast<String, dynamic>() ?? {};

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Info card
        _SectionCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (project['location'] != null)
              _InfoRow(Icons.location_on_outlined, project['location'] as String),
            if (startDate != null || endDate != null)
              _InfoRow(Icons.calendar_today_outlined,
                [if (startDate != null) fmt.format(startDate), if (endDate != null) fmt.format(endDate)].join(' → ')),
          ]),
        ),
        const SizedBox(height: 16),

        // Stats grid
        Text('Summary', style: AppTypography.labelLarge),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 2.2,
          children: [
            _StatCard('Requests', '${stats['requests_total'] ?? 0}', Icons.assignment_outlined, AppColors.softGold),
            _StatCard('Installations', '${stats['installations_count'] ?? 0}', Icons.construction_outlined, AppColors.successGreen),
            _StatCard('Notes', '${stats['notes_count'] ?? 0}', Icons.note_outlined, AppColors.mutedBlueGray),
            _StatCard('Emails', '${stats['emails_count'] ?? 0}', Icons.mail_outline, AppColors.warningAmber),
          ],
        ),
        const SizedBox(height: 16),

        // Install progress
        if ((stats['installations_count'] as int? ?? 0) > 0) ...[
          Text('Installation Progress', style: AppTypography.labelLarge),
          const SizedBox(height: 10),
          _SectionCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Average completion', style: AppTypography.bodyMedium),
              Text('${stats['installations_avg_completion'] ?? 0}%',
                  style: AppTypography.labelLarge.copyWith(color: AppColors.softGold)),
            ]),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: ((stats['installations_avg_completion'] as int? ?? 0)) / 100,
                backgroundColor: AppColors.sandBeige,
                color: AppColors.softGold,
                minHeight: 8,
              ),
            ),
          ])),
          const SizedBox(height: 16),
        ],

        // Requests by status
        if (byStatus.isNotEmpty) ...[
          Text('Requests by Stage', style: AppTypography.labelLarge),
          const SizedBox(height: 10),
          _SectionCard(child: Column(
            children: byStatus.entries.map((e) {
              final label = e.key.replaceAll('_', ' ').toLowerCase();
              final count = e.value as int;
              final total = stats['requests_total'] as int? ?? 1;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(children: [
                  Expanded(flex: 3, child: Text(label, style: AppTypography.bodyMedium)),
                  Expanded(flex: 5, child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: count / total,
                      backgroundColor: AppColors.sandBeige,
                      color: AppColors.softGold,
                      minHeight: 6,
                    ),
                  )),
                  const SizedBox(width: 8),
                  Text('$count', style: AppTypography.labelSmall),
                ]),
              );
            }).toList(),
          )),
        ],
      ],
    );
  }
}

// ── Requests tab ─────────────────────────────────────────────────────────────

class _RequestsTab extends StatelessWidget {
  const _RequestsTab({required this.requests, required this.projectId});
  final List<Map<String, dynamic>> requests;
  final String projectId;

  static const _statusColors = {
    'MATERIAL_REQUEST': AppColors.mutedBlueGray,
    'PO_REQUESTED': AppColors.warningAmber,
    'PO_CREATED': AppColors.softGold,
    'DELIVERY': Color(0xFF6B8CAE),
    'STOREKEEPER_CONFIRMED': AppColors.successGreen,
    'INSTALLATION_IN_PROGRESS': Color(0xFF9B6BAE),
    'INSTALLATION_COMPLETE': AppColors.successGreen,
  };

  static const _priorityColors = {
    'LOW': AppColors.mutedBlueGray,
    'MEDIUM': AppColors.softGold,
    'HIGH': AppColors.warningAmber,
    'URGENT': AppColors.errorRed,
  };

  @override
  Widget build(BuildContext context) {
    if (requests.isEmpty) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.assignment_outlined, size: 48, color: AppColors.mutedBlueGray),
        const SizedBox(height: 12),
        Text('No requests yet', style: AppTypography.bodyMedium.copyWith(color: AppColors.mutedBlueGray)),
      ]));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: requests.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final r = requests[i];
        final status = r['status'] as String? ?? '';
        final priority = r['priority'] as String? ?? '';
        final statusColor = _statusColors[status] ?? AppColors.mutedBlueGray;
        final priorityColor = _priorityColors[priority] ?? AppColors.mutedBlueGray;
        return _SectionCard(child: Row(children: [
          Container(
            width: 4, height: 48,
            decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(r['title'] as String? ?? '', style: AppTypography.labelLarge, maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text(status.replaceAll('_', ' '), style: AppTypography.bodyMedium.copyWith(color: statusColor, fontSize: 12)),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: priorityColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(priority, style: AppTypography.labelSmall.copyWith(color: priorityColor)),
          ),
        ]));
      },
    );
  }
}

// ── Installations tab ─────────────────────────────────────────────────────────

class _InstallationsTab extends StatelessWidget {
  const _InstallationsTab({required this.installations});
  final List<Map<String, dynamic>> installations;

  @override
  Widget build(BuildContext context) {
    if (installations.isEmpty) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.construction_outlined, size: 48, color: AppColors.mutedBlueGray),
        const SizedBox(height: 12),
        Text('No installations yet', style: AppTypography.bodyMedium.copyWith(color: AppColors.mutedBlueGray)),
      ]));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: installations.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final inst = installations[i];
        final pct = inst['completion_percentage'] as int? ?? 0;
        final fmt = DateFormat('MMM d, yyyy');
        final start = inst['start_date'] != null ? DateTime.tryParse(inst['start_date'] as String) : null;
        final end = inst['estimated_end_date'] != null ? DateTime.tryParse(inst['estimated_end_date'] as String) : null;
        return _SectionCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Installation ${i + 1}', style: AppTypography.labelLarge),
            Text('$pct%', style: AppTypography.labelLarge.copyWith(
              color: pct == 100 ? AppColors.successGreen : AppColors.softGold)),
          ]),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct / 100,
              backgroundColor: AppColors.sandBeige,
              color: pct == 100 ? AppColors.successGreen : AppColors.softGold,
              minHeight: 8,
            ),
          ),
          if (start != null || end != null) ...[
            const SizedBox(height: 8),
            Text(
              [if (start != null) 'Start: ${fmt.format(start)}', if (end != null) 'Est. end: ${fmt.format(end)}'].join('  ·  '),
              style: AppTypography.labelSmall,
            ),
          ],
          if (inst['is_partial'] == true) ...[
            const SizedBox(height: 4),
            Text('Partial installation', style: AppTypography.labelSmall.copyWith(color: AppColors.warningAmber)),
          ],
        ]));
      },
    );
  }
}

// ── Notes tab ────────────────────────────────────────────────────────────────

class _NotesTab extends StatelessWidget {
  const _NotesTab({required this.notes});
  final List<Map<String, dynamic>> notes;

  @override
  Widget build(BuildContext context) {
    if (notes.isEmpty) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.note_outlined, size: 48, color: AppColors.mutedBlueGray),
        const SizedBox(height: 12),
        Text('No notes yet', style: AppTypography.bodyMedium.copyWith(color: AppColors.mutedBlueGray)),
      ]));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: notes.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final n = notes[i];
        final createdAt = n['created_at'] != null ? DateTime.tryParse(n['created_at'] as String) : null;
        return _SectionCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(n['title'] as String? ?? '', style: AppTypography.labelLarge),
          if (n['content'] != null && (n['content'] as String).isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(n['content'] as String,
                style: AppTypography.bodyMedium.copyWith(color: AppColors.mutedBlueGray),
                maxLines: 3, overflow: TextOverflow.ellipsis),
          ],
          if (createdAt != null) ...[
            const SizedBox(height: 8),
            Text(DateFormat('MMM d, yyyy').format(createdAt), style: AppTypography.labelSmall),
          ],
        ]));
      },
    );
  }
}

// ── Emails tab ───────────────────────────────────────────────────────────────

class _EmailsTab extends StatelessWidget {
  const _EmailsTab({required this.emails});
  final List<Map<String, dynamic>> emails;

  @override
  Widget build(BuildContext context) {
    if (emails.isEmpty) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.mail_outline, size: 48, color: AppColors.mutedBlueGray),
        const SizedBox(height: 12),
        Text('No emails yet', style: AppTypography.bodyMedium.copyWith(color: AppColors.mutedBlueGray)),
      ]));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: emails.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final e = emails[i];
        final sent = e['is_sent'] as bool? ?? false;
        final createdAt = e['created_at'] != null ? DateTime.tryParse(e['created_at'] as String) : null;
        return _SectionCard(child: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (sent ? AppColors.successGreen : AppColors.mutedBlueGray).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              sent ? Icons.mark_email_read_outlined : Icons.drafts_outlined,
              size: 18,
              color: sent ? AppColors.successGreen : AppColors.mutedBlueGray,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(e['subject'] as String? ?? '(no subject)', style: AppTypography.labelLarge,
                maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text(e['recipient_email'] as String? ?? '', style: AppTypography.bodyMedium.copyWith(fontSize: 12, color: AppColors.mutedBlueGray)),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(sent ? 'Sent' : 'Draft',
                style: AppTypography.labelSmall.copyWith(color: sent ? AppColors.successGreen : AppColors.mutedBlueGray)),
            if (createdAt != null)
              Text(DateFormat('MMM d').format(createdAt), style: AppTypography.labelSmall),
          ]),
        ]));
      },
    );
  }
}

// ── Shared widgets ────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(blurRadius: 16, offset: Offset(0, 4), color: Color(0x0A000000))],
      ),
      child: child,
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard(this.label, this.value, this.icon, this.color);
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(blurRadius: 16, offset: Offset(0, 4), color: Color(0x0A000000))],
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value, style: AppTypography.headingMedium.copyWith(fontSize: 20)),
          Text(label, style: AppTypography.labelSmall),
        ]),
      ]),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.icon, this.text);
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(children: [
        Icon(icon, size: 14, color: AppColors.mutedBlueGray),
        const SizedBox(width: 6),
        Expanded(child: Text(text,
            style: AppTypography.bodyMedium.copyWith(color: AppColors.mutedBlueGray), maxLines: 1, overflow: TextOverflow.ellipsis)),
      ]),
    );
  }
}

// ── Status parse helper ───────────────────────────────────────────────────────

ProjectStatus _parseProjectStatus(String? value) {
  switch (value) {
    case 'ACTIVE': return ProjectStatus.active;
    case 'ON_HOLD': return ProjectStatus.onHold;
    case 'COMPLETED': return ProjectStatus.completed;
    default: return ProjectStatus.planning;
  }
}
