class AppSettings {
  final bool notificationAlerts;
  final bool gpsAssist;
  final bool strongBlueAccent;

  const AppSettings({
    this.notificationAlerts = true,
    this.gpsAssist = true,
    this.strongBlueAccent = false,
  });

  AppSettings copyWith({
    bool? notificationAlerts,
    bool? gpsAssist,
    bool? strongBlueAccent,
  }) {
    return AppSettings(
      notificationAlerts: notificationAlerts ?? this.notificationAlerts,
      gpsAssist: gpsAssist ?? this.gpsAssist,
      strongBlueAccent: strongBlueAccent ?? this.strongBlueAccent,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'notificationAlerts': notificationAlerts,
      'gpsAssist': gpsAssist,
      'strongBlueAccent': strongBlueAccent,
    };
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      notificationAlerts: json['notificationAlerts'] ?? true,
      gpsAssist: json['gpsAssist'] ?? true,
      strongBlueAccent: json['strongBlueAccent'] ?? false,
    );
  }
}