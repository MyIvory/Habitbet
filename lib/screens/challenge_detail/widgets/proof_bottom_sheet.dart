import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

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
        const SnackBar(content: Text('Please take or select a photo')),
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
          SnackBar(content: Text('Upload failed: $e')),
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
            'Submit Proof',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
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
                  label: const Text('Camera'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Gallery'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _noteController,
            decoration: const InputDecoration(
              labelText: 'Note (optional)',
              hintText: 'Any details about today\'s progress...',
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          AppButton(
            label: 'Submit Proof',
            onPressed: _submit,
            isLoading: _isUploading,
          ),
        ],
      ),
    );
  }
}
