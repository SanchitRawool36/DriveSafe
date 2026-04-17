import 'package:flutter/material.dart';
import '../models/complaint_model.dart';
import '../models/app_user_model.dart';
import '../services/complaint_repository.dart';
import '../services/auth_service.dart';
import '../utils/ui_feedback.dart';
import '../widgets/app_widgets.dart';
import 'ambulance_screen.dart';
import 'complaint_detail_screen.dart';
import 'incidents_screen.dart';
import 'report_issue_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<Complaint> complaints = [];
  AppUser? currentUser;
  Map<String, int> stats = const {
    'total': 0,
    'resolved': 0,
    'pending': 0,
    'inProgress': 0,
  };

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

      final data = await ComplaintRepository.getComplaints();
      final complaintStats = await ComplaintRepository.getComplaintStats();
      if (!mounted) return;
      setState(() {
        complaints = data;
        currentUser = user;
        stats = complaintStats;
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
    return Scaffold(
      appBar: AppBar(
        title: Row(children: const [Icon(Icons.shield, color: Colors.white), SizedBox(width: 8), Text('DriveSafe')]),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.pushNamed(context, '/profile').then((_) => loadComplaints());
            },
            icon: const Icon(Icons.person),
            tooltip: 'Profile',
          ),
          IconButton(
            onPressed: () {
              Navigator.pushNamed(context, '/notifications');
            },
            icon: const Icon(Icons.notifications),
          ),
          IconButton(
            onPressed: () {
              Navigator.pushNamed(context, '/settings');
            },
            icon: const Icon(Icons.settings),
          ),
          IconButton(
            onPressed: () async {
              await AuthService.logout();
              if (!context.mounted) return;
              Navigator.pushReplacementNamed(context, '/login');
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: const LinearGradient(
                  colors: [Color(0xFF0B65C2), Color(0xFF2F80ED)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0B65C2).withValues(alpha: 0.18),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: Colors.white,
                        child: Text(
                          ((currentUser?.name ?? 'D').isEmpty ? 'D' : (currentUser?.name ?? 'D')[0]).toUpperCase(),
                          style: const TextStyle(
                            color: Color(0xFF0B65C2),
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Dashboard',
                              style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Welcome, ${(currentUser?.name ?? '').isNotEmpty ? currentUser!.name : 'Driver'}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Report new incidents quickly, track active cases, and keep your profile updated from one place.',
                    style: TextStyle(color: Colors.white, height: 1.45),
                  ),
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const ReportIssueScreen()),
                          ).then((_) => loadComplaints());
                        },
                        icon: const Icon(Icons.report),
                        label: const Text('New Report'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF0B65C2),
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const AmbulanceScreen()),
                          );
                        },
                        icon: const Icon(Icons.local_hospital_outlined),
                        label: const Text('Ambulance'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white70),
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pushNamed(context, '/profile').then((_) => loadComplaints());
                        },
                        icon: const Icon(Icons.person),
                        label: const Text('View Profile'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white70),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const AppSectionTitle(
              title: 'Performance Snapshot',
              subtitle: 'A quick view of current complaint volume and progress.',
            ),
            const SizedBox(height: 14),
            LayoutBuilder(
              builder: (context, constraints) {
                final cardWidth = constraints.maxWidth >= 720
                    ? (constraints.maxWidth - 24) / 3
                    : constraints.maxWidth >= 460
                        ? (constraints.maxWidth - 12) / 2
                        : constraints.maxWidth;

                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _summaryCard('Reports', '${stats['total'] ?? 0}', const Color(0xFF0B65C2), cardWidth),
                    _summaryCard('Resolved', '${stats['resolved'] ?? 0}', Colors.green, cardWidth),
                    _summaryCard('Pending', '${stats['pending'] ?? 0}', Colors.orange, cardWidth),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            AppInfoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Quick Actions',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Jump to the most common tasks without hunting through the navigation.',
                    style: TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _actionChip(
                        label: 'Report',
                        icon: Icons.report,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const ReportIssueScreen()),
                          ).then((_) => loadComplaints());
                        },
                      ),
                      _actionChip(
                        label: 'Track',
                        icon: Icons.route,
                        onTap: () {
                          Navigator.pushNamed(context, '/track').then((_) => loadComplaints());
                        },
                      ),
                      _actionChip(
                        label: 'Profile',
                        icon: Icons.person,
                        onTap: () {
                          Navigator.pushNamed(context, '/profile').then((_) => loadComplaints());
                        },
                      ),
                      _actionChip(
                        label: 'Ambulance',
                        icon: Icons.local_hospital,
                        onTap: () {
                          Navigator.pushNamed(context, '/ambulance');
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Incident Categories',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const IncidentsScreen()),
                    );
                  },
                  child: const Text('All Incidents'),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                categoryCard("Accident", Icons.car_crash, const Color(0xFF0B65C2)),
                categoryCard("Traffic Jam", Icons.traffic, const Color(0xFFF6B400)),
                categoryCard("Road Hazard", Icons.warning, Colors.redAccent),
              ],
            ),
            const SizedBox(height: 24),
            const AppSectionTitle(
              title: 'Recent Reports Near You',
              subtitle: 'Recent activity appears here so you can open details and monitor status changes quickly.',
            ),
            const SizedBox(height: 12),
            complaints.isEmpty
                ? const Text("No reports yet")
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: complaints.length,
                    itemBuilder: (context, index) {
                      final c = complaints[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: AppInfoCard(
                          child: ListTile(
                            dense: true,
                            leading: const CircleAvatar(
                              radius: 18,
                              child: Icon(Icons.warning_amber_rounded, size: 18),
                            ),
                            title: Text(
                              c.displayTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              '${c.incidentType} • ${c.status}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ComplaintDetailScreen(complaint: c),
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF0B65C2),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.report), label: "Report"),
          BottomNavigationBarItem(icon: Icon(Icons.route), label: "Track"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
        onTap: (index) {
          if (index == 1) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportIssueScreen())).then((_) => loadComplaints());
          } else if (index == 2) {
            Navigator.pushNamed(context, '/track').then((_) => loadComplaints());
          } else if (index == 3) {
            Navigator.pushNamed(context, '/profile').then((_) => loadComplaints());
          }
        },
      ),
    );
  }

  Widget categoryCard(String title, IconData icon, Color color) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => IncidentsScreen(incidentType: title)),
        );
      },
      child: Container(
        width: 110,
        height: 90,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 6),
            Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _summaryCard(String label, String value, Color color, double width) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(color: Colors.black54)),
        ],
      ),
    );
  }

  Widget _actionChip({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return ActionChip(
      avatar: Icon(icon, size: 18, color: const Color(0xFF0B65C2)),
      label: Text(label),
      onPressed: onTap,
      side: BorderSide(color: const Color(0xFF0B65C2).withValues(alpha: 0.18)),
      backgroundColor: const Color(0xFF0B65C2).withValues(alpha: 0.06),
      labelStyle: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF0B65C2)),
    );
  }
}