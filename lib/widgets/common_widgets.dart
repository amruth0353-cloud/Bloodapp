import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../services/firestore_service.dart';

class BloodTypeBadge extends StatelessWidget {
  final String bloodType;
  final double size;
  const BloodTypeBadge({super.key, required this.bloodType, this.size = 48});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppTheme.primaryRed,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryRed.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          bloodType,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: size * 0.35,
          ),
        ),
      ),
    );
  }
}

class UrgencyBadge extends StatelessWidget {
  final String level;
  const UrgencyBadge({super.key, required this.level});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    IconData icon;
    switch (level) {
      case 'critical':
        color = AppTheme.criticalOrange;
        label = 'CRITICAL';
        icon = Icons.warning_rounded;
        break;
      case 'urgent':
        color = AppTheme.warningAmber;
        label = 'URGENT';
        icon = Icons.priority_high_rounded;
        break;
      default:
        color = AppTheme.infoBlue;
        label = 'STANDARD';
        icon = Icons.info_outline_rounded;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class BloodRequestCard extends StatelessWidget {
  final BloodRequestModel request;
  final VoidCallback? onAccept;
  final VoidCallback? onDecline;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool isAdmin;
  final bool hasResponded;

  const BloodRequestCard({
    super.key,
    required this.request,
    this.onAccept,
    this.onDecline,
    this.onEdit,
    this.onDelete,
    this.isAdmin = false,
    this.hasResponded = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(
        children: [
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: request.urgencyColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    BloodTypeBadge(bloodType: request.bloodType),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            request.hospitalName,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on_outlined,
                                size: 14,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                request.location,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    UrgencyBadge(level: request.urgencyLevel),
                    if (isAdmin) ...[
                      const SizedBox(width: 4),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 20),
                        onPressed: onEdit,
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(4),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          size: 20,
                          color: Colors.red,
                        ),
                        onPressed: onDelete,
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(4),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _InfoChip(
                      icon: Icons.water_drop_outlined,
                      label: '${request.unitsNeeded} units needed',
                    ),
                    const SizedBox(width: 8),
                    _InfoChip(
                      icon: Icons.people_outline,
                      label: '${request.respondedDonors.length} responded',
                    ),
                    if (request.requiredBy != null) ...[
                      const SizedBox(width: 8),
                      _InfoChip(
                        icon: Icons.calendar_today_outlined,
                        label:
                            'By ${DateFormat('MMMd').add_jm().format(request.requiredBy!)}',
                      ),
                    ],
                  ],
                ),
                if (request.notes.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    request.notes,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
                if (!isAdmin && request.status == 'open') ...[
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  if (hasResponded)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.successGreen.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.check_circle_outline,
                            color: AppTheme.successGreen,
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'You have responded',
                            style: GoogleFonts.poppins(
                              color: AppTheme.successGreen,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: onDecline,
                            icon: const Icon(Icons.close, size: 18),
                            label: const Text('Decline'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.grey.shade600,
                              side: BorderSide(color: Colors.grey.shade300),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (request.respondedDonors.length >=
                            request.unitsNeeded)
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: null,
                              icon: const Icon(Icons.done_all, size: 18),
                              label: const Text('Request Filled'),
                              style: ElevatedButton.styleFrom(
                                disabledBackgroundColor: Colors.grey.shade300,
                                disabledForegroundColor: Colors.grey.shade600,
                              ),
                            ),
                          )
                        else
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: onAccept,
                              icon: const Icon(
                                Icons.favorite_outline,
                                size: 18,
                              ),
                              label: const Text('I Can Donate'),
                            ),
                          ),
                      ],
                    ),
                ],
                if (isAdmin && request.respondedDonors.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      onPressed: () => _showDonorsSheet(context, request),
                      icon: const Icon(Icons.people_alt_outlined, size: 18),
                      label: Text(
                        'View ${request.respondedDonors.length} Responded Donor(s)',
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0);
  }
}

void _showDonorsSheet(BuildContext context, BloodRequestModel request) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => _DonorsSheet(request: request),
  );
}

class _DonorsSheet extends StatefulWidget {
  final BloodRequestModel request;
  const _DonorsSheet({required this.request});

  @override
  State<_DonorsSheet> createState() => _DonorsSheetState();
}

