import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/appointment_model.dart';
import '../../providers/admin_provider.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_constants.dart';
import '../../widgets/appointment_card_widget.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  String _selectedService = 'All';
  late Timer _clockTimer;
  late DateTime _now;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _clockTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    super.dispose();
  }

  Future<void> _showRescheduleSheet(
      BuildContext context, AppointmentModel apt, AdminProvider admin) async {
    DateTime? newDate;
    String? newTimeSlot;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
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
              const Text('Reschedule Appointment',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.calendar_month_rounded,
                    color: AppColors.adminAccent),
                title: Text(newDate == null
                    ? 'Select new date'
                    : DateFormat('EEE, dd MMM yyyy').format(newDate!)),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                onTap: () async {
                  final date = await showDatePicker(
                    context: ctx,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 90)),
                  );
                  if (date != null) setSheet(() => newDate = date);
                },
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: newTimeSlot,
                decoration: const InputDecoration(
                  labelText: 'New Time Slot',
                  prefixIcon: Icon(Icons.access_time_rounded,
                      color: AppColors.adminAccent),
                  border: OutlineInputBorder(),
                ),
                items: AppConstants.timeSlots
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) => setSheet(() => newTimeSlot = v),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: newDate == null || newTimeSlot == null
                      ? null
                      : () async {
                          await admin.rescheduleAppointment(
                            apt.appointmentId,
                            DateFormat('yyyy-MM-dd').format(newDate!),
                            newTimeSlot!,
                          );
                          if (ctx.mounted) Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Appointment rescheduled!'),
                              backgroundColor: AppColors.completed,
                            ),
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.adminAccent,
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
    return Consumer<AdminProvider>(
      builder: (context, admin, _) {
        var filteredApts = admin.allAppointments
            .where((a) =>
                a.preferredDate ==
                DateFormat('yyyy-MM-dd').format(DateTime.now()))
            .toList();

        if (_selectedService != 'All') {
          filteredApts = filteredApts
              .where((a) => a.serviceType == _selectedService)
              .toList();
        }

        return RefreshIndicator(
          onRefresh: () async => admin.listenToAllAppointments(),
          color: AppColors.adminAccent,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with date/time
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF1A2332), AppColors.adminPrimary],
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              DateFormat('EEEE').format(_now),
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.7),
                              ),
                            ),
                            Text(
                              DateFormat('dd MMMM yyyy').format(_now),
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          DateFormat('hh:mm a').format(_now),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Stats row
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      _statCard(
                          'Total Today',
                          admin.totalToday.toString(),
                          Icons.calendar_today_rounded,
                          AppColors.adminAccent),
                      const SizedBox(width: 10),
                      _statCard(
                          'In Progress',
                          admin.inProgressToday.toString(),
                          Icons.play_circle_rounded,
                          AppColors.inProgress),
                      const SizedBox(width: 10),
                      _statCard(
                          'Completed',
                          admin.completedToday.toString(),
                          Icons.check_circle_rounded,
                          AppColors.completed),
                      const SizedBox(width: 10),
                      _statCard(
                          'Pending',
                          admin.pendingToday.toString(),
                          Icons.pending_rounded,
                          AppColors.cancelled),
                    ],
                  ),
                ),

                // Service selector
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Filter by Service',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 36,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: ['All', ...AppConstants.serviceTypes]
                              .map((s) {
                            final isSelected = _selectedService == s;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: GestureDetector(
                                onTap: () =>
                                    setState(() => _selectedService = s),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.adminAccent
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: isSelected
                                          ? AppColors.adminAccent
                                          : AppColors.divider,
                                    ),
                                  ),
                                  child: Text(
                                    s,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: isSelected
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      color: isSelected
                                          ? Colors.white
                                          : AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Text(
                        "Today's Appointments (${filteredApts.length})",
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                if (admin.isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(
                          color: AppColors.adminAccent),
                    ),
                  )
                else if (filteredApts.isEmpty)
                  _buildEmptyToday()
                else
                  ...filteredApts.map(
                    (apt) => AppointmentCardWidget(
                      appointment: apt,
                      isAdminView: true,
                      onComplete: apt.status != AppointmentStatus.completed &&
                              apt.status != AppointmentStatus.cancelled
                          ? () async {
                              await admin.markAsCompleted(
                                apt.appointmentId,
                                apt.preferredDate,
                                apt.serviceType,
                              );
                            }
                          : null,
                      onCancel: apt.status != AppointmentStatus.cancelled
                          ? () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(16)),
                                  title: const Text('Cancel Appointment',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w700)),
                                  content: const Text(
                                      'Are you sure you want to cancel this appointment?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(ctx, false),
                                      child: const Text('No'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () =>
                                          Navigator.pop(ctx, true),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.cancelled,
                                        foregroundColor: Colors.white,
                                      ),
                                      child: const Text('Yes, Cancel'),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                await admin.cancelAppointment(
                                    apt.appointmentId);
                              }
                            }
                          : null,
                      onReschedule:
                          apt.status != AppointmentStatus.completed &&
                                  apt.status != AppointmentStatus.cancelled
                              ? () => _showRescheduleSheet(context, apt, admin)
                              : null,
                    ),
                  ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _statCard(
      String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 9,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyToday() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.event_available_rounded,
                size: 48, color: AppColors.textSecondary.withOpacity(0.5)),
            const SizedBox(height: 12),
            const Text(
              'No appointments today',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
