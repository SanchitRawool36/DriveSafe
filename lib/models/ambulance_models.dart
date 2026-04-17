class AmbulanceProvider {
  final String id;
  final String name;
  final String operatorType;
  final String area;
  final String phoneNumber;
  final int etaMinutes;
  final int serviceFee;
  final String currentPosition;
  final String notes;
  final bool isGovernment;
  final double latitude;
  final double longitude;

  const AmbulanceProvider({
    required this.id,
    required this.name,
    required this.operatorType,
    required this.area,
    required this.phoneNumber,
    required this.etaMinutes,
    required this.serviceFee,
    required this.currentPosition,
    required this.notes,
    required this.isGovernment,
    required this.latitude,
    required this.longitude,
  });
}

class AmbulanceBooking {
  final String id;
  final String providerId;
  final String providerName;
  final String providerArea;
  final String phoneNumber;
  final String bookedByUserId;
  final String bookedByName;
  final String bookedByPhone;
  final String bookedByEmail;
  final String patientName;
  final String emergencyReason;
  final String pickupLocation;
  final double pickupLatitude;
  final double pickupLongitude;
  final String paymentMethod;
  final int serviceFee;
  final int etaMinutes;
  final String status;
  final String currentPosition;
  final double currentLatitude;
  final double currentLongitude;
  final double progress;
  final int stageIndex;
  final String bookedAtIso;
  final List<Map<String, double>> routePoints;

  const AmbulanceBooking({
    required this.id,
    required this.providerId,
    required this.providerName,
    required this.providerArea,
    required this.phoneNumber,
    required this.bookedByUserId,
    required this.bookedByName,
    required this.bookedByPhone,
    required this.bookedByEmail,
    required this.patientName,
    required this.emergencyReason,
    required this.pickupLocation,
    required this.pickupLatitude,
    required this.pickupLongitude,
    required this.paymentMethod,
    required this.serviceFee,
    required this.etaMinutes,
    required this.status,
    required this.currentPosition,
    required this.currentLatitude,
    required this.currentLongitude,
    required this.progress,
    required this.stageIndex,
    required this.bookedAtIso,
    required this.routePoints,
  });

  AmbulanceBooking copyWith({
    String? id,
    String? providerId,
    String? providerName,
    String? providerArea,
    String? phoneNumber,
    String? bookedByUserId,
    String? bookedByName,
    String? bookedByPhone,
    String? bookedByEmail,
    String? patientName,
    String? emergencyReason,
    String? pickupLocation,
    double? pickupLatitude,
    double? pickupLongitude,
    String? paymentMethod,
    int? serviceFee,
    int? etaMinutes,
    String? status,
    String? currentPosition,
    double? currentLatitude,
    double? currentLongitude,
    double? progress,
    int? stageIndex,
    String? bookedAtIso,
    List<Map<String, double>>? routePoints,
  }) {
    return AmbulanceBooking(
      id: id ?? this.id,
      providerId: providerId ?? this.providerId,
      providerName: providerName ?? this.providerName,
      providerArea: providerArea ?? this.providerArea,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      bookedByUserId: bookedByUserId ?? this.bookedByUserId,
      bookedByName: bookedByName ?? this.bookedByName,
      bookedByPhone: bookedByPhone ?? this.bookedByPhone,
      bookedByEmail: bookedByEmail ?? this.bookedByEmail,
      patientName: patientName ?? this.patientName,
      emergencyReason: emergencyReason ?? this.emergencyReason,
      pickupLocation: pickupLocation ?? this.pickupLocation,
      pickupLatitude: pickupLatitude ?? this.pickupLatitude,
      pickupLongitude: pickupLongitude ?? this.pickupLongitude,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      serviceFee: serviceFee ?? this.serviceFee,
      etaMinutes: etaMinutes ?? this.etaMinutes,
      status: status ?? this.status,
      currentPosition: currentPosition ?? this.currentPosition,
      currentLatitude: currentLatitude ?? this.currentLatitude,
      currentLongitude: currentLongitude ?? this.currentLongitude,
      progress: progress ?? this.progress,
      stageIndex: stageIndex ?? this.stageIndex,
      bookedAtIso: bookedAtIso ?? this.bookedAtIso,
      routePoints: routePoints ?? this.routePoints,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'providerId': providerId,
      'providerName': providerName,
      'providerArea': providerArea,
      'phoneNumber': phoneNumber,
      'bookedByUserId': bookedByUserId,
      'bookedByName': bookedByName,
      'bookedByPhone': bookedByPhone,
      'bookedByEmail': bookedByEmail,
      'patientName': patientName,
      'emergencyReason': emergencyReason,
      'pickupLocation': pickupLocation,
      'pickupLatitude': pickupLatitude,
      'pickupLongitude': pickupLongitude,
      'paymentMethod': paymentMethod,
      'serviceFee': serviceFee,
      'etaMinutes': etaMinutes,
      'status': status,
      'currentPosition': currentPosition,
      'currentLatitude': currentLatitude,
      'currentLongitude': currentLongitude,
      'progress': progress,
      'stageIndex': stageIndex,
      'bookedAtIso': bookedAtIso,
      'routePoints': routePoints,
    };
  }

  factory AmbulanceBooking.fromJson(Map<String, dynamic> json) {
    return AmbulanceBooking(
      id: json['id'] ?? '',
      providerId: json['providerId'] ?? '',
      providerName: json['providerName'] ?? '',
      providerArea: json['providerArea'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      bookedByUserId: json['bookedByUserId'] ?? '',
      bookedByName: json['bookedByName'] ?? '',
      bookedByPhone: json['bookedByPhone'] ?? '',
      bookedByEmail: json['bookedByEmail'] ?? '',
      patientName: json['patientName'] ?? '',
      emergencyReason: json['emergencyReason'] ?? '',
      pickupLocation: json['pickupLocation'] ?? '',
      pickupLatitude: (json['pickupLatitude'] ?? 0.0).toDouble(),
      pickupLongitude: (json['pickupLongitude'] ?? 0.0).toDouble(),
      paymentMethod: json['paymentMethod'] ?? 'UPI',
      serviceFee: json['serviceFee'] ?? 0,
      etaMinutes: json['etaMinutes'] ?? 0,
      status: json['status'] ?? 'Booking Confirmed',
      currentPosition: json['currentPosition'] ?? '',
      currentLatitude: (json['currentLatitude'] ?? 0.0).toDouble(),
      currentLongitude: (json['currentLongitude'] ?? 0.0).toDouble(),
      progress: (json['progress'] ?? 0.0).toDouble(),
      stageIndex: json['stageIndex'] ?? 0,
      bookedAtIso: json['bookedAtIso'] ?? DateTime.now().toIso8601String(),
      routePoints: (json['routePoints'] as List<dynamic>? ?? const [])
          .map<Map<String, double>>(
            (entry) => <String, double>{
              'lat': (((entry as Map<String, dynamic>)['lat']) ?? 0.0).toDouble(),
              'lon': ((entry['lon']) ?? 0.0).toDouble(),
            },
          )
          .toList(),
    );
  }
}