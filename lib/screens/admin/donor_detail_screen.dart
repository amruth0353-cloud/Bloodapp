import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/models.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../utils/constants.dart';

class DonorDetailScreen extends StatelessWidget {
  final UserModel donor;

  const DonorDetailScreen({super.key, required this.donor});

  Future<void> _makePhoneCall(String phoneNumber) async {
    final uri = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _sendEmail(String email) async {
    final uri = Uri.parse('mailto:$email?subject=BloodConnect%20Update');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTimeEligible =
        donor.lastDonationDate == null ||
        DateTime.now().isAfter(
          donor.lastDonationDate!.add(
            const Duration(days: AppConstants.donationCooldownDays),
          ),
        );

    return Scaffold(
      appBar: BloodConnectAppBar(
        title: 'Donor Details',
        actions: [
          IconButton(
            icon: const Icon(Icons.phone_outlined, color: Colors.white),
            tooltip: 'Call Donor',
            onPressed: donor.phone.isNotEmpty
                ? () => _makePhoneCall(donor.phone)
                : null,
          ),
          IconButton(
            icon: const Icon(Icons.email_outlined, color: Colors.white),
            tooltip: 'Email Donor',
            onPressed: donor.email.isNotEmpty
                ? () => _sendEmail(donor.email)
                : null,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    BloodTypeBadge(bloodType: donor.bloodType, size: 54),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            donor.name,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            donor.email,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: Colors.grey.shade600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${donor.gender.toUpperCase()} • ${donor.age} yrs old',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isTimeEligible
                            ? AppTheme.successGreen.withValues(alpha: 0.12)
                            : Colors.orange.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isTimeEligible ? 'Eligible' : 'On Cooldown',
                        style: TextStyle(
                          color: isTimeEligible
                              ? AppTheme.successGreen
                              : Colors.orange.shade800,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Contact Details Card
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Contact Information',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const Divider(),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.phone_outlined,
                        color: AppTheme.primaryRed,
                      ),
                      title: Text(
                        donor.phone.isNotEmpty ? donor.phone : 'Not provided',
                      ),
                      subtitle: const Text('Phone Number'),
                      trailing: donor.phone.isNotEmpty
                          ? IconButton(
                              icon: const Icon(
                                Icons.call,
                                color: AppTheme.successGreen,
                              ),
                              onPressed: () => _makePhoneCall(donor.phone),
                            )
                          : null,
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.email_outlined,
                        color: AppTheme.primaryRed,
                      ),
                      title: Text(donor.email),
                      subtitle: const Text('Email Address'),
                      trailing: IconButton(
                        icon: const Icon(Icons.send, color: AppTheme.infoBlue),
                        onPressed: () => _sendEmail(donor.email),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Eligibility status
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Donation Eligibility',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const Divider(),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          const SizedBox(
                            width: 140,
                            child: Text(
                              'Last Donation',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          Text(
                            donor.lastDonationDate != null
                                ? DateFormat.yMMMd().format(
                                    donor.lastDonationDate!,
                                  )
                                : 'None recorded',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          const SizedBox(
                            width: 140,
                            child: Text(
                              'Next Eligible Date',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          Text(
                            donor.lastDonationDate != null
                                ? DateFormat.yMMMd().format(
                                    donor.lastDonationDate!.add(
                                      const Duration(
                                        days: AppConstants.donationCooldownDays,
                                      ),
                                    ),
                                  )
                                : 'Eligible now',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: isTimeEligible
                                  ? AppTheme.successGreen
                                  : Colors.orange.shade800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          const SizedBox(
                            width: 140,
                            child: Text(
                              'Cooldown Rule',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          const Text(
                            '${AppConstants.donationCooldownDays} days between whole blood donations',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Donation History Stream
            Text(
              'Donation History',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            StreamBuilder<List<DonationHistoryModel>>(
              stream: FirestoreService().getDonorHistory(donor.uid),
              builder: (ctx, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(
                        color: AppTheme.primaryRed,
                      ),
                    ),
                  );
                }
                if (snap.hasError) {
                  return const Center(
                    child: Text(
                      'Could not load history',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }
                final records = snap.data ?? [];
                if (records.isEmpty) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(
                        child: Text(
                          'No donation records found for this donor.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),
                  );
                }
                return Column(
                  children: records
                      .map(
                        (r) => Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: r.status == 'donated'
                                  ? AppTheme.successGreen.withValues(
                                      alpha: 0.15,
                                    )
                                  : Colors.grey.shade200,
                              child: Icon(
                                r.status == 'donated'
                                    ? Icons.favorite
                                    : Icons.close,
                                color: r.status == 'donated'
                                    ? AppTheme.successGreen
                                    : Colors.grey,
                                size: 20,
                              ),
                            ),
                            title: Text(
                              DateFormat.yMMMd().format(r.donationDate),
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              '${r.location.isNotEmpty ? r.location : "Blood Bank"} • Health: ${r.healthStatus}',
                            ),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: r.status == 'donated'
                                    ? AppTheme.successGreen.withValues(
                                        alpha: 0.1,
                                      )
                                    : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                r.status == 'donated'
                                    ? 'Donated'
                                    : 'Not Donated',
                                style: TextStyle(
                                  color: r.status == 'donated'
                                      ? AppTheme.successGreen
                                      : Colors.grey,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                );
              },
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
