import 'package:flutter/material.dart';
import '../models/appointment_model.dart';
import '../utils/app_colors.dart';

class StatusBadgeWidget extends StatelessWidget {
  final AppointmentStatus status;
  final bool compact;

  const StatusBadgeWidget({
    super.key,
    required this.status,
    this.compact = false,
  });

  Color get _bgColor {
    switch (status) {
      case AppointmentStatus.scheduled:
        return AppColors.scheduled.withOpacity(0.15);
      case AppointmentStatus.inProgress:
        return AppColors.inProgress.withOpacity(0.15);
      case AppointmentStatus.completed:
        return AppColors.completed.withOpacity(0.15);
      case AppointmentStatus.cancelled:
        return AppColors.cancelled.withOpacity(0.15);
    }
  }

  Color get _textColor {
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

  String get _label {
    switch (status) {
      case AppointmentStatus.scheduled:
        return 'Scheduled';
      case AppointmentStatus.inProgress:
        return 'In Progress';
      case AppointmentStatus.completed:
        return 'Completed';
      case AppointmentStatus.cancelled:
        return 'Cancelled';
    }
  }

  IconData get _icon {
    switch (status) {
      case AppointmentStatus.scheduled:
        return Icons.schedule_rounded;
      case AppointmentStatus.inProgress:
        return Icons.play_circle_outline_rounded;
      case AppointmentStatus.completed:
        return Icons.check_circle_outline_rounded;
      case AppointmentStatus.cancelled:
        return Icons.cancel_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: _bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _textColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, size: compact ? 10 : 12, color: _textColor),
          SizedBox(width: compact ? 3 : 4),
          Text(
            _label,
            style: TextStyle(
              color: _textColor,
              fontSize: compact ? 10 : 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
