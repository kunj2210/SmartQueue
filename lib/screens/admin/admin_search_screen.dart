import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/appointment_model.dart';
import '../../providers/admin_provider.dart';
import '../../utils/app_colors.dart';
import '../../widgets/appointment_card_widget.dart';

class AdminSearchScreen extends StatefulWidget {
  const AdminSearchScreen({super.key});

  @override
  State<AdminSearchScreen> createState() => _AdminSearchScreenState();
}

class _AdminSearchScreenState extends State<AdminSearchScreen> {
  final _searchCtrl = TextEditingController();
  Timer? _debounce;
  String _query = '';
  final Set<AppointmentStatus> _statusFilters = {};
  DateTime? _filterDate;

  @override
  void dispose() {
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() => _query = value.trim());
    });
  }

  List<AppointmentModel> _filter(List<AppointmentModel> all) {
    return all.where((a) {
      if (_query.isNotEmpty) {
        final q = _query.toLowerCase();
        if (!a.userName.toLowerCase().contains(q) &&
            !a.appointmentId.toLowerCase().contains(q) &&
            !a.userEmail.toLowerCase().contains(q)) {
          return false;
        }
      }
      if (_filterDate != null &&
          a.preferredDate !=
              DateFormat('yyyy-MM-dd').format(_filterDate!)) {
        return false;
      }
      if (_statusFilters.isNotEmpty && !_statusFilters.contains(a.status)) {
        return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Consumer<AdminProvider>(
        builder: (context, admin, _) {
          final hasSearch = _query.isNotEmpty ||
              _filterDate != null ||
              _statusFilters.isNotEmpty;
          final results = hasSearch ? _filter(admin.allAppointments) : <AppointmentModel>[];

          return Column(
            children: [
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Column(
                  children: [
                    TextField(
                      controller: _searchCtrl,
                      onChanged: _onSearchChanged,
                      decoration: InputDecoration(
                        hintText:
                            'Search by name, email, or appointment ID...',
                        hintStyle: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 13),
                        prefixIcon: const Icon(Icons.search_rounded,
                            color: AppColors.adminAccent),
                        suffixIcon: _searchCtrl.text.isNotEmpty
                            ? IconButton(
                                onPressed: () {
                                  _searchCtrl.clear();
                                  setState(() => _query = '');
                                },
                                icon: const Icon(Icons.close_rounded),
                              )
                            : null,
                        filled: true,
                        fillColor: AppColors.background,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: _filterDate ?? DateTime.now(),
                              firstDate: DateTime(2024),
                              lastDate:
                                  DateTime.now().add(const Duration(days: 90)),
                            );
                            if (date != null) {
                              setState(() => _filterDate = date);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 7),
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
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.calendar_today_rounded,
                                    size: 12,
                                    color: AppColors.adminAccent),
                                const SizedBox(width: 5),
                                Text(
                                  _filterDate == null
                                      ? 'Date'
                                      : DateFormat('dd MMM')
                                          .format(_filterDate!),
                                  style: const TextStyle(fontSize: 11),
                                ),
                                if (_filterDate != null) ...[
                                  const SizedBox(width: 4),
                                  GestureDetector(
                                    onTap: () =>
                                        setState(() => _filterDate = null),
                                    child: const Icon(Icons.close_rounded,
                                        size: 10),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ...AppointmentStatus.values.map(
                          (status) {
                            final selected = _statusFilters.contains(status);
                            return Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: GestureDetector(
                                onTap: () => setState(() {
                                  if (selected) {
                                    _statusFilters.remove(status);
                                  } else {
                                    _statusFilters.add(status);
                                  }
                                }),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: selected
                                        ? AppColors.adminAccent
                                            .withOpacity(0.15)
                                        : AppColors.background,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: selected
                                          ? AppColors.adminAccent
                                          : AppColors.divider,
                                    ),
                                  ),
                                  child: Text(
                                    status.name,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: selected
                                          ? FontWeight.w700
                                          : FontWeight.normal,
                                      color: selected
                                          ? AppColors.adminAccent
                                          : AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              if (hasSearch)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                  child: Row(
                    children: [
                      Text(
                        '${results.length} result${results.length == 1 ? "" : "s"} found',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      if (_statusFilters.isNotEmpty || _filterDate != null)
                        TextButton(
                          onPressed: () => setState(() {
                            _statusFilters.clear();
                            _filterDate = null;
                          }),
                          child: const Text('Clear filters',
                              style: TextStyle(
                                  color: AppColors.cancelled, fontSize: 12)),
                        ),
                    ],
                  ),
                ),

              const Divider(height: 1),

              Expanded(
                child: results.isEmpty && !hasSearch
                    ? _buildPrompt()
                    : results.isEmpty
                        ? _buildNoResults()
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            itemCount: results.length,
                            itemBuilder: (_, i) => AppointmentCardWidget(
                              appointment: results[i],
                              isAdminView: false,
                            ),
                          ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPrompt() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.adminAccent.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.manage_search_rounded,
                  size: 36, color: AppColors.adminAccent),
            ),
            const SizedBox(height: 16),
            const Text(
              'Search All Appointments',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Search across all users by name, email, or appointment ID.',
              textAlign: TextAlign.center,
              style:
                  TextStyle(color: AppColors.textSecondary, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off_rounded,
              size: 48, color: AppColors.textSecondary),
          const SizedBox(height: 12),
          const Text(
            'No results found',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Try a different search term or adjust filters',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
