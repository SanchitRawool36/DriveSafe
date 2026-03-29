import 'package:flutter/material.dart';
import '../models/app_user_model.dart';
import '../services/auth_service.dart';
import '../widgets/app_widgets.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  AppUser? user;

  @override
  void initState() {
    super.initState();
    loadUser();
  }

  Future<void> loadUser() async {
    final currentUser = await AuthService.getCurrentUserProfile();
    if (!mounted) return;
    setState(() {
      user = currentUser;
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

    if (currentUser.licenseStatus == 'Renewal Requested') {
      notifications.insert(0, 'Your license renewal request has been sent to admin and is awaiting review.');
    }

    if (currentUser.renewalTestDate.isNotEmpty) {
      notifications.insert(0, 'Your renewal test date is ${currentUser.renewalTestDate}. Please be ready with your documents.');
    }

    if (currentUser.licenseStatus == 'Renewal Approved') {
      notifications.insert(0, 'Your renewal request has been approved by admin.');
    }

    if (currentUser.licenseStatus == 'Renewal Rejected') {
      notifications.insert(0, 'Your renewal request was rejected. Open the license screen to review the latest update.');
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
              subtitle: 'Complaint, renewal, and account updates for your DriveSafe profile.',
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
