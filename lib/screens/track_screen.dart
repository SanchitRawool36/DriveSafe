import 'package:flutter/material.dart';
import '../models/app_user_model.dart';
import '../models/complaint_model.dart';
import '../services/auth_service.dart';
import '../services/complaint_repository.dart';
import '../utils/ui_feedback.dart';
import '../widgets/app_widgets.dart';
import 'complaint_detail_screen.dart';

class TrackScreen extends StatefulWidget {
  const TrackScreen({super.key});

  @override
  State<TrackScreen> createState() => _TrackScreenState();
}

class _TrackScreenState extends State<TrackScreen> {
  AppUser? currentUser;
  List<Complaint> complaints = [];
  String selectedStatus = 'All';

  @override
  void initState() {
    super.initState();
    loadComplaints();
  }

  Future<void> loadComplaints() async {
    try {
      final user = await AuthService.getCurrentUserProfile();
      if (!mounted) return;

      if (user == null) {
        showAppSnackBar(context, 'Your session expired. Please sign in again.', isError: true);
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }

      final allComplaints = await ComplaintRepository.getComplaintsForUser(user.id);
      if (!mounted) return;
      setState(() {
        currentUser = user;
        complaints = allComplaints;
      });
    } catch (error) {
      if (!mounted) return;
      showErrorSnackBar(context, error);
      await AuthService.logout();
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final visibleComplaints = selectedStatus == 'All'
        ? complaints
        : complaints.where((complaint) => complaint.status == selectedStatus).toList();

    return Scaffold(
      appBar: AppBar(title: const Text("Track Complaints")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppSectionTitle(
              title: 'Complaint Tracking',
              subtitle: currentUser == null
                  ? 'Showing complaints from Firebase.'
                  : 'Tracking complaints submitted by ${currentUser?.name ?? 'User'}. Only admins can change complaint status.',
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: selectedStatus,
              decoration: const InputDecoration(
                labelText: 'Filter By Status',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'All', child: Text('All')),
                DropdownMenuItem(value: 'Pending', child: Text('Pending')),
                DropdownMenuItem(value: 'In Progress', child: Text('In Progress')),
                DropdownMenuItem(value: 'Resolved', child: Text('Resolved')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    selectedStatus = value;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            Expanded(
              child: visibleComplaints.isEmpty
                  ? const Center(child: Text('No complaints found for this filter.'))
                  : ListView.builder(
                      itemCount: visibleComplaints.length,
                      itemBuilder: (context, index) {
                        final complaint = visibleComplaints[index];
                        return InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ComplaintDetailScreen(complaint: complaint),
                              ),
                            );
                          },
                          child: AppInfoCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        complaint.displayTitle,
                                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    ComplaintStatusChip(status: complaint.status),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  complaint.incidentType,
                                  style: const TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 8),
                                Text(complaint.displayDescription),
                                const SizedBox(height: 12),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.03),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    'Status updates are managed by admin.',
                                    style: TextStyle(color: Colors.black54),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}