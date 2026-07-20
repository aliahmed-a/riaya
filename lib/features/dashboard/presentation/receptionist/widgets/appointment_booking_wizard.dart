import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/network/lookup_resources.dart';
import '../../../../appointments/data/repositories/appointment_repository.dart';
import '../../../../appointments/presentation/providers/upcoming_appointments_provider.dart';
import '../../../../patients/data/repositories/patient_repository.dart';
import '../../../../patients/data/models/patient_model.dart';

/// Bottom sheet opened from the front-desk FAB: picks a doctor/room, finds or
/// quick-registers a patient, then books the encounter slot.
class AppointmentBookingWizard extends ConsumerStatefulWidget {
  const AppointmentBookingWizard({super.key});

  @override
  ConsumerState<AppointmentBookingWizard> createState() => _AppointmentBookingWizardState();
}

class _AppointmentBookingWizardState extends ConsumerState<AppointmentBookingWizard> {
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

              // 🟢 EXTRACTED MEDICAL OFFICER LABEL
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 8),
                    child: Text(
                      'Assign Medical Officer *',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                  doctorsAsync.when(
                    loading: () => const LinearProgressIndicator(),
                    error: (e, s) => Text('Doctor Fetch Failure: $e', style: TextStyle(color: theme.statusColors.danger)),
                    data: (List<LookupResource> docs) => DropdownButtonFormField<String>(
                      isExpanded: true, // Prevents overflow issues with longer names/specialties
                      dropdownColor: theme.colorScheme.surface,
                      decoration: InputDecoration(
                        // 🟢 REMOVED labelText from here
                          filled: true,
                          fillColor: inputFill,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)
                      ),
                      value: _selectedDoctorId,
                      items: docs.map<DropdownMenuItem<String>>((LookupResource d) {

                        final String doctorSpecialty = d.specializationName ?? 'General Practice';

                        return DropdownMenuItem<String>(
                            value: d.id.toString(),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                      d.name,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontWeight: FontWeight.w600)
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    doctorSpecialty,
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: theme.colorScheme.primary
                                    ),
                                  ),
                                ),
                              ],
                            )
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _selectedDoctorId = val),
                      validator: (v) => v == null ? 'Please select a practitioner' : null,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // 🟢 EXTRACTED ROOM LABEL
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 8),
                    child: Text(
                      'Clinic Allocation Room (Optional)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                  roomsAsync.when(
                    loading: () => const SizedBox(),
                    error: (e, s) => const SizedBox(),
                    data: (List<LookupResource> rooms) => DropdownButtonFormField<String>(
                      dropdownColor: theme.colorScheme.surface,
                      decoration: InputDecoration(
                        // 🟢 REMOVED labelText from here
                          filled: true,
                          fillColor: inputFill,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                ],
              ),
              const SizedBox(height: 24),

              const Text('Patient Demographic Identity', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 12),
              if (_selectedPatient != null)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: theme.statusColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: theme.statusColors.success.withValues(alpha: 0.3))
                  ),
                  child: ListTile(
                    leading: Icon(Icons.check_circle_rounded, color: theme.statusColors.success, size: 32),
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
                    decoration: BoxDecoration(color: theme.colorScheme.surface, border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)), borderRadius: BorderRadius.circular(12)),
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
                      border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02), blurRadius: 8, offset: const Offset(0, 4))]
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
                          TextButton(onPressed: _isRegistering ? null : () => setState(() => _showRegistrationForm = false), child: Text('Back', style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6)))),
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
                            Icon(Icons.date_range_rounded, size: 20, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6)),
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
                            Icon(Icons.access_time_rounded, size: 20, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6)),
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
                    color: theme.statusColors.danger.withValues(alpha: 0.1),
                    border: Border.all(color: theme.statusColors.danger.withValues(alpha: 0.3)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: theme.statusColors.danger),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: theme.statusColors.danger, fontWeight: FontWeight.w600),
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
            backgroundColor: Theme.of(context).statusColors.danger
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
        final successColor = Theme.of(context).statusColors.success;
        ref.read(upcomingAppointmentsProvider.notifier).refreshQueue();
        Navigator.pop(context);
        messenger.showSnackBar(SnackBar(content: const Text('Encounter Slot Registered and Confirmed! 🗓️'), backgroundColor: successColor));
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
