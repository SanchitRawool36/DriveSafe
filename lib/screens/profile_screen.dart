import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import '../models/app_user_model.dart';
import '../models/complaint_model.dart';
import 'package:image_picker/image_picker.dart';
import '../services/auth_service.dart';
import '../services/complaint_repository.dart';
import '../utils/ui_feedback.dart';
import '../widgets/app_widgets.dart';
import 'complaint_detail_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  AppUser? user;
  List<Complaint> complaints = [];
  int selectedTabIndex = 0;
  Map<String, int> stats = const {
    'total': 0,
    'accepted': 0,
    'rejected': 0,
    'resolved': 0,
    'pending': 0,
    'inProgress': 0,
  };
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    loadUser();
  }

  Future<void> loadUser() async {
    final currentUser = await AuthService.getCurrentUserProfile();
    final userComplaints = await ComplaintRepository.getComplaintsForUser(currentUser?.id);
    final complaintStats = await ComplaintRepository.getComplaintStats(userId: currentUser?.id);
    if (!mounted) return;
    setState(() {
      user = currentUser;
      complaints = userComplaints;
      stats = complaintStats;
    });
  }

  Future<void> editProfile() async {
    final currentUser = user;
    if (currentUser == null) {
      return;
    }

    final nameController = TextEditingController(text: currentUser.name);
    final emailController = TextEditingController(text: currentUser.email);
    final phoneController = TextEditingController(text: currentUser.phone);
    final bioController = TextEditingController(text: currentUser.bio);
    final addressController = TextEditingController(text: currentUser.address);

    final updated = await showDialog<AppUser>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Profile'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name')),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  helperText: 'Email is managed by Firebase Auth.',
                ),
              ),
              const SizedBox(height: 12),
              TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'Phone')),
              const SizedBox(height: 12),
              TextField(controller: addressController, decoration: const InputDecoration(labelText: 'Address')),
              const SizedBox(height: 12),
              TextField(controller: bioController, maxLines: 3, decoration: const InputDecoration(labelText: 'Bio')),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  currentUser.copyWith(
                    name: nameController.text.trim(),
                    email: emailController.text.trim(),
                    phone: phoneController.text.trim(),
                    address: addressController.text.trim(),
                    bio: bioController.text.trim(),
                  ),
                );
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (updated == null) {
      return;
    }

    await AuthService.updateCurrentUser(updated);
    await loadUser();
  }

  Future<void> pickProfileImage() async {
    final currentUser = user;
    if (currentUser == null) {
      return;
    }

    final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 75);
    if (picked == null) {
      return;
    }

    final bytes = await picked.readAsBytes();
    final updatedUser = currentUser.copyWith(profileImageData: base64Encode(bytes));
    await AuthService.updateCurrentUser(updatedUser);
    await loadUser();
    if (!mounted) return;
    showAppSnackBar(context, 'Profile photo updated.');
  }

  Uint8List? getProfileImageBytes(AppUser currentUser) {
    if (!currentUser.hasProfileImage) {
      return null;
    }

    try {
      return base64Decode(currentUser.profileImageData);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = user;

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: const Center(child: Text('No user session found.')),
      );
    }

    final profileImageBytes = getProfileImageBytes(currentUser);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: const LinearGradient(
                  colors: [Color(0xFF0B65C2), Color(0xFF2F80ED), Color(0xFFF6B400)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            CircleAvatar(
                              radius: 38,
                              backgroundColor: Colors.white,
                              backgroundImage: profileImageBytes == null ? null : MemoryImage(profileImageBytes),
                              child: profileImageBytes == null
                                  ? Text(
                                      currentUser.name.isEmpty ? 'D' : currentUser.name[0].toUpperCase(),
                                      style: const TextStyle(color: Color(0xFF0B65C2), fontSize: 28, fontWeight: FontWeight.bold),
                                    )
                                  : null,
                            ),
                            Positioned(
                              right: -2,
                              bottom: -2,
                              child: InkWell(
                                onTap: pickProfileImage,
                                borderRadius: BorderRadius.circular(999),
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.camera_alt, size: 16, color: Color(0xFF0B65C2)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Wrap(
                          spacing: 20,
                          runSpacing: 12,
                          alignment: WrapAlignment.spaceBetween,
                          children: [
                            _headerStat('Posts', '${stats['total'] ?? 0}'),
                            _headerStat('Accepted', '${stats['accepted'] ?? 0}'),
                            _headerStat('Pending', '${stats['pending'] ?? 0}'),
                            _headerStat('Rejected', '${stats['rejected'] ?? 0}'),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    currentUser.name,
                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '@${currentUser.name.toLowerCase().replaceAll(' ', '_')}',
                    style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    currentUser.bio,
                    style: const TextStyle(color: Colors.white, height: 1.4),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _metaChip(Icons.place_outlined, currentUser.address),
                      _metaChip(Icons.phone_outlined, currentUser.phone),
                      _metaChip(Icons.local_hospital_outlined, 'Ambulance Help'),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: editProfile,
                          icon: const Icon(Icons.edit),
                          label: const Text('Edit Profile'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF0B65C2),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            showAppSnackBar(context, 'Profile link sharing can be added later.');
                          },
                          icon: const Icon(Icons.share_outlined),
                          label: const Text('Share Profile'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white70),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            AppInfoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Account Snapshot', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  const Text(
                    'A compact summary of how your reports are performing right now.',
                    style: TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 14),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final tileWidth = constraints.maxWidth >= 720
                          ? (constraints.maxWidth - 24) / 3
                          : constraints.maxWidth >= 460
                              ? (constraints.maxWidth - 12) / 2
                              : constraints.maxWidth;

                      return Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _profileMetricTile('Open Cases', '${stats['pending'] ?? 0}', const Color(0xFFF6B400), tileWidth),
                          _profileMetricTile('Resolved', '${stats['resolved'] ?? 0}', Colors.green, tileWidth),
                          _profileMetricTile('Accepted', '${stats['accepted'] ?? 0}', const Color(0xFF0B65C2), tileWidth),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            _buildTabBar(),
            const SizedBox(height: 18),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: _buildSelectedTabContent(currentUser),
            ),
            const SizedBox(height: 18),
            AppInfoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Quick Actions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  const Text(
                    'Move between the most useful areas of the app from your profile.',
                    style: TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _actionTile('Ambulance', Icons.local_hospital, () => Navigator.pushNamed(context, '/ambulance')),
                      _actionTile('Track', Icons.route, () => Navigator.pushNamed(context, '/track')),
                      _actionTile('Settings', Icons.settings, () => Navigator.pushNamed(context, '/settings')),
                      _actionTile('Logout', Icons.logout, () async {
                        await AuthService.logout();
                        if (!context.mounted) return;
                        Navigator.pushReplacementNamed(context, '/login');
                      }),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _headerStat(String label, String value) {
    return SizedBox(
      width: 58,
      child: Column(
        children: [
          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _profileMetricTile(String label, String value, Color color, double width) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(color: Colors.black54)),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    const tabs = [
      ('Posts', Icons.grid_on_rounded),
      ('Activity', Icons.auto_graph_outlined),
      ('About', Icons.person_outline_rounded),
    ];

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          for (var index = 0; index < tabs.length; index++)
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () {
                  setState(() {
                    selectedTabIndex = index;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  decoration: BoxDecoration(
                    color: selectedTabIndex == index ? const Color(0xFF0B65C2) : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        tabs[index].$2,
                        size: 18,
                        color: selectedTabIndex == index ? Colors.white : Colors.black54,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tabs[index].$1,
                        style: TextStyle(
                          color: selectedTabIndex == index ? Colors.white : Colors.black54,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSelectedTabContent(AppUser currentUser) {
    switch (selectedTabIndex) {
      case 1:
        return _buildActivityTab();
      case 2:
        return _buildAboutTab(currentUser);
      default:
        return _buildPostsTab();
    }
  }

  Widget _buildPostsTab() {
    return AppInfoCard(
      key: const ValueKey('posts-tab'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Posts', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          const Text('Your recent incident posts in a compact profile grid.', style: TextStyle(color: Colors.black54)),
          const SizedBox(height: 14),
          complaints.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 18),
                    child: Text('No posts yet. Start reporting incidents to build your profile.'),
                  ),
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final crossAxisCount = constraints.maxWidth > 620 ? 3 : 2;
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: complaints.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 1,
                      ),
                      itemBuilder: (context, index) {
                        final complaint = complaints[index];
                        Uint8List? imageBytes;
                        final hasImageUrl = (complaint.imageUrl ?? '').startsWith('http');
                        if ((complaint.imageData ?? '').isNotEmpty) {
                          try {
                            imageBytes = base64Decode(complaint.imageData!);
                          } catch (_) {
                            imageBytes = null;
                          }
                        }

                        return InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ComplaintDetailScreen(complaint: complaint),
                              ),
                            );
                          },
                          child: Container(
                            clipBehavior: Clip.antiAlias,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              gradient: imageBytes == null
                                  ? LinearGradient(
                                      colors: [
                                        const Color(0xFF0B65C2).withValues(alpha: 0.95),
                                        const Color(0xFF2F80ED).withValues(alpha: 0.85),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    )
                                  : null,
                            ),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                if (imageBytes != null)
                                  Image.memory(imageBytes, fit: BoxFit.cover)
                                else if (hasImageUrl)
                                  Image.network(
                                    complaint.imageUrl!,
                                    fit: BoxFit.cover,
                                    webHtmlElementStrategy: kIsWeb
                                      ? WebHtmlElementStrategy.prefer
                                        : WebHtmlElementStrategy.never,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: const Color(0xFF0B65C2).withValues(alpha: 0.18),
                                        alignment: Alignment.center,
                                        child: const Icon(Icons.broken_image_outlined, color: Colors.white70),
                                      );
                                    },
                                  )
                                else
                                  const SizedBox.shrink(),
                                Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.black.withValues(alpha: 0.08),
                                        Colors.black.withValues(alpha: 0.55),
                                      ],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                    ),
                                  ),
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withValues(alpha: 0.16),
                                              borderRadius: BorderRadius.circular(999),
                                            ),
                                            child: Text(
                                              complaint.incidentType,
                                              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                                            ),
                                          ),
                                          Icon(
                                            imageBytes == null ? Icons.open_in_full : Icons.photo_library_outlined,
                                            color: Colors.white,
                                            size: 18,
                                          ),
                                        ],
                                      ),
                                      const Spacer(),
                                      Text(
                                        complaint.displayTitle,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        complaint.status,
                                        style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildActivityTab() {
    return AppInfoCard(
      key: const ValueKey('activity-tab'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Activity Overview', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _softMetricCard('In Progress', '${stats['inProgress'] ?? 0}', Icons.pending_actions_outlined, Colors.orange),
              _softMetricCard('Accepted', '${stats['accepted'] ?? 0}', Icons.check_circle_outline, Colors.green),
              _softMetricCard('Rejected', '${stats['rejected'] ?? 0}', Icons.cancel_outlined, Colors.red),
            ],
          ),
          const SizedBox(height: 12),
          Text('Latest Complaint: ${complaints.isEmpty ? 'No complaints yet' : complaints.first.displayTitle}'),
          const SizedBox(height: 14),
          const Text('Highlights', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _highlightItem('Ambulance', Icons.local_hospital_outlined, const Color(0xFF0B65C2)),
                _highlightItem('Reports', Icons.report_gmailerrorred, const Color(0xFFF6B400)),
                _highlightItem('Safety', Icons.shield_outlined, Colors.green),
                _highlightItem('Contact', Icons.contact_phone_outlined, Colors.redAccent),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutTab(AppUser currentUser) {
    return AppInfoCard(
      key: const ValueKey('about-tab'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Contact Information', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Text('Email: ${currentUser.email}'),
          const SizedBox(height: 6),
          Text('Phone: ${currentUser.phone}'),
          const SizedBox(height: 6),
          Text('Address: ${currentUser.address}'),
          const SizedBox(height: 16),
          const Text('Ambulance Support', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          const Text(
            'Need urgent medical transport? Open Ambulance Service to call Government support or book a Private ambulance with tracking.',
          ),
          const SizedBox(height: 6),
          if (currentUser.address.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text('Default pickup location: ${currentUser.address}'),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/ambulance'),
              icon: const Icon(Icons.local_hospital_outlined),
              label: const Text('Open Ambulance Service'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _metaChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _highlightItem(String label, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.45), width: 2),
            ),
            child: CircleAvatar(
              radius: 26,
              backgroundColor: color.withValues(alpha: 0.14),
              child: Icon(icon, color: color),
            ),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _softMetricCard(String label, String value, IconData icon, Color color) {
    return Container(
      width: 102,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 10),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.black54, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _actionTile(String label, IconData icon, VoidCallback onPressed) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onPressed,
      child: Container(
        width: 110,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF0B65C2).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF0B65C2)),
            const SizedBox(height: 8),
            Text(label, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
