import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/appointment_model.dart';
import '../utils/app_colors.dart';
import 'status_badge_widget.dart';

class AppointmentCardWidget extends StatelessWidget {
  final AppointmentModel appointment;
  final bool isAdminView;
  final VoidCallback? onCancel;
  final VoidCallback? onComplete;
  final VoidCallback? onReschedule;
  final VoidCallback? onTap;

  const AppointmentCardWidget({
    super.key,
    required this.appointment,
    this.isAdminView = false,
    this.onCancel,
    this.onComplete,
    this.onReschedule,
    this.onTap,
  });

  Color get _statusColor {
    switch (appointment.status) {
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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Status color bar
              Container(
                width: 5,
                decoration: BoxDecoration(
                  color: _statusColor,
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(16),
                  ),
                ),
              ),
              // Card content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              appointment.serviceType,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          StatusBadgeWidget(
                              status: appointment.status, compact: true),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        appointment.appointmentId,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                          fontFamily: 'monospace',
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (isAdminView) ...[
                        _infoRow(Icons.person_outline_rounded,
                            appointment.userName),
                        const SizedBox(height: 3),
                        _infoRow(
                            Icons.email_outlined, appointment.userEmail),
                        const SizedBox(height: 3),
                      ],
                      Row(
                        children: [
                          Expanded(
                            child: _infoRow(
                              Icons.calendar_today_outlined,
                              _formatDate(appointment.preferredDate),
                            ),
                          ),
                          _infoRow(Icons.access_time_rounded,
                              appointment.timeSlot),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          _infoRow(Icons.tag_rounded,
                              'Queue #${appointment.queuePosition}'),
                          const Spacer(),
                          // Sync indicator
                          Icon(
                            appointment.isSynced
                                ? Icons.cloud_done_rounded
                                : Icons.cloud_upload_outlined,
                            size: 14,
                            color: appointment.isSynced
                                ? AppColors.completed
                                : AppColors.textSecondary,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            appointment.isSynced ? 'Synced' : 'Pending sync',
                            style: TextStyle(
                              fontSize: 10,
                              color: appointment.isSynced
                                  ? AppColors.completed
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      if (isAdminView &&
                          appointment.status != AppointmentStatus.completed &&
                          appointment.status != AppointmentStatus.cancelled) ...[
                        const Divider(height: 16),
                        Row(
                          children: [
                            if (onComplete != null)
                              Expanded(
                                child: _actionButton(
                                  '✓ Complete',
                                  AppColors.completed,
                                  onComplete!,
                                ),
                              ),
                            if (onComplete != null) const SizedBox(width: 6),
                            if (onReschedule != null)
                              Expanded(
                                child: _actionButton(
                                  '📅 Reschedule',
                                  AppColors.scheduled,
                                  onReschedule!,
                                ),
                              ),
                            if (onReschedule != null) const SizedBox(width: 6),
                            if (onCancel != null)
                              Expanded(
                                child: _actionButton(
                                  '✗ Cancel',
                                  AppColors.cancelled,
                                  onCancel!,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _actionButton(String label, Color color, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      return DateFormat('dd MMM yyyy').format(dt);
    } catch (_) {
      return dateStr;
    }
  }
}
