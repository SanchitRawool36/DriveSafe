import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/ambulance_models.dart';
import '../models/app_user_model.dart';
import '../models/complaint_model.dart';
import '../services/ambulance_service.dart';
import '../services/auth_service.dart';
import '../services/complaint_repository.dart';
import '../services/migration_service.dart';
import '../utils/ui_feedback.dart';
import '../widgets/app_widgets.dart';
import 'complaint_detail_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  List<Complaint> complaints = [];
  List<AmbulanceBooking> ambulanceBookings = [];
  List<AppUser> users = [];
  final TextEditingController searchController = TextEditingController();
  String selectedFilter = 'All';
  String searchQuery = '';
  Map<String, int> stats = const {
    'total': 0,
    'pending': 0,
    'inProgress': 0,
    'accepted': 0,
    'rejected': 0,
    'resolved': 0,
  };
  MigrationSummary legacySummary = const MigrationSummary(localUsers: 0, localComplaints: 0);
  bool migrating = false;
  bool renewalBusy = false;

  String _historyEntry(String message) {
    final now = DateTime.now();
    final day = now.day.toString().padLeft(2, '0');
    final month = now.month.toString().padLeft(2, '0');
    final year = now.year.toString();
    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute - $message';
  }

  @override
  void initState() {
    super.initState();
    loadComplaints();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> loadComplaints() async {
    final data = await ComplaintRepository.getComplaints();
    final bookings = await AmbulanceService.getAllBookings();
    final allUsers = await AuthService.getAllUserProfiles();
    final summary = await MigrationService.getLegacySummary();
    final userIds = data
        .map((complaint) => complaint.userId)
        .whereType<String>()
        .where((userId) => userId.isNotEmpty)
        .toSet()
        .toList();
    final profiles = <String, AppUser>{};

    for (final userId in userIds) {
      final profile = await AuthService.getUserProfileById(userId);
      if (profile != null) {
        profiles[userId] = profile;
      }
    }

    for (final complaint in data) {
      final profile = profiles[complaint.userId];
      complaint.reporterName = complaint.reporterName ?? profile?.name;
      complaint.reporterEmail = complaint.reporterEmail ?? profile?.email;
      complaint.reporterPhone = complaint.reporterPhone ?? profile?.phone;
    }

    if (!mounted) return;
    setState(() {
      complaints = data;
      ambulanceBookings = bookings;
      users = allUsers.where((user) => !user.isAdmin).toList();
      legacySummary = summary;
      stats = {
        'total': data.length,
        'pending': data.where((complaint) => complaint.status == 'Pending').length,
        'inProgress': data.where((complaint) => complaint.status == 'In Progress').length,
        'accepted': data.where((complaint) => complaint.status == 'Accepted').length,
        'rejected': data.where((complaint) => complaint.status == 'Rejected').length,
        'resolved': data.where((complaint) => complaint.status == 'Resolved').length,
      };
    });
  }

  Future<void> updateStatus(Complaint complaint, String status) async {
    await ComplaintRepository.updateComplaintStatus(complaint.id, status);
    if (!mounted) return;
    await loadComplaints();
    if (!mounted) return;
    showAppSnackBar(context, 'Complaint marked as $status.');
  }

  Future<void> migrateLegacyData() async {
    setState(() {
      migrating = true;
    });

    try {
      final result = await MigrationService.migrateLocalDataToFirebase();
      if (!mounted) return;
      await loadComplaints();
      if (!mounted) return;
      final warningText = result.warnings.isEmpty ? '' : '\nWarnings: ${result.warnings.join(' | ')}';
      showAppSnackBar(
        context,
        'Migrated ${result.migratedUsers} users and ${result.migratedComplaints} complaints.$warningText',
      );
    } catch (error) {
      if (!mounted) return;
      showErrorSnackBar(context, error);
    } finally {
      if (mounted) {
        setState(() {
          migrating = false;
        });
      }
    }
  }

  Future<void> scheduleRenewalTest(AppUser user) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked == null) {
      return;
    }

    setState(() {
      renewalBusy = true;
    });

    final formattedDate = '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
    final updatedUser = user.copyWith(
      licenseStatus: 'Renewal Test Scheduled',
      renewalTestDate: formattedDate,
      renewalHistory: [
        ...user.renewalHistory,
        _historyEntry('Admin assigned renewal test date: $formattedDate.'),
      ],
    );

    try {
      await AuthService.updateUserProfileByAdmin(updatedUser);
      if (!mounted) return;
      await loadComplaints();
      if (!mounted) return;
      showAppSnackBar(context, 'Renewal test date sent to ${user.name}.');
    } catch (error) {
      if (!mounted) return;
      showErrorSnackBar(context, error);
    } finally {
      if (mounted) {
        setState(() {
          renewalBusy = false;
        });
      }
    }
  }

  Future<void> approveRenewal(AppUser user) async {
    setState(() {
      renewalBusy = true;
    });

    final updatedUser = user.copyWith(
      licenseStatus: 'Renewal Approved',
      renewalHistory: [
        ...user.renewalHistory,
        _historyEntry('Admin approved the renewal request.'),
      ],
    );

    try {
      await AuthService.updateUserProfileByAdmin(updatedUser);
      if (!mounted) return;
      await loadComplaints();
      if (!mounted) return;
      showAppSnackBar(context, 'Renewal approved for ${user.name}.');
    } catch (error) {
      if (!mounted) return;
      showErrorSnackBar(context, error);
    } finally {
      if (mounted) {
        setState(() {
          renewalBusy = false;
        });
      }
    }
  }

  Future<void> rejectRenewal(AppUser user) async {
    final noteController = TextEditingController();
    final rejectionNote = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Renewal'),
        content: TextField(
          controller: noteController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Reason for rejection',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, noteController.text.trim()),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (rejectionNote == null) {
      return;
    }

    setState(() {
      renewalBusy = true;
    });

    final updatedUser = user.copyWith(
      licenseStatus: 'Renewal Rejected',
      renewalTestDate: '',
      renewalHistory: [
        ...user.renewalHistory,
        _historyEntry(
          rejectionNote.isEmpty
              ? 'Admin rejected the renewal request.'
              : 'Admin rejected the renewal request. Reason: $rejectionNote',
        ),
      ],
    );

    try {
      await AuthService.updateUserProfileByAdmin(updatedUser);
      if (!mounted) return;
      await loadComplaints();
      if (!mounted) return;
      showAppSnackBar(context, 'Renewal rejected for ${user.name}.');
    } catch (error) {
      if (!mounted) return;
      showErrorSnackBar(context, error);
    } finally {
      if (mounted) {
        setState(() {
          renewalBusy = false;
        });
      }
    }
  }

  Future<void> contactBySms(AppUser user) async {
    if (user.phone.trim().isEmpty) {
      showAppSnackBar(context, 'No phone number is available for this user.', isError: true);
      return;
    }

    final uri = Uri.parse('sms:${Uri.encodeComponent(user.phone.trim())}');
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!context.mounted || opened) {
      return;
    }
    showAppSnackBar(context, 'Could not open the SMS app.', isError: true);
  }

  Future<void> contactByEmail(AppUser user) async {
    if (user.email.trim().isEmpty) {
      showAppSnackBar(context, 'No email is available for this user.', isError: true);
      return;
    }

    final uri = Uri(
      scheme: 'mailto',
      path: user.email.trim(),
      queryParameters: {
        'subject': 'DriveSafe Licence Renewal',
      },
    );
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!context.mounted || opened) {
      return;
    }
    showAppSnackBar(context, 'Could not open the email app.', isError: true);
  }

  @override
  Widget build(BuildContext context) {
    final normalizedSearch = searchQuery.trim().toLowerCase();
    final renewalUsers = users.where((user) {
      final statusMatches = user.licenseStatus == 'Renewal Requested' ||
          user.licenseStatus == 'Renewal Test Scheduled' ||
          user.licenseStatus == 'Renewal Approved' ||
          user.licenseStatus == 'Renewal Rejected';
      if (!statusMatches) {
        return false;
      }

      if (normalizedSearch.isEmpty) {
        return true;
      }

      return user.name.toLowerCase().contains(normalizedSearch) ||
          user.email.toLowerCase().contains(normalizedSearch) ||
          user.phone.toLowerCase().contains(normalizedSearch);
    }).toList();

    final visibleComplaints = complaints.where((complaint) {
      final statusMatches = selectedFilter == 'All' || complaint.status == selectedFilter;
      if (!statusMatches) {
        return false;
      }

      if (normalizedSearch.isEmpty) {
        return true;
      }

      final reporterName = complaint.reporterName?.toLowerCase() ?? '';
      final reporterEmail = complaint.reporterEmail?.toLowerCase() ?? '';
      final reporterPhone = complaint.reporterPhone?.toLowerCase() ?? '';
      return reporterName.contains(normalizedSearch) ||
          reporterEmail.contains(normalizedSearch) ||
          reporterPhone.contains(normalizedSearch);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
        actions: [
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
      body: RefreshIndicator(
        onRefresh: loadComplaints,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSummarySection(),
            const SizedBox(height: 16),
            _buildMigrationSection(),
            const SizedBox(height: 16),
            _buildFilterSection(),
            const SizedBox(height: 16),
            TextField(
              controller: searchController,
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                labelText: 'Search reporter name, email, or phone',
                border: const OutlineInputBorder(),
                suffixIcon: searchQuery.trim().isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          searchController.clear();
                          setState(() {
                            searchQuery = '';
                          });
                        },
                        icon: const Icon(Icons.close),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            _buildEmergencySupportSection(),
            const SizedBox(height: 16),
            _buildAmbulanceBookingsSection(),
            const SizedBox(height: 16),
            if (visibleComplaints.isEmpty)
              AppInfoCard(
                child: Text(
                  normalizedSearch.isEmpty
                      ? 'No complaints available for this filter.'
                      : 'No complaints match that reporter search.',
                ),
              )
            else
              for (final complaint in visibleComplaints)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: AppInfoCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                complaint.displayTitle,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ComplaintDetailScreen(complaint: complaint),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.open_in_new),
                              tooltip: 'Open Details',
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text('Type: ${complaint.incidentType}'),
                        const SizedBox(height: 8),
                        _reporterSummary(complaint),
                        const SizedBox(height: 8),
                        ComplaintStatusChip(status: complaint.status),
                        const SizedBox(height: 4),
                        Text(
                          complaint.displayDescription,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.black54),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ElevatedButton.icon(
                              onPressed: () => updateStatus(complaint, 'Accepted'),
                              icon: const Icon(Icons.check),
                              label: const Text('Accept'),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                            ),
                            ElevatedButton.icon(
                              onPressed: () => updateStatus(complaint, 'Rejected'),
                              icon: const Icon(Icons.close),
                              label: const Text('Reject'),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                            ),
                            OutlinedButton.icon(
                              onPressed: () => updateStatus(complaint, 'In Progress'),
                              icon: const Icon(Icons.pending_actions),
                              label: const Text('In Progress'),
                            ),
                            OutlinedButton.icon(
                              onPressed: () => updateStatus(complaint, 'Resolved'),
                              icon: const Icon(Icons.task_alt),
                              label: const Text('Resolved'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummarySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppSectionTitle(
          title: 'Admin Overview',
          subtitle: 'Monitor all reported complaints and update their status.',
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _summaryCard('Total', '${stats['total'] ?? 0}', const Color(0xFF0B65C2)),
            _summaryCard('Pending', '${stats['pending'] ?? 0}', const Color(0xFFF6B400)),
            _summaryCard('In Progress', '${stats['inProgress'] ?? 0}', Colors.orange),
            _summaryCard('Accepted', '${stats['accepted'] ?? 0}', Colors.green),
            _summaryCard('Rejected', '${stats['rejected'] ?? 0}', Colors.red),
            _summaryCard('Resolved', '${stats['resolved'] ?? 0}', Colors.green),
          ],
        ),
      ],
    );
  }

  Widget _buildFilterSection() {
    const filters = ['All', 'Pending', 'In Progress', 'Accepted', 'Rejected', 'Resolved'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Filters',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final filter in filters)
              ChoiceChip(
                label: Text(filter),
                selected: selectedFilter == filter,
                onSelected: (_) {
                  setState(() {
                    selectedFilter = filter;
                  });
                },
              ),
          ],
        ),
      ],
    );
  }

  Widget _summaryCard(String label, String value, Color color) {
    return Container(
      width: 110,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.black54)),
        ],
      ),
    );
  }

  Widget _buildMigrationSection() {
    return AppInfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Firebase Migration',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Legacy local users: ${legacySummary.localUsers} • Legacy local complaints: ${legacySummary.localComplaints}',
            style: const TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 12),
          migrating
              ? const Center(child: CircularProgressIndicator())
              : Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    ElevatedButton.icon(
                      onPressed: legacySummary.hasLegacyData ? migrateLegacyData : null,
                      icon: const Icon(Icons.cloud_upload_outlined),
                      label: const Text('Migrate Local Data'),
                    ),
                    OutlinedButton.icon(
                      onPressed: loadComplaints,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Refresh Summary'),
                    ),
                  ],
                ),
          if (!legacySummary.hasLegacyData) ...[
            const SizedBox(height: 8),
            const Text(
              'No local legacy records remain to be migrated.',
              style: TextStyle(color: Colors.black54),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRenewalSection(List<AppUser> renewalUsers) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppSectionTitle(
          title: 'Licence Renewal Requests',
          subtitle: 'Review renewal requests and send the renewal test date to the user.',
        ),
        const SizedBox(height: 12),
        if (renewalUsers.isEmpty)
          const AppInfoCard(
            child: Text('No licence renewal requests found.'),
          )
        else
          for (final renewalUser in renewalUsers)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: AppInfoCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      renewalUser.name,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text('Email: ${renewalUser.email}'),
                    const SizedBox(height: 4),
                    Text('Phone: ${renewalUser.phone.isEmpty ? '-' : renewalUser.phone}'),
                    const SizedBox(height: 4),
                    Text('Licence No: ${renewalUser.licenseNumber}'),
                    const SizedBox(height: 4),
                    Text('Vehicle Class: ${renewalUser.vehicleClass.isEmpty ? '-' : renewalUser.vehicleClass}'),
                    const SizedBox(height: 4),
                    Text('Status: ${renewalUser.licenseStatus}'),
                    if (renewalUser.renewalRequestedAt.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text('Requested At: ${renewalUser.renewalRequestedAt.split('T').first}'),
                    ],
                    if (renewalUser.renewalRequestNote.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text('Request Note: ${renewalUser.renewalRequestNote}'),
                    ],
                    if (renewalUser.renewalTestDate.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text('Assigned Test Date: ${renewalUser.renewalTestDate}'),
                    ],
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ElevatedButton.icon(
                          onPressed: renewalBusy ? null : () => scheduleRenewalTest(renewalUser),
                          icon: const Icon(Icons.event_available),
                          label: Text(
                            renewalUser.renewalTestDate.isEmpty ? 'Send Test Date' : 'Update Test Date',
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: renewalBusy ? null : () => approveRenewal(renewalUser),
                          icon: const Icon(Icons.verified_outlined),
                          label: const Text('Accept Renewal'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                        ),
                        ElevatedButton.icon(
                          onPressed: renewalBusy ? null : () => rejectRenewal(renewalUser),
                          icon: const Icon(Icons.cancel_outlined),
                          label: const Text('Reject Renewal'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => contactBySms(renewalUser),
                          icon: const Icon(Icons.sms_outlined),
                          label: const Text('SMS'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => contactByEmail(renewalUser),
                          icon: const Icon(Icons.email_outlined),
                          label: const Text('Email'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
      ],
    );
  }

  Widget _buildEmergencySupportSection() {
    return AppInfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ambulance Service Update',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Licence renewal has been removed from the active app flow. Users now access Ambulance Service for Government calling and Private booking with tracking.',
            style: TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              OutlinedButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/ambulance'),
                icon: const Icon(Icons.local_hospital_outlined),
                label: const Text('Open Ambulance Service'),
              ),
              OutlinedButton.icon(
                onPressed: loadComplaints,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh Complaints'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAmbulanceBookingsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSectionTitle(
          title: 'Ambulance Bookings',
          subtitle: 'See who booked an ambulance, why it was booked, the pickup point, and the current fake live travel status.',
        ),
        const SizedBox(height: 12),
        if (ambulanceBookings.isEmpty)
          const AppInfoCard(
            child: Text('No ambulance bookings found yet.'),
          )
        else
          for (final booking in ambulanceBookings)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: AppInfoCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${booking.providerName} • ${booking.providerArea}',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                        ComplaintStatusChip(status: booking.status),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('Booked by: ${booking.bookedByName}'),
                    const SizedBox(height: 4),
                    Text('Contact: ${booking.bookedByPhone.isEmpty ? booking.phoneNumber : booking.bookedByPhone}'),
                    if (booking.bookedByEmail.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text('Email: ${booking.bookedByEmail}'),
                    ],
                    const SizedBox(height: 4),
                    Text('Patient: ${booking.patientName}'),
                    const SizedBox(height: 4),
                    Text('Reason: ${booking.emergencyReason}'),
                    const SizedBox(height: 4),
                    Text('Booked at: ${booking.bookedAtIso.replaceFirst('T', ' ').split('.').first}'),
                    const SizedBox(height: 4),
                    Text('Pickup: ${booking.pickupLocation}'),
                    const SizedBox(height: 4),
                    Text('Current travel note: ${booking.currentPosition}'),
                    const SizedBox(height: 4),
                    Text('ETA: ${booking.etaMinutes == 0 ? 'Arrived' : '${booking.etaMinutes} min'} • Payment: ${booking.paymentMethod} • Rs. ${booking.serviceFee}'),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        height: 220,
                        width: double.infinity,
                        child: FlutterMap(
                          options: MapOptions(
                            initialCenter: LatLng(booking.currentLatitude, booking.currentLongitude),
                            initialZoom: 12.6,
                          ),
                          children: [
                            TileLayer(
                              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.example.drive_safe_app',
                            ),
                            PolylineLayer(
                              polylines: [
                                Polyline(
                                  points: booking.routePoints
                                      .map((point) => LatLng(point['lat'] ?? 0, point['lon'] ?? 0))
                                      .toList(),
                                  strokeWidth: 4,
                                  color: const Color(0xFF0B65C2),
                                ),
                              ],
                            ),
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: LatLng(booking.pickupLatitude, booking.pickupLongitude),
                                  width: 42,
                                  height: 42,
                                  child: const Icon(Icons.place, color: Colors.redAccent, size: 34),
                                ),
                                Marker(
                                  point: LatLng(booking.currentLatitude, booking.currentLongitude),
                                  width: 48,
                                  height: 48,
                                  child: const Icon(Icons.local_hospital, color: Colors.green, size: 34),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
      ],
    );
  }

  Widget _reporterSummary(Complaint complaint) {
    final name = complaint.reporterName?.trim();
    final email = complaint.reporterEmail?.trim();
    final phone = complaint.reporterPhone?.trim();

    if ((name == null || name.isEmpty) && (email == null || email.isEmpty) && (phone == null || phone.isEmpty)) {
      return const Text(
        'Reporter details unavailable.',
        style: TextStyle(color: Colors.black54),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Reporter: ${name == null || name.isEmpty ? 'Unknown' : name}'),
        if (email != null && email.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text('Email: $email'),
        ],
        if (phone != null && phone.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text('Phone: $phone'),
        ],
      ],
    );
  }
}