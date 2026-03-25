import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../email_providers.dart';

class ComposeEmailSheet extends ConsumerStatefulWidget {
  const ComposeEmailSheet({super.key});

  @override
  ConsumerState<ComposeEmailSheet> createState() => _ComposeEmailSheetState();
}

class _ComposeEmailSheetState extends ConsumerState<ComposeEmailSheet> {
  final _subjectCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  String _recipientType = 'ACCOUNTING';
  bool _loading = false;

  static const _types = [
    ('ACCOUNTING', 'Accounting'),
    ('SUPPLIER', 'Supplier'),
    ('STOREKEEPER', 'Storekeeper'),
  ];

  @override
  void dispose() {
    _subjectCtrl.dispose();
    _bodyCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_subjectCtrl.text.isEmpty || _bodyCtrl.text.isEmpty) return;
    setState(() => _loading = true);
    try {
      await ref.read(emailDraftsProvider.notifier).create(
            subject: _subjectCtrl.text.trim(),
            body: _bodyCtrl.text.trim(),
            recipientType: _recipientType,
            recipientEmail:
                _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
          );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save draft: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          24, 16, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Compose Email', style: AppTypography.headingMedium),
          const SizedBox(height: 20),
          // Recipient type selector
          Text('Recipient', style: AppTypography.labelSmall),
          const SizedBox(height: 8),
          Row(
            children: _types
                .map(
                  (t) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(t.$2),
                      selected: _recipientType == t.$1,
                      onSelected: (_) =>
                          setState(() => _recipientType = t.$1),
                      selectedColor: AppColors.softGold.withValues(alpha: 0.2),
                      labelStyle: AppTypography.labelSmall.copyWith(
                        color: _recipientType == t.$1
                            ? AppColors.softGold
                            : AppColors.mutedBlueGray,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 16),
          // Recipient email
          _Field(
            controller: _emailCtrl,
            label: 'Recipient Email (optional)',
            hint: 'email@example.com',
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 12),
          _Field(
            controller: _subjectCtrl,
            label: 'Subject',
            hint: 'e.g. PO Follow-up — Unit 4B',
          ),
          const SizedBox(height: 12),
          _Field(
            controller: _bodyCtrl,
            label: 'Body',
            hint: 'Write your email here…',
            maxLines: 5,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: AppButton(
              label: 'Save Draft',
              onPressed: _save,
              isLoading: _loading,
            ),
          ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    required this.hint,
    this.maxLines = 1,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final int maxLines;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.labelSmall),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: AppTypography.bodyMedium,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTypography.bodyMedium
                .copyWith(color: AppColors.mutedBlueGray),
            filled: true,
            fillColor: AppColors.sandBeige,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }
}
