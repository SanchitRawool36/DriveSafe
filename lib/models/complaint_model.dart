class Complaint {
  String id;
  String title;
  String description;
  String incidentType;
  String status;
  String? imageUrl;
  String? imageData;
  DateTime createdAt;
  String? userId;
  Map<String, dynamic>? location;
  String? reporterName;
  String? reporterEmail;
  String? reporterPhone;

  Complaint({
    this.id = '',
    required this.title,
    required this.description,
    this.incidentType = 'Other',
    this.status = 'Pending',
    this.imageUrl,
    this.imageData,
    DateTime? createdAt,
    this.userId,
    this.location,
    this.reporterName,
    this.reporterEmail,
    this.reporterPhone,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'incidentType': incidentType,
      'status': status,
      'imageUrl': imageUrl,
      'imageData': imageData,
      'createdAt': createdAt.toUtc().toIso8601String(),
      'userId': userId,
      'location': location,
      'reporterName': reporterName,
      'reporterEmail': reporterEmail,
      'reporterPhone': reporterPhone,
    };
  }

  factory Complaint.fromJson(Map<String, dynamic> json) {
    return Complaint(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      incidentType: json['incidentType'] ?? _inferIncidentType(json['title'] ?? ''),
      status: json['status'] ?? 'Pending',
      imageUrl: json['imageUrl'],
      imageData: json['imageData'],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']).toLocal() : DateTime.now(),
      userId: json['userId'],
      location: json['location'] != null ? Map<String, dynamic>.from(json['location']) : null,
      reporterName: json['reporterName'],
      reporterEmail: json['reporterEmail'],
      reporterPhone: json['reporterPhone'],
    );
  }

  factory Complaint.fromFirestore(Map<String, dynamic> json, String id) {
    final data = Map<String, dynamic>.from(json);
    data['id'] = id;
    return Complaint.fromJson(data);
  }

  String get displayTitle {
    if (_isLegacyCategoryTitle(title) && description.contains('\n')) {
      return description.split('\n').first.trim();
    }
    return title;
  }

  String get displayDescription {
    if (_isLegacyCategoryTitle(title) && description.contains('\n')) {
      return description.split('\n').skip(1).join('\n').trim();
    }
    return description;
  }

  static String _inferIncidentType(String title) {
    if (_isLegacyCategoryTitle(title)) {
      return title;
    }
    return 'Other';
  }

  static bool _isLegacyCategoryTitle(String value) {
    return const {
      'Accident',
      'Traffic Jam',
      'Road Hazard',
      'Reckless Driving',
    }.contains(value);
  }
}
