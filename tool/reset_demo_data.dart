import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:drive_safe_app/firebase_options.dart';
import 'package:drive_safe_app/services/auth_service.dart';
import 'package:drive_safe_app/services/local_storage_service.dart';
import 'package:drive_safe_app/services/session_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  String result;

  try {
    final adminProfile = await AuthService.loginAdmin(
      email: LocalStorageService.adminEmail,
      password: LocalStorageService.adminPassword,
    );

    final firestore = FirebaseFirestore.instance;
    final complaintsSnapshot = await firestore.collection('complaints').get();
    final usersSnapshot = await firestore.collection('users').get();

    var deletedComplaints = 0;
    var deletedUserDocs = 0;

    final complaintDocs = complaintsSnapshot.docs;
    for (var index = 0; index < complaintDocs.length; index += 250) {
      final batch = firestore.batch();
      for (final doc in complaintDocs.skip(index).take(250)) {
        batch.delete(doc.reference);
        deletedComplaints += 1;
      }
      await batch.commit();
    }

    final nonAdminDocs = usersSnapshot.docs.where((doc) => doc.id != adminProfile.id).toList();
    for (var index = 0; index < nonAdminDocs.length; index += 250) {
      final batch = firestore.batch();
      for (final doc in nonAdminDocs.skip(index).take(250)) {
        batch.delete(doc.reference);
        deletedUserDocs += 1;
      }
      await batch.commit();
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(LocalStorageService.complaintKey);
    await prefs.remove(LocalStorageService.usersKey);
    await prefs.remove(LocalStorageService.legacyMigratedKey);
    await SessionStore.remove(LocalStorageService.currentUserKey);
    await SessionStore.remove(LocalStorageService.adminSessionKey);

    await FirebaseAuth.instance.signOut();

    result = 'Reset complete.\n'
        'Deleted complaints: $deletedComplaints\n'
        'Deleted non-admin user docs: $deletedUserDocs\n'
        'Kept admin profile: ${adminProfile.email} (${adminProfile.id})\n'
        'Note: Firebase Auth sign-in records for deleted non-admin users were not removed by this reset.';
  } catch (error) {
    result = 'Reset failed: $error';
  }

  debugPrint(result);
  runApp(_ResetResultApp(message: result));
}

class _ResetResultApp extends StatelessWidget {
  const _ResetResultApp({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('DriveSafe Reset Tool')),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: SelectableText(message),
        ),
      ),
    );
  }
}