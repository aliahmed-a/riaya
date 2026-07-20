import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../appointments/data/models/upcoming_appointment_model.dart';
import '../../../../appointments/data/repositories/appointment_repository.dart';
import '../../../../appointments/presentation/providers/upcoming_appointments_provider.dart';

/// Bottom sheet opened from the patient queue: shows check-in status, patient
/// history, and — once the patient is checked in — the form to record the
/// clinical encounter (symptoms/diagnosis/notes/prescriptions) and finalize it.
class ClinicalActionSheet extends ConsumerStatefulWidget {
  final UpcomingAppointment appointment;
  final ThemeData theme;

  const ClinicalActionSheet({super.key, required this.appointment, required this.theme});

  @override
  ConsumerState<ClinicalActionSheet> createState() => _ClinicalActionSheetState();
}

class _ClinicalActionSheetState extends ConsumerState<ClinicalActionSheet> {
  final _formKey = GlobalKey<FormState>();
  final _symptomsController = TextEditingController();
  final _diagnosisController = TextEditingController();
  final _notesController = TextEditingController();

  final List<Map<String, dynamic>> _prescriptions = [];
  final _consultationProgress = ConsultationProgress();
  bool _isProcessing = false;

  @override
  void dispose() {
    _symptomsController.dispose();
    _diagnosisController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _showPatientHistory() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: widget.theme.colorScheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('${widget.appointment.patientName} - History', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: double.maxFinite,
            child: FutureBuilder<Map<String, dynamic>>(
              future: ref.read(appointmentRepositoryProvider).getPatientHistory(widget.appointment.patientId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(padding: EdgeInsets.all(32.0), child: Center(child: CircularProgressIndicator()));
                }
                if (snapshot.hasError) {
                  return Text('Error loading history: ${snapshot.error}', style: TextStyle(color: widget.theme.statusColors.danger));
                }
                if (!snapshot.hasData || snapshot.data == null) {
                  return const Text('No history available.');
                }

                final history = snapshot.data!;
                final visits = history['visits'] as List<dynamic>? ?? [];

                return ListView(
                  shrinkWrap: true,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatBadge('Total Visits', history['totalVisits'].toString()),
                        _buildStatBadge('Total Appts', history['totalAppointments'].toString()),
                      ],
                    ),
                    const Divider(height: 32),
                    if (visits.isEmpty) const Text('No previous recorded clinical visits.'),
                    ...visits.map((v) {
                      final dateStr = v['visitDate'] ?? '';
                      final date = DateTime.tryParse(dateStr) ?? DateTime.now();
                      final formattedDate = DateFormat('MMM d, yyyy').format(date);
                      return Card(
                        elevation: 0,
                        color: widget.theme.colorScheme.primary.withValues(alpha: 0.05),
                        shape: RoundedRectangleBorder(
                          side: BorderSide(color: widget.theme.dividerColor.withValues(alpha: 0.1)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          title: Text(v['diagnosis'] ?? 'No Diagnosis', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text('$formattedDate\nSymptoms: ${v['symptoms'] ?? 'None recorded'}'),
                          ),
                          isThreeLine: true,
                        ),
                      );
                    }),
                  ],
                );
              },
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
          ],
        );
      },
    );
  }

  Widget _buildStatBadge(String label, String value) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: widget.theme.colorScheme.primary)),
        Text(label, style: TextStyle(color: widget.theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6), fontSize: 12)),
      ],
    );
  }

  void _showAddMedicationDialog() {
    final medNameCtrl = TextEditingController();
    final dosageCtrl = TextEditingController();
    final instCtrl = TextEditingController();
    final daysCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: widget.theme.colorScheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Add Prescription', style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildFilledField(medNameCtrl, 'Medication Name (e.g. Amoxicillin)'),
                const SizedBox(height: 12),
                _buildFilledField(dosageCtrl, 'Dosage (e.g. 500mg)'),
                const SizedBox(height: 12),
                _buildFilledField(instCtrl, 'Instructions (e.g. After meals)'),
                const SizedBox(height: 12),
                _buildFilledField(daysCtrl, 'Duration (Days)', isNumber: true),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: TextStyle(color: widget.theme.textTheme.bodyMedium?.color))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                backgroundColor: widget.theme.colorScheme.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                if (medNameCtrl.text.isNotEmpty && dosageCtrl.text.isNotEmpty && daysCtrl.text.isNotEmpty) {
                  setState(() {
                    _prescriptions.add({
                      'medicationName': medNameCtrl.text,
                      'dosage': dosageCtrl.text,
                      'instructions': instCtrl.text,
                      'durationInDays': int.tryParse(daysCtrl.text) ?? 1,
                    });
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('Add Order'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFilledField(TextEditingController controller, String label, {bool isNumber = false}) {
    final isDark = widget.theme.brightness == Brightness.dark;
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: isDark ? widget.theme.colorScheme.surfaceContainerHighest : Colors.grey.shade50,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentStatus = widget.appointment.status.toLowerCase();
    final isCheckedIn = currentStatus == 'checkedin' || currentStatus == 'checked-in';
    final isCompleted = currentStatus == 'completed';
    final isDark = widget.theme.brightness == Brightness.dark;
    final inputFill = isDark ? widget.theme.colorScheme.surfaceContainerHighest : Colors.grey.shade50;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        top: 24,
        left: 24,
        right: 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.appointment.patientName,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text('Status: ${widget.appointment.status}', style: TextStyle(color: widget.theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6), fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: _showPatientHistory,
                  icon: const Icon(Icons.history_rounded, size: 18),
                  label: const Text('History'),
                  style: TextButton.styleFrom(
                      foregroundColor: widget.theme.colorScheme.primary,
                      backgroundColor: widget.theme.colorScheme.primary.withValues(alpha: 0.1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                  style: IconButton.styleFrom(backgroundColor: inputFill),
                )
              ],
            ),
            const Divider(height: 32),

            if (_isProcessing)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40.0),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (isCompleted)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: widget.theme.statusColors.success.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_rounded, color: widget.theme.statusColors.success, size: 28),
                      const SizedBox(width: 12),
                      Text(
                        'Encounter finalized successfully.',
                        style: TextStyle(color: widget.theme.statusColors.success, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              )
            else if (!isCheckedIn)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: widget.theme.statusColors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: widget.theme.statusColors.warning.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.hourglass_empty_rounded, color: widget.theme.statusColors.warning, size: 32),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Awaiting Front-Desk Check-In',
                              style: TextStyle(color: widget.theme.statusColors.warning, fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Clinical documentation workflows will unlock automatically once front-desk staff checks this patient in.',
                              style: TextStyle(color: widget.theme.statusColors.warning, fontSize: 13, height: 1.4),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              else
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Record Clinical Encounter Details',
                        style: TextStyle(fontWeight: FontWeight.bold, color: widget.theme.colorScheme.primary, fontSize: 15),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _symptomsController,
                        decoration: InputDecoration(
                          labelText: 'Presented Symptoms *',
                          hintText: 'e.g., Persistent cough, high fever',
                          filled: true,
                          fillColor: inputFill,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                        validator: (v) => (v == null || v.trim().length < 2) ? 'Please log actual symptoms' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _diagnosisController,
                        decoration: InputDecoration(
                          labelText: 'Clinical Diagnosis *',
                          hintText: 'e.g., Acute Bronchitis',
                          filled: true,
                          fillColor: inputFill,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                        validator: (v) => (v == null || v.trim().length < 2) ? 'Please input a clear diagnosis summary' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _notesController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: 'Internal Medical Notes (Optional)',
                          filled: true,
                          fillColor: inputFill,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Prescribed Medications', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          ElevatedButton.icon(
                            onPressed: _showAddMedicationDialog,
                            icon: const Icon(Icons.add_box_rounded, size: 18),
                            label: const Text('Add Order'),
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              backgroundColor: widget.theme.colorScheme.primary.withValues(alpha: 0.1),
                              foregroundColor: widget.theme.colorScheme.primary,
                              elevation: 0,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (_prescriptions.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(color: widget.theme.dividerColor.withValues(alpha: 0.2), style: BorderStyle.solid),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text('No medications added.', textAlign: TextAlign.center, style: TextStyle(color: widget.theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5), fontSize: 13)),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _prescriptions.length,
                          itemBuilder: (context, idx) {
                            final p = _prescriptions[idx];
                            return Card(
                              elevation: 0,
                              color: widget.theme.colorScheme.primary.withValues(alpha: 0.05),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                title: Text(p['medicationName'], style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Text('${p['dosage']} — ${p['durationInDays']} Days\n${p['instructions']}', style: TextStyle(height: 1.3, color: widget.theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.8))),
                                ),
                                isThreeLine: true,
                                trailing: IconButton(
                                  icon: Icon(Icons.delete_outline, color: widget.theme.statusColors.danger),
                                  onPressed: () => setState(() => _prescriptions.removeAt(idx)),
                                ),
                              ),
                            );
                          },
                        ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            if (_formKey.currentState?.validate() ?? false) {
                              setState(() => _isProcessing = true);
                              final errorMsg = await ref.read(upcomingAppointmentsProvider.notifier).finalizeClinicalConsultation(
                                appointmentId: widget.appointment.id,
                                symptoms: _symptomsController.text.trim(),
                                diagnosis: _diagnosisController.text.trim(),
                                notes: _notesController.text.trim(),
                                prescriptions: _prescriptions,
                                progress: _consultationProgress,
                              );

                              if (!context.mounted) return;

                              final displayError = (errorMsg != null && errorMsg.trim().isNotEmpty) ? errorMsg : null;
                              setState(() => _isProcessing = false);

                              // Only close the sheet on success — on failure, keep it open
                              // (with the already-typed notes/prescriptions intact) so the
                              // doctor can retry without redoing their work. A retry reuses
                              // _consultationProgress, so it won't re-create the visit or
                              // prescriptions that already saved successfully.
                              if (displayError == null) {
                                Navigator.pop(context);
                              }
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(displayError ?? 'Encounter & Prescriptions Finalized!'),
                                  backgroundColor: displayError == null ? widget.theme.statusColors.success : widget.theme.statusColors.danger,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: widget.theme.statusColors.success,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: const Text('Finalize Consultation & Close Encounter', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
