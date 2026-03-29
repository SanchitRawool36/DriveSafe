import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import '../models/app_settings_model.dart';
import '../models/complaint_model.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import '../services/auth_service.dart';
import '../services/complaint_repository.dart';
import '../services/local_storage_service.dart';
import '../utils/ui_feedback.dart';
import '../widgets/app_widgets.dart';

class ReportIssueScreen extends StatefulWidget {
  const ReportIssueScreen({super.key});

  @override
  State<ReportIssueScreen> createState() => _ReportIssueScreenState();
}

class _ReportIssueScreenState extends State<ReportIssueScreen> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descController = TextEditingController();
  Uint8List? _imageBytes;
  String? _imageName;
  Map<String, dynamic>? _location;
  String issueType = 'Accident';
  final ImagePicker _picker = ImagePicker();

  Future<Map<String, dynamic>> _captureLocationOrThrow() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are turned off on this phone. Turn on GPS and try again.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw Exception('Location permission is required to attach GPS to a complaint.');
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permission is permanently denied. Enable location access for DriveSafe in phone settings.');
    }

    const locationSettings = LocationSettings(accuracy: LocationAccuracy.best);
    final pos = await Geolocator.getCurrentPosition(locationSettings: locationSettings);
    return {'lat': pos.latitude, 'lon': pos.longitude};
  }

  Future<void> _pickImageFromSource(ImageSource source) async {
    final settings = LocalStorageService.settingsNotifier.value;
    if (!settings.gpsAssist) {
      showAppSnackBar(
        context,
        'Turn on GPS assistance in Settings before attaching a photo.',
        isError: true,
      );
      return;
    }

    final XFile? picked = await _picker.pickImage(source: source, imageQuality: 75);
    if (picked != null) {
      try {
        final location = await _captureLocationOrThrow();
        if (!mounted) return;
        final bytes = await picked.readAsBytes();
        setState(() {
          _imageBytes = bytes;
          _imageName = picked.name;
          _location = location;
        });
        showAppSnackBar(context, 'Photo attached with GPS location.');
      } catch (error) {
        if (!mounted) return;
        showErrorSnackBar(context, error);
      }
    }
  }

  Future<void> _pickImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Click Image'),
              subtitle: const Text('Open the camera and take a new photo.'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Upload From Gallery'),
              subtitle: const Text('Choose an existing photo from the gallery.'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null || !mounted) {
      return;
    }

    await _pickImageFromSource(source);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(title: const Text("Report Incident")),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                children: [
              const AppSectionTitle(
                title: 'Report An Issue',
                subtitle: 'Submit a complaint with title, type, details, optional photo, and GPS location.',
              ),

              const SizedBox(height: 20),

              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.title),
                  labelText: "Issue Title",
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 15),

              DropdownButtonFormField<String>(
                initialValue: issueType,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.list_alt),
                  labelText: 'Incident Type',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'Accident', child: Text('Accident')),
                  DropdownMenuItem(value: 'Traffic Jam', child: Text('Traffic Jam')),
                  DropdownMenuItem(value: 'Road Hazard', child: Text('Road Hazard')),
                  DropdownMenuItem(value: 'Reckless Driving', child: Text('Reckless Driving')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      issueType = value;
                    });
                  }
                },
              ),

              const SizedBox(height: 15),

              TextField(
                controller: descController,
                maxLines: 4,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.description),
                  labelText: "Description",
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 20),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.photo_camera),
                    label: const Text('Upload Photo'),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0B65C2)),
                  ),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 260),
                    child: _imageBytes == null
                        ? Text(_imageName ?? 'No file chosen', overflow: TextOverflow.ellipsis)
                        : SizedBox(width: 80, height: 80, child: Image.memory(_imageBytes!, fit: BoxFit.cover)),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              const SizedBox(height: 12),

              ValueListenableBuilder<AppSettings>(
                valueListenable: LocalStorageService.settingsNotifier,
                builder: (context, settings, _) {
                  final gpsEnabled = settings.gpsAssist;

                  if (!gpsEnabled && _location != null) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!mounted) return;
                      setState(() {
                        _location = null;
                      });
                    });
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          SizedBox(
                            width: 200,
                            child: ElevatedButton.icon(
                              onPressed: !gpsEnabled
                                  ? null
                                  : () async {
                                      try {
                                        final loc = await _captureLocationOrThrow();
                                        if (!context.mounted) return;
                                        setState(() {
                                          _location = loc;
                                        });
                                        showAppSnackBar(context, 'Location captured.');
                                      } catch (error) {
                                        if (!context.mounted) return;
                                        showErrorSnackBar(context, error);
                                      }
                                    },
                              icon: const Icon(Icons.my_location),
                              label: Text(gpsEnabled ? 'Use GPS' : 'GPS Disabled'),
                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF6B400)),
                            ),
                          ),
                          SizedBox(
                            width: 200,
                            child: OutlinedButton.icon(
                              onPressed: () => setState(() {
                                _imageBytes = null;
                                _imageName = null;
                              }),
                              icon: const Icon(Icons.delete),
                              label: const Text('Clear Photo'),
                            ),
                          ),
                        ],
                      ),
                      if (!gpsEnabled) ...[
                        const SizedBox(height: 10),
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'GPS assistance is turned off in Settings, so location capture is disabled here.',
                            style: TextStyle(color: Colors.black54),
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),

              if (_location != null) ...[
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'GPS: ${_location?['lat'] ?? '-'}, ${_location?['lon'] ?? '-'}',
                    style: const TextStyle(color: Colors.black54),
                  ),
                ),
              ],

              const SizedBox(height: 12),

              AppPrimaryButton(
                label: 'Submit Complaint',
                icon: Icons.send,
                onPressed: () async {
                  final navigator = Navigator.of(context);

                  if (titleController.text.isEmpty ||
                      descController.text.isEmpty) {
                    showAppSnackBar(context, 'Please fill all fields.', isError: true);
                    return;
                  }

                  if (_imageBytes != null && _location == null) {
                    showAppSnackBar(
                      context,
                      'A photo report must include GPS location. Capture location and try again.',
                      isError: true,
                    );
                    return;
                  }

                  try {
                    final currentUser = await AuthService.getCurrentUserProfile();
                    if (!context.mounted) return;
                    final complaint = Complaint(
                      title: titleController.text.trim(),
                      description: descController.text.trim(),
                      incidentType: issueType,
                      location: _location,
                      userId: currentUser?.id,
                      reporterName: currentUser?.name,
                      reporterEmail: currentUser?.email,
                      reporterPhone: currentUser?.phone,
                      imageUrl: _imageBytes == null ? null : _imageName,
                      imageData: _imageBytes == null ? null : base64Encode(_imageBytes!),
                    );

                    await ComplaintRepository.saveComplaint(
                      complaint,
                      imageBytes: _imageBytes,
                      imageName: _imageName,
                    );

                    if (!context.mounted) return;
                    showAppSnackBar(context, 'Complaint submitted successfully.');

                    titleController.clear();
                    descController.clear();
                    setState(() {
                      _imageBytes = null;
                      _imageName = null;
                      _location = null;
                      issueType = 'Accident';
                    });
                    navigator.pop();
                  } catch (error) {
                    if (!context.mounted) return;
                    showErrorSnackBar(context, error);
                  }
                },
              ),
              const SizedBox(height: 10),
              AppSecondaryButton(
                label: 'Track My Complaints',
                icon: Icons.route,
                onPressed: () => Navigator.pushNamed(context, '/track'),
              ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}