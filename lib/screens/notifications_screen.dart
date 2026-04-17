import 'package:flutter/material.dart';
import '../models/ambulance_models.dart';
import '../models/app_user_model.dart';
import '../services/ambulance_service.dart';
import '../services/auth_service.dart';
import '../widgets/app_widgets.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  AppUser? user;
  AmbulanceBooking? booking;

  @override
  void initState() {
    super.initState();
    loadUser();
  }

  Future<void> loadUser() async {
    final currentUser = await AuthService.getCurrentUserProfile();
    final activeBooking = await AmbulanceService.getCurrentUserBooking();
    if (!mounted) return;
    setState(() {
      user = currentUser;
      booking = activeBooking;
    });
  }

  List<String> _buildNotifications() {
    final currentUser = user;
    final notifications = <String>[
      'Your recent complaint is under review.',
      'Road hazard updates are available in your area.',
      'Profile completeness helps with faster report processing.',
    ];

    if (currentUser == null) {
      return notifications;
    }

    final activeBooking = booking;
    if (activeBooking != null) {
      notifications.insert(0, 'Ambulance ETA: ${activeBooking.etaMinutes == 0 ? 'Arrived' : '${activeBooking.etaMinutes} min'} for ${activeBooking.providerName}.');
      notifications.insert(0, 'Ambulance tracking update: ${activeBooking.currentPosition}.');
    }

    if ((currentUser.address).trim().isNotEmpty) {
      notifications.insert(0, 'Default ambulance pickup location is set from your profile address.');
    }

    return notifications;
  }

  @override
  Widget build(BuildContext context) {
    final notifications = _buildNotifications();

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppSectionTitle(
              title: 'Notifications',
              subtitle: 'Complaint, ambulance, and account updates for your DriveSafe profile.',
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  return AppInfoCard(
                    child: ListTile(
                      leading: const Icon(Icons.notifications_active),
                      title: Text(notifications[index]),
                    ),
                  );
                },
              ),
            ),
            AppSecondaryButton(
              label: 'Mark All As Read',
              icon: Icons.done_all,
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All notifications marked as read.')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
