import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import '../models/complaint_model.dart';

class FirestoreService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  static void _ensureSignedIn() {
    if (FirebaseAuth.instance.currentUser == null) {
      throw Exception('Your session expired. Please sign in again.');
    }
  }

  static Future<void> saveComplaint(
    Complaint complaint, {
    Uint8List? imageBytes,
    String? imageName,
  }) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    final userId = currentUser?.uid;
    Map<String, dynamic>? reporterData;
    final docRef = complaint.id.isEmpty
        ? _db.collection('complaints').doc()
        : _db.collection('complaints').doc(complaint.id);

    if (userId != null && userId.isNotEmpty) {
      final userDoc = await _db.collection('users').doc(userId).get();
      reporterData = userDoc.data();
    }

    String? imageUrl = complaint.imageUrl;
    if (imageBytes != null && imageBytes.isNotEmpty) {
      final uploadId = const Uuid().v4();
      final extension = _fileExtension(imageName);
      final ref = _storage.ref().child('complaint_images/${userId ?? 'anonymous'}/$uploadId$extension');
      await ref.putData(
        imageBytes,
        SettableMetadata(contentType: _contentTypeForFileName(imageName)),
      );
      imageUrl = await ref.getDownloadURL();
    }

    final payload = Map<String, dynamic>.from(complaint.toJson())
      ..['id'] = docRef.id
      ..['userId'] = complaint.userId ?? userId
      ..['createdAt'] = complaint.createdAt.toUtc().toIso8601String()
      ..['imageUrl'] = imageUrl
      ..['imageData'] = imageUrl == null ? complaint.imageData : null
      ..['reporterName'] = complaint.reporterName ?? reporterData?['name'] ?? currentUser?.displayName ?? 'DriveSafe User'
      ..['reporterEmail'] = complaint.reporterEmail ?? reporterData?['email'] ?? currentUser?.email
      ..['reporterPhone'] = complaint.reporterPhone ?? reporterData?['phone'];

    await docRef.set(payload, SetOptions(merge: true));
  }

  static Future<List<Complaint>> getComplaints() async {
    _ensureSignedIn();
    final snap = await _db.collection('complaints').orderBy('createdAt', descending: true).get();
    return snap.docs.map((d) => Complaint.fromFirestore(d.data(), d.id)).toList();
  }

  static Stream<List<Complaint>> watchComplaints({String? userId}) {
    Query<Map<String, dynamic>> query = _db.collection('complaints');

    if (userId != null && userId.isNotEmpty) {
      query = _db.collection('complaints').where('userId', isEqualTo: userId);
    } else {
      query = query.orderBy('createdAt', descending: true);
    }

    return query.snapshots().map((snap) {
      final complaints = snap.docs.map((d) => Complaint.fromFirestore(d.data(), d.id)).toList();
      complaints.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return complaints;
    });
  }

  static Future<List<Complaint>> getComplaintsForUser(String? userId) async {
    _ensureSignedIn();
    if (userId == null || userId.isEmpty) {
      return getComplaints();
    }

    final snap = await _db.collection('complaints').where('userId', isEqualTo: userId).get();
    final complaints = snap.docs.map((d) => Complaint.fromFirestore(d.data(), d.id)).toList();
    complaints.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return complaints;
  }

  static Future<Map<String, int>> getComplaintStats({String? userId}) async {
    _ensureSignedIn();
    final complaints = userId == null ? await getComplaints() : await getComplaintsForUser(userId);
    final accepted = complaints.where((complaint) => complaint.status == 'Accepted').length;
    final resolved = complaints.where((complaint) => complaint.status == 'Resolved').length;
    final pending = complaints.where((complaint) => complaint.status == 'Pending').length;
    final inProgress = complaints.where((complaint) => complaint.status == 'In Progress').length;
    final rejected = complaints.where((complaint) => complaint.status == 'Rejected').length;

    return {
      'total': complaints.length,
      'accepted': accepted,
      'resolved': resolved,
      'pending': pending,
      'inProgress': inProgress,
      'rejected': rejected,
    };
  }

  static Stream<Map<String, int>> watchComplaintStats({String? userId}) {
    return watchComplaints(userId: userId).map((complaints) {
      final accepted = complaints.where((complaint) => complaint.status == 'Accepted').length;
      final resolved = complaints.where((complaint) => complaint.status == 'Resolved').length;
      final pending = complaints.where((complaint) => complaint.status == 'Pending').length;
      final inProgress = complaints.where((complaint) => complaint.status == 'In Progress').length;
      final rejected = complaints.where((complaint) => complaint.status == 'Rejected').length;

      return {
        'total': complaints.length,
        'accepted': accepted,
        'resolved': resolved,
        'pending': pending,
        'inProgress': inProgress,
        'rejected': rejected,
      };
    });
  }

  static Future<void> updateComplaintStatus(String complaintId, String status) async {
    _ensureSignedIn();
    await _db.collection('complaints').doc(complaintId).update({'status': status});
  }

  static Future<void> saveAllComplaints(List<Complaint> complaints) async {
    final batch = _db.batch();

    for (final complaint in complaints) {
      final docId = complaint.id.isEmpty ? _db.collection('complaints').doc().id : complaint.id;
      final docRef = _db.collection('complaints').doc(docId);
      final payload = Map<String, dynamic>.from(complaint.toJson())..['id'] = docId;
      batch.set(docRef, payload);
    }

    await batch.commit();
  }

  static String _fileExtension(String? imageName) {
    if (imageName == null || !imageName.contains('.')) {
      return '.jpg';
    }

    return '.${imageName.split('.').last.toLowerCase()}';
  }

  static String _contentTypeForFileName(String? imageName) {
    final extension = _fileExtension(imageName);
    switch (extension) {
      case '.png':
        return 'image/png';
      case '.webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }
}
