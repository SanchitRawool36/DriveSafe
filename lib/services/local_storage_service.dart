import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/ambulance_models.dart';
import '../models/app_settings_model.dart';
import '../models/app_user_model.dart';
import '../models/complaint_model.dart';
import 'session_store.dart';

class LocalStorageService {
  static const String adminEmail = 'admin@gmail.com';
  static const String adminPassword = 'admin123';
  static const String complaintKey = 'complaints';
  static const String usersKey = 'users';
  static const String currentUserKey = 'current_user';
  static const String settingsKey = 'app_settings';
  static const String adminSessionKey = 'admin_session';
  static const String legacyMigratedKey = 'legacy_data_migrated';
  static const String ambulanceBookingKey = 'ambulance_booking';
  static final ValueNotifier<AppSettings> settingsNotifier = ValueNotifier(const AppSettings());

  static bool isAdminIdentifier(String identifier) {
    return identifier.trim().toLowerCase() == adminEmail;
  }

  static Future<bool> getIsAdminSession() async {
    return await SessionStore.getBool(adminSessionKey) ?? false;
  }

  static Future<void> loginAsAdmin({required String password}) async {
    if (password != adminPassword) {
      throw Exception('Invalid admin credentials.');
    }

    await SessionStore.setBool(adminSessionKey, true);
    await SessionStore.remove(currentUserKey);
  }

