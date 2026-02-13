import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  Future<XFile?> pickImage({ImageSource source = ImageSource.camera}) async {
    return _picker.pickImage(
      source: source,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 80,
    );
  }

  Future<String> uploadProofImage({
    required String challengeId,
    required String dayRecordId,
    required File file,
  }) async {
    final ref = _storage
        .ref()
        .child('proofs')
        .child(challengeId)
        .child('$dayRecordId.jpg');

    final uploadTask = ref.putFile(
      file,
      SettableMetadata(contentType: 'image/jpeg'),
    );

    final snapshot = await uploadTask;
    return snapshot.ref.getDownloadURL();
  }

  Future<void> deleteProofImage({
    required String challengeId,
    required String dayRecordId,
  }) async {
    final ref = _storage
        .ref()
        .child('proofs')
        .child(challengeId)
        .child('$dayRecordId.jpg');

    await ref.delete();
  }
}
