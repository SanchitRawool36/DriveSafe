import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/ambulance_models.dart';
import '../models/app_user_model.dart';
import '../services/auth_service.dart';
import '../services/ambulance_service.dart';
import '../utils/ui_feedback.dart';
import '../widgets/app_widgets.dart';

class AmbulanceScreen extends StatefulWidget {
  const AmbulanceScreen({super.key});

  @override
  State<AmbulanceScreen> createState() => _AmbulanceScreenState();
}

class _AmbulanceScreenState extends State<AmbulanceScreen> {
  String selectedServiceType = 'Government';
  AppUser? currentUser;
  AmbulanceBooking? activeBooking;
  bool isLoading = true;
  Timer? _trackingTimer;

  @override
  void initState() {
    super.initState();
    _loadScreenState();
  }

  @override
  void dispose() {
    _trackingTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadScreenState() async {
    final user = await AuthService.getCurrentUserProfile();
    final booking = await AmbulanceService.getCurrentUserBooking();
    if (!mounted) return;
    setState(() {
      currentUser = user;
      activeBooking = booking;
      selectedServiceType = booking == null
          ? selectedServiceType
          : (AmbulanceService.providerById(booking.providerId)?.isGovernment ?? false)
              ? 'Government'
              : 'Private';
      isLoading = false;
    });
    _syncTrackingTimer();
  }

  void _syncTrackingTimer() {
    _trackingTimer?.cancel();
    final booking = activeBooking;
    if (booking == null || booking.status == 'Arrived' || booking.status == 'Completed') {
      return;
    }

    _trackingTimer = Timer.periodic(const Duration(seconds: 6), (_) async {
      final current = activeBooking;
      if (!mounted || current == null || current.status == 'Arrived' || current.status == 'Completed') {
        _trackingTimer?.cancel();
        return;
      }

      final updated = AmbulanceService.advanceBooking(current);
      await AmbulanceService.updateBooking(updated);
      if (!mounted) return;
      setState(() {
        activeBooking = updated;
      });
      if (updated.status == 'Arrived') {
        _trackingTimer?.cancel();
      }
    });
  }

  String _formatPhone(String phone) {
    if (phone.length == 10) {
      return '+91 $phone';
    }
    if (phone.startsWith('+91') && phone.length > 3) {
      final digits = phone.substring(3);
      if (digits.length == 10) {
        return '+91 ${digits.substring(0, 5)} ${digits.substring(5)}';
      }
    }
    return phone;
  }

  Future<void> _callProvider(String phoneNumber) async {
    final uri = Uri(scheme: 'tel', path: phoneNumber.replaceAll(RegExp(r'[^0-9+]'), ''));
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!mounted || opened) {
      return;
    }
    showAppSnackBar(context, 'Could not open the phone dialer.', isError: true);
  }

