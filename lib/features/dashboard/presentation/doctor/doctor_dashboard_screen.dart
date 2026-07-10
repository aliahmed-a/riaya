import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

// Import your theme and provider
import '../../../../core/theme/app_theme.dart';

import '../../../appointments/presentation/providers/upcoming_appointments_provider.dart';
import '../../../appointments/data/models/upcoming_appointment_model.dart';
import '../../../appointments/data/repositories/appointment_repository.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../doctor_schedule/presentation/providers/doctor_schedule_provider.dart';
import '../../../doctor_schedule/data/models/doctor_schedule_model.dart';

class DoctorDashboardScreen extends ConsumerWidget {
  const DoctorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final doctorName = authState.user?.fullName ?? 'Doctor Workspace';
    final theme = Theme.of(context);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor, // Adaptive background
        appBar: AppBar(
          elevation: 0,
          title: const Text('Clinical Workspace', style: TextStyle(fontWeight: FontWeight.w600,fontSize: 18,)),
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: Colors.white,
          centerTitle: false,
          actions: [
            // 🟢 Theme Toggle Button
            IconButton(
              icon: Icon(
                theme.brightness == Brightness.dark
                    ? Icons.light_mode_rounded
                    : Icons.dark_mode_rounded,
              ),
              tooltip: 'Toggle Theme',
              onPressed: () {
                // Call the dedicated method on our notifier to change and save the theme
                ref.read(themeModeProvider.notifier).updateThemeMode(
                  theme.brightness == Brightness.dark
                      ? ThemeMode.light
                      : ThemeMode.dark,
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.logout_rounded),
              onPressed: () {
                ref.read(authProvider.notifier).logout();
                context.go('/login');
              },
            ),
          ],
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelStyle: TextStyle(fontWeight: FontWeight.bold),
            tabs: [
              Tab(icon: Icon(Icons.assignment_ind_rounded), text: "Patient Queue"),
              Tab(icon: Icon(Icons.edit_calendar_rounded), text: "Shift Availability"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildPatientQueueTab(context, ref, doctorName, theme),
            _buildScheduleManagementTab(context, ref, theme),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // TAB 1: PATIENT QUEUE DESIGN
  // ==========================================
  Widget _buildPatientQueueTab(BuildContext context, WidgetRef ref, String doctorName, ThemeData theme) {
    final queueState = ref.watch(upcomingAppointmentsProvider);

    return RefreshIndicator(
      onRefresh: () => ref.read(upcomingAppointmentsProvider.notifier).refreshQueue(),
      color: theme.colorScheme.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeHeader(context, doctorName, theme, ref),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Today's Patient Queue",
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: queueState.maybeWhen(
                    data: (list) => Text(
                      '${list.length} Total',
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    orElse: () => const Text('...', style: TextStyle(fontSize: 12)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            queueState.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 40.0),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, stack) => Container(
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Failed to synchronize schedule: $error',
                  style: const TextStyle(color: Colors.red),
                ),
              ),
              data: (appointments) {
                if (appointments.isEmpty) {
                  return _buildEmptyQueueState(context, theme);
                }
                return _buildQueueList(context, ref, appointments, theme);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeHeader(BuildContext context, String doctorName, ThemeData theme, WidgetRef ref) {
    Color indicatorColor = Colors.greenAccent;
    String statusText = 'Connected to Clinical Node';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Icon(
              Icons.local_hospital_rounded,
              size: 110,
              color: Colors.white.withOpacity(0.1),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                          color: indicatorColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: indicatorColor.withOpacity(0.5), blurRadius: 6, spreadRadius: 1)
                          ]
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      statusText,
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Clinical Officer On-Duty',
                style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 0.5),
              ),
              const SizedBox(height: 4),
              Text(
                doctorName,
                style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyQueueState(BuildContext context, ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 16.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface, // Adaptive surface
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(theme.brightness == Brightness.dark ? 0.3 : 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4)
          )
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.assignment_turned_in_rounded, size: 56, color: theme.colorScheme.primary.withOpacity(0.5)),
          ),
          const SizedBox(height: 20),
          Text(
            'No Appointments Scheduled',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'All clear! There are no remaining patients in your pipeline queue.',
            textAlign: TextAlign.center,
            style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6), fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildQueueList(BuildContext context, WidgetRef ref, List<UpcomingAppointment> appointments, ThemeData theme) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: appointments.length,
      itemBuilder: (context, index) {
        final appointment = appointments[index];
        final timeString = DateFormat('hh:mm a').format(appointment.appointmentDate);
        final statusLower = appointment.status.toLowerCase();

        Color badgeColor = Colors.amber.withOpacity(0.15);
        Color textBadgeColor = Colors.amber.shade700;
        if (statusLower == 'checkedin' || statusLower == 'checked-in') {
          badgeColor = Colors.blue.withOpacity(0.15);
          textBadgeColor = Colors.blue.shade700;
        } else if (statusLower == 'completed') {
          badgeColor = Colors.green.withOpacity(0.15);
          textBadgeColor = Colors.green.shade700;
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface, // Adaptive surface
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(theme.brightness == Brightness.dark ? 0.3 : 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _openClinicalActionMenu(context, ref, appointment, theme),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.person_outline_rounded, color: theme.colorScheme.primary, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            appointment.patientName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(Icons.access_time_rounded, size: 14, color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5)),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  '$timeString • ${appointment.durationMinutes} Min',
                                  style: TextStyle(fontSize: 13, color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6)),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(Icons.meeting_room_rounded, size: 14, color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5)),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  'Rm ${appointment.clinicRoomName ?? "N/A"}',
                                  style: TextStyle(fontSize: 13, color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6)),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: badgeColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        appointment.status,
                        style: TextStyle(
                          color: textBadgeColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _openClinicalActionMenu(BuildContext context, WidgetRef ref, UpcomingAppointment appointment, ThemeData theme) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.scaffoldBackgroundColor, // Adaptive modal background
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return _ClinicalActionSheet(appointment: appointment, theme: theme);
      },
    );
  }

  // ==========================================
  // TAB 2: SHIFT / AVAILABILITY MATRIX (VIEW ONLY)
  // ==========================================
  Widget _buildScheduleManagementTab(BuildContext context, WidgetRef ref, ThemeData theme) {
    final scheduleState = ref.watch(doctorScheduleProvider);

    return RefreshIndicator(
      onRefresh: () => ref.read(doctorScheduleProvider.notifier).refreshSchedules(),
      color: theme.colorScheme.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Active Working Timeframes",
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            scheduleState.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 40.0),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (err, stack) => Text('Failed to load schedule rules: $err', style: const TextStyle(color: Colors.red)),
              data: (schedules) {
                if (schedules.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40.0),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.calendar_today_rounded, size: 48, color: theme.textTheme.bodyMedium?.color?.withOpacity(0.3)),
                          const SizedBox(height: 12),
                          Text(
                            'No working timeblocks configured.\nPlease contact an administrator to set up your schedule.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6), fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final sorted = List<DoctorScheduleModel>.from(schedules)
                  ..sort((a, b) => a.dayOfWeek.compareTo(b.dayOfWeek));

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: sorted.length,
                  itemBuilder: (context, idx) {
                    final item = sorted[idx];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(theme.brightness == Brightness.dark ? 0.3 : 0.03), blurRadius: 10, offset: const Offset(0, 4))
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.wb_sunny_rounded, color: Colors.blue.shade400, size: 22),
                        ),
                        title: Text(
                          _getDayName(item.dayOfWeek),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            '${_cleanTimeStr(item.startTime)} — ${_cleanTimeStr(item.endTime)}',
                            style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7), fontSize: 14),
                          ),
                        ),
                        // 🟢 Trailing delete icon completely removed here
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _getDayName(int day) {
    switch (day) {
      case 0: return 'Sunday';
      case 1: return 'Monday';
      case 2: return 'Tuesday';
      case 3: return 'Wednesday';
      case 4: return 'Thursday';
      case 5: return 'Friday';
      case 6: return 'Saturday';
      default: return 'Day Block';
    }
  }

  String _cleanTimeStr(String time) {
    if (time.length >= 5) {
      return time.substring(0, 5);
    }
    return time;
  }
}

