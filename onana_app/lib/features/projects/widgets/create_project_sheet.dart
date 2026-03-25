import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../projects_providers.dart';

class CreateProjectSheet extends ConsumerStatefulWidget {
  const CreateProjectSheet({super.key});

  @override
  ConsumerState<CreateProjectSheet> createState() =>
      _CreateProjectSheetState();
}

class _CreateProjectSheetState extends ConsumerState<CreateProjectSheet> {
  final _nameCtrl = TextEditingController();
  final _clientCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _clientCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Project name is required.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(projectsProvider.notifier).create(
            name: name,
            clientName: _clientCtrl.text.trim().isEmpty
                ? null
                : _clientCtrl.text.trim(),
            location: _locationCtrl.text.trim().isEmpty
                ? null
                : _locationCtrl.text.trim(),
          );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _error = 'Failed to create project. Please try again.');
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
          // Handle bar
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
          Row(
            children: [
              Expanded(
                child: Text('New Project',
                    style: AppTypography.headingMedium),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: AppColors.mutedBlueGray),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _Field(
            controller: _nameCtrl,
            label: 'Project Name *',
            hint: 'e.g. Al-Noor Residences',
            autofocus: true,
          ),
          const SizedBox(height: 12),
          _Field(
            controller: _clientCtrl,
            label: 'Client Name',
            hint: 'e.g. Emaar Properties',
          ),
          const SizedBox(height: 12),
          _Field(
            controller: _locationCtrl,
            label: 'Location',
            hint: 'e.g. Dubai Marina',
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
            child: AppButton(
              label: 'Create Project',
              onPressed: _submit,
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
    this.autofocus = false,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.labelSmall),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          autofocus: autofocus,
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
