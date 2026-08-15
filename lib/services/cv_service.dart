import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

Future<String?> pickPdf() async {
  final result = await FilePicker.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['pdf'],
  );

  if (result.isEmpty) {
    return null;
  }

  return result.single.path;
}

Future<String?> uploadPdf(String path, String userId) async {
  try {
    final ref = FirebaseStorage.instance
        .ref()
        .child('cv/$userId.pdf');

    await ref.putFile(File(path));
    return await ref.getDownloadURL();
  } catch (e) {
    print('Error subiendo PDF: $e');
    return null;
  }
}

Future<String?> uploadImage(String path, String userId) async {
  try {
    final ref = FirebaseStorage.instance
        .ref()
        .child('documents/$userId.jpg');

    await ref.putFile(File(path));
    return await ref.getDownloadURL();
  } catch (e) {
    print('Error subiendo imagen: $e');
    return null;
  }
}

Future<void> saveUserData(
  String userId,
  Map<String, dynamic> data,
) async {
  await FirebaseFirestore.instance
      .collection('usuarios')
      .doc(userId)
      .set(data);
}