class _ClinicalActionSheet extends ConsumerStatefulWidget {
  final UpcomingAppointment appointment;
  final ThemeData theme;

  const _ClinicalActionSheet({required this.appointment, required this.theme});

  @override
  ConsumerState<_ClinicalActionSheet> createState() => _ClinicalActionSheetState();
}

class _ClinicalActionSheetState extends ConsumerState<_ClinicalActionSheet> {
  final _formKey = GlobalKey<FormState>();
  final _symptomsController = TextEditingController();
  final _diagnosisController = TextEditingController();
  final _notesController = TextEditingController();

  final List<Map<String, dynamic>> _prescriptions = [];
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
                  return Text('Error loading history: ${snapshot.error}', style: const TextStyle(color: Colors.red));
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
                        color: widget.theme.colorScheme.primary.withOpacity(0.05),
                        shape: RoundedRectangleBorder(
                          side: BorderSide(color: widget.theme.dividerColor.withOpacity(0.1)),
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
        Text(label, style: TextStyle(color: widget.theme.textTheme.bodyMedium?.color?.withOpacity(0.6), fontSize: 12)),
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
                      Text('Status: ${widget.appointment.status}', style: TextStyle(color: widget.theme.textTheme.bodyMedium?.color?.withOpacity(0.6), fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: _showPatientHistory,
                  icon: const Icon(Icons.history_rounded, size: 18),
                  label: const Text('History'),
                  style: TextButton.styleFrom(
                      foregroundColor: widget.theme.colorScheme.primary,
                      backgroundColor: widget.theme.colorScheme.primary.withOpacity(0.1),
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
                  decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_rounded, color: Colors.green.shade600, size: 28),
                      const SizedBox(width: 12),
                      Text(
                        'Encounter finalized successfully.',
                        style: TextStyle(color: Colors.green.shade600, fontWeight: FontWeight.bold),
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
                    color: Colors.amber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.amber.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.hourglass_empty_rounded, color: Colors.amber.shade700, size: 32),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Awaiting Front-Desk Check-In',
                              style: TextStyle(color: Colors.amber.shade700, fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Clinical documentation workflows will unlock automatically once front-desk staff checks this patient in.',
                              style: TextStyle(color: Colors.amber.shade700, fontSize: 13, height: 1.4),
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
                              backgroundColor: widget.theme.colorScheme.primary.withOpacity(0.1),
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
                            border: Border.all(color: widget.theme.dividerColor.withOpacity(0.2), style: BorderStyle.solid),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text('No medications added.', textAlign: TextAlign.center, style: TextStyle(color: widget.theme.textTheme.bodyMedium?.color?.withOpacity(0.5), fontSize: 13)),
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
                              color: widget.theme.colorScheme.primary.withOpacity(0.05),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                title: Text(p['medicationName'], style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Text('${p['dosage']} — ${p['durationInDays']} Days\n${p['instructions']}', style: TextStyle(height: 1.3, color: widget.theme.textTheme.bodyMedium?.color?.withOpacity(0.8))),
                                ),
                                isThreeLine: true,
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.red),
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
                              );

                              if (mounted) {
                                Navigator.pop(context);
                                final displayError = (errorMsg != null && errorMsg.trim().isNotEmpty) ? errorMsg : null;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(displayError ?? 'Encounter & Prescriptions Finalized!'),
                                    backgroundColor: displayError == null ? Colors.green.shade600 : Colors.red.shade700,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade700,
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