  Future<void> _bookPrivateAmbulance(AmbulanceProvider provider) async {
    final patientController = TextEditingController(text: currentUser?.name ?? '');
    final pickupController = TextEditingController(text: currentUser?.address ?? '');
    final reasonController = TextEditingController();
    String paymentMethod = 'UPI';

    final booking = await showDialog<AmbulanceBooking>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Book ${provider.name}'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Area: ${provider.area}'),
                    const SizedBox(height: 6),
                    Text('Estimated arrival: ${provider.etaMinutes} min'),
                    const SizedBox(height: 6),
                    Text('Service charge: Rs. ${provider.serviceFee}'),
                    const SizedBox(height: 12),
                    TextField(
                      controller: patientController,
                      decoration: const InputDecoration(
                        labelText: 'Patient Name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: pickupController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Pickup Location',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: reasonController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Emergency Reason',
                        hintText: 'For example: accident injury, chest pain, patient transfer.',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: paymentMethod,
                      decoration: const InputDecoration(
                        labelText: 'Payment Method',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'UPI', child: Text('UPI')),
                        DropdownMenuItem(value: 'Card', child: Text('Card')),
                        DropdownMenuItem(value: 'Cash', child: Text('Cash')),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setDialogState(() {
                          paymentMethod = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final patientName = patientController.text.trim();
                    final pickupLocation = pickupController.text.trim();
                    final emergencyReason = reasonController.text.trim();
                    if (patientName.isEmpty || pickupLocation.isEmpty || emergencyReason.isEmpty) {
                      showAppSnackBar(context, 'Enter patient name, pickup location, and reason.', isError: true);
                      return;
                    }

                    Navigator.pop(
                      context,
                      AmbulanceService.buildBooking(
                        provider: provider,
                        currentUser: currentUser,
                        patientName: patientName,
                        pickupLocation: pickupLocation,
                        emergencyReason: emergencyReason,
                        paymentMethod: paymentMethod,
                      ),
                    );
                  },
                  child: const Text('Book & Pay'),
                ),
              ],
            );
          },
        );
      },
    );

    if (booking == null) {
      return;
    }

    await AmbulanceService.saveBooking(booking);
    if (!mounted) return;
    setState(() {
      activeBooking = booking;
      selectedServiceType = 'Private';
    });
    _syncTrackingTimer();
    showAppSnackBar(context, '${provider.name} booked successfully. Tracking started.');
  }

  Future<void> _refreshTracking() async {
    final booking = activeBooking;
    if (booking == null) {
      return;
    }

    final updated = AmbulanceService.advanceBooking(booking);
    await AmbulanceService.updateBooking(updated);
    if (!mounted) return;
    setState(() {
      activeBooking = updated;
    });
    _syncTrackingTimer();
    showAppSnackBar(context, 'Tracking refreshed for ${updated.providerName}.');
  }

  Future<void> _clearTracking() async {
    await AmbulanceService.clearCurrentBooking();
    if (!mounted) return;
    setState(() {
      activeBooking = null;
    });
    _trackingTimer?.cancel();
    showAppSnackBar(context, 'Ambulance trip marked complete.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ambulance Service')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadScreenState,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const AppSectionTitle(
                    title: 'Ambulance Service',
                    subtitle: 'Choose Government emergency calling or book a Private ambulance with payment and live-style tracking.',
                  ),
                  const SizedBox(height: 16),
                  AppInfoCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Service Type', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ChoiceChip(
                              label: const Text('Government'),
                              selected: selectedServiceType == 'Government',
                              onSelected: (_) {
                                setState(() {
                                  selectedServiceType = 'Government';
                                });
                              },
                            ),
                            ChoiceChip(
                              label: const Text('Private'),
                              selected: selectedServiceType == 'Private',
                              onSelected: (_) {
                                setState(() {
                                  selectedServiceType = 'Private';
                                });
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Government services are call-only. Private services support booking, payment, and tracking in the app.',
                          style: TextStyle(color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                  if (activeBooking != null) ...[
                    const SizedBox(height: 16),
                    _buildTrackingCard(activeBooking!),
                  ],
                  const SizedBox(height: 16),
                  if (selectedServiceType == 'Government')
                    ...AmbulanceService.governmentProviders.map(_buildGovernmentCard)
                  else
                    ...AmbulanceService.privateProviders.map(_buildPrivateCard),
                  const SizedBox(height: 16),
                  AppInfoCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('Coverage Note', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        SizedBox(height: 8),
                        Text(
                          'Private operators in this screen were added from the client-approved local ambulance list for Sindhudurg, Sawantwadi, Kudal, Shiroda, Tulas, Malewad, and nearby areas.',
                          style: TextStyle(color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildTrackingCard(AmbulanceBooking booking) {
    return AppInfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Active Ambulance Tracking', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('${booking.providerName} • ${booking.providerArea}'),
          const SizedBox(height: 4),
          Text('Booked by: ${booking.bookedByName}${booking.bookedByPhone.isEmpty ? '' : ' • ${booking.bookedByPhone}'}'),
          const SizedBox(height: 4),
          Text('Patient: ${booking.patientName}'),
          const SizedBox(height: 4),
          Text('Reason: ${booking.emergencyReason}'),
          const SizedBox(height: 4),
          Text('Pickup: ${booking.pickupLocation}'),
          const SizedBox(height: 4),
          Text('Booked at: ${booking.bookedAtIso.replaceFirst('T', ' ').split('.').first}'),
          const SizedBox(height: 4),
          Text('Payment: ${booking.paymentMethod} • Rs. ${booking.serviceFee}'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ComplaintStatusChip(status: booking.status),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF0B65C2).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  booking.etaMinutes == 0 ? 'Arrived' : 'ETA ${booking.etaMinutes} min',
                  style: const TextStyle(color: Color(0xFF0B65C2), fontWeight: FontWeight.w600, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: booking.progress,
            minHeight: 8,
            borderRadius: BorderRadius.circular(999),
            backgroundColor: Colors.black12,
          ),
          const SizedBox(height: 10),
          Text('Current position: ${booking.currentPosition}'),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: 240,
              width: double.infinity,
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: LatLng(booking.currentLatitude, booking.currentLongitude),
                  initialZoom: 12.7,
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
                        child: const Icon(Icons.place, color: Colors.redAccent, size: 36),
                      ),
                      Marker(
                        point: LatLng(booking.currentLatitude, booking.currentLongitude),
                        width: 52,
                        height: 52,
                        child: const Icon(Icons.local_hospital, color: Colors.green, size: 38),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              ElevatedButton.icon(
                onPressed: booking.stageIndex >= booking.routePoints.length - 1 ? null : _refreshTracking,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh Tracking'),
              ),
              OutlinedButton.icon(
                onPressed: () => _callProvider(booking.phoneNumber),
                icon: const Icon(Icons.call),
                label: const Text('Call Ambulance'),
              ),
              OutlinedButton.icon(
                onPressed: _clearTracking,
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Complete Trip'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGovernmentCard(AmbulanceProvider provider) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppInfoCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(provider.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(provider.area),
            const SizedBox(height: 4),
            Text('Contact: ${_formatPhone(provider.phoneNumber)}'),
            const SizedBox(height: 4),
            Text('Expected dispatch window: about ${provider.etaMinutes} min'),
            const SizedBox(height: 8),
            Text(provider.notes, style: const TextStyle(color: Colors.black54)),
            const SizedBox(height: 12),
            AppPrimaryButton(
              label: 'Call Government Ambulance',
              icon: Icons.call,
              onPressed: () => _callProvider(provider.phoneNumber),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivateCard(AmbulanceProvider provider) {
    final isTracked = activeBooking?.providerId == provider.id;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppInfoCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(provider.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                if (isTracked) const ComplaintStatusChip(status: 'Tracked'),
              ],
            ),
            const SizedBox(height: 6),
            Text('${provider.area} • ${_formatPhone(provider.phoneNumber)}'),
            const SizedBox(height: 4),
            Text('ETA: ${provider.etaMinutes} min • Fee: Rs. ${provider.serviceFee}'),
            const SizedBox(height: 4),
            Text('Current route note: ${provider.currentPosition}'),
            const SizedBox(height: 8),
            Text(provider.notes, style: const TextStyle(color: Colors.black54)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _bookPrivateAmbulance(provider),
                  icon: const Icon(Icons.local_hospital),
                  label: const Text('Book & Pay'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _callProvider(provider.phoneNumber),
                  icon: const Icon(Icons.call),
                  label: const Text('Call'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}