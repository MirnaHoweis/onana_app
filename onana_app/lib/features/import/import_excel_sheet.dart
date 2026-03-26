import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

class ImportExcelSheet extends StatefulWidget {
  const ImportExcelSheet({super.key});

  @override
  State<ImportExcelSheet> createState() => _ImportExcelSheetState();
}

class _ImportExcelSheetState extends State<ImportExcelSheet> {
  bool _loading = false;
  Map<String, dynamic>? _result;
  String? _error;

  Future<void> _pickAndImport() async {
    setState(() {
      _loading = true;
      _result = null;
      _error = null;
    });

    try {
      final picked = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xlsm'],
        withData: true,
      );

      if (picked == null || picked.files.isEmpty) {
        setState(() => _loading = false);
        return;
      }

      final file = picked.files.first;
      if (file.bytes == null) {
        setState(() {
          _loading = false;
          _error = 'Could not read file.';
        });
        return;
      }

      final response = await ApiClient.instance.postFile(
        ApiEndpoints.importExcel,
        fileName: file.name,
        bytes: file.bytes!,
      );

      setState(() => _result = response.data as Map<String, dynamic>);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.warmWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Import from Excel', style: AppTypography.headingMedium),
          const SizedBox(height: 8),
          Text(
            'Upload an .xlsx file with "Projects" and/or "Requests" sheets.',
            style: AppTypography.bodyMedium.copyWith(color: AppColors.mutedBlueGray),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.sandBeige,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Expected columns', style: AppTypography.labelLarge),
                const SizedBox(height: 10),
                _sheetInfo('Projects sheet', [
                  'Name*', 'Client Name', 'Location', 'Status',
                  'Start Date', 'End Date',
                ]),
                const SizedBox(height: 8),
                _sheetInfo('Requests sheet', [
                  'Project Name*', 'Unit Name*', 'Unit Type', 'Title*',
                  'Category', 'Priority', 'Description', 'Supplier',
                  'Expected Delivery',
                ]),
              ],
            ),
          ),
          const SizedBox(height: 24),

          if (_result != null) _ResultView(result: _result!),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                _error!,
                style: AppTypography.bodyMedium.copyWith(color: AppColors.errorRed),
              ),
            ),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _loading ? null : _pickAndImport,
              icon: _loading
                  ? const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.upload_file_outlined),
              label: Text(_loading ? 'Importing…' : 'Choose File & Import'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.softGold,
                foregroundColor: AppColors.deepCharcoal,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sheetInfo(String title, List<String> cols) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTypography.labelSmall.copyWith(color: AppColors.mutedBlueGray)),
        const SizedBox(height: 4),
        Wrap(
          spacing: 6, runSpacing: 4,
          children: cols.map((c) => _ColChip(c)).toList(),
        ),
      ],
    );
  }
}

class _ColChip extends StatelessWidget {
  const _ColChip(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    final required = label.endsWith('*');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: required
            ? AppColors.softGold.withValues(alpha: 0.2)
            : AppColors.cardSurface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.divider),
      ),
      child: Text(label, style: AppTypography.labelSmall),
    );
  }
}

class _ResultView extends StatelessWidget {
  const _ResultView({required this.result});
  final Map<String, dynamic> result;

  @override
  Widget build(BuildContext context) {
    final projectsCreated = result['projects_created'] ?? 0;
    final requestsCreated = result['requests_created'] ?? 0;
    final errors = (result['errors'] as List?)?.cast<String>() ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.successGreen.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.successGreen.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Import complete',
              style: AppTypography.labelLarge.copyWith(color: AppColors.successGreen)),
          const SizedBox(height: 8),
          Text('$projectsCreated project(s) created', style: AppTypography.bodyMedium),
          Text('$requestsCreated request(s) created', style: AppTypography.bodyMedium),
          if (errors.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('${errors.length} warning(s):',
                style: AppTypography.labelSmall.copyWith(color: AppColors.warningAmber)),
            ...errors.map((e) => Text('• $e',
                style: AppTypography.bodyMedium.copyWith(fontSize: 12))),
          ],
        ],
      ),
    );
  }
}
