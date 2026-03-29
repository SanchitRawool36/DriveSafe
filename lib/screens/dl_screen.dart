import 'package:flutter/material.dart';
import '../models/app_user_model.dart';
import '../services/auth_service.dart';
import '../utils/ui_feedback.dart';
import '../widgets/app_widgets.dart';

class DLScreen extends StatefulWidget {
  const DLScreen({super.key});

  @override
  State<DLScreen> createState() => _DLScreenState();
}

class _DLScreenState extends State<DLScreen> {
  AppUser? user;
  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final licenseNumberController = TextEditingController();
  final dobController = TextEditingController();
  final issueDateController = TextEditingController();
  final expiryDateController = TextEditingController();
  final emergencyContactController = TextEditingController();
  String vehicleClass = 'LMV';
  String bloodGroup = 'O+';
  int currentStep = 0;
  bool showForm = false;
  bool saving = false;
  bool requestingRenewal = false;

  String _historyEntry(String message) {
    final now = DateTime.now();
    return '${formatDate(now)} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} - $message';
  }

  String formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day/$month/$year';
  }

  @override
  void initState() {
    super.initState();
    loadUser();
  }

  Future<void> loadUser() async {
    final currentUser = await AuthService.getCurrentUserProfile();
    if (!mounted) return;
    if (currentUser != null) {
      nameController.text = currentUser.name;
      phoneController.text = currentUser.phone;
      licenseNumberController.text = currentUser.licenseNumber;
      dobController.text = currentUser.dateOfBirth;
      issueDateController.text = currentUser.issueDate;
      expiryDateController.text = currentUser.expiryDate;
      emergencyContactController.text = currentUser.emergencyContact;
      vehicleClass = currentUser.vehicleClass.isEmpty ? 'LMV' : currentUser.vehicleClass;
      bloodGroup = currentUser.bloodGroup.isEmpty ? 'O+' : currentUser.bloodGroup;
    }
    setState(() {
      user = currentUser;
      showForm = currentUser == null ? true : !currentUser.hasCompletedLicenseProfile;
    });
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    licenseNumberController.dispose();
    dobController.dispose();
    issueDateController.dispose();
    expiryDateController.dispose();
    emergencyContactController.dispose();
    super.dispose();
  }

  Future<void> submitLicense() async {
    final currentUser = user;
    if (currentUser == null) {
      showAppSnackBar(context, 'No active user profile found.', isError: true);
      return;
    }

    if (!_formKey.currentState!.validate()) {
      showAppSnackBar(context, 'Please complete all required license fields.', isError: true);
      return;
    }

    setState(() {
      saving = true;
    });

    final updatedUser = currentUser.copyWith(
      name: nameController.text.trim(),
      phone: phoneController.text.trim(),
      licenseNumber: licenseNumberController.text.trim(),
      dateOfBirth: dobController.text.trim(),
      issueDate: issueDateController.text.trim(),
      expiryDate: expiryDateController.text.trim(),
      emergencyContact: emergencyContactController.text.trim(),
      vehicleClass: vehicleClass,
      bloodGroup: bloodGroup,
      licenseStatus: 'Active',
      renewalRequestNote: '',
      renewalRequestedAt: '',
      renewalTestDate: '',
      renewalHistory: currentUser.renewalHistory,
    );

    try {
      await AuthService.updateCurrentUser(updatedUser);
      if (!mounted) return;
      setState(() {
        user = updatedUser;
        showForm = false;
        currentStep = 0;
      });
      showAppSnackBar(context, 'Driving license details saved successfully.');
    } catch (error) {
      if (!mounted) return;
      showErrorSnackBar(context, error);
    } finally {
      if (mounted) {
        setState(() {
          saving = false;
        });
      }
    }
  }

  Future<void> renewLicense() async {
    final currentUser = user;
    if (currentUser == null) {
      showAppSnackBar(context, 'No active user profile found.', isError: true);
      return;
    }

    if (!currentUser.hasCompletedLicenseProfile) {
      showAppSnackBar(context, 'Complete and save your license details before requesting renewal.', isError: true);
      return;
    }

    final noteController = TextEditingController();
    final renewalNote = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Renew License'),
        content: TextField(
          controller: noteController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Reason or note for admin',
            hintText: 'For example: License expiring soon, request renewal test slot.',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, noteController.text.trim()),
            child: const Text('Send Request'),
          ),
        ],
      ),
    );

    if (!mounted || renewalNote == null) {
      return;
    }

    setState(() {
      requestingRenewal = true;
    });

    final updatedUser = currentUser.copyWith(
      licenseStatus: 'Renewal Requested',
      renewalRequestNote: renewalNote,
      renewalRequestedAt: DateTime.now().toIso8601String(),
      renewalTestDate: '',
      renewalHistory: [
        ...currentUser.renewalHistory,
        _historyEntry(
          renewalNote.isEmpty
              ? 'Renewal request sent to admin.'
              : 'Renewal request sent to admin. Note: $renewalNote',
        ),
      ],
    );
    try {
      await AuthService.updateCurrentUser(updatedUser);
      if (!mounted) return;
      setState(() {
        user = updatedUser;
      });
      showAppSnackBar(context, 'Renewal request sent to admin.');
    } catch (error) {
      if (!mounted) return;
      showErrorSnackBar(context, error);
    } finally {
      if (mounted) {
        setState(() {
          requestingRenewal = false;
        });
      }
    }
  }

  Widget buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label, hintText: hint),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Required';
        }
        return null;
      },
    );
  }

  Future<void> selectDate({
    required TextEditingController controller,
    required DateTime firstDate,
    required DateTime lastDate,
  }) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.isBefore(firstDate) ? firstDate : now.isAfter(lastDate) ? lastDate : now,
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (picked == null || !mounted) {
      return;
    }

    setState(() {
      controller.text = formatDate(picked);
    });
  }

  Widget buildDateField({
    required TextEditingController controller,
    required String label,
    required DateTime firstDate,
    required DateTime lastDate,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: const Icon(Icons.calendar_today),
      ),
      onTap: () => selectDate(
        controller: controller,
        firstDate: firstDate,
        lastDate: lastDate,
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Required';
        }
        return null;
      },
    );
  }

  Widget buildLicenseForm(AppUser currentUser) {
    return Form(
      key: _formKey,
      child: AppInfoCard(
        child: Stepper(
          type: StepperType.vertical,
          physics: const ClampingScrollPhysics(),
          currentStep: currentStep,
          onStepContinue: () {
            if (currentStep < 2) {
              setState(() {
                currentStep += 1;
              });
              return;
            }
            submitLicense();
          },
          onStepCancel: () {
            if (currentStep == 0) {
              return;
            }
            setState(() {
              currentStep -= 1;
            });
          },
          onStepTapped: (step) {
            setState(() {
              currentStep = step;
            });
          },
          controlsBuilder: (context, details) {
            final isLastStep = currentStep == 2;
            return Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  ElevatedButton(
                    onPressed: saving ? null : details.onStepContinue,
                    child: Text(saving ? 'Saving...' : isLastStep ? 'Save License' : 'Continue'),
                  ),
                  if (currentStep > 0)
                    OutlinedButton(
                      onPressed: details.onStepCancel,
                      child: const Text('Back'),
                    ),
                ],
              ),
            );
          },
          steps: [
            Step(
              title: const Text('Personal Details'),
              isActive: currentStep >= 0,
              content: Column(
                children: [
                  buildTextField(controller: nameController, label: 'Full Name'),
                  const SizedBox(height: 12),
                  buildDateField(
                    controller: dobController,
                    label: 'Date of Birth',
                    firstDate: DateTime(1950),
                    lastDate: DateTime.now(),
                  ),
                  const SizedBox(height: 12),
                  buildTextField(controller: phoneController, label: 'Phone Number'),
                  const SizedBox(height: 12),
                  buildTextField(controller: emergencyContactController, label: 'Emergency Contact'),
                ],
              ),
            ),
            Step(
              title: const Text('License Details'),
              isActive: currentStep >= 1,
              content: Column(
                children: [
                  buildTextField(controller: licenseNumberController, label: 'License Number'),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: vehicleClass,
                    decoration: const InputDecoration(labelText: 'Vehicle Class'),
                    items: const ['LMV', 'MCWG', 'HMV', 'Transport']
                        .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        vehicleClass = value;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: bloodGroup,
                    decoration: const InputDecoration(labelText: 'Blood Group'),
                    items: const ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-']
                        .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        bloodGroup = value;
                      });
                    },
                  ),
                ],
              ),
            ),
            Step(
              title: const Text('Validity & Review'),
              isActive: currentStep >= 2,
              content: Column(
                children: [
                  buildDateField(
                    controller: issueDateController,
                    label: 'Issue Date',
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  ),
                  const SizedBox(height: 12),
                  buildDateField(
                    controller: expiryDateController,
                    label: 'Expiry Date',
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 3650)),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Applicant: ${currentUser.email}',
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildLicenseSummary(AppUser currentUser) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppInfoCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 120,
                height: 92,
                decoration: BoxDecoration(
                  color: const Color(0xFF0B65C2).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.badge, size: 34, color: Color(0xFF0B65C2)),
                    SizedBox(height: 8),
                    Text('Digital DL', style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(currentUser.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    const SizedBox(height: 8),
                    Text('DL No: ${currentUser.licenseNumber}'),
                    const SizedBox(height: 6),
                    Text('Class: ${currentUser.vehicleClass}'),
                    const SizedBox(height: 6),
                    Text('Status: ${currentUser.licenseStatus}'),
                    const SizedBox(height: 6),
                    Text('Valid Till: ${currentUser.expiryDate}'),
                    if (currentUser.renewalTestDate.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text('Renewal Test Date: ${currentUser.renewalTestDate}'),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AppInfoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('License Details', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Text('Date of Birth: ${currentUser.dateOfBirth}'),
              const SizedBox(height: 6),
              Text('Blood Group: ${currentUser.bloodGroup}'),
              const SizedBox(height: 6),
              Text('Issue Date: ${currentUser.issueDate}'),
              const SizedBox(height: 6),
              Text('Emergency Contact: ${currentUser.emergencyContact}'),
              const SizedBox(height: 6),
              Text('Phone: ${currentUser.phone}'),
              if (currentUser.renewalRequestNote.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text('Renewal Note: ${currentUser.renewalRequestNote}'),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        AppInfoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Renewal History', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              if (currentUser.renewalHistory.isEmpty)
                const Text(
                  'No renewal history yet.',
                  style: TextStyle(color: Colors.black54),
                )
              else
                for (final entry in currentUser.renewalHistory.reversed)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 2),
                          child: Icon(Icons.history, size: 18, color: Color(0xFF0B65C2)),
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: Text(entry)),
                      ],
                    ),
                  ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        AppPrimaryButton(
          label: 'Update License Details',
          icon: Icons.edit_document,
          onPressed: () {
            setState(() {
              showForm = true;
              currentStep = 0;
            });
          },
        ),
        const SizedBox(height: 8),
        AppSecondaryButton(
          label: requestingRenewal ? 'Sending Renewal Request...' : 'Renew License',
          icon: Icons.autorenew,
          onPressed: requestingRenewal ? null : renewLicense,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = user;

    return Scaffold(
      appBar: AppBar(title: const Text('Driver License')),
      body: currentUser == null
          ? const Center(child: Text('No driving license data available.'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppSectionTitle(
                    title: showForm ? 'Driving License Form' : 'My Driving License',
                    subtitle: showForm
                    ? 'Complete the form to save your digital license details.'
                    : 'Your saved digital license and renewal actions.',
                  ),
                  const SizedBox(height: 16),
                  if (showForm) buildLicenseForm(currentUser) else buildLicenseSummary(currentUser),
                ],
              ),
            ),
    );
  }
}
