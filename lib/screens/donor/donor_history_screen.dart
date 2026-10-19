import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart';
import '../../services/app_provider.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../utils/constants.dart';

class DonorHistoryScreen extends StatelessWidget {
  const DonorHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppProvider>().currentUser;
    if (user == null) return const SizedBox();

    return Scaffold(
      appBar: BloodConnectAppBar(title: 'Donation History', showBack: false),
      body: SingleChildScrollView(
        child: Column(
          children: [
            EligibilityCard(user: user),
            StreamBuilder<List<DonationHistoryModel>>(
              stream: FirestoreService().getDonorHistory(user.uid),
              builder: (ctx, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(
                        color: AppTheme.primaryRed,
                      ),
                    ),
                  );
                }
                if (snap.hasError) {
                  return Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Column(
                        children: [
                          const Icon(
                            Icons.wifi_off_rounded,
                            color: Colors.grey,
                            size: 48,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Could not load history. Check your connection.',
                            style: Theme.of(ctx).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final history = snap.data ?? [];
                if (history.isEmpty) {
                  return const EmptyState(
                    icon: Icons.history_edu_outlined,
                    title: 'No Donation History',
                    subtitle:
                        'Your donation records will appear here after your first donation.',
                  );
                }

                final completedCount = history
                    .where((h) => h.status == 'donated')
                    .length;

                // Group by Year and Month
                final grouped = <String, List<DonationHistoryModel>>{};
                for (final h in history) {
                  final groupKey = DateFormat(
                    'MMMM yyyy',
                  ).format(h.donationDate);
                  grouped.putIfAbsent(groupKey, () => []).add(h);
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Summary stats row
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: StatsCard(
                              title: 'Completed',
                              value: '$completedCount',
                              icon: Icons.favorite,
                              color: AppTheme.primaryRed,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: StatsCard(
                              title: 'Lives Saved',
                              value:
                                  '${completedCount * AppConstants.livesSavedMultiplier}',
                              icon: Icons.people,
                              color: AppTheme.successGreen,
                              subtitle: 'estimated',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Donation Timeline',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Grouped history entries
                    ...grouped.entries.map((entry) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.calendar_today,
                                  size: 14,
                                  color: AppTheme.primaryRed,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  entry.key,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: AppTheme.primaryRed,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Divider(color: Colors.grey.shade300),
                                ),
                              ],
                            ),
                          ),
                          ...entry.value.map((h) {
                            final isDonated = h.status == 'donated';
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: isDonated
                                      ? AppTheme.successGreen.withValues(
                                          alpha: 0.15,
                                        )
                                      : Colors.grey.shade100,
                                  child: Icon(
                                    isDonated
                                        ? Icons.favorite
                                        : Icons.cancel_outlined,
                                    color: isDonated
                                        ? AppTheme.successGreen
                                        : Colors.grey,
                                    size: 22,
                                  ),
                                ),
                                title: Text(
                                  DateFormat(
                                    'EEEE, dd MMM yyyy',
                                  ).format(h.donationDate),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.location_on_outlined,
                                          size: 14,
                                          color: Colors.grey,
                                        ),
                                        const SizedBox(width: 2),
                                        Expanded(
                                          child: Text(
                                            h.location.isNotEmpty
                                                ? h.location
                                                : 'Blood Bank Center',
                                            style: const TextStyle(
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Health Status: ${h.healthStatus}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDonated
                                        ? AppTheme.successGreen.withValues(
                                            alpha: 0.1,
                                          )
                                        : Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    isDonated ? 'Donated' : 'Deferred',
                                    style: TextStyle(
                                      color: isDonated
                                          ? AppTheme.successGreen
                                          : Colors.grey,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                isThreeLine: true,
                              ),
                            );
                          }),
                        ],
                      );
                    }),
                    const SizedBox(height: 80),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
