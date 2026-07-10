import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

// Import your theme and provider
import '../../../../core/theme/app_theme.dart';

import '../../../../core/network/lookup_resources.dart';
import '../../../appointments/data/models/upcoming_appointment_model.dart';
import '../../../appointments/presentation/providers/upcoming_appointments_provider.dart';
import '../../../appointments/data/repositories/appointment_repository.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../patients/data/repositories/patient_repository.dart';
import '../../../patients/data/models/patient_model.dart';
import '../../../billing/data/repositories/billing_repository.dart';

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
    Color indicatorColor = Colors.greenAccent;
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
            color: theme.colorScheme.secondary.withOpacity(0.3),
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
                          boxShadow: [BoxShadow(color: indicatorColor.withOpacity(0.6), blurRadius: 6, spreadRadius: 1)]
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
        color: theme.colorScheme.primary.withOpacity(0.1),
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
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      padding: const EdgeInsets.all(16.0),
      child: Text('Sync Error: $error', style: const TextStyle(color: Colors.red)),
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
              color: Colors.black.withOpacity(theme.brightness == Brightness.dark ? 0.3 : 0.03),
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
              color: theme.colorScheme.primary.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.calendar_today_rounded, size: 56, color: theme.colorScheme.primary.withOpacity(0.5)),
          ),
          const SizedBox(height: 20),
          Text('No appointments scheduled', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Use the button below to add your first check-in encounter record.', textAlign: TextAlign.center, style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6), fontSize: 14)),
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

        Color badgeColor = Colors.amber.withOpacity(0.15);
        Color textBadgeColor = Colors.amber.shade700;
        if (statusLower.contains('check')) {
          badgeColor = Colors.blue.withOpacity(0.15);
          textBadgeColor = Colors.blue.shade700;
        } else if (statusLower == 'completed') {
          badgeColor = Colors.green.withOpacity(0.15);
          textBadgeColor = Colors.green.shade700;
        } else if (statusLower == 'cancelled') {
          badgeColor = Colors.red.withOpacity(0.15);
          textBadgeColor = Colors.red.shade700;
        } else if (statusLower == 'confirmed') {
          badgeColor = Colors.teal.withOpacity(0.15);
          textBadgeColor = Colors.teal.shade700;
        } else if (statusLower == 'noshow' || statusLower == 'no-show') {
          badgeColor = theme.dividerColor.withOpacity(0.2);
          textBadgeColor = theme.textTheme.bodyMedium!.color!.withOpacity(0.8);
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface, // Adaptive surface
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(theme.brightness == Brightness.dark ? 0.3 : 0.03),
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
                  color: theme.colorScheme.primary.withOpacity(0.08),
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
                        Icon(Icons.schedule_rounded, size: 14, color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '$timeString • Dr. ${app.doctorName}',
                            style: TextStyle(fontSize: 13, color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6)),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.meeting_room_rounded, size: 14, color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Room: ${app.clinicRoomName ?? 'Not Assigned'}',
                            style: TextStyle(fontSize: 13, color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6)),
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
                                foregroundColor: Colors.teal.shade500,
                                side: BorderSide(color: Colors.teal.shade500.withOpacity(0.5)),
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
                                foregroundColor: Colors.red.shade400,
                                side: BorderSide(color: Colors.red.shade400.withOpacity(0.5)),
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
                                        foregroundColor: Colors.blue.shade500,
                                        side: BorderSide(color: Colors.blue.shade500.withOpacity(0.5)),
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
                                        disabledForegroundColor: theme.textTheme.bodyMedium?.color?.withOpacity(0.3),
                                        side: BorderSide(color: theme.dividerColor.withOpacity(0.2)),
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
                                      foregroundColor: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                                      side: BorderSide(color: theme.dividerColor.withOpacity(0.3)),
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
                            backgroundColor: Colors.green.shade700,
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(successMsg), backgroundColor: Colors.green.shade600));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red.shade700));
      }
    }
  }

  void _openBookingWizard(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent, // Controlled by the widget itself
      builder: (_) => const _AppointmentBookingWizard(),
    );
  }

  void _openBillingWizard(BuildContext context, UpcomingAppointment app) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BillingCheckoutSheet(appointment: app),
    );
  }
}

// ============================================================================
// BILLING WIZARD
// ============================================================================
class _BillingCheckoutSheet extends ConsumerStatefulWidget {
  final UpcomingAppointment appointment;
  const _BillingCheckoutSheet({required this.appointment});

