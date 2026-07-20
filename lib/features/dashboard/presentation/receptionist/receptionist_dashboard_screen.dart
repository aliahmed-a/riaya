import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

// Import your theme and provider
import '../../../../core/theme/app_theme.dart';

import '../../../appointments/data/models/upcoming_appointment_model.dart';
import '../../../appointments/presentation/providers/upcoming_appointments_provider.dart';
import '../../../appointments/data/repositories/appointment_repository.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import 'widgets/billing_checkout_sheet.dart';
import 'widgets/appointment_booking_wizard.dart';

class ReceptionistDashboardScreen extends ConsumerWidget {
  const ReceptionistDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queueState = ref.watch(upcomingAppointmentsProvider);
    final authState = ref.watch(authProvider);
    final staffName = authState.user?.fullName ?? 'Front Desk Team';
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor, // Adaptive background
      appBar: AppBar(
        elevation: 0,
        title: const Text('Front Desk Command Center', style: TextStyle(fontWeight: FontWeight.w600,fontSize: 18,)),
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
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openBookingWizard(context),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.calendar_today_rounded),
        label: const Text('Book Appointment', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(upcomingAppointmentsProvider.notifier).refreshQueue(),
        color: theme.colorScheme.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStaffHeader(context, staffName, theme, ref),
              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Today's Active Patient Queue",
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  _buildCountBadge(theme, queueState),
                ],
              ),
              const SizedBox(height: 16),

              queueState.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40.0),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, stack) => _buildErrorCard(error.toString(), theme),
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
      ),
    );
  }

  Widget _buildStaffHeader(BuildContext context, String staffName, ThemeData theme, WidgetRef ref) {
    Color indicatorColor = theme.statusColors.success;
    String statusText = 'Live Network Routing Enabled';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.colorScheme.secondary, theme.colorScheme.primary],
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.secondary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            bottom: -20,
            child: Icon(
              Icons.support_agent_rounded,
              size: 120,
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
                          boxShadow: [BoxShadow(color: indicatorColor.withValues(alpha: 0.6), blurRadius: 6, spreadRadius: 1)]
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
                'Operations Coordinator On-Duty',
                style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.5),
              ),
              const SizedBox(height: 4),
              Text(
                staffName,
                style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCountBadge(ThemeData theme, AsyncValue<List<UpcomingAppointment>> queueState) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: queueState.maybeWhen(
        data: (list) => Text(
          '${list.length} Scheduled',
          style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 12),
        ),
        orElse: () => const Text('...', style: TextStyle(fontSize: 12)),
      ),
    );
  }

  Widget _buildErrorCard(String error, ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.statusColors.danger.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.statusColors.danger.withValues(alpha: 0.3)),
      ),
      padding: const EdgeInsets.all(16.0),
      child: Text('Sync Error: $error', style: TextStyle(color: theme.statusColors.danger)),
    );
  }

  Widget _buildEmptyQueueState(BuildContext context, ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 16.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface, // Adaptive Surface
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
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.calendar_today_rounded, size: 56, color: theme.colorScheme.primary.withValues(alpha: 0.5)),
          ),
          const SizedBox(height: 20),
          Text('No appointments scheduled', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Use the button below to add your first check-in encounter record.', textAlign: TextAlign.center, style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6), fontSize: 14)),
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
        final app = appointments[index];
        final timeString = DateFormat('hh:mm a').format(app.appointmentDate);
        final statusLower = app.status.toLowerCase();

        Color badgeColor = theme.statusColors.warning.withValues(alpha: 0.15);
        Color textBadgeColor = theme.statusColors.warning;
        if (statusLower.contains('check')) {
          badgeColor = theme.statusColors.info.withValues(alpha: 0.15);
          textBadgeColor = theme.statusColors.info;
        } else if (statusLower == 'completed') {
          badgeColor = theme.statusColors.success.withValues(alpha: 0.15);
          textBadgeColor = theme.statusColors.success;
        } else if (statusLower == 'cancelled') {
          badgeColor = theme.statusColors.danger.withValues(alpha: 0.15);
          textBadgeColor = theme.statusColors.danger;
        } else if (statusLower == 'confirmed') {
          badgeColor = theme.statusColors.confirmed.withValues(alpha: 0.15);
          textBadgeColor = theme.statusColors.confirmed;
        } else if (statusLower == 'noshow' || statusLower == 'no-show') {
          badgeColor = theme.dividerColor.withValues(alpha: 0.2);
          textBadgeColor = theme.textTheme.bodyMedium!.color!.withValues(alpha: 0.8);
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface, // Adaptive surface
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: theme.brightness == Brightness.dark ? 0.3 : 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Theme(
            data: theme.copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
              collapsedShape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.person_rounded, color: theme.colorScheme.primary, size: 24),
              ),
              title: Text(app.patientName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 6.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.schedule_rounded, size: 14, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '$timeString • Dr. ${app.doctorName}',
                            style: TextStyle(fontSize: 13, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6)),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.meeting_room_rounded, size: 14, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Room: ${app.clinicRoomName ?? 'Not Assigned'}',
                            style: TextStyle(fontSize: 13, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6)),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: badgeColor, borderRadius: BorderRadius.circular(20)),
                child: Text(app.status, style: TextStyle(color: textBadgeColor, fontSize: 12, fontWeight: FontWeight.w600)),
              ),
              children: [
                if (statusLower == 'pending')
                  Padding(
                    padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _executeAction(context, ref, () => ref.read(appointmentRepositoryProvider).confirmAppointment(app.id), 'Appointment Confirmed'),
                            icon: const Icon(Icons.thumb_up_alt_rounded, size: 16),
                            label: const Text('Confirm Appt'),
                            style: OutlinedButton.styleFrom(
                                foregroundColor: theme.statusColors.confirmed,
                                side: BorderSide(color: theme.statusColors.confirmed.withValues(alpha: 0.5)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                padding: const EdgeInsets.symmetric(vertical: 12)
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _executeAction(context, ref, () => ref.read(appointmentRepositoryProvider).cancelAppointment(app.id), 'Appointment Cancelled'),
                            icon: const Icon(Icons.cancel_rounded, size: 16),
                            label: const Text('Cancel Appt'),
                            style: OutlinedButton.styleFrom(
                                foregroundColor: theme.statusColors.danger,
                                side: BorderSide(color: theme.statusColors.danger.withValues(alpha: 0.5)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                padding: const EdgeInsets.symmetric(vertical: 12)
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                if (statusLower == 'confirmed')
                  Padding(
                    padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
                    child: Builder(
                        builder: (context) {
                          final now = DateTime.now();
                          final apptDate = app.appointmentDate;
                          final isToday = apptDate.year == now.year &&
                              apptDate.month == now.month &&
                              apptDate.day == now.day;

                          return Row(
                            children: [
                              if (isToday)
                                Expanded(
                                  flex: 2,
                                  child: OutlinedButton.icon(
                                    onPressed: () => _executeAction(context, ref, () => ref.read(appointmentRepositoryProvider).checkInAppointment(app.id), 'Patient checked-in successfully'),
                                    icon: const Icon(Icons.assignment_turned_in_rounded, size: 16),
                                    label: const Text('Check In Patient'),
                                    style: OutlinedButton.styleFrom(
                                        foregroundColor: theme.statusColors.info,
                                        side: BorderSide(color: theme.statusColors.info.withValues(alpha: 0.5)),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        padding: const EdgeInsets.symmetric(vertical: 12)
                                    ),
                                  ),
                                )
                              else
                                Expanded(
                                  flex: 2,
                                  child: OutlinedButton.icon(
                                    onPressed: null,
                                    icon: const Icon(Icons.lock_clock_rounded, size: 16),
                                    label: Text('Check-In opens ${DateFormat('MMM d').format(apptDate)}'),
                                    style: OutlinedButton.styleFrom(
                                        disabledForegroundColor: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.3),
                                        side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.2)),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        padding: const EdgeInsets.symmetric(vertical: 12)
                                    ),
                                  ),
                                ),

                              const SizedBox(width: 12),

                              Expanded(
                                flex: 1,
                                child: OutlinedButton.icon(
                                  onPressed: () => _executeAction(
                                      context,
                                      ref,
                                          () => ref.read(appointmentRepositoryProvider).markNoShow(app.id),
                                      'Patient marked as No-Show'
                                  ),
                                  icon: const Icon(Icons.person_off_rounded, size: 16),
                                  label: const Text('No Show'),
                                  style: OutlinedButton.styleFrom(
                                      foregroundColor: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                                      side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.3)),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      padding: const EdgeInsets.symmetric(vertical: 12)
                                  ),
                                ),
                              ),
                            ],
                          );
                        }
                    ),
                  ),

                if (statusLower == 'completed')
                  Padding(
                    padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _openBillingWizard(context, app),
                        icon: const Icon(Icons.receipt_long_rounded),
                        label: const Text('Generate Billing & Check-Out', style: TextStyle(fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: theme.statusColors.success,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _executeAction(BuildContext context, WidgetRef ref, Future<dynamic> Function() action, String successMsg) async {
    try {
      final res = await action();
      if (res is String?) {
        if (res != null) throw Exception(res);
      } else if (res is bool && !res) {
        throw Exception('Operation rejected by backend nodes.');
      }
      ref.read(upcomingAppointmentsProvider.notifier).refreshQueue();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(successMsg), backgroundColor: Theme.of(context).statusColors.success));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Theme.of(context).statusColors.danger));
      }
    }
  }

  void _openBookingWizard(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent, // Controlled by the widget itself
      builder: (_) => const AppointmentBookingWizard(),
    );
  }

  void _openBillingWizard(BuildContext context, UpcomingAppointment app) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BillingCheckoutSheet(appointment: app),
    );
  }
}
