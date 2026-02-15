import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../config/constants.dart';
import '../../../models/day_record.dart';
import '../../../services/storage_service.dart';
import '../../../widgets/app_button.dart';

class ProofBottomSheet extends StatefulWidget {
  final DayRecord record;
  final void Function(String imageUrl, String note) onSubmit;

  const ProofBottomSheet({
    super.key,
    required this.record,
    required this.onSubmit,
  });

  @override
  State<ProofBottomSheet> createState() => _ProofBottomSheetState();
}

class _ProofBottomSheetState extends State<ProofBottomSheet> {
  final _noteController = TextEditingController();
  final _storageService = StorageService();
  XFile? _selectedImage;
  bool _isUploading = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final image = await _storageService.pickImage(source: source);
    if (image != null) {
      setState(() => _selectedImage = image);
    }
  }

  Future<void> _submit() async {
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('please_select_photo'.tr())),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      final imageUrl = await _storageService.uploadProofImage(
        challengeId: widget.record.challengeId,
        dayRecordId: widget.record.id,
        file: File(_selectedImage!.path),
      );

      widget.onSubmit(imageUrl, _noteController.text.trim());
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('upload_failed'.tr(args: ['$e']))),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'submit_proof'.tr(),
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          if (widget.record.proofAttempts > 0) ...[
            const SizedBox(height: 4),
            Text(
              'proof_attempt'.tr(args: [
                '${widget.record.proofAttempts + 1}',
                '${AppConstants.maxProofAttempts}',
              ]),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.orange,
                  ),
            ),
            if (widget.record.rejectionReason != null &&
                widget.record.rejectionReason!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'payment_proof_rejected_reason'.tr(args: [widget.record.rejectionReason!]),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
              ),
            ],
          ],
          const SizedBox(height: 16),
          if (_selectedImage != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                File(_selectedImage!.path),
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            )
          else
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Icon(Icons.camera_alt, size: 48),
              ),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickImage(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt),
                  label: Text('camera'.tr()),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library),
                  label: Text('gallery'.tr()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _noteController,
            decoration: InputDecoration(
              labelText: 'note_label'.tr(),
              hintText: 'note_hint'.tr(),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          AppButton(
            label: 'submit_proof'.tr(),
            onPressed: _submit,
            isLoading: _isUploading,
          ),
        ],
      ),
    );
  }
}