class _DonorsSheetState extends State<_DonorsSheet> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final donorIds = widget.request.respondedDonors;
    return Container(
      padding: const EdgeInsets.all(24),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Responded Donors',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: donorIds.length,
              itemBuilder: (ctx, i) {
                return FutureBuilder(
                  future: FirestoreService().getUserById(donorIds[i]),
                  builder: (ctx, snap) {
                    if (snap.connectionState == ConnectionState.waiting)
                      return const ListTile(
                        leading: CircularProgressIndicator(),
                        title: Text('Loading...'),
                      );
                    final user = snap.data;
                    if (user == null)
                      return const ListTile(
                        leading: Icon(Icons.person_off),
                        title: Text('Unknown Donor'),
                      );
                    final isCompleted = widget.request.completedDonors.contains(
                      user.uid,
                    );
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: BloodTypeBadge(
                        bloodType: user.bloodType,
                        size: 40,
                      ),
                      title: Text(
                        user.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text('${user.phone}\n${user.email}'),
                      isThreeLine: true,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.call,
                              color: AppTheme.successGreen,
                            ),
                            onPressed: () {},
                          ),
                          if (isCompleted)
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8.0),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    color: AppTheme.successGreen,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Completed',
                                    style: TextStyle(
                                      color: AppTheme.successGreen,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryRed,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: _isLoading
                                  ? null
                                  : () async {
                                      setState(() => _isLoading = true);
                                      try {
                                        await FirestoreService()
                                            .markDonationCompleted(
                                              widget.request.id,
                                              user.uid,
                                            );
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Donation marked as completed!',
                                              ),
                                            ),
                                          );
                                          Navigator.pop(context);
                                        }
                                      } catch (e) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text('Error: $e'),
                                            ),
                                          );
                                        }
                                      } finally {
                                        if (mounted)
                                          setState(() => _isLoading = false);
                                      }
                                    },
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text('Complete'),
                            ),
                        ],
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

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade600),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }
}

class StatsCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String? subtitle;
  final VoidCallback? onTap;

  const StatsCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: color, size: 22),
                  ),
                  const Spacer(),
                  Text(
                    value,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  if (onTap != null)
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 12,
                      color: Colors.grey.shade400,
                    ),
                ],
              ),
              if (subtitle != null)
                Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.95, 0.95));
  }
}

class EligibilityCard extends StatelessWidget {
  final UserModel user;
  const EligibilityCard({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: FirestoreService().hasActiveRequest(user.uid),
      builder: (context, snapshot) {
        final hasActive = snapshot.data ?? false;
        final isEligible = user.isTimeEligible && !hasActive;

        Color cardColor;
        IconData cardIcon;
        String statusText;
        String subText;

        if (hasActive) {
          cardColor = AppTheme.warningAmber;
          cardIcon = Icons.medical_services_outlined;
          statusText = 'Currently Responding';
          subText = 'You have already accepted an active blood request.';
        } else if (isEligible) {
          cardColor = AppTheme.successGreen;
          cardIcon = Icons.check_circle_outline;
          statusText = 'Eligible to Donate!';
          subText = 'You can donate blood today. Thank you for saving lives!';
        } else {
          cardColor = AppTheme.warningAmber;
          cardIcon = Icons.schedule_outlined;
          statusText = 'Not Yet Eligible';
          final nextDate = user.nextEligibleDate;
          subText = nextDate != null
              ? 'Next eligible: ${_formatDate(nextDate)}'
              : 'Please check with the blood bank.';
        }

        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [cardColor.withValues(alpha: 0.85), cardColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: cardColor.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(cardIcon, color: Colors.white, size: 48),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      statusText,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subText,
                      style: GoogleFonts.poppins(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ).animate().fadeIn().slideX(begin: -0.1);
      },
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

class InventoryBar extends StatelessWidget {
  final String bloodType;
  final int units;
  final int maxUnits;
  const InventoryBar({
    super.key,
    required this.bloodType,
    required this.units,
    required this.maxUnits,
  });

  @override
  Widget build(BuildContext context) {
    final fraction = maxUnits > 0 ? (units / maxUnits).clamp(0.0, 1.0) : 0.0;
    Color barColor = fraction > 0.5
        ? AppTheme.successGreen
        : fraction > 0.2
        ? AppTheme.warningAmber
        : AppTheme.primaryRed;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          BloodTypeBadge(bloodType: bloodType, size: 36),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$units units',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${(fraction * 100).toInt()}% full',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: fraction,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation(barColor),
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class BloodConnectAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showBack;

  const BloodConnectAppBar({
    super.key,
    required this.title,
    this.actions,
    this.showBack = true,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppTheme.primaryRed,
      elevation: 0,
      leading: showBack
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            )
          : null,
      automaticallyImplyLeading: false,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.water_drop, color: Colors.white70, size: 20),
          const SizedBox(width: 6),
          Text(
            title,
            style: GoogleFonts.playfairDisplay(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      centerTitle: true,
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  const LoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: Colors.black38,
            child: const Center(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: AppTheme.primaryRed),
                      SizedBox(height: 12),
                      Text('Please wait...'),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? action;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade500),
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[const SizedBox(height: 20), action!],
          ],
        ),
      ),
    );
  }
}