  @override
  ConsumerState<_BillingCheckoutSheet> createState() => _BillingCheckoutSheetState();
}

class _BillingCheckoutSheetState extends ConsumerState<_BillingCheckoutSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController(text: 'Standard Medical Consultation');

  int _selectedPaymentMethod = 0;
  bool _isProcessing = false;
  String? _errorMessage;

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _processCheckOut() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      final amount = double.parse(_amountController.text.trim());
      final billingRepo = ref.read(billingRepositoryProvider);

      final invoiceId = await billingRepo.createInvoice(
        patientId: widget.appointment.patientId,
        appointmentId: widget.appointment.id,
        items: [
          {
            'description': _descriptionController.text.trim(),
            'quantity': 1,
            'unitPrice': amount,
          }
        ],
      );

      final paymentSuccess = await billingRepo.processPayment(
        invoiceId: invoiceId,
        amount: amount,
        paymentMethod: _selectedPaymentMethod,
      );

      if (paymentSuccess && mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment processed successfully! Patient Check-Out complete.'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception('Payment authorization failed.');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final inputFill = isDark ? theme.colorScheme.surfaceContainerHighest : Colors.grey.shade50;

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor, // Adaptive background
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          top: 24, left: 24, right: 24
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Billing & Check-Out', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                    style: IconButton.styleFrom(backgroundColor: inputFill),
                  ),
                ],
              ),
              Text('Patient: ${widget.appointment.patientName}', style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6), fontSize: 15)),
              const Divider(height: 32),

              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                    labelText: 'Invoice Item Description',
                    filled: true,
                    fillColor: inputFill,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)
                ),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Total Amount Due',
                  filled: true,
                  fillColor: inputFill,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  prefixIcon: const Icon(Icons.attach_money),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Please enter amount';
                  if (double.tryParse(v) == null) return 'Invalid number';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<int>(
                value: _selectedPaymentMethod,
                dropdownColor: theme.colorScheme.surface,
                decoration: InputDecoration(
                    labelText: 'Payment Method',
                    filled: true,
                    fillColor: inputFill,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)
                ),
                items: const [
                  DropdownMenuItem(value: 0, child: Text('Cash', style: TextStyle(fontWeight: FontWeight.w500))),
                  DropdownMenuItem(value: 1, child: Text('Credit / Debit Card', style: TextStyle(fontWeight: FontWeight.w500))),
                  DropdownMenuItem(value: 2, child: Text('Bank Transfer', style: TextStyle(fontWeight: FontWeight.w500))),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _selectedPaymentMethod = val);
                },
              ),
              const SizedBox(height: 24),

              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                ),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : _processCheckOut,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))
                  ),
                  child: _isProcessing
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Process Payment & Close Invoice', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// APPOINTMENT BOOKING WIZARD
// ============================================================================
class _AppointmentBookingWizard extends ConsumerStatefulWidget {
  const _AppointmentBookingWizard();

  @override
  ConsumerState<_AppointmentBookingWizard> createState() => _AppointmentBookingWizardState();
}

