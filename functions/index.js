const {onDocumentCreated} = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");

admin.initializeApp();

exports.notifyDonorsOnNewRequest = onDocumentCreated("blood_requests/{requestId}", async (event) => {
  const requestData = event.data.data();
  if (!requestData) return;

  const bloodType = requestData.bloodType;
  const hospitalName = requestData.hospitalName;
  const urgencyLevel = requestData.urgencyLevel;
  const requestId = event.params.requestId;

  // Determine compatible blood types
  const compatibleTypes = getCompatibleBloodTypes(bloodType);
  
  // Find all donors with compatible blood types
  const db = admin.firestore();
  const eligibleTokens = [];

  for (const bt of compatibleTypes) {
    const donorsSnap = await db.collection("users")
      .where("role", "==", "donor")
      .where("bloodType", "==", bt)
      .get();
      
    for (const doc of donorsSnap.docs) {
      const donor = doc.data();
      
      // Check 90-day cooldown eligibility
      const isEligible = isTimeEligible(donor.lastDonationDate);
      if (!isEligible) continue;
      
      if (donor.fcmToken) {
        eligibleTokens.push(donor.fcmToken);
      }
    }
  }

  if (eligibleTokens.length === 0) {
    console.log("No eligible donors found for request:", requestId);
    return;
  }

  // Send multicast push notification
  const message = {
    notification: {
      title: urgencyLevel === 'critical' 
        ? `Critical: ${bloodType} Blood Needed!` 
        : 'Blood Donation Request',
      body: `${bloodType} blood urgently needed at ${hospitalName}`,
    },
    data: {
      type: 'blood_request',
      requestId: requestId,
      bloodType: bloodType,
      urgencyLevel: urgencyLevel,
    },
    tokens: eligibleTokens,
  };

  try {
    const response = await admin.messaging().sendEachForMulticast(message);
    console.log(`Successfully sent ${response.successCount} messages; Failed: ${response.failureCount}`);
  } catch (error) {
    console.error("Error sending push notifications:", error);
  }
});

function getCompatibleBloodTypes(requestedType) {
  const donors = {
    'A+': ['A+', 'A-', 'O+', 'O-'],
    'A-': ['A-', 'O-'],
    'B+': ['B+', 'B-', 'O+', 'O-'],
    'B-': ['B-', 'O-'],
    'AB+': ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'],
    'AB-': ['A-', 'B-', 'AB-', 'O-'],
    'O+': ['O+', 'O-'],
    'O-': ['O-'],
  };
  return donors[requestedType] || [requestedType];
}

function isTimeEligible(lastDonationDate) {
  if (!lastDonationDate) return true;
  // lastDonationDate is a Firestore Timestamp object
  const lastDate = lastDonationDate.toDate();
  const ninetyDaysInMs = 90 * 24 * 60 * 60 * 1000;
  const eligibleDate = new Date(lastDate.getTime() + ninetyDaysInMs);
  return Date.now() > eligibleDate.getTime();
}
