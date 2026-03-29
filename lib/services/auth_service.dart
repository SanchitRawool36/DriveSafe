import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../models/app_user_model.dart';
import 'local_storage_service.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final CollectionReference<Map<String, dynamic>> _users =
      FirebaseFirestore.instance.collection('users');
  static const String _reservedAdminEmail = 'admin@gmail.com';

  static Future<bool> isCurrentUserAdmin() async {
    final profile = await getCurrentUserProfile();
    return profile?.isAdmin ?? false;
  }

  static Future<AppUser?> getCurrentUserProfile() async {
    if (Firebase.apps.isEmpty) {
      return null;
    }

    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return null;
    }

    return _ensureProfileForUser(currentUser);
  }

  static Future<AppUser?> getUserProfileById(String? userId) async {
    if (Firebase.apps.isEmpty || userId == null || userId.isEmpty) {
      return null;
    }

    final doc = await _users.doc(userId).get();
    if (!doc.exists) {
      return null;
    }

    return AppUser.fromJson({
      ...(doc.data() ?? <String, dynamic>{}),
      'id': userId,
      'password': '',
    });
  }

  static Future<List<AppUser>> getAllUserProfiles() async {
    if (Firebase.apps.isEmpty) {
      return const [];
    }

    final snapshot = await _users.get();
    final users = snapshot.docs
        .map(
          (doc) => AppUser.fromJson({
            ...doc.data(),
            'id': doc.id,
            'password': '',
          }),
        )
        .toList();
    users.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return users;
  }

  static Future<AppUser> registerUser({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final normalizedPhone = phone.trim();

    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );

      final firebaseUser = credential.user;
      if (firebaseUser == null) {
        throw Exception('Account created, but user session was not returned.');
      }

      if (name.trim().isNotEmpty) {
        try {
          await firebaseUser.updateDisplayName(name.trim());
        } catch (_) {
          // Firebase Auth profile updates are optional for this app.
        }
      }

      final profile = AppUser(
        id: firebaseUser.uid,
        name: name.trim().isEmpty ? 'DriveSafe User' : name.trim(),
        email: normalizedEmail,
        phone: normalizedPhone,
        password: '',
        licenseNumber: _defaultLicenseNumber(firebaseUser.uid),
        bio: 'Committed to safer roads and civic reporting.',
        address: 'Add your address from profile',
        role: 'user',
      );

      try {
        await _saveUserProfile(profile);
      } catch (_) {
        // Firestore profile creation is best-effort here. The app can still
        // continue with the authenticated Firebase user and recreate the
        // profile document later.
      }
      return profile;
    } on FirebaseAuthException catch (error) {
      throw Exception(_friendlyAuthError(error));
    } on FirebaseException catch (error) {
      throw Exception(_friendlyFirebaseError(error));
    } catch (error) {
      throw Exception(_friendlyUnknownError(error));
    }
  }

  static Future<AppUser> loginUser({
    required String identifier,
    required String password,
  }) async {
    final normalizedIdentifier = identifier.trim();
    if (!normalizedIdentifier.contains('@')) {
      throw Exception('Use your email address to sign in. Phone login is not enabled with Firebase Auth in this app.');
    }

    try {
      final resolvedEmail = normalizedIdentifier.toLowerCase();

      await _auth.signInWithEmailAndPassword(
        email: resolvedEmail,
        password: password,
      );

      final profile = await getCurrentUserProfile();
      if (profile == null) {
        throw Exception('Unable to load your profile after login.');
      }

      return profile;
    } on FirebaseAuthException catch (error) {
      throw Exception(_friendlyAuthError(error));
    } on FirebaseException catch (error) {
      throw Exception(_friendlyFirebaseError(error));
    } catch (error) {
      throw Exception(_friendlyUnknownError(error));
    }
  }

  static Future<AppUser> loginAdmin({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final isReservedAdmin = normalizedEmail == _reservedAdminEmail &&
        password == LocalStorageService.adminPassword;

    try {
      await _auth.signInWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );
    } on FirebaseAuthException catch (error) {
      if ((error.code == 'user-not-found' || error.code == 'invalid-credential') && isReservedAdmin) {
        final credential = await _auth.createUserWithEmailAndPassword(
          email: normalizedEmail,
          password: password,
        );
        final createdUser = credential.user;
        if (createdUser == null) {
          throw Exception('Unable to create the Firebase admin account.');
        }

        final adminProfile = AppUser(
          id: createdUser.uid,
          name: 'DriveSafe Admin',
          email: normalizedEmail,
          phone: '',
          password: '',
          licenseNumber: _defaultLicenseNumber(createdUser.uid),
          bio: 'Drive Safe platform administrator.',
          address: 'Admin Console',
          role: 'admin',
        );
        await _saveUserProfile(adminProfile);
        return adminProfile;
      }

      if (error.code == 'email-already-in-use' && isReservedAdmin) {
        throw Exception('The reserved admin email already exists in Firebase Auth with a different password.');
      }

      throw Exception(_friendlyAuthError(error));
    }

    if (isReservedAdmin) {
      final firebaseUser = _auth.currentUser;
      if (firebaseUser == null) {
        throw Exception('Unable to load the admin profile after login.');
      }

      final adminProfile = AppUser(
        id: firebaseUser.uid,
        name: (firebaseUser.displayName ?? '').trim().isEmpty
            ? 'DriveSafe Admin'
            : firebaseUser.displayName!.trim(),
        email: firebaseUser.email ?? normalizedEmail,
        phone: '',
        password: '',
        licenseNumber: _defaultLicenseNumber(firebaseUser.uid),
        bio: 'Drive Safe platform administrator.',
        address: 'Admin Console',
        role: 'admin',
      );
      await _saveUserProfile(adminProfile);
      return adminProfile;
    }

    final profile = await getCurrentUserProfile();
    if (profile == null) {
      throw Exception('Unable to load the admin profile after login.');
    }

    if (profile.isAdmin) {
      return profile;
    }

    await _auth.signOut();
    throw Exception('This account is not authorized as an admin.');
  }

  static Future<AppUser> updateCurrentUser(AppUser updatedUser) async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) {
      throw Exception('No signed-in Firebase user found.');
    }

    final nextUser = updatedUser.copyWith(
      id: firebaseUser.uid,
      email: firebaseUser.email ?? updatedUser.email,
      password: '',
    );

    if ((firebaseUser.displayName ?? '') != nextUser.name) {
      try {
        await firebaseUser.updateDisplayName(nextUser.name);
      } catch (_) {
        // Ignore Firebase Auth profile update failures if Firestore succeeds.
      }
    }

    await _saveUserProfile(nextUser);
    return nextUser;
  }

  static Future<AppUser> updateUserProfileByAdmin(AppUser updatedUser) async {
    final nextUser = updatedUser.copyWith(password: '');
    await _saveUserProfile(nextUser);
    return nextUser;
  }

  static Future<void> logout() async {
    if (Firebase.apps.isNotEmpty) {
      await _auth.signOut();
    }
    await LocalStorageService.logout();
  }

  static Future<AppUser> _ensureProfileForUser(User firebaseUser) async {
    try {
      final doc = await _users.doc(firebaseUser.uid).get();
      if (doc.exists) {
        final data = doc.data() ?? <String, dynamic>{};
        return AppUser.fromJson({
          ...data,
          'id': firebaseUser.uid,
          'email': data['email'] ?? firebaseUser.email ?? '',
          'password': '',
        });
      }
    } catch (_) {
      return _fallbackProfileFor(firebaseUser);
    }

    final generatedProfile = _fallbackProfileFor(firebaseUser);

    try {
      await _saveUserProfile(generatedProfile);
    } catch (_) {
      // If Firestore is still unavailable for profile writes, keep the app
      // usable with the auth-derived fallback profile.
    }
    return generatedProfile;
  }

  static Future<void> _saveUserProfile(AppUser user) {
    return _users.doc(user.id).set(_profileData(user), SetOptions(merge: true));
  }

  static Map<String, dynamic> _profileData(AppUser user) {
    return {
      'id': user.id,
      'name': user.name,
      'email': user.email,
      'phone': user.phone,
      'licenseNumber': user.licenseNumber,
      'bio': user.bio,
      'address': user.address,
      'dateOfBirth': user.dateOfBirth,
      'bloodGroup': user.bloodGroup,
      'vehicleClass': user.vehicleClass,
      'issueDate': user.issueDate,
      'expiryDate': user.expiryDate,
      'emergencyContact': user.emergencyContact,
      'licenseStatus': user.licenseStatus,
      'renewalRequestNote': user.renewalRequestNote,
      'renewalRequestedAt': user.renewalRequestedAt,
      'renewalTestDate': user.renewalTestDate,
      'renewalHistory': user.renewalHistory,
      'profileImageData': user.profileImageData,
      'role': user.role,
    };
  }

  static AppUser _fallbackProfileFor(User firebaseUser) {
    return AppUser(
      id: firebaseUser.uid,
      name: (firebaseUser.displayName ?? '').trim().isEmpty
          ? 'DriveSafe User'
          : firebaseUser.displayName!.trim(),
      email: firebaseUser.email ?? '',
      phone: '',
      password: '',
      licenseNumber: _defaultLicenseNumber(firebaseUser.uid),
      role: 'user',
    );
  }

  static String _defaultLicenseNumber(String uid) {
    final normalized = uid.replaceAll('-', '').toUpperCase();
    final fragment = normalized.length >= 8
        ? normalized.substring(0, 8)
        : normalized.padRight(8, '0');
    return 'DL-$fragment';
  }

  static String _friendlyAuthError(FirebaseAuthException error) {
    switch (error.code) {
      case 'operation-not-allowed':
        return 'Email/password sign-in is not enabled in Firebase Authentication yet.';
      case 'email-already-in-use':
        return 'An account already exists for this email.';
      case 'invalid-email':
        return 'Enter a valid email address.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'user-not-found':
        return 'No account found. Please register first.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Invalid email, phone, or password.';
      case 'network-request-failed':
        return 'Network error. Check your connection and try again.';
      default:
        return error.message ?? 'Authentication failed. Please try again.';
    }
  }

  static String _friendlyFirebaseError(FirebaseException error) {
    switch (error.code) {
      case 'permission-denied':
        return 'Firebase rejected the request. Check Firestore security rules and make sure the user document can be created.';
      case 'unavailable':
        return 'Firebase is temporarily unavailable. Try again in a moment.';
      default:
        return error.message ?? 'Firebase request failed. Please try again.';
    }
  }

  static String _friendlyUnknownError(Object error) {
    final text = error.toString();
    if (text.contains('operation-not-allowed')) {
      return 'Email/password sign-in is not enabled in Firebase Authentication yet.';
    }
    return text;
  }
}