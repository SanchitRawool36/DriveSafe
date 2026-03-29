import 'package:flutter/material.dart';

import '../models/complaint_model.dart';
import '../services/complaint_repository.dart';
import '../widgets/app_widgets.dart';
import 'complaint_detail_screen.dart';

class IncidentsScreen extends StatefulWidget {
  final String? incidentType;

  const IncidentsScreen({super.key, this.incidentType});

  @override
  State<IncidentsScreen> createState() => _IncidentsScreenState();
}

class _IncidentsScreenState extends State<IncidentsScreen> {
  List<Complaint> complaints = [];

  @override
  void initState() {
    super.initState();
    loadComplaints();
  }

  Future<void> loadComplaints() async {
    final allComplaints = await ComplaintRepository.getComplaints();
    if (!mounted) return;
    setState(() {
      complaints = allComplaints;
    });
  }

  @override
  Widget build(BuildContext context) {
    final selectedType = widget.incidentType;
    final visibleComplaints = selectedType == null
        ? complaints
        : complaints.where((complaint) => complaint.incidentType == selectedType).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(selectedType ?? 'All Incidents'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppSectionTitle(
              title: selectedType == null ? 'All Incidents' : '$selectedType Incidents',
              subtitle: selectedType == null
                  ? 'Browse every locally stored road-safety report.'
                  : 'Showing only reports tagged as $selectedType.',
            ),
            const SizedBox(height: 16),
            Expanded(
              child: visibleComplaints.isEmpty
                  ? const Center(child: Text('No incidents found for this category.'))
                  : ListView.separated(
                      itemCount: visibleComplaints.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
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
