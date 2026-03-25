import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/app_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/loading_shimmer.dart';
import 'ai_providers.dart';
import 'models/ai_models.dart';

bool _isKeyMissing(Object e) =>
    e is AppException && e.statusCode == 503;

class AiScreen extends ConsumerStatefulWidget {
  const AiScreen({super.key});

  @override
  ConsumerState<AiScreen> createState() => _AiScreenState();
}

class _AiScreenState extends ConsumerState<AiScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _chatCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    _chatCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.warmWhite,
      appBar: AppBar(
        backgroundColor: AppColors.warmWhite,
        elevation: 0,
        title: Text('AI Assistant', style: AppTypography.headingMedium),
        bottom: TabBar(
          controller: _tabs,
          labelColor: AppColors.softGold,
          unselectedLabelColor: AppColors.mutedBlueGray,
          indicatorColor: AppColors.softGold,
          labelStyle: AppTypography.labelSmall,
          tabs: const [
            Tab(text: 'Summary'),
            Tab(text: 'Delays'),
            Tab(text: 'Chat'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _SummaryTab(),
          _DelaysTab(),
          _ChatTab(
            ctrl: _chatCtrl,
            scrollCtrl: _scrollCtrl,
            sending: _sending,
            onSend: _sendMessage,
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage() async {
    final text = _chatCtrl.text.trim();
    if (text.isEmpty) return;
    _chatCtrl.clear();
    setState(() => _sending = true);
    await ref.read(chatProvider.notifier).send(text);
    setState(() => _sending = false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
}

// ---------------------------------------------------------------------------
// Summary Tab
// ---------------------------------------------------------------------------

class _SummaryTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(dailySummaryProvider);
    return summaryAsync.when(
      loading: () => const LoadingShimmer(),
      error: (e, _) =>
          _isKeyMissing(e) ? const _ApiKeyMissingView() : _ErrorView(message: e.toString()),
      data: (s) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.wb_sunny_outlined,
                        color: AppColors.softGold, size: 20),
                    const SizedBox(width: 8),
                    Text('Daily Briefing',
                        style: AppTypography.labelLarge),
                  ],
                ),
                const SizedBox(height: 12),
                Text(s.summary, style: AppTypography.bodyMedium),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _StatPill(
                        label: 'Pending',
                        value: '${s.pendingCount}',
                        color: AppColors.warningAmber),
                    const SizedBox(width: 8),
                    _StatPill(
                        label: 'Overdue',
                        value: '${s.overdueCount}',
                        color: AppColors.errorRed),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text('Highlights',
              style: AppTypography.labelSmall
                  .copyWith(color: AppColors.mutedBlueGray)),
          const SizedBox(height: 8),
          ...s.highlights.map(
            (h) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: AppCard(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.arrow_right,
                        color: AppColors.softGold, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(h, style: AppTypography.bodyMedium),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Delays Tab
// ---------------------------------------------------------------------------

class _DelaysTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final delaysAsync = ref.watch(delayAlertsProvider);
    return delaysAsync.when(
      loading: () => const LoadingShimmer(),
      error: (e, _) =>
          _isKeyMissing(e) ? const _ApiKeyMissingView() : _ErrorView(message: e.toString()),
      data: (result) {
        if (result == null) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.radar_outlined,
                    size: 48, color: AppColors.mutedBlueGray),
                const SizedBox(height: 16),
                Text('Scan for overdue items',
                    style: AppTypography.bodyMedium),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () =>
                      ref.read(delayAlertsProvider.notifier).detect(),
                  icon: const Icon(Icons.search),
                  label: const Text('Detect Delays'),
                ),
              ],
            ),
          );
        }
        if (result.alerts.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle_outline,
                    size: 48, color: AppColors.successGreen),
                const SizedBox(height: 12),
                Text('No delays detected!',
                    style: AppTypography.bodyMedium),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () =>
                      ref.read(delayAlertsProvider.notifier).detect(),
                  child: const Text('Re-scan'),
                ),
              ],
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: result.alerts.length + 1,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, i) {
            if (i == 0) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${result.alerts.length} alerts',
                      style: AppTypography.labelSmall
                          .copyWith(color: AppColors.mutedBlueGray)),
                  TextButton(
                    onPressed: () =>
                        ref.read(delayAlertsProvider.notifier).detect(),
                    child: const Text('Re-scan'),
                  ),
                ],
              );
            }
            return _DelayCard(alert: result.alerts[i - 1]);
          },
        );
      },
    );
  }
}

