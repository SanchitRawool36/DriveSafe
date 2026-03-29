import '../models/complaint_model.dart';
import 'firestore_service.dart';
import 'local_storage_service.dart';
import 'dart:typed_data';

enum ComplaintBackend {
  local,
  firebase,
}

class ComplaintRepository {
  static const ComplaintBackend backend = ComplaintBackend.firebase;

  static bool get isFirebaseMode => backend == ComplaintBackend.firebase;

  static Future<void> saveComplaint(
    Complaint complaint, {
    Uint8List? imageBytes,
    String? imageName,
  }) {
    switch (backend) {
      case ComplaintBackend.firebase:
        return FirestoreService.saveComplaint(
          complaint,
          imageBytes: imageBytes,
          imageName: imageName,
        );
      case ComplaintBackend.local:
        return LocalStorageService.saveComplaint(complaint);
    }
  }

  static Future<List<Complaint>> getComplaints() {
    switch (backend) {
      case ComplaintBackend.firebase:
        return FirestoreService.getComplaints();
      case ComplaintBackend.local:
        return LocalStorageService.getComplaints();
    }
  }

  static Stream<List<Complaint>> watchComplaints({String? userId}) async* {
    switch (backend) {
      case ComplaintBackend.firebase:
        yield* FirestoreService.watchComplaints(userId: userId);
      case ComplaintBackend.local:
        final complaints = userId == null ? await LocalStorageService.getComplaints() : await LocalStorageService.getComplaintsForUser(userId);
        yield complaints;
    }
  }

  static Future<List<Complaint>> getComplaintsForUser(String? userId) {
    switch (backend) {
      case ComplaintBackend.firebase:
        return FirestoreService.getComplaintsForUser(userId);
      case ComplaintBackend.local:
        return LocalStorageService.getComplaintsForUser(userId);
    }
  }

  static Future<Map<String, int>> getComplaintStats({String? userId}) {
    switch (backend) {
      case ComplaintBackend.firebase:
        return FirestoreService.getComplaintStats(userId: userId);
      case ComplaintBackend.local:
        return LocalStorageService.getComplaintStats(userId: userId);
    }
  }

  static Stream<Map<String, int>> watchComplaintStats({String? userId}) async* {
    switch (backend) {
      case ComplaintBackend.firebase:
        yield* FirestoreService.watchComplaintStats(userId: userId);
      case ComplaintBackend.local:
        yield await LocalStorageService.getComplaintStats(userId: userId);
    }
  }

  static Future<void> updateComplaintStatus(String complaintId, String status) {
    switch (backend) {
      case ComplaintBackend.firebase:
        return FirestoreService.updateComplaintStatus(complaintId, status);
      case ComplaintBackend.local:
        return LocalStorageService.updateComplaintStatus(complaintId, status);
    }
  }

  static Future<void> saveAllComplaints(List<Complaint> complaints) {
    switch (backend) {
      case ComplaintBackend.firebase:
        return FirestoreService.saveAllComplaints(complaints);
      case ComplaintBackend.local:
        return LocalStorageService.saveAllComplaints(complaints);
    }
  }
}