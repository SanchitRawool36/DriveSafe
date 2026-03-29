import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/app_user_model.dart';
import 'auth_service.dart';
import 'local_storage_service.dart';

class MigrationSummary {
  final int localUsers;
  final int localComplaints;

  const MigrationSummary({
    required this.localUsers,
    required this.localComplaints,
  });

  bool get hasLegacyData => localUsers > 0 || localComplaints > 0;
}

class MigrationResult {
  final int migratedUsers;
  final int migratedComplaints;
  final List<String> warnings;

  const MigrationResult({
    required this.migratedUsers,
    required this.migratedComplaints,
    this.warnings = const [],
  });
}

class MigrationService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static Future<MigrationSummary> getLegacySummary() async {
    final users = await LocalStorageService.getUsers();
    final complaints = await LocalStorageService.getComplaints();
    return MigrationSummary(
      localUsers: users.length,
      localComplaints: complaints.length,
    );
  }

  static Future<MigrationResult> migrateLocalDataToFirebase() async {
    final adminProfile = await AuthService.getCurrentUserProfile();
    if (adminProfile == null || !adminProfile.isAdmin) {
      throw Exception('Only an admin can migrate local data to Firebase.');
    }

    final localUsers = await LocalStorageService.getUsers();
    final localComplaints = await LocalStorageService.getComplaints();
    final warnings = <String>[];
    final legacyToFirebaseUserId = <String, String>{};
    var migratedUsers = 0;

    for (final localUser in localUsers) {
      try {
        final firebaseUserId = await _ensureFirebaseAccountForLocalUser(localUser);
        legacyToFirebaseUserId[localUser.id] = firebaseUserId;
        migratedUsers += 1;
      } catch (error) {
        warnings.add('User ${localUser.email.isEmpty ? localUser.phone : localUser.email}: $error');
      }
    }

    final batch = _db.batch();
    var migratedComplaints = 0;
    for (final complaint in localComplaints) {
      final docId = complaint.id.isEmpty ? _db.collection('complaints').doc().id : complaint.id;
      final nextComplaint = complaint.toJson()
        ..['id'] = docId
        ..['userId'] = legacyToFirebaseUserId[complaint.userId] ?? complaint.userId;
      batch.set(
        _db.collection('complaints').doc(docId),
        nextComplaint,
        SetOptions(merge: true),
      );
      migratedComplaints += 1;
    }

    if (migratedComplaints > 0) {
      await batch.commit();
    }

    await AuthService.loginAdmin(
      email: LocalStorageService.adminEmail,
      password: LocalStorageService.adminPassword,
    );
    await LocalStorageService.markLegacyDataMigrated();

    return MigrationResult(
      migratedUsers: migratedUsers,
      migratedComplaints: migratedComplaints,
      warnings: warnings,
    );
  }

  static Future<String> _ensureFirebaseAccountForLocalUser(AppUser localUser) async {
    final email = localUser.email.trim().toLowerCase();
    final password = localUser.password.trim();
    final isAdmin = localUser.isAdmin || email == LocalStorageService.adminEmail;

    if (email.isEmpty) {
      throw Exception('Missing email address, cannot create Firebase Auth user.');
    }

    UserCredential? credential;
    try {
      credential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (error) {
      if (error.code == 'email-already-in-use' || error.code == 'credential-already-in-use') {
        try {
          credential = await _auth.signInWithEmailAndPassword(email: email, password: password);
        } on FirebaseAuthException {
          final existingDoc = await _db.collection('users').where('email', isEqualTo: email).limit(1).get();
          if (existingDoc.docs.isEmpty) {
            rethrow;
          }
          final uid = existingDoc.docs.first.id;
          await _db.collection('users').doc(uid).set(
            localUser.copyWith(id: uid, password: '', role: isAdmin ? 'admin' : localUser.role).toJson(),
            SetOptions(merge: true),
          );
          return uid;
        }
      } else {
        rethrow;
      }
    }

    final user = credential.user;
    if (user == null) {
      throw Exception('Unable to create Firebase account for $email.');
    }

    await _db.collection('users').doc(user.uid).set(
      localUser.copyWith(id: user.uid, password: '', role: isAdmin ? 'admin' : localUser.role).toJson(),
      SetOptions(merge: true),
    );
    return user.uid;
  }
}