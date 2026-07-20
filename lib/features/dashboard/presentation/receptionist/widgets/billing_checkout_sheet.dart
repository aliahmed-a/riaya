import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../appointments/data/models/upcoming_appointment_model.dart';
import '../../../../billing/data/repositories/billing_repository.dart';

/// Bottom sheet opened from a completed appointment: creates the invoice and
/// records the payment, then closes out the patient's check-out.
class BillingCheckoutSheet extends ConsumerStatefulWidget {
  final UpcomingAppointment appointment;
  const BillingCheckoutSheet({super.key, required this.appointment});

  @override
  ConsumerState<BillingCheckoutSheet> createState() => _BillingCheckoutSheetState();
}

class _BillingCheckoutSheetState extends ConsumerState<BillingCheckoutSheet> {
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
        final successColor = Theme.of(context).statusColors.success;
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Payment processed successfully! Patient Check-Out complete.'),
            backgroundColor: successColor,
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
              Text('Patient: ${widget.appointment.patientName}', style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6), fontSize: 15)),
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
                  decoration: BoxDecoration(color: theme.statusColors.danger.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                  child: Text(_errorMessage!, style: TextStyle(color: theme.statusColors.danger)),
                ),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : _processCheckOut,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: theme.statusColors.success,
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
