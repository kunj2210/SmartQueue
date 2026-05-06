import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/appointment_model.dart';
import '../../providers/admin_provider.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_constants.dart';
import '../../widgets/appointment_card_widget.dart';

class AdminAppointmentsScreen extends StatefulWidget {
  const AdminAppointmentsScreen({super.key});

  @override
  State<AdminAppointmentsScreen> createState() =>
      _AdminAppointmentsScreenState();
}

class _AdminAppointmentsScreenState extends State<AdminAppointmentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _filterDate;
  String? _filterService;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<AppointmentModel> _filtered(List<AppointmentModel> all) {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final tabIndex = _tabController.index;

    List<AppointmentModel> result = all;

    // Tab filter
    switch (tabIndex) {
      case 0:
        result = result.where((a) => a.preferredDate == today).toList();
        break;
      case 1:
        break;
      case 2:
        result = result
            .where((a) => a.status == AppointmentStatus.scheduled)
            .toList();
        break;
      case 3:
        result = result
            .where((a) => a.status == AppointmentStatus.completed)
            .toList();
        break;
      case 4:
        result = result
            .where((a) => a.status == AppointmentStatus.cancelled)
            .toList();
        break;
    }

    // Additional filters
    if (_filterDate != null) {
      result =
          result.where((a) => a.preferredDate == _filterDate).toList();
    }
    if (_filterService != null) {
      result = result
          .where((a) => a.serviceType == _filterService)
          .toList();
    }

    return result;
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
                trailing:
                    const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                onTap: () async {
                  final date = await showDatePicker(
                    context: ctx,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate:
                        DateTime.now().add(const Duration(days: 90)),
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
                    .map((t) =>
                        DropdownMenuItem(value: t, child: Text(t)))
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
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Consumer<AdminProvider>(
        builder: (context, admin, _) {
          final filtered = _filtered(admin.allAppointments);

          return Column(
            children: [
              // Tab bar
              Container(
                color: Colors.white,
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  labelColor: AppColors.adminAccent,
                  unselectedLabelColor: AppColors.textSecondary,
                  indicatorColor: AppColors.adminAccent,
                  labelStyle: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 12),
                  tabs: const [
                    Tab(text: 'Today'),
                    Tab(text: 'All'),
                    Tab(text: 'Scheduled'),
                    Tab(text: 'Completed'),
                    Tab(text: 'Cancelled'),
                  ],
                ),
              ),

              // Filters
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2024),
                            lastDate:
                                DateTime.now().add(const Duration(days: 90)),
                          );
                          if (date != null) {
                            setState(() => _filterDate =
                                DateFormat('yyyy-MM-dd').format(date));
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: _filterDate != null
                                ? AppColors.adminAccent.withOpacity(0.1)
                                : AppColors.background,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _filterDate != null
                                  ? AppColors.adminAccent
                                  : AppColors.divider,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_month_rounded,
                                  size: 14, color: AppColors.adminAccent),
                              const SizedBox(width: 6),
                              Text(
                                _filterDate == null
                                    ? 'Filter by date'
                                    : DateFormat('dd MMM').format(
                                        DateTime.parse(_filterDate!)),
                                style: const TextStyle(fontSize: 11),
                              ),
                              if (_filterDate != null) ...[
                                const Spacer(),
                                GestureDetector(
                                  onTap: () =>
                                      setState(() => _filterDate = null),
                                  child: const Icon(Icons.close_rounded,
                                      size: 12),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _filterService,
                        decoration: InputDecoration(
                          hintText: 'Service',
                          hintStyle: const TextStyle(fontSize: 11),
                          filled: true,
                          fillColor: _filterService != null
                              ? AppColors.adminAccent.withOpacity(0.1)
                              : AppColors.background,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide:
                                const BorderSide(color: AppColors.divider),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide:
                                const BorderSide(color: AppColors.divider),
                          ),
                          isDense: true,
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('All Services',
                                style: TextStyle(fontSize: 11)),
                          ),
                          ...AppConstants.serviceTypes.map(
                            (s) => DropdownMenuItem(
                              value: s,
                              child:
                                  Text(s, style: const TextStyle(fontSize: 11)),
                            ),
                          ),
                        ],
                        onChanged: (v) =>
                            setState(() => _filterService = v),
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // List
              Expanded(
                child: admin.isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                            color: AppColors.adminAccent))
                    : filtered.isEmpty
                        ? const Center(
                            child: Text(
                              'No appointments found.',
                              style:
                                  TextStyle(color: AppColors.textSecondary),
                            ),
                          )
                        : ListView.builder(
                            padding:
                                const EdgeInsets.symmetric(vertical: 8),
                            itemCount: filtered.length,
                            itemBuilder: (_, i) {
                              final apt = filtered[i];
                              return AppointmentCardWidget(
                                appointment: apt,
                                isAdminView: true,
                                onComplete: apt.status !=
                                            AppointmentStatus.completed &&
                                        apt.status !=
                                            AppointmentStatus.cancelled
                                    ? () => admin.markAsCompleted(
                                          apt.appointmentId,
                                          apt.preferredDate,
                                          apt.serviceType,
                                        )
                                    : null,
                                onCancel: apt.status !=
                                        AppointmentStatus.cancelled
                                    ? () async {
                                        final confirm =
                                            await showDialog<bool>(
                                          context: context,
                                          builder: (ctx) => AlertDialog(
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        16)),
                                            title: const Text(
                                                'Cancel Appointment',
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.w700)),
                                            content: const Text(
                                                'Cancel this appointment?'),
                                            actions: [
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(
                                                        ctx, false),
                                                child: const Text('No'),
                                              ),
                                              ElevatedButton(
                                                onPressed: () =>
                                                    Navigator.pop(
                                                        ctx, true),
                                                style:
                                                    ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      AppColors.cancelled,
                                                  foregroundColor:
                                                      Colors.white,
                                                ),
                                                child:
                                                    const Text('Cancel'),
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
                                onReschedule: apt.status !=
                                            AppointmentStatus.completed &&
                                        apt.status !=
                                            AppointmentStatus.cancelled
                                    ? () => _showRescheduleSheet(
                                        context, apt, admin)
                                    : null,
                              );
                            },
                          ),
              ),
            ],
          );
        },
      ),
    );
  }
}
