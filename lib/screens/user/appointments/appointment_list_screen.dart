import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../models/appointment_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/appointment_provider.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/app_constants.dart';
import '../../../widgets/appointment_card_widget.dart';
import '../booking/appointment_booking_screen.dart';

class AppointmentListScreen extends StatefulWidget {
  const AppointmentListScreen({super.key});

  @override
  State<AppointmentListScreen> createState() => _AppointmentListScreenState();
}

class _AppointmentListScreenState extends State<AppointmentListScreen> {
  AppointmentStatus? _selectedStatus;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _loadAppointments();
    }
  }

  Future<void> _loadAppointments() async {
    final user = context.read<AuthProvider>().currentUser;
    if (user != null) {
      await context.read<AppointmentProvider>().loadUserAppointments(user.uid);
    }
  }

  Future<bool?> _showCancelConfirm(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cancel Appointment',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text(
            'Are you sure you want to cancel this appointment? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep It'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.cancelled,
              foregroundColor: Colors.white,
            ),
            child: const Text('Cancel Booking'),
          ),
        ],
      ),
    );
  }

  void _showRescheduleSheet(AppointmentModel apt) {
    DateTime? newDate;
    String? newTimeSlot;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Reschedule Appointment',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.calendar_month_rounded,
                    color: AppColors.primary),
                title: Text(
                  newDate == null
                      ? 'Select new date'
                      : DateFormat('EEE, dd MMM yyyy').format(newDate!),
                ),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                onTap: () async {
                  final date = await showDatePicker(
                    context: ctx,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 90)),
                  );
                  if (date != null) {
                    setSheetState(() => newDate = date);
                  }
                },
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: newTimeSlot,
                decoration: const InputDecoration(
                  labelText: 'New Time Slot',
                  prefixIcon: Icon(Icons.access_time_rounded,
                      color: AppColors.primary),
                  border: OutlineInputBorder(),
                ),
                items: AppConstants.timeSlots
                    .map((t) =>
                        DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) => setSheetState(() => newTimeSlot = v),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: newDate == null || newTimeSlot == null
                      ? null
                      : () async {
                          // TODO: call reschedule on provider
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Appointment rescheduled!'),
                              backgroundColor: AppColors.completed,
                            ),
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Confirm Reschedule',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthProvider>().currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Consumer<AppointmentProvider>(
        builder: (context, aptProv, _) {
          var appointments = aptProv.appointments
              .where((a) => a.userId == user?.uid)
              .toList();

          if (_selectedStatus != null) {
            appointments = appointments
                .where((a) => a.status == _selectedStatus)
                .toList();
          }

          return RefreshIndicator(
            onRefresh: _loadAppointments,
            color: AppColors.primary,
            child: Column(
              children: [
                // Filter chips
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _filterChip('All', null),
                        const SizedBox(width: 8),
                        _filterChip(
                            'Scheduled', AppointmentStatus.scheduled),
                        const SizedBox(width: 8),
                        _filterChip(
                            'In Progress', AppointmentStatus.inProgress),
                        const SizedBox(width: 8),
                        _filterChip(
                            'Completed', AppointmentStatus.completed),
                        const SizedBox(width: 8),
                        _filterChip(
                            'Cancelled', AppointmentStatus.cancelled),
                      ],
                    ),
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: aptProv.isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                              color: AppColors.primary))
                      : appointments.isEmpty
                          ? _buildEmptyState(context)
                          : ListView.builder(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 8),
                              itemCount: appointments.length,
                              itemBuilder: (_, i) {
                                final apt = appointments[i];
                                return AppointmentCardWidget(
                                  appointment: apt,
                                  onTap: () => _showDetailSheet(apt),
                                  onCancel: apt.status ==
                                          AppointmentStatus.scheduled
                                      ? () async {
                                          final confirmed =
                                              await _showCancelConfirm(
                                                  context);
                                          if (confirmed == true) {
                                            await aptProv
                                                .cancelAppointment(
                                                    apt.appointmentId);
                                          }
                                        }
                                      : null,
                                );
                              },
                            ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Book',
            style:
                TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _filterChip(String label, AppointmentStatus? status) {
    final isSelected = _selectedStatus == status;
    return GestureDetector(
      onTap: () => setState(() => _selectedStatus = status),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.divider,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight:
                isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  void _showDetailSheet(AppointmentModel apt) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Appointment Details',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(ctx),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            _detailItem('ID', apt.appointmentId),
            _detailItem('Service', apt.serviceType),
            _detailItem('Date',
                DateFormat('EEEE, dd MMMM yyyy').format(DateTime.parse(apt.preferredDate))),
            _detailItem('Time', apt.timeSlot),
            _detailItem('Queue Position', '#${apt.queuePosition}'),
            _detailItem('Status', apt.status.name.toUpperCase()),
            const SizedBox(height: 16),
            if (apt.status == AppointmentStatus.scheduled)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _showRescheduleSheet(apt);
                  },
                  icon: const Icon(Icons.calendar_month_rounded),
                  label: const Text('Reschedule'),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    side: const BorderSide(color: AppColors.primary),
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _detailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.list_alt_rounded,
                  size: 40, color: AppColors.primary),
            ),
            const SizedBox(height: 20),
            const Text(
              'No Appointments Yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your booking history will appear here once you make your first appointment.',
              textAlign: TextAlign.center,
              style:
                  TextStyle(color: AppColors.textSecondary, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