  static Future<AppSettings> getSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(settingsKey);
    final settings = data == null || data.isEmpty
        ? const AppSettings()
        : AppSettings.fromJson(jsonDecode(data));
    settingsNotifier.value = settings;
    return settings;
  }

  static Future<void> saveSettings(AppSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(settingsKey, jsonEncode(settings.toJson()));
    settingsNotifier.value = settings;
  }

  static Future<List<AppUser>> getUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList(usersKey) ?? [];
    return data.map((item) => AppUser.fromJson(jsonDecode(item))).toList();
  }

  static Future<AppUser?> getCurrentUser() async {
    final data = await SessionStore.getString(currentUserKey);
    if (data == null || data.isEmpty) {
      return null;
    }
    return AppUser.fromJson(jsonDecode(data));
  }

  static Future<void> _persistUsers(List<AppUser> users) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      usersKey,
      users.map((user) => jsonEncode(user.toJson())).toList(),
    );
  }

  static Future<void> _setCurrentUser(AppUser? user) async {
    if (user == null) {
      await SessionStore.remove(currentUserKey);
      return;
    }
    await SessionStore.setString(currentUserKey, jsonEncode(user.toJson()));
  }

  static Future<AppUser> registerUser({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    final users = await getUsers();
    final normalizedEmail = email.trim().toLowerCase();
    final normalizedPhone = phone.trim();

    final exists = users.any(
      (user) => user.email.toLowerCase() == normalizedEmail || user.phone == normalizedPhone,
    );

    if (exists) {
      throw Exception('Account already exists for this email or phone.');
    }

    final newUser = AppUser(
      id: const Uuid().v4(),
      name: name.trim().isEmpty ? 'DriveSafe User' : name.trim(),
      email: normalizedEmail,
      phone: normalizedPhone,
      password: password,
      licenseNumber: 'DL-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}',
      bio: 'Committed to safer roads and civic reporting.',
      address: 'Add your address from profile',
    );

    users.add(newUser);
    await _persistUsers(users);
    await _setCurrentUser(newUser);
    return newUser;
  }

  static Future<AppUser> loginUser({
    required String identifier,
    required String password,
  }) async {
    final users = await getUsers();
    final query = identifier.trim().toLowerCase();

    final match = users.where((user) {
      return user.email.toLowerCase() == query || user.phone == identifier.trim();
    }).toList();

    if (match.isEmpty) {
      throw Exception('No account found. Please register first.');
    }

    final user = match.first;
    if (user.password != password) {
      throw Exception('Invalid password.');
    }

    await _setCurrentUser(user);
    return user;
  }

  static Future<AppUser> updateCurrentUser(AppUser updatedUser) async {
    final users = await getUsers();
    final nextUsers = users.map((user) {
      return user.id == updatedUser.id ? updatedUser : user;
    }).toList();
    await _persistUsers(nextUsers);
    await _setCurrentUser(updatedUser);
    return updatedUser;
  }

  static Future<void> logout() async {
    await _setCurrentUser(null);
    await SessionStore.remove(adminSessionKey);
  }

  static Future<void> saveComplaint(Complaint complaint) async {
    final prefs = await SharedPreferences.getInstance();

    final existing = prefs.getStringList(complaintKey) ?? [];

    final payload = Map<String, dynamic>.from(complaint.toJson());
    if (complaint.id.isEmpty) {
      payload['id'] = const Uuid().v4();
    }

    existing.add(jsonEncode(payload));

    await prefs.setStringList(complaintKey, existing);
  }

  static Future<List<Complaint>> getComplaints() async {
    final prefs = await SharedPreferences.getInstance();

    final data = prefs.getStringList(complaintKey) ?? [];

    return data
        .map((e) => Complaint.fromJson(jsonDecode(e)))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  static Future<void> saveAllComplaints(List<Complaint> complaints) async {
    final prefs = await SharedPreferences.getInstance();
    final data = complaints.map((complaint) => jsonEncode(complaint.toJson())).toList();
    await prefs.setStringList(complaintKey, data);
  }

  static Future<List<Complaint>> getComplaintsForUser(String? userId) async {
    final complaints = await getComplaints();
    if (userId == null || userId.isEmpty) {
      return complaints;
    }
    return complaints.where((complaint) => complaint.userId == userId).toList();
  }

  static Future<Map<String, int>> getComplaintStats({String? userId}) async {
    final complaints = userId == null
        ? await getComplaints()
        : await getComplaintsForUser(userId);

    final accepted = complaints.where((complaint) => complaint.status == 'Accepted').length;
    final rejected = complaints.where((complaint) => complaint.status == 'Rejected').length;
    final resolved = complaints.where((complaint) => complaint.status == 'Resolved').length;
    final pending = complaints.where((complaint) => complaint.status == 'Pending').length;
    final inProgress = complaints.where((complaint) => complaint.status == 'In Progress').length;

    return {
      'total': complaints.length,
      'accepted': accepted,
      'rejected': rejected,
      'resolved': resolved,
      'pending': pending,
      'inProgress': inProgress,
    };
  }

  static Future<void> updateComplaintStatus(String complaintId, String status) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList(complaintKey) ?? [];
    final updated = data.map((item) {
      final json = Map<String, dynamic>.from(jsonDecode(item));
      if (json['id'] == complaintId) {
        json['status'] = status;
      }
      return jsonEncode(json);
    }).toList();
    await prefs.setStringList(complaintKey, updated);
  }

  static Future<void> saveAmbulanceBooking(AmbulanceBooking booking) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(ambulanceBookingKey, jsonEncode(booking.toJson()));
  }

  static Future<AmbulanceBooking?> getAmbulanceBooking() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(ambulanceBookingKey);
    if (data == null || data.isEmpty) {
      return null;
    }
    return AmbulanceBooking.fromJson(jsonDecode(data));
  }

  static Future<void> clearAmbulanceBooking() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(ambulanceBookingKey);
  }

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await SessionStore.remove(currentUserKey);
    await SessionStore.remove(adminSessionKey);
    await prefs.remove(usersKey);
    await prefs.remove(complaintKey);
    await prefs.remove(settingsKey);
    await prefs.remove(legacyMigratedKey);
    await prefs.remove(ambulanceBookingKey);
    settingsNotifier.value = const AppSettings();
  }

  static Future<bool> hasLegacyData() async {
    final users = await getUsers();
    final complaints = await getComplaints();
    return users.isNotEmpty || complaints.isNotEmpty;
  }

  static Future<bool> hasMarkedLegacyMigrationComplete() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(legacyMigratedKey) ?? false;
  }

  static Future<void> markLegacyDataMigrated() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(legacyMigratedKey, true);
  }
}