class _DelayCard extends StatelessWidget {
  const _DelayCard({required this.alert});
  final DelayAlert alert;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.errorRed.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${alert.daysOverdue}d overdue',
                  style: AppTypography.labelSmall
                      .copyWith(color: AppColors.errorRed),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  alert.stage.replaceAll('_', ' '),
                  style: AppTypography.labelSmall
                      .copyWith(color: AppColors.mutedBlueGray),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(alert.title, style: AppTypography.labelLarge),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.lightbulb_outline,
                  size: 14, color: AppColors.softGold),
              const SizedBox(width: 6),
              Expanded(
                child: Text(alert.recommendation,
                    style: AppTypography.bodyMedium
                        .copyWith(color: AppColors.mutedBlueGray)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Chat Tab
// ---------------------------------------------------------------------------

class _ChatTab extends ConsumerWidget {
  const _ChatTab({
    required this.ctrl,
    required this.scrollCtrl,
    required this.sending,
    required this.onSend,
  });

  final TextEditingController ctrl;
  final ScrollController scrollCtrl;
  final bool sending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messages = ref.watch(chatProvider);
    return Column(
      children: [
        Expanded(
          child: messages.isEmpty
              ? _ChatEmpty()
              : ListView.builder(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  itemCount: messages.length,
                  itemBuilder: (_, i) => _ChatBubble(msg: messages[i]),
                ),
        ),
        _ChatInput(
          ctrl: ctrl,
          sending: sending,
          onSend: onSend,
        ),
      ],
    );
  }
}

class _ChatEmpty extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.auto_awesome_outlined,
              size: 48, color: AppColors.softGold),
          const SizedBox(height: 12),
          Text('Ask me anything about your projects',
              style: AppTypography.bodyMedium),
          const SizedBox(height: 8),
          Text(
            'I can extract tasks from notes,\ndetect patterns, and suggest next steps.',
            style: AppTypography.bodyMedium
                .copyWith(color: AppColors.mutedBlueGray),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.msg});
  final ChatMessage msg;

  @override
  Widget build(BuildContext context) {
    final isUser = msg.role == ChatRole.user;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isUser
              ? AppColors.softGold
              : AppColors.cardSurface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
          boxShadow: const [
            BoxShadow(
              blurRadius: 8,
              offset: Offset(0, 2),
              color: Color(0x0A000000),
            ),
          ],
        ),
        child: Text(
          msg.text,
          style: AppTypography.bodyMedium.copyWith(
            color: isUser
                ? AppColors.deepCharcoal
                : AppColors.deepCharcoal,
          ),
        ),
      ),
    );
  }
}

class _ChatInput extends StatelessWidget {
  const _ChatInput({
    required this.ctrl,
    required this.sending,
    required this.onSend,
  });

  final TextEditingController ctrl;
  final bool sending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 8, 16, MediaQuery.of(context).viewInsets.bottom + 12),
      decoration: const BoxDecoration(
        color: AppColors.cardSurface,
        border: Border(
            top: BorderSide(color: AppColors.divider, width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: ctrl,
              maxLines: null,
              keyboardType: TextInputType.multiline,
              style: AppTypography.bodyMedium,
              decoration: InputDecoration(
                hintText: 'Ask or paste a note…',
                hintStyle: AppTypography.bodyMedium
                    .copyWith(color: AppColors.mutedBlueGray),
                filled: true,
                fillColor: AppColors.sandBeige,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 8),
          _SendButton(sending: sending, onSend: onSend),
        ],
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  const _SendButton({required this.sending, required this.onSend});
  final bool sending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: sending ? null : onSend,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: sending
              ? AppColors.softGold.withValues(alpha: 0.5)
              : AppColors.softGold,
          borderRadius: BorderRadius.circular(12),
        ),
        child: sending
            ? const Padding(
                padding: EdgeInsets.all(12),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.deepCharcoal,
                ),
              )
            : const Icon(Icons.send_rounded,
                color: AppColors.deepCharcoal, size: 20),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared helpers
// ---------------------------------------------------------------------------

class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value,
              style: AppTypography.labelLarge.copyWith(color: color)),
          const SizedBox(width: 4),
          Text(label,
              style: AppTypography.labelSmall
                  .copyWith(color: color)),
        ],
      ),
    );
  }
}

class _ApiKeyMissingView extends StatelessWidget {
  const _ApiKeyMissingView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.key_off_outlined,
                size: 48, color: AppColors.mutedBlueGray),
            const SizedBox(height: 16),
            Text('API Key Not Configured',
                style: AppTypography.labelLarge),
            const SizedBox(height: 8),
            Text(
              'Add ANTHROPIC_API_KEY=sk-ant-... to your backend .env file and restart the server.',
              style: AppTypography.bodyMedium
                  .copyWith(color: AppColors.mutedBlueGray),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Error: $message',
          style: AppTypography.bodyMedium
              .copyWith(color: AppColors.errorRed),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
