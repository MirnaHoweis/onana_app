import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/loading_shimmer.dart';
import 'notes_providers.dart';
import 'widgets/note_card.dart';

class NotesScreen extends ConsumerWidget {
  const NotesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notesAsync = ref.watch(notesProvider);

    return Scaffold(
      backgroundColor: AppColors.warmWhite,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text('Notes', style: AppTypography.headingMedium),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh_outlined),
                    color: AppColors.mutedBlueGray,
                    onPressed: () => ref.invalidate(notesProvider),
                  ),
                ],
              ),
            ),
            Expanded(
              child: notesAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(16),
                  child: LoadingShimmer(itemCount: 5),
                ),
                error: (e, _) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.cloud_off_outlined,
                          size: 48, color: AppColors.mutedBlueGray),
                      const SizedBox(height: 16),
                      Text('Could not load notes',
                          style: AppTypography.headingMedium),
                      const SizedBox(height: 24),
                      TextButton.icon(
                        onPressed: () => ref.invalidate(notesProvider),
                        icon: const Icon(Icons.refresh,
                            color: AppColors.softGold),
                        label: Text('Retry',
                            style: AppTypography.labelLarge
                                .copyWith(color: AppColors.softGold)),
                      ),
                    ],
                  ),
                ),
                data: (notes) {
                  if (notes.isEmpty) {
                    return const EmptyState(
                      title: 'No notes yet',
                      subtitle: 'Tap + to write a note or record your voice.',
                      icon: Icons.notes_outlined,
                    );
                  }
                  return RefreshIndicator(
                    color: AppColors.softGold,
                    onRefresh: () =>
                        ref.read(notesProvider.notifier).refresh(),
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                      itemCount: notes.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 10),
                      itemBuilder: (context, i) => NoteCard(
                        note: notes[i],
                        onTap: () {},
                        onDelete: () => ref
                            .read(notesProvider.notifier)
                            .delete(notes[i].id),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'voice_note',
            backgroundColor: AppColors.deepCharcoal,
            foregroundColor: AppColors.warmWhite,
            onPressed: () => _showVoiceSheet(context, ref),
            child: const Icon(Icons.mic),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            heroTag: 'text_note',
            backgroundColor: AppColors.softGold,
            foregroundColor: AppColors.deepCharcoal,
            onPressed: () => _showCreateSheet(context, ref),
            child: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
    );
  }

  void _showCreateSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CreateNoteSheet(ref: ref),
    );
  }

  void _showVoiceSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _VoiceNoteSheet(ref: ref),
    );
  }
}

// ── Text note sheet ────────────────────────────────────────────────────────

class _CreateNoteSheet extends StatefulWidget {
  const _CreateNoteSheet({required this.ref});
  final WidgetRef ref;

  @override
  State<_CreateNoteSheet> createState() => _CreateNoteSheetState();
}

class _CreateNoteSheetState extends State<_CreateNoteSheet> {
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
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
              Text('New Note', style: AppTypography.headingMedium),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _titleCtrl,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Title'),
            style: AppTypography.bodyMedium,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _contentCtrl,
            maxLines: 4,
            decoration:
                const InputDecoration(labelText: 'Content (optional)'),
            style: AppTypography.bodyMedium,
          ),
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
                  : Text('Save', style: AppTypography.labelLarge),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) return;
    setState(() => _loading = true);
    try {
      await widget.ref.read(notesProvider.notifier).create(
            title: title,
            content: _contentCtrl.text.trim().isEmpty
                ? null
                : _contentCtrl.text.trim(),
          );
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

// ── Voice note sheet ───────────────────────────────────────────────────────

class _VoiceNoteSheet extends StatefulWidget {
  const _VoiceNoteSheet({required this.ref});
  final WidgetRef ref;

  @override
  State<_VoiceNoteSheet> createState() => _VoiceNoteSheetState();
}

class _VoiceNoteSheetState extends State<_VoiceNoteSheet> {
  final SpeechToText _stt = SpeechToText();
  bool _available = false;
  bool _listening = false;
  String _transcript = '';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final available = await _stt.initialize();
    if (mounted) setState(() => _available = available);
  }

  Future<void> _toggleListen() async {
    if (_listening) {
      await _stt.stop();
      setState(() => _listening = false);
    } else {
      await _stt.listen(
        onResult: (result) => setState(
          () => _transcript = result.recognizedWords,
        ),
      );
      setState(() => _listening = true);
    }
  }

  @override
  void dispose() {
    _stt.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.warmWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text('Voice Note', style: AppTypography.headingMedium),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: _available ? _toggleListen : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _listening
                    ? AppColors.errorRed
                    : _available
                        ? AppColors.softGold
                        : AppColors.sandBeige,
              ),
              child: Icon(
                _listening ? Icons.stop : Icons.mic,
                size: 36,
                color: _listening || _available
                    ? AppColors.deepCharcoal
                    : AppColors.mutedBlueGray,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _listening
                ? 'Listening…'
                : _available
                    ? 'Tap to record'
                    : 'Microphone unavailable',
            style: AppTypography.labelSmall,
          ),
          if (_transcript.isNotEmpty) ...[
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.sandBeige,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(_transcript, style: AppTypography.bodyMedium),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.deepCharcoal,
                        ),
                      )
                    : Text('Save Note', style: AppTypography.labelLarge),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (_transcript.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      final title = _transcript.length > 40
          ? '${_transcript.substring(0, 40)}…'
          : _transcript;
      await widget.ref.read(notesProvider.notifier).create(
            title: title,
            content: _transcript,
          );
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
