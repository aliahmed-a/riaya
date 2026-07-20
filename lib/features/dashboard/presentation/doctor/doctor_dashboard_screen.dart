import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

// Import your theme and provider
import '../../../../core/theme/app_theme.dart';

import '../../../appointments/presentation/providers/upcoming_appointments_provider.dart';
import '../../../appointments/data/models/upcoming_appointment_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../doctor_schedule/presentation/providers/doctor_schedule_provider.dart';
import '../../../doctor_schedule/data/models/doctor_schedule_model.dart';
import 'widgets/clinical_action_sheet.dart';

class DoctorDashboardScreen extends ConsumerWidget {
  const DoctorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final doctorName = authState.user?.fullName ?? 'Doctor Workspace';

    // 🟢 DYNAMIC LOGIC: Read the specialization dynamically from the auth response state
    final specialization = authState.user?.specializationName ?? 'General Practitioner';
    final theme = Theme.of(context);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor, // Adaptive background
        appBar: AppBar(
          elevation: 0,
          title: const Text('Clinical Workspace', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18)),
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: Colors.white,
          centerTitle: false,
          actions: [
            // Theme Toggle Button
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
            _buildPatientQueueTab(context, ref, doctorName, specialization, theme), // 🟢 UPDATED: Passed specialization parameter
            _buildScheduleManagementTab(context, ref, theme),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // TAB 1: PATIENT QUEUE DESIGN
  // ==========================================
  Widget _buildPatientQueueTab(BuildContext context, WidgetRef ref, String doctorName, String specialization, ThemeData theme) {
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
            _buildWelcomeHeader(context, doctorName, specialization, theme, ref), // 🟢 UPDATED: Passed specialization parameter
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
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
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
                  color: theme.statusColors.danger.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.statusColors.danger.withValues(alpha: 0.3)),
                ),
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Failed to synchronize schedule: $error',
                  style: TextStyle(color: theme.statusColors.danger),
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

  Widget _buildWelcomeHeader(BuildContext context, String doctorName, String specialization, ThemeData theme, WidgetRef ref) {
    Color indicatorColor = theme.statusColors.success;
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
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
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
              color: Colors.white.withValues(alpha: 0.1),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
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
                            BoxShadow(color: indicatorColor.withValues(alpha: 0.5), blurRadius: 6, spreadRadius: 1)
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

              // 🟢 UPDATED: Using the dynamic specialization value here instead of the static string
              Text(
                specialization,
                style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 0.5),
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
              color: Colors.black.withValues(alpha: theme.brightness == Brightness.dark ? 0.3 : 0.03),
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
              color: theme.colorScheme.primary.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.assignment_turned_in_rounded, size: 56, color: theme.colorScheme.primary.withValues(alpha: 0.5)),
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
            style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6), fontSize: 14),
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

        Color badgeColor = theme.statusColors.warning.withValues(alpha: 0.15);
        Color textBadgeColor = theme.statusColors.warning;
        if (statusLower == 'checkedin' || statusLower == 'checked-in') {
          badgeColor = theme.statusColors.info.withValues(alpha: 0.15);
          textBadgeColor = theme.statusColors.info;
        } else if (statusLower == 'completed') {
          badgeColor = theme.statusColors.success.withValues(alpha: 0.15);
          textBadgeColor = theme.statusColors.success;
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface, // Adaptive surface
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: theme.brightness == Brightness.dark ? 0.3 : 0.04),
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
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
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
                              Icon(Icons.access_time_rounded, size: 14, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5)),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  '$timeString • ${appointment.durationMinutes} Min',
                                  style: TextStyle(fontSize: 13, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6)),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(Icons.meeting_room_rounded, size: 14, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5)),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  'Rm ${appointment.clinicRoomName ?? "N/A"}',
                                  style: TextStyle(fontSize: 13, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6)),
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
        return ClinicalActionSheet(appointment: appointment, theme: theme);
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
              error: (err, stack) => Text('Failed to load schedule rules: $err', style: TextStyle(color: theme.statusColors.danger)),
              data: (schedules) {
                if (schedules.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40.0),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.calendar_today_rounded, size: 48, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.3)),
                          const SizedBox(height: 12),
                          Text(
                            'No working timeblocks configured.\nPlease contact an administrator to set up your schedule.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6), fontSize: 14),
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
                          BoxShadow(color: Colors.black.withValues(alpha: theme.brightness == Brightness.dark ? 0.3 : 0.03), blurRadius: 10, offset: const Offset(0, 4))
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: theme.statusColors.info.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.wb_sunny_rounded, color: theme.statusColors.info, size: 22),
                        ),
                        title: Text(
                          getBackendDayName(item.dayOfWeek), // Reads its own dayOfWeek value via custom mapper
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            '${_cleanTimeStr(item.startTime)} — ${_cleanTimeStr(item.endTime)}',
                            style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7), fontSize: 14),
                          ),
                        ),
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

  String getBackendDayName(int dayOfWeek) {
    switch (dayOfWeek) {
      case 0: return 'Sunday';
      case 1: return 'Monday';
      case 2: return 'Tuesday';
      case 3: return 'Wednesday';
      case 4: return 'Thursday';
      case 5: return 'Friday';
      case 6: return 'Saturday';
      default: return 'Unknown';
    }
  }

  String _cleanTimeStr(String time) {
    if (time.length >= 5) {
      return time.substring(0, 5);
    }
    return time;
  }
}
