import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../models/appointment_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/appointment_provider.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/app_constants.dart';
import '../../../widgets/appointment_card_widget.dart';

class SearchFilterScreen extends StatefulWidget {
  const SearchFilterScreen({super.key});

  @override
  State<SearchFilterScreen> createState() => _SearchFilterScreenState();
}

class _SearchFilterScreenState extends State<SearchFilterScreen> {
  final _searchCtrl = TextEditingController();
  Timer? _debounce;
  String _query = '';
  final Set<AppointmentStatus> _statusFilters = {};
  final Set<String> _serviceFilters = {};
  DateTime? _filterDate;
  bool _showFilters = false;

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

  List<AppointmentModel> _filterResults(List<AppointmentModel> all) {
    return all.where((a) {
      if (_query.isNotEmpty) {
        final q = _query.toLowerCase();
        if (!a.userName.toLowerCase().contains(q) &&
            !a.appointmentId.toLowerCase().contains(q)) {
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
      if (_serviceFilters.isNotEmpty &&
          !_serviceFilters.contains(a.serviceType)) {
        return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthProvider>().currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Consumer<AppointmentProvider>(
        builder: (context, aptProv, _) {
          final userApts = aptProv.appointments
              .where((a) => a.userId == user?.uid)
              .toList();
          final results = (_query.isNotEmpty ||
                  _filterDate != null ||
                  _statusFilters.isNotEmpty ||
                  _serviceFilters.isNotEmpty)
              ? _filterResults(userApts)
              : [];

          return Column(
            children: [
              // Search Bar
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Column(
                  children: [
                    TextField(
                      controller: _searchCtrl,
                      onChanged: _onSearchChanged,
                      decoration: InputDecoration(
                        hintText:
                            'Search by name or appointment ID...',
                        hintStyle: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 14),
                        prefixIcon: const Icon(Icons.search_rounded,
                            color: AppColors.primary),
                        suffixIcon: _searchCtrl.text.isNotEmpty
                            ? IconButton(
                                onPressed: () {
                                  _searchCtrl.clear();
                                  setState(() => _query = '');
                                },
                                icon: const Icon(Icons.close_rounded,
                                    color: AppColors.textSecondary),
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
                    const SizedBox(height: 8),
                    // Filters toggle
                    GestureDetector(
                      onTap: () =>
                          setState(() => _showFilters = !_showFilters),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: _showFilters
                              ? AppColors.primary
                              : AppColors.background,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _showFilters
                                ? AppColors.primary
                                : AppColors.divider,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.filter_list_rounded,
                                size: 16,
                                color: _showFilters
                                    ? Colors.white
                                    : AppColors.textSecondary),
                            const SizedBox(width: 6),
                            Text(
                              'Filters${_statusFilters.isNotEmpty || _serviceFilters.isNotEmpty || _filterDate != null ? " •" : ""}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _showFilters
                                    ? Colors.white
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Filters panel
              if (_showFilters) _buildFiltersPanel(),

              const Divider(height: 1),

              // Results
              Expanded(
                child: results.isEmpty
                    ? _buildEmptyOrPrompt(_query.isNotEmpty ||
                        _filterDate != null ||
                        _statusFilters.isNotEmpty ||
                        _serviceFilters.isNotEmpty)
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: results.length,
                        itemBuilder: (_, i) => AppointmentCardWidget(
                          appointment: results[i] as AppointmentModel,
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFiltersPanel() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date filter
          Row(
            children: [
              const Text(
                'Date:',
                style: TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 13),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _filterDate ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (date != null) setState(() => _filterDate = date);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _filterDate != null
                        ? AppColors.primary.withOpacity(0.1)
                        : AppColors.background,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _filterDate != null
                          ? AppColors.primary
                          : AppColors.divider,
                    ),
                  ),
                  child: Text(
                    _filterDate == null
                        ? 'Select date'
                        : DateFormat('dd MMM yyyy').format(_filterDate!),
                    style: TextStyle(
                      fontSize: 12,
                      color: _filterDate != null
                          ? AppColors.primary
                          : AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              if (_filterDate != null) ...[
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () => setState(() => _filterDate = null),
                  child: const Icon(Icons.close_rounded,
                      size: 16, color: AppColors.textSecondary),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          // Status filters
          const Text('Status:',
              style: TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: AppointmentStatus.values.map((status) {
              final selected = _statusFilters.contains(status);
              return FilterChip(
                label: Text(status.name),
                selected: selected,
                onSelected: (v) {
                  setState(() {
                    if (v) {
                      _statusFilters.add(status);
                    } else {
                      _statusFilters.remove(status);
                    }
                  });
                },
                selectedColor: AppColors.primary.withOpacity(0.15),
                checkmarkColor: AppColors.primary,
                labelStyle: TextStyle(
                  fontSize: 11,
                  color:
                      selected ? AppColors.primary : AppColors.textSecondary,
                  fontWeight:
                      selected ? FontWeight.w600 : FontWeight.normal,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),
          // Clear all
          if (_statusFilters.isNotEmpty ||
              _serviceFilters.isNotEmpty ||
              _filterDate != null)
            TextButton(
              onPressed: () => setState(() {
                _statusFilters.clear();
                _serviceFilters.clear();
                _filterDate = null;
              }),
              child: const Text('Clear All Filters',
                  style: TextStyle(color: AppColors.cancelled)),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyOrPrompt(bool hasFilters) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                hasFilters
                    ? Icons.search_off_rounded
                    : Icons.search_rounded,
                size: 36,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              hasFilters ? 'No Results Found' : 'Search Appointments',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              hasFilters
                  ? 'Try different search terms or adjust your filters.'
                  : 'Type a name or appointment ID to search.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: AppColors.textSecondary, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
