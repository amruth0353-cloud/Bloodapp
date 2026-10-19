import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../utils/constants.dart';
import 'donor_detail_screen.dart';

class DonorListScreen extends StatefulWidget {
  const DonorListScreen({super.key});

  @override
  State<DonorListScreen> createState() => _DonorListScreenState();
}

class _DonorListScreenState extends State<DonorListScreen> {
  final _searchCtrl = TextEditingController();
  String _selectedBloodType = 'All';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: BloodConnectAppBar(title: 'Registered Donors'),
      body: Column(
        children: [
          // Search & Filter header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            color: Colors.white,
            child: Column(
              children: [
                TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Search donor by name...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () =>
                                setState(() => _searchCtrl.clear()),
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['All', ...AppConstants.bloodTypes].map((bt) {
                      final isSelected = _selectedBloodType == bt;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: FilterChip(
                          label: Text(bt),
                          selected: isSelected,
                          onSelected: (_) =>
                              setState(() => _selectedBloodType = bt),
                          selectedColor: AppTheme.primaryRed.withValues(
                            alpha: 0.15,
                          ),
                          checkmarkColor: AppTheme.primaryRed,
                          labelStyle: TextStyle(
                            color: isSelected
                                ? AppTheme.primaryRed
                                : Colors.grey.shade700,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Donors List
          Expanded(
            child: StreamBuilder<List<UserModel>>(
              stream: FirestoreService().getAllDonors(),
              builder: (ctx, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryRed,
                    ),
                  );
                }
                if (snap.hasError) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.wifi_off_rounded,
                          color: Colors.grey,
                          size: 48,
                        ),
                        SizedBox(height: 8),
                        Text('Failed to load donors. Check connection.'),
                      ],
                    ),
                  );
                }

                var donors = snap.data ?? [];

                // Filter by blood type
                if (_selectedBloodType != 'All') {
                  donors = donors
                      .where((d) => d.bloodType == _selectedBloodType)
                      .toList();
                }

                // Filter by search query
                final query = _searchCtrl.text.trim().toLowerCase();
                if (query.isNotEmpty) {
                  donors = donors
                      .where(
                        (d) =>
                            d.name.toLowerCase().contains(query) ||
                            d.email.toLowerCase().contains(query) ||
                            d.phone.contains(query),
                      )
                      .toList();
                }

                if (donors.isEmpty) {
                  return const EmptyState(
                    icon: Icons.people_outline,
                    title: 'No Donors Found',
                    subtitle:
                        'Try adjusting your search query or blood type filter.',
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: donors.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (ctx, i) {
                    final d = donors[i];
                    final isTimeEligible =
                        d.lastDonationDate == null ||
                        DateTime.now().isAfter(
                          d.lastDonationDate!.add(
                            const Duration(
                              days: AppConstants.donationCooldownDays,
                            ),
                          ),
                        );

                    return Card(
                      child: ListTile(
                        leading: BloodTypeBadge(
                          bloodType: d.bloodType,
                          size: 42,
                        ),
                        title: Text(
                          d.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          '${d.phone.isNotEmpty ? d.phone : d.email} • ${d.age} yrs',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: isTimeEligible
                                    ? AppTheme.successGreen.withValues(
                                        alpha: 0.12,
                                      )
                                    : Colors.orange.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                isTimeEligible ? 'Eligible' : 'Cooldown',
                                style: TextStyle(
                                  color: isTimeEligible
                                      ? AppTheme.successGreen
                                      : Colors.orange.shade800,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.chevron_right, color: Colors.grey),
                          ],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DonorDetailScreen(donor: d),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
