class AppUser {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String password;
  final String licenseNumber;
  final String bio;
  final String address;
  final String dateOfBirth;
  final String bloodGroup;
  final String vehicleClass;
  final String issueDate;
  final String expiryDate;
  final String emergencyContact;
  final String licenseStatus;
  final String renewalRequestNote;
  final String renewalRequestedAt;
  final String renewalTestDate;
  final List<String> renewalHistory;
  final String profileImageData;
  final String role;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.password,
    required this.licenseNumber,
    this.bio = 'Road safety volunteer and active citizen reporter.',
    this.address = 'City Center',
    this.dateOfBirth = '',
    this.bloodGroup = '',
    this.vehicleClass = '',
    this.issueDate = '',
    this.expiryDate = '',
    this.emergencyContact = '',
    this.licenseStatus = 'Not Submitted',
    this.renewalRequestNote = '',
    this.renewalRequestedAt = '',
    this.renewalTestDate = '',
    this.renewalHistory = const [],
    this.profileImageData = '',
    this.role = 'user',
  });

  bool get hasCompletedLicenseProfile {
    return dateOfBirth.isNotEmpty &&
        bloodGroup.isNotEmpty &&
        vehicleClass.isNotEmpty &&
        issueDate.isNotEmpty &&
        expiryDate.isNotEmpty;
  }

  bool get hasProfileImage => profileImageData.isNotEmpty;

  bool get isAdmin => role == 'admin';

  AppUser copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? password,
    String? licenseNumber,
    String? bio,
    String? address,
    String? dateOfBirth,
    String? bloodGroup,
    String? vehicleClass,
    String? issueDate,
    String? expiryDate,
    String? emergencyContact,
    String? licenseStatus,
    String? renewalRequestNote,
    String? renewalRequestedAt,
    String? renewalTestDate,
    List<String>? renewalHistory,
    String? profileImageData,
    String? role,
  }) {
    return AppUser(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      password: password ?? this.password,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      bio: bio ?? this.bio,
      address: address ?? this.address,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      vehicleClass: vehicleClass ?? this.vehicleClass,
      issueDate: issueDate ?? this.issueDate,
      expiryDate: expiryDate ?? this.expiryDate,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      licenseStatus: licenseStatus ?? this.licenseStatus,
      renewalRequestNote: renewalRequestNote ?? this.renewalRequestNote,
      renewalRequestedAt: renewalRequestedAt ?? this.renewalRequestedAt,
      renewalTestDate: renewalTestDate ?? this.renewalTestDate,
      renewalHistory: renewalHistory ?? this.renewalHistory,
      profileImageData: profileImageData ?? this.profileImageData,
      role: role ?? this.role,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'password': password,
      'licenseNumber': licenseNumber,
      'bio': bio,
      'address': address,
      'dateOfBirth': dateOfBirth,
      'bloodGroup': bloodGroup,
      'vehicleClass': vehicleClass,
      'issueDate': issueDate,
      'expiryDate': expiryDate,
      'emergencyContact': emergencyContact,
      'licenseStatus': licenseStatus,
      'renewalRequestNote': renewalRequestNote,
      'renewalRequestedAt': renewalRequestedAt,
      'renewalTestDate': renewalTestDate,
      'renewalHistory': renewalHistory,
      'profileImageData': profileImageData,
      'role': role,
    };
  }

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] ?? '',
      name: json['name'] ?? 'User',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      password: json['password'] ?? '',
      licenseNumber: json['licenseNumber'] ?? 'DL-0000-0000000',
      bio: json['bio'] ?? 'Road safety volunteer and active citizen reporter.',
      address: json['address'] ?? 'City Center',
      dateOfBirth: json['dateOfBirth'] ?? '',
      bloodGroup: json['bloodGroup'] ?? '',
      vehicleClass: json['vehicleClass'] ?? '',
      issueDate: json['issueDate'] ?? '',
      expiryDate: json['expiryDate'] ?? '',
      emergencyContact: json['emergencyContact'] ?? '',
      licenseStatus: json['licenseStatus'] ?? 'Not Submitted',
      renewalRequestNote: json['renewalRequestNote'] ?? '',
      renewalRequestedAt: json['renewalRequestedAt'] ?? '',
      renewalTestDate: json['renewalTestDate'] ?? '',
      renewalHistory: (json['renewalHistory'] as List<dynamic>? ?? const [])
          .map((entry) => entry.toString())
          .toList(),
      profileImageData: json['profileImageData'] ?? '',
      role: json['role'] ?? 'user',
    );
  }
}