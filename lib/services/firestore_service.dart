import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<String> createBloodRequest(BloodRequestModel request) async {
    final doc = await _db.collection('blood_requests').add(request.toMap());
    return doc.id;
  }

  Stream<List<BloodRequestModel>> getOpenBloodRequests() {
    return _db.collection('blood_requests')
        .where('status', isEqualTo: 'open')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(BloodRequestModel.fromFirestore).toList());
  }

  Stream<List<BloodRequestModel>> getAllBloodRequests() {
    return _db.collection('blood_requests')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(BloodRequestModel.fromFirestore).toList());
  }

  Stream<List<BloodRequestModel>> getRequestsForBloodType(String bloodType) {
    final compatible = _getCompatibleBloodTypes(bloodType);
    return _db.collection('blood_requests')
        .where('status', isEqualTo: 'open')
        .where('bloodType', whereIn: compatible)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(BloodRequestModel.fromFirestore).toList());
  }

  Future<void> respondToRequest(String requestId, String donorId, bool accept) async {
    if (accept) {
      await _db.collection('blood_requests').doc(requestId).update({
        'respondedDonors': FieldValue.arrayUnion([donorId]),
      });
    }
  }

  Future<void> updateRequestStatus(String requestId, String status) async {
    await _db.collection('blood_requests').doc(requestId).update({'status': status});
  }

  List<String> _getCompatibleBloodTypes(String donorType) {
    const compatibility = {
      'A+': ['A+', 'AB+'], 'A-': ['A+', 'A-', 'AB+', 'AB-'],
      'B+': ['B+', 'AB+'], 'B-': ['B+', 'B-', 'AB+', 'AB-'],
      'AB+': ['AB+'], 'AB-': ['AB+', 'AB-'],
      'O+': ['A+', 'B+', 'AB+', 'O+'],
      'O-': ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'],
    };
    return compatibility[donorType] ?? [donorType];
  }

  Future<String> createAppointment(AppointmentModel apt) async {
    final doc = await _db.collection('appointments').add(apt.toMap());
    return doc.id;
  }

  Stream<List<AppointmentModel>> getUpcomingAppointments() {
    return _db.collection('appointments')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime.now()))
        .where('status', whereIn: ['open', 'full'])
        .orderBy('date')
        .snapshots()
        .map((snap) => snap.docs.map(AppointmentModel.fromFirestore).toList());
  }

  Stream<List<AppointmentModel>> getAllAppointments() {
    return _db.collection('appointments')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(AppointmentModel.fromFirestore).toList());
  }

  Future<List<AppointmentModel>> getDonorAppointments(String donorId) async {
    final snap = await _db.collection('appointments')
        .where('bookedDonors', arrayContains: donorId)
        .orderBy('date', descending: true)
        .get();
    return snap.docs.map(AppointmentModel.fromFirestore).toList();
  }

  Future<void> bookAppointment(String appointmentId, String donorId) async {
    final ref = _db.collection('appointments').doc(appointmentId);
    await _db.runTransaction((txn) async {
      final doc = await txn.get(ref);
      final apt = AppointmentModel.fromFirestore(doc);
      if (apt.isFull) throw Exception('Appointment is fully booked.');
      if (apt.bookedDonors.contains(donorId)) throw Exception('Already booked.');
      txn.update(ref, {
        'bookedDonors': FieldValue.arrayUnion([donorId]),
        'status': apt.availableSlots <= 1 ? 'full' : 'open',
      });
    });
  }

  Future<void> cancelBooking(String appointmentId, String donorId) async {
    await _db.collection('appointments').doc(appointmentId).update({
      'bookedDonors': FieldValue.arrayRemove([donorId]),
      'status': 'open',
    });
  }

  Future<void> markDonorAttendance(String appointmentId, String donorId, bool donated) async {
    await recordDonation(DonationHistoryModel(
      id: '', donorId: donorId, donorName: '', bloodType: '',
      donationDate: DateTime.now(), location: '',
      healthStatus: 'healthy',
      status: donated ? 'donated' : 'not_donated',
      appointmentId: appointmentId,
    ));
  }

  Future<void> deleteAppointment(String appointmentId) async {
    await _db.collection('appointments').doc(appointmentId).delete();
  }

  Stream<List<BloodInventoryModel>> getInventory() {
    return _db.collection('blood_inventory')
        .orderBy('collectedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(BloodInventoryModel.fromFirestore).toList());
  }

  Future<Map<String, int>> getInventorySummary() async {
    final snap = await _db.collection('blood_inventory')
        .where('status', isEqualTo: 'available').get();
    final summary = <String, int>{};
    for (final doc in snap.docs) {
      final item = BloodInventoryModel.fromFirestore(doc);
      summary[item.bloodType] = (summary[item.bloodType] ?? 0) + item.units;
    }
    return summary;
  }

  Future<void> addInventory(BloodInventoryModel item) async {
    await _db.collection('blood_inventory').add(item.toMap());
  }

  Future<void> removeInventory(String id) async {
    await _db.collection('blood_inventory').doc(id).delete();
  }

  Future<void> recordDonation(DonationHistoryModel history) async {
    await _db.collection('donation_history').add(history.toMap());
    if (history.status == 'donated') {
      final nextEligible = DateTime.now().add(const Duration(days: 56));
      await _db.collection('eligibility').doc(history.donorId).set({
        'donorId': history.donorId,
        'lastDonationDate': Timestamp.fromDate(history.donationDate),
        'nextEligibleDate': Timestamp.fromDate(nextEligible),
        'lastHealthStatus': history.healthStatus,
        'isPermanentlyIneligible': false,
      }, SetOptions(merge: true));
    }
  }

  Stream<List<DonationHistoryModel>> getDonorHistory(String donorId) {
    return _db.collection('donation_history')
        .where('donorId', isEqualTo: donorId)
        .orderBy('donationDate', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(DonationHistoryModel.fromFirestore).toList());
  }

  Stream<List<DonationHistoryModel>> getAllHistory() {
    return _db.collection('donation_history')
        .orderBy('donationDate', descending: true)
        .limit(200)
        .snapshots()
        .map((snap) => snap.docs.map(DonationHistoryModel.fromFirestore).toList());
  }

  Future<EligibilityModel?> getDonorEligibility(String donorId) async {
    final doc = await _db.collection('eligibility').doc(donorId).get();
    if (!doc.exists) return null;
    return EligibilityModel.fromFirestore(doc);
  }

  Stream<EligibilityModel?> watchDonorEligibility(String donorId) {
    return _db.collection('eligibility').doc(donorId).snapshots()
        .map((doc) => doc.exists ? EligibilityModel.fromFirestore(doc) : null);
  }

  Future<void> updateEligibility(String donorId, Map<String, dynamic> data) async {
    await _db.collection('eligibility').doc(donorId).set(data, SetOptions(merge: true));
  }

  Stream<List<UserModel>> getAllDonors() {
    return _db.collection('users')
        .where('role', isEqualTo: 'donor')
        .orderBy('name')
        .snapshots()
        .map((snap) => snap.docs.map(UserModel.fromFirestore).toList());
  }

  Future<UserModel?> getUserById(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  Future<void> saveNotification(String userId, AppNotification notification) async {
    await _db.collection('users').doc(userId)
        .collection('notifications').add(notification.toMap());
  }

  Stream<List<AppNotification>> getUserNotifications(String userId) {
    return _db.collection('users').doc(userId).collection('notifications')
        .orderBy('createdAt', descending: true).limit(50)
        .snapshots()
        .map((snap) => snap.docs.map(AppNotification.fromFirestore).toList());
  }

  Future<Map<String, dynamic>> getAdminStats() async {
    final results = await Future.wait([
      _db.collection('users').where('role', isEqualTo: 'donor').count().get(),
      _db.collection('blood_requests').where('status', isEqualTo: 'open').count().get(),
      _db.collection('appointments')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime.now()))
          .count().get(),
      _db.collection('donation_history').where('status', isEqualTo: 'donated').count().get(),
    ]);
    return {
      'totalDonors': results[0].count,
      'openRequests': results[1].count,
      'upcomingAppointments': results[2].count,
      'totalDonations': results[3].count,
    };
  }
}