class _AppointmentBookingWizardState extends ConsumerState<_AppointmentBookingWizard> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedDoctorId;
  String? _selectedRoomId;
  PatientModel? _selectedPatient;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  final _searchController = TextEditingController();
  List<PatientModel> _searchResults = [];
  bool _isSearching = false;
  bool _isSaving = false;
  bool _isRegistering = false;

  String? _errorMessage;

  bool _showRegistrationForm = false;
  final _regNameController = TextEditingController();
  final _regPhoneController = TextEditingController();
  String _regGender = 'Other';
  DateTime _regDob = DateTime(2000, 1, 1);

  @override
  void dispose() {
    _searchController.dispose();
    _regNameController.dispose();
    _regPhoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final doctorsAsync = ref.watch(dynamicDoctorsProvider);
    final roomsAsync = ref.watch(dynamicRoomsProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final inputFill = isDark ? theme.colorScheme.surfaceContainerHighest : Colors.grey.shade50;

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor, // Adaptive background
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 20, top: 24, left: 24, right: 24),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Schedule New Encounter', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                    style: IconButton.styleFrom(backgroundColor: inputFill),
                  ),
                ],
              ),
              const Divider(height: 24),

              doctorsAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (e, s) => Text('Doctor Fetch Failure: $e', style: const TextStyle(color: Colors.red)),
                data: (List<LookupResource> docs) => DropdownButtonFormField<String>(
                  dropdownColor: theme.colorScheme.surface,
                  decoration: InputDecoration(
                      labelText: 'Assign Medical Officer *',
                      filled: true,
                      fillColor: inputFill,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)
                  ),
                  value: _selectedDoctorId,
                  items: docs.map<DropdownMenuItem<String>>((LookupResource d) => DropdownMenuItem<String>(
                      value: d.id.toString(), // ensure ID is string
                      child: Text(d.name, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w500))
                  )).toList(),
                  onChanged: (val) => setState(() => _selectedDoctorId = val),
                  validator: (v) => v == null ? 'Please select a practitioner' : null,
                ),
              ),
              const SizedBox(height: 12),

              roomsAsync.when(
                loading: () => const SizedBox(),
                error: (e, s) => const SizedBox(),
                data: (List<LookupResource> rooms) => DropdownButtonFormField<String>(
                  dropdownColor: theme.colorScheme.surface,
                  decoration: InputDecoration(
                      labelText: 'Clinic Allocation Room (Optional)',
                      filled: true,
                      fillColor: inputFill,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)
                  ),
                  value: _selectedRoomId,
                  items: rooms.map<DropdownMenuItem<String>>((LookupResource r) => DropdownMenuItem<String>(
                      value: r.id.toString(), // ensure ID is string
                      child: Text(r.name, style: const TextStyle(fontWeight: FontWeight.w500))
                  )).toList(),
                  onChanged: (val) => setState(() => _selectedRoomId = val),
                ),
              ),
              const SizedBox(height: 24),

              const Text('Patient Demographic Identity', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 12),
              if (_selectedPatient != null)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.green.withOpacity(0.3))
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 32),
                    title: Text(_selectedPatient!.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('DOB: ${DateFormat('yyyy-MM-dd').format(_selectedPatient!.dateOfBirth)} • Phone: ${_selectedPatient!.phoneNumber}'),
                    trailing: TextButton(
                      onPressed: () => setState(() => _selectedPatient = null),
                      child: const Text('Change'),
                    ),
                  ),
                )
              else if (!_showRegistrationForm) ...[
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                            hintText: 'Search patient name...',
                            prefixIcon: const Icon(Icons.search),
                            filled: true,
                            fillColor: inputFill,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _isSearching ? null : _performPatientSearch,
                      style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                      ),
                      child: _isSearching ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Query'),
                    ),
                  ],
                ),
                if (_searchResults.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 180),
                    decoration: BoxDecoration(color: theme.colorScheme.surface, border: Border.all(color: theme.dividerColor.withOpacity(0.1)), borderRadius: BorderRadius.circular(12)),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: _searchResults.length,
                      separatorBuilder: (context, index) => const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final p = _searchResults[i];
                        return ListTile(
                          title: Text(p.fullName, style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text(p.phoneNumber),
                          onTap: () => setState(() { _selectedPatient = p; _searchResults.clear(); }),
                        );
                      },
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () => setState(() => _showRegistrationForm = true),
                  icon: const Icon(Icons.person_add_alt_1),
                  label: const Text('New Profile Entry (Quick Intake)'),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.2 : 0.02), blurRadius: 8, offset: const Offset(0, 4))]
                  ),
                  child: Column(
                    children: [
                      TextFormField(
                          controller: _regNameController,
                          decoration: InputDecoration(labelText: 'Full Patient Legal Name *', filled: true, fillColor: inputFill, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none))
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                          controller: _regPhoneController,
                          decoration: InputDecoration(labelText: 'Contact Phone String *', filled: true, fillColor: inputFill, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none)),
                          keyboardType: TextInputType.phone
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('DOB: ${DateFormat('yyyy-MM-dd').format(_regDob)}', style: const TextStyle(fontWeight: FontWeight.w500)),
                          TextButton(
                            onPressed: () async {
                              final picked = await showDatePicker(context: context, initialDate: _regDob, firstDate: DateTime(1920), lastDate: DateTime.now());
                              if (picked != null) setState(() => _regDob = picked);
                            },
                            child: const Text('Pick Date'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      DropdownButtonFormField<String>(
                        value: _regGender,
                        dropdownColor: theme.colorScheme.surface,
                        decoration: InputDecoration(filled: true, fillColor: inputFill, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none)),
                        items: const [DropdownMenuItem(value: 'Male', child: Text('Male')), DropdownMenuItem(value: 'Female', child: Text('Female')), DropdownMenuItem(value: 'Other', child: Text('Other'))],
                        onChanged: (v) => setState(() => _regGender = v ?? 'Other'),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(onPressed: _isRegistering ? null : () => setState(() => _showRegistrationForm = false), child: Text('Back', style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6)))),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: _isRegistering ? null : _performQuickRegistration,
                            style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                            child: _isRegistering
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                                : const Text('Register Core Profile'),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),

              const Text('Encounter Slot Scheduling', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _pickEncounterDate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                        decoration: BoxDecoration(color: inputFill, borderRadius: BorderRadius.circular(12)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(DateFormat('yyyy-MM-dd').format(_selectedDate), style: const TextStyle(fontWeight: FontWeight.w600)),
                            Icon(Icons.date_range_rounded, size: 20, color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: _pickEncounterTime,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                        decoration: BoxDecoration(color: inputFill, borderRadius: BorderRadius.circular(12)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(_selectedTime.format(context), style: const TextStyle(fontWeight: FontWeight.w600)),
                            Icon(Icons.access_time_rounded, size: 20, color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 40),

              if (_errorMessage != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red.shade700),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _submitAppointmentPayload,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))
                  ),
                  child: _isSaving ? const CircularProgressIndicator(color: Colors.white) : const Text('Authorize & Commit Schedule Slot', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _performPatientSearch() async {
    if (_searchController.text.trim().isEmpty) return;
    setState(() => _isSearching = true);
    try {
      final res = await ref.read(patientRepositoryProvider).searchPatients(query: _searchController.text.trim());
      setState(() => _searchResults = res);
    } catch (_) {
      setState(() => _searchResults = []);
    } finally {
      setState(() => _isSearching = false);
    }
  }

  Future<void> _performQuickRegistration() async {
    if (_regNameController.text.trim().isEmpty || _regPhoneController.text.trim().isEmpty) return;
    setState(() => _isRegistering = true);
    try {
      final request = CreatePatientRequest(
        fullName: _regNameController.text.trim(),
        phoneNumber: _regPhoneController.text.trim(),
        dateOfBirth: _regDob,
        gender: _regGender,
      );

      final profile = await ref.read(patientRepositoryProvider).createPatient(request);
      if (mounted) {
        setState(() { _selectedPatient = profile; _showRegistrationForm = false; });
      }
    } catch (e) {
      String errorMessage = e.toString().replaceAll('Exception: ', '');
      if (errorMessage.toLowerCase().contains('phone number already exists') ||
          errorMessage.toLowerCase().contains('conflict 409')) {
        errorMessage = "A patient with this phone number already exists in database. Please use search instead.";
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red.shade700
        ));
      }
    } finally {
      if (mounted) {
        setState(() => _isRegistering = false);
      }
    }
  }

  Future<void> _pickEncounterDate() async {
    final picked = await showDatePicker(context: context, initialDate: _selectedDate, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 90)));
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickEncounterTime() async {
    final picked = await showTimePicker(context: context, initialTime: _selectedTime);
    if (picked != null) setState(() => _selectedTime = picked);
  }

  Future<void> _submitAppointmentPayload() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _errorMessage = null;
    });

    if (_selectedPatient == null) {
      setState(() {
        _errorMessage = 'Verification error: Please allocate a registered patient profiling card first.';
      });
      return;
    }

    setState(() => _isSaving = true);
    try {
      final combinedDateTime = DateTime(
        _selectedDate.year, _selectedDate.month, _selectedDate.day,
        _selectedTime.hour, _selectedTime.minute,
      );

      final success = await ref.read(appointmentRepositoryProvider).createAppointment(
        doctorId: int.parse(_selectedDoctorId!),
        patientId: _selectedPatient!.id,
        clinicRoomId: _selectedRoomId != null ? int.tryParse(_selectedRoomId!) : null,
        appointmentDate: combinedDateTime,
      );

      if (success && mounted) {
        final messenger = ScaffoldMessenger.of(context);
        ref.read(upcomingAppointmentsProvider.notifier).refreshQueue();
        Navigator.pop(context);
        messenger.showSnackBar(const SnackBar(content: Text('Encounter Slot Registered and Confirmed! 🗓️'), backgroundColor: Colors.green));
      } else {
        throw Exception('Encounter slot reservation rejected by medical controller validations.');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}