/// Centralized constants for BloodConnect app.
/// All magic numbers and shared string keys live here.
class AppConstants {
  AppConstants._();

  // ── Donation eligibility ─────────────────────────────────────────────────
  /// Minimum days between whole-blood donations (WHO / Red Cross standard).
  static const int donationCooldownDays = 56;

  /// Days until donated whole-blood unit expires in the inventory.
  static const int bloodUnitExpiryDays = 42;

  /// Units of blood (approx.) that can be helped per donation
  static const int livesSavedMultiplier = 3;

  // ── Firestore collection names ───────────────────────────────────────────
  static const String colUsers = 'users';
  static const String colBloodRequests = 'blood_requests';
  static const String colAppointments = 'appointments';
  static const String colBloodInventory = 'blood_inventory';
  static const String colDonationHistory = 'donation_history';
  static const String colEligibility = 'eligibility';
  static const String colNotifications = 'notifications';

  // ── Blood types ──────────────────────────────────────────────────────────
  static const List<String> bloodTypes = [
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'AB-',
    'O+',
    'O-',
  ];

  // ── Request statuses ─────────────────────────────────────────────────────
  static const String statusOpen = 'open';
  static const String statusFulfilled = 'fulfilled';
  static const String statusCancelled = 'cancelled';
  static const String statusFull = 'full';

  // ── Urgency levels ───────────────────────────────────────────────────────
  static const String urgencyStandard = 'standard';
  static const String urgencyUrgent = 'urgent';
  static const String urgencyCritical = 'critical';

  // ── Pagination ───────────────────────────────────────────────────────────
  static const int notificationsLimit = 50;
  static const int historyLimit = 200;
}
