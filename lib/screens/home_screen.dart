import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'register_screen.dart';
import 'report_issue_screen.dart';
import 'track_screen.dart';
import 'dl_screen.dart';
import '../widgets/app_widgets.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Widget buildButton(BuildContext context, String title, Widget screen) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: AppPrimaryButton(
        label: title,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => screen),
          );
        },
      ),
    );
  }

  Widget buildSecondaryButton(BuildContext context, String title, Widget screen) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: AppSecondaryButton(
        label: title,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => screen),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Drive Safe")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            const AppSectionTitle(
              title: 'Welcome To Drive Safe',
              subtitle: 'Local prototype for crowd reporting and digital license workflows.',
            ),
            const SizedBox(height: 20),

            buildButton(context, "Login", const LoginScreen()),
            buildSecondaryButton(context, "Register", const RegisterScreen()),
            buildButton(context, "Report Issue", const ReportIssueScreen()),
            buildButton(context, "Track Complaints", const TrackScreen()),
            buildSecondaryButton(context, "Apply Driving License", const DLScreen()),
          ],
        ),
      ),
    );
  }
}