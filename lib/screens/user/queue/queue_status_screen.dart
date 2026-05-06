import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../models/appointment_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/appointment_provider.dart';
import '../../../providers/queue_provider.dart';
import '../../../utils/app_colors.dart';
import '../../../widgets/queue_indicator_widget.dart';

class QueueStatusScreen extends StatefulWidget {
  const QueueStatusScreen({super.key});

  @override
  State<QueueStatusScreen> createState() => _QueueStatusScreenState();
}

class _QueueStatusScreenState extends State<QueueStatusScreen> {
  AppointmentModel? _selectedAppointment;
  String _lastUpdated = 'just now';

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    final user = context.read<AuthProvider>().currentUser;
    if (user != null) {
      await context.read<AppointmentProvider>().loadUserAppointments(user.uid);
    }
  }

  void _selectAppointment(AppointmentModel apt) {
    setState(() {
      _selectedAppointment = apt;
      _lastUpdated = 'just now';
    });
    context.read<QueueProvider>().listenToQueue(
          apt.preferredDate,
          apt.serviceType,
        );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthProvider>().currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Consumer<AppointmentProvider>(
        builder: (context, aptProv, _) {
          final activeApts = aptProv.appointments
              .where((a) =>
                  a.userId == user?.uid &&
                  (a.status == AppointmentStatus.scheduled ||
                      a.status == AppointmentStatus.inProgress))
              .toList();

          if (aptProv.isLoading) {
            return const Center(
                child: CircularProgressIndicator(color: AppColors.primary));
          }

          if (activeApts.isEmpty) {
            return _buildEmptyState(context);
          }

          // Auto-select first if none selected
          if (_selectedAppointment == null && activeApts.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _selectAppointment(activeApts.first);
            });
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Appointment selector
                if (activeApts.length > 1) ...[
                  const Text(
                    'Select Appointment to Track',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 40,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: activeApts.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, i) {
                        final apt = activeApts[i];
                        final isSelected =
                            _selectedAppointment?.appointmentId ==
                                apt.appointmentId;
                        return GestureDetector(
                          onTap: () => _selectAppointment(apt),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.divider,
                              ),
                            ),
                            child: Text(
                              apt.serviceType,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.textPrimary,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                if (_selectedAppointment != null)
                  Consumer<QueueProvider>(
                    builder: (context, queueProv, _) {
                      final queue = queueProv.queueModel;
                      final apt = _selectedAppointment!;
                      final currentToken = queue?.currentToken ?? 0;
                      final userToken = apt.queuePosition;
                      final ahead = userToken - currentToken - 1;
                      final wait =
                          queueProv.getEstimatedWait(userToken);

                      return Column(
                        children: [
                          // Queue circle
                          Center(
                            child: QueueIndicatorWidget(
                              currentToken: currentToken,
                              userToken: userToken,
                              size: 180,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Status message
                          _buildStatusMessage(ahead),
                          const SizedBox(height: 16),

                          // User info card
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                _queueInfoRow(
                                    'Your Token',
                                    '#$userToken',
                                    Icons.confirmation_number_rounded,
                                    AppColors.primary),
                                const Divider(height: 20),
                                _queueInfoRow(
                                    'Currently Serving',
                                    '#$currentToken',
                                    Icons.play_circle_rounded,
                                    AppColors.inProgress),
                                const Divider(height: 20),
                                _queueInfoRow(
                                    'Estimated Wait',
                                    wait == 0
                                        ? "It's your turn!"
                                        : '~$wait min',
                                    Icons.timer_outlined,
                                    AppColors.queueSoon),
                                const Divider(height: 20),
                                _queueInfoRow(
                                    'Service',
                                    apt.serviceType,
                                    Icons.medical_services_outlined,
                                    AppColors.textSecondary),
                                const Divider(height: 20),
                                _queueInfoRow(
                                    'Date',
                                    _formatDate(apt.preferredDate),
                                    Icons.calendar_today_rounded,
                                    AppColors.textSecondary),
                                const Divider(height: 20),
                                _queueInfoRow(
                                    'Time Slot',
                                    apt.timeSlot,
                                    Icons.access_time_rounded,
                                    AppColors.textSecondary),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Progress bar
                          if (queue != null && queue.totalAppointments > 0)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Queue Progress',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      '${queue.currentToken}/${queue.totalAppointments}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: LinearProgressIndicator(
                                    value: queue.totalAppointments > 0
                                        ? queue.currentToken /
                                            queue.totalAppointments
                                        : 0,
                                    backgroundColor:
                                        AppColors.primary.withOpacity(0.15),
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
                                            AppColors.primary),
                                    minHeight: 10,
                                  ),
                                ),
                              ],
                            ),
                          const SizedBox(height: 12),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.update_rounded,
                                  size: 13,
                                  color: AppColors.textSecondary),
                              const SizedBox(width: 4),
                              Text(
                                'Last updated: $_lastUpdated',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusMessage(int ahead) {
    Color color;
    String message;
    IconData icon;

    if (ahead <= 0) {
      color = AppColors.queueNext;
      message = "It's your turn! Please proceed 🎉";
      icon = Icons.celebration_rounded;
    } else if (ahead <= 4) {
      color = AppColors.queueSoon;
      message = 'Almost there... $ahead ${ahead == 1 ? "person" : "people"} ahead';
      icon = Icons.hourglass_bottom_rounded;
    } else {
      color = AppColors.queueWaiting;
      message = '$ahead people ahead of you';
      icon = Icons.people_outline_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              message,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _queueInfoRow(
      String label, String value, IconData icon, Color iconColor) {
    return Row(
      children: [
        Icon(icon, size: 18, color: iconColor),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
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
              child: const Icon(Icons.confirmation_number_outlined,
                  size: 40, color: AppColors.primary),
            ),
            const SizedBox(height: 20),
            const Text(
              'No Active Appointments',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Book an appointment to track your queue position in real-time.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, height: 1.5),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add_rounded),
              label: const Text('Book Now'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      final today = DateTime.now();
      if (dt.year == today.year &&
          dt.month == today.month &&
          dt.day == today.day) {
        return 'Today, ${DateFormat('dd MMM').format(dt)}';
      }
      return DateFormat('EEE, dd MMM yyyy').format(dt);
    } catch (_) {
      return dateStr;
    }
  }
}
