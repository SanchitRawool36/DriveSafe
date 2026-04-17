import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/ambulance_models.dart';
import '../models/app_user_model.dart';
import 'local_storage_service.dart';

class AmbulanceService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static const List<AmbulanceProvider> governmentProviders = [
    AmbulanceProvider(
      id: 'gov-108',
      name: '108 Emergency Ambulance',
      operatorType: 'Government',
      area: 'Sindhudurg District Emergency Support',
      phoneNumber: '108',
      etaMinutes: 12,
      serviceFee: 0,
      currentPosition: 'Government emergency dispatch network',
      notes: 'Use this for immediate emergency response. Government ambulance dispatch is call-only from this screen.',
      isGovernment: true,
      latitude: 16.0167,
      longitude: 73.6833,
    ),
  ];

  static const List<AmbulanceProvider> privateProviders = [
    AmbulanceProvider(
      id: 'jeevan-jyot-kudal',
      name: 'Jeevan Jyot Ambulance',
      operatorType: 'Private',
      area: 'Kudal',
      phoneNumber: '+917942694350',
      etaMinutes: 18,
      serviceFee: 1200,
      currentPosition: 'Leaving Kudal ambulance point',
      notes: 'Client-approved operator for Kudal coverage and nearby highway response.',
      isGovernment: false,
      latitude: 16.0111,
      longitude: 73.6889,
    ),
    AmbulanceProvider(
      id: 'arekar-sawantwadi',
      name: 'Arekar Ambulance',
      operatorType: 'Private',
      area: 'Sawantwadi',
      phoneNumber: '+919422632012',
      etaMinutes: 12,
      serviceFee: 900,
      currentPosition: 'Near Sawantwadi market route',
      notes: 'Suitable for Sawantwadi city pickup and surrounding local transport.',
      isGovernment: false,
      latitude: 15.9050,
      longitude: 73.8213,
    ),
    AmbulanceProvider(
      id: 'hemant-marathe-malewad',
      name: 'Hemant Marathe Ambulance',
      operatorType: 'Private',
      area: 'Malewad',
      phoneNumber: '+919420130724',
      etaMinutes: 20,
      serviceFee: 1100,
      currentPosition: 'On the Malewad highway stretch',
      notes: 'Client-approved operator covering Malewad and nearby routes.',
      isGovernment: false,
      latitude: 15.9560,
      longitude: 73.8590,
    ),
    AmbulanceProvider(
      id: 'janseva-kolhapur',
      name: 'Janseva Ambulance',
      operatorType: 'Private',
      area: 'Kolhapur',
      phoneNumber: '+913094494948',
      etaMinutes: 35,
      serviceFee: 1800,
      currentPosition: 'Dispatching from Kolhapur city side',
      notes: 'Longer-distance private support option for intercity transport.',
      isGovernment: false,
      latitude: 16.7050,
      longitude: 74.2433,
    ),
    AmbulanceProvider(
      id: 'rawool-shiroda',
      name: 'Rawool Ambulance',
      operatorType: 'Private',
      area: 'Shiroda',
      phoneNumber: '+917038493367',
      etaMinutes: 15,
      serviceFee: 1000,
      currentPosition: 'Near Shiroda junction',
      notes: 'Client-approved operator for Shiroda side pickups.',
      isGovernment: false,
      latitude: 15.8980,
      longitude: 73.6810,
    ),
    AmbulanceProvider(
      id: 'naik-tulas',
      name: 'Naik Ambulance',
      operatorType: 'Private',
      area: 'Tulas',
      phoneNumber: '+919309136877',
      etaMinutes: 17,
      serviceFee: 950,
      currentPosition: 'Approaching Tulas road section',
      notes: 'Client-approved local operator for Tulas area support.',
      isGovernment: false,
      latitude: 15.8720,
      longitude: 73.7420,
    ),
  ];

  static List<AmbulanceProvider> get allProviders => [...governmentProviders, ...privateProviders];

  static AmbulanceProvider? providerById(String id) {
    for (final provider in allProviders) {
      if (provider.id == id) {
        return provider;
      }
    }
    return null;
  }

  static Future<void> saveBooking(AmbulanceBooking booking) async {
    final docId = booking.id.isEmpty ? _db.collection('ambulance_bookings').doc().id : booking.id;
    final payload = Map<String, dynamic>.from(booking.toJson())..['id'] = docId;
    try {
      await _db.collection('ambulance_bookings').doc(docId).set(payload, SetOptions(merge: true));
    } on FirebaseException catch (error) {
      if (error.code != 'permission-denied') {
        rethrow;
      }
    }
    await LocalStorageService.saveAmbulanceBooking(booking.copyWith(id: docId));
  }

  static Future<AmbulanceBooking?> getCurrentUserBooking() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return LocalStorageService.getAmbulanceBooking();
    }

    QuerySnapshot<Map<String, dynamic>> snap;
    try {
      snap = await _db
          .collection('ambulance_bookings')
          .where('bookedByUserId', isEqualTo: currentUser.uid)
          .get();
    } on FirebaseException catch (error) {
      if (error.code == 'permission-denied') {
        return LocalStorageService.getAmbulanceBooking();
      }
      rethrow;
    }

    if (snap.docs.isEmpty) {
      return LocalStorageService.getAmbulanceBooking();
    }

    final bookings = snap.docs.map((doc) => AmbulanceBooking.fromJson(doc.data())).toList()
      ..sort((a, b) => b.bookedAtIso.compareTo(a.bookedAtIso));
    final booking = bookings.first;
    await LocalStorageService.saveAmbulanceBooking(booking);
    return booking;
  }

  static Future<List<AmbulanceBooking>> getAllBookings() async {
    try {
      final snap = await _db.collection('ambulance_bookings').orderBy('bookedAtIso', descending: true).get();
      return snap.docs.map((doc) => AmbulanceBooking.fromJson(doc.data())).toList();
    } on FirebaseException catch (error) {
      if (error.code == 'permission-denied') {
        final localBooking = await LocalStorageService.getAmbulanceBooking();
        return localBooking == null ? const [] : [localBooking];
      }
      rethrow;
    }
  }

  static Future<void> updateBooking(AmbulanceBooking booking) async {
    if (booking.id.isEmpty) {
      await saveBooking(booking);
      return;
    }

    try {
      await _db.collection('ambulance_bookings').doc(booking.id).set(booking.toJson(), SetOptions(merge: true));
    } on FirebaseException catch (error) {
      if (error.code != 'permission-denied') {
        rethrow;
      }
    }
    await LocalStorageService.saveAmbulanceBooking(booking);
  }

  static Future<void> clearCurrentBooking() async {
    final booking = await LocalStorageService.getAmbulanceBooking();
    if (booking != null && booking.id.isNotEmpty) {
      try {
        await _db.collection('ambulance_bookings').doc(booking.id).set({'status': 'Completed'}, SetOptions(merge: true));
      } on FirebaseException catch (error) {
        if (error.code != 'permission-denied') {
          rethrow;
        }
      }
    }
    await LocalStorageService.clearAmbulanceBooking();
  }

  static List<Map<String, double>> buildRoutePoints({
    required AmbulanceProvider provider,
    required double pickupLatitude,
    required double pickupLongitude,
  }) {
    const totalPoints = 12;
    final route = <Map<String, double>>[];
    for (var index = 0; index < totalPoints; index++) {
      final t = index / (totalPoints - 1);
      final curve = sin(t * pi) * 0.015;
      final lat = provider.latitude + ((pickupLatitude - provider.latitude) * t) + curve;
      final lon = provider.longitude + ((pickupLongitude - provider.longitude) * t) - (curve / 2);
      route.add(<String, double>{'lat': lat, 'lon': lon});
    }
    return route;
  }

  static Map<String, double> estimatePickupCoordinates(String seedText, AmbulanceProvider provider) {
    final hash = seedText.codeUnits.fold<int>(0, (sum, char) => sum + char);
    final latOffset = ((hash % 14) - 7) * 0.0035;
    final lonOffset = (((hash ~/ 10) % 14) - 7) * 0.0035;
    return {
      'lat': provider.latitude + latOffset,
      'lon': provider.longitude + lonOffset,
    };
  }

  static AmbulanceBooking advanceBooking(AmbulanceBooking booking) {
    if (booking.routePoints.isEmpty) {
      return booking;
    }

    final nextStage = min(booking.stageIndex + 1, booking.routePoints.length - 1);
    final point = booking.routePoints[nextStage];
    final remainingStops = booking.routePoints.length - 1 - nextStage;
    final nextEta = max((booking.etaMinutes * (remainingStops / max(booking.routePoints.length - 1, 1))).round(), 0);
    String nextStatus;
    if (nextStage == booking.routePoints.length - 1) {
      nextStatus = 'Arrived';
    } else if (nextStage >= booking.routePoints.length - 3) {
      nextStatus = 'Nearby';
    } else if (nextStage >= 2) {
      nextStatus = 'On The Way';
    } else {
      nextStatus = 'Driver Assigned';
    }

    return booking.copyWith(
      status: nextStatus,
      currentPosition: nextStage == booking.routePoints.length - 1
          ? 'Ambulance has arrived at ${booking.pickupLocation}'
          : 'Ambulance moving towards ${booking.pickupLocation}',
      currentLatitude: point['lat'] ?? booking.currentLatitude,
      currentLongitude: point['lon'] ?? booking.currentLongitude,
      etaMinutes: nextEta,
      progress: nextStage / (booking.routePoints.length - 1),
      stageIndex: nextStage,
    );
  }

  static AmbulanceBooking buildBooking({
    required AmbulanceProvider provider,
    required AppUser? currentUser,
    required String patientName,
    required String pickupLocation,
    required String emergencyReason,
    required String paymentMethod,
  }) {
    final pickup = estimatePickupCoordinates(pickupLocation, provider);
    final route = buildRoutePoints(
      provider: provider,
      pickupLatitude: pickup['lat']!,
      pickupLongitude: pickup['lon']!,
    );
    final start = route.first;

    return AmbulanceBooking(
      id: '',
      providerId: provider.id,
      providerName: provider.name,
      providerArea: provider.area,
      phoneNumber: provider.phoneNumber,
      bookedByUserId: currentUser?.id ?? '',
      bookedByName: currentUser?.name ?? patientName,
      bookedByPhone: currentUser?.phone ?? '',
      bookedByEmail: currentUser?.email ?? '',
      patientName: patientName,
      emergencyReason: emergencyReason,
      pickupLocation: pickupLocation,
      pickupLatitude: pickup['lat']!,
      pickupLongitude: pickup['lon']!,
      paymentMethod: paymentMethod,
      serviceFee: provider.serviceFee,
      etaMinutes: provider.etaMinutes,
      status: 'Booked & Paid',
      currentPosition: 'Dispatch confirmed at ${provider.area}',
      currentLatitude: start['lat']!,
      currentLongitude: start['lon']!,
      progress: 0,
      stageIndex: 0,
      bookedAtIso: DateTime.now().toIso8601String(),
      routePoints: route,
    );
  }
}