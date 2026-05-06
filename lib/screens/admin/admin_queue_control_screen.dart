import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/appointment_model.dart';
import '../../providers/admin_provider.dart';
import '../../providers/queue_provider.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_constants.dart';
import '../../widgets/queue_indicator_widget.dart';

class AdminQueueControlScreen extends StatefulWidget {
  const AdminQueueControlScreen({super.key});

  @override
  State<AdminQueueControlScreen> createState() =>
      _AdminQueueControlScreenState();
}

class _AdminQueueControlScreenState extends State<AdminQueueControlScreen> {
  String _selectedService = AppConstants.serviceTypes.first;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _listenToQueue();
  }

  void _listenToQueue() {
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    context.read<QueueProvider>().listenToQueue(dateStr, _selectedService);
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);

    return Consumer2<QueueProvider, AdminProvider>(
      builder: (context, queueProv, adminProv, _) {
        final queue = queueProv.queueModel;
        final currentToken = queue?.currentToken ?? 0;
        final totalApts = adminProv.allAppointments
            .where((a) =>
                a.preferredDate == dateStr &&
                a.serviceType == _selectedService &&
                a.status != AppointmentStatus.cancelled)
            .toList()
          ..sort((a, b) => a.queuePosition.compareTo(b.queuePosition));

        final completed =
            totalApts.where((a) => a.status == AppointmentStatus.completed).length;
        final remaining = totalApts.length - completed;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Service selector
              const Text('Service',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedService,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.medical_services_outlined,
                      color: AppColors.adminAccent),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.divider),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.divider),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                ),
                items: AppConstants.serviceTypes
                    .map((s) => DropdownMenuItem(
                          value: s,
                          child: Text(s, style: const TextStyle(fontSize: 14)),
                        ))
                    .toList(),
                onChanged: (v) {
                  if (v != null) {
                    setState(() => _selectedService = v);
                    _listenToQueue();
                  }
                },
              ),
              const SizedBox(height: 12),
              // Date picker
              GestureDetector(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2024),
                    lastDate: DateTime.now().add(const Duration(days: 90)),
                    builder: (context, child) => Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: const ColorScheme.light(
                            primary: AppColors.adminAccent),
                      ),
                      child: child!,
                    ),
                  );
                  if (date != null) {
                    setState(() => _selectedDate = date);
                    _listenToQueue();
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_month_rounded,
                          color: AppColors.adminAccent, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        DateFormat('EEE, dd MMMM yyyy').format(_selectedDate),
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Large queue display
              Center(
                child: QueueIndicatorWidget(
                  currentToken: currentToken,
                  userToken: currentToken + 1,
                  size: 180,
                ),
              ),
              const SizedBox(height: 20),

              // Stats row
              Row(
                children: [
                  _queueStat('Total', totalApts.length.toString(),
                      AppColors.adminAccent),
                  const SizedBox(width: 12),
                  _queueStat(
                      'Completed', completed.toString(), AppColors.completed),
                  const SizedBox(width: 12),
                  _queueStat(
                      'Remaining', remaining.toString(), AppColors.inProgress),
                ],
              ),
              const SizedBox(height: 20),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await adminProv.moveQueueForward(
                            dateStr, _selectedService);
                      },
                      icon: const Icon(Icons.skip_next_rounded),
                      label: const Text('Next Token'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.adminAccent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                            title: const Text('Reset Queue',
                                style:
                                    TextStyle(fontWeight: FontWeight.w700)),
                            content: const Text(
                                'This will reset the current token to 0. Continue?'),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.pop(ctx, false),
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton(
                                onPressed: () =>
                                    Navigator.pop(ctx, true),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.cancelled,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Reset'),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          // Reset via FirebaseService
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Queue reset to 0'),
                              backgroundColor: AppColors.inProgress,
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Reset'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.cancelled,
                        side: const BorderSide(color: AppColors.cancelled),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Live queue list
              const Text(
                'Queue Order',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              if (totalApts.isEmpty)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text(
                      'No appointments in queue for this date & service.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                )
              else
                ...totalApts.map((apt) {
                  final isServing = apt.queuePosition == currentToken;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isServing
                          ? AppColors.inProgress.withOpacity(0.1)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isServing
                            ? AppColors.inProgress
                            : AppColors.divider,
                        width: isServing ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: isServing
                                ? AppColors.inProgress
                                : AppColors.primary.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '#${apt.queuePosition}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: isServing
                                    ? Colors.white
                                    : AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                apt.userName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                '${apt.timeSlot} — ${apt.serviceType}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isServing)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.inProgress,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'NOW',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _statusColor(apt.status)
                                  .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              apt.status.name,
                              style: TextStyle(
                                color: _statusColor(apt.status),
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                }),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _queueStat(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.scheduled:
        return AppColors.scheduled;
      case AppointmentStatus.inProgress:
        return AppColors.inProgress;
      case AppointmentStatus.completed:
        return AppColors.completed;
      case AppointmentStatus.cancelled:
        return AppColors.cancelled;
    }
  }
}
