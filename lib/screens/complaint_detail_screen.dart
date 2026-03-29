import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/complaint_model.dart';
import '../utils/ui_feedback.dart';
import '../widgets/app_widgets.dart';

class ComplaintDetailScreen extends StatelessWidget {
  final Complaint complaint;

  const ComplaintDetailScreen({
    super.key,
    required this.complaint,
  });

  Uri? _buildGoogleMapsUri() {
    final lat = complaint.location?['lat'];
    final lon = complaint.location?['lon'];
    if (lat == null || lon == null) {
      return null;
    }

    return Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lon');
  }

  String? _coordinatesText() {
    final lat = complaint.location?['lat'];
    final lon = complaint.location?['lon'];
    if (lat == null || lon == null) {
      return null;
    }

    return '$lat, $lon';
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = (complaint.imageUrl ?? '').isNotEmpty;
    final isNetworkImage = (complaint.imageUrl ?? '').startsWith('http');
    final hasImageData = (complaint.imageData ?? '').isNotEmpty;
    final hasLocation = complaint.location != null;
    final mapsUri = _buildGoogleMapsUri();
    final coordinatesText = _coordinatesText();
    final latitude = complaint.location?['lat'];
    final longitude = complaint.location?['lon'];

    return Scaffold(
      appBar: AppBar(title: const Text('Complaint Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppSectionTitle(
              title: complaint.displayTitle,
              subtitle: '${complaint.incidentType} • ${complaint.createdAt.toLocal()}',
            ),
            const SizedBox(height: 16),
            AppInfoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Current Status', style: TextStyle(fontWeight: FontWeight.bold)),
                      ComplaintStatusChip(status: complaint.status),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text('Description', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(complaint.displayDescription.isEmpty ? 'No description added.' : complaint.displayDescription),
                ],
              ),
            ),
            if ((complaint.reporterName ?? '').isNotEmpty ||
                (complaint.reporterEmail ?? '').isNotEmpty ||
                (complaint.reporterPhone ?? '').isNotEmpty) ...[
              const SizedBox(height: 16),
              AppInfoCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Reporter Details', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    if ((complaint.reporterName ?? '').isNotEmpty)
                      Text('Name: ${complaint.reporterName}'),
                    if ((complaint.reporterEmail ?? '').isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text('Email: ${complaint.reporterEmail}'),
                    ],
                    if ((complaint.reporterPhone ?? '').isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text('Phone: ${complaint.reporterPhone}'),
                    ],
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            AppInfoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Attachments', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.image_outlined),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          hasImage ? 'Image attached: ${complaint.imageUrl}' : 'No image uploaded',
                        ),
                      ),
                    ],
                  ),
                  if (hasImageData || isNetworkImage) ...[
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: hasImageData
                          ? Image.memory(
                              base64Decode(complaint.imageData!),
                              height: 180,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            )
                          : Image.network(
                              complaint.imageUrl!,
                              height: 180,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              webHtmlElementStrategy: kIsWeb
                                  ? WebHtmlElementStrategy.prefer
                                  : WebHtmlElementStrategy.never,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  height: 180,
                                  width: double.infinity,
                                  color: Colors.black12,
                                  alignment: Alignment.center,
                                  child: const Text('Image preview unavailable'),
                                );
                              },
                            ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.place_outlined),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          hasLocation
                              ? 'GPS: ${complaint.location?['lat'] ?? '-'}, ${complaint.location?['lon'] ?? '-'}'
                              : 'No GPS location captured',
                        ),
                      ),
                    ],
                  ),
                  if (hasLocation) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0B65C2).withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF0B65C2).withValues(alpha: 0.14),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.map_outlined, color: Color(0xFF0B65C2)),
                              SizedBox(width: 8),
                              Text(
                                'Map Preview',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Lat: ${complaint.location?['lat'] ?? '-'}\nLon: ${complaint.location?['lon'] ?? '-'}',
                            style: const TextStyle(color: Colors.black54, height: 1.5),
                          ),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: SizedBox(
                              height: 220,
                              width: double.infinity,
                              child: FlutterMap(
                                options: MapOptions(
                                  initialCenter: LatLng(
                                    (latitude as num).toDouble(),
                                    (longitude as num).toDouble(),
                                  ),
                                  initialZoom: 15,
                                  interactionOptions: const InteractionOptions(
                                    flags: InteractiveFlag.drag |
                                        InteractiveFlag.pinchZoom |
                                        InteractiveFlag.doubleTapZoom,
                                  ),
                                ),
                                children: [
                                  TileLayer(
                                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                    userAgentPackageName: 'com.example.drive_safe_app',
                                  ),
                                  MarkerLayer(
                                    markers: [
                                      Marker(
                                        point: LatLng(
                                          (latitude).toDouble(),
                                          (longitude).toDouble(),
                                        ),
                                        width: 48,
                                        height: 48,
                                        child: const Icon(
                                          Icons.location_on,
                                          size: 40,
                                          color: Color(0xFFB42318),
                                        ),
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
                              OutlinedButton.icon(
                                onPressed: coordinatesText == null
                                    ? null
                                    : () async {
                                        await Clipboard.setData(
                                          ClipboardData(text: coordinatesText),
                                        );
                                        if (!context.mounted) return;
                                        showAppSnackBar(context, 'Coordinates copied.');
                                      },
                                icon: const Icon(Icons.copy_outlined),
                                label: const Text('Copy Coordinates'),
                              ),
                              OutlinedButton.icon(
                                onPressed: mapsUri == null
                                    ? null
                                    : () async {
                                        final opened = await launchUrl(
                                          mapsUri,
                                          mode: LaunchMode.externalApplication,
                                        );
                                        if (!context.mounted || opened) {
                                          return;
                                        }
                                        showAppSnackBar(
                                          context,
                                          'Could not open Google Maps on this device.',
                                          isError: true,
                                        );
                                      },
                                icon: const Icon(Icons.open_in_new),
                                label: const Text('Open in Google Maps'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            AppSecondaryButton(
              label: 'Back',
              icon: Icons.arrow_back,
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}