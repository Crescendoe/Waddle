const functions = require("firebase-functions");
const admin = require("firebase-admin");
const escape = require("escape-html");
admin.initializeApp();

// Your helper function to send FCM messages
async function sendFcmMessage(fcmToken, title, body) {
  if (!fcmToken) {
    console.error("FCM token is missing. Cannot send message.");
    return;
  }
  const message = {
    token: fcmToken,
    notification: {
      title: title,
      body: body,
    },
    // You can also send 'data' payload for custom handling in the app
    // data: {
    //   screen: '/waterlog', // Example to navigate user
    // }
  };

  try {
    const response = await admin.messaging().send(message);
    console.log("Successfully sent message to token:", fcmToken, response);
  } catch (error) {
    console.error("Error sending message to token:", fcmToken, error);
    // Handle token cleanup if it's invalid (e.g., NotRegistered or Unregistered)
    if (
      error.code === "messaging/registration-token-not-registered" ||
      error.code === "messaging/invalid-registration-token"
    ) {
      console.log(
        `Token ${fcmToken} is no longer valid. Consider removing it from Firestore.`
      );
      // Here you might want to write code to remove the invalid token from the user's document in Firestore
      // For example: await admin.firestore().collection('users').doc(userIdWithInvalidToken).update({ fcmToken: null });
    }
  }
}

// Example: A scheduled function that runs every day at 9 AM
// (You'll need to set up a Pub/Sub schedule in Google Cloud Console or using gcloud commands)
exports.sendDailyReminders = functions.pubsub
  .schedule("every day 09:00")
  .timeZone("America/Chicago") // Set your desired timezone
  .onRun(async (context) => {
    console.log("Running daily reminder function...");
    const now = new Date();
    const currentHour = now.getHours(); // Adjust for timezone if needed or use server time
    const currentMinute = now.getMinutes();

    try {
      const usersSnapshot = await admin
        .firestore()
        .collection("users")
        .where("fcmSettings.notificationsEnabled", "==", true)
        .get();

      if (usersSnapshot.empty) {
        console.log("No users found with notifications enabled.");
        return null;
      }

      usersSnapshot.forEach(async (doc) => {
        const userData = doc.data();
        const userFcmToken = userData.fcmToken;
        const dailyReminderTime = userData.fcmSettings.dailyReminderTime; // e.g., { hour: 9, minute: 0 }

        if (
          userFcmToken &&
          dailyReminderTime &&
          dailyReminderTime.hour === currentHour &&
          dailyReminderTime.minute === currentMinute
        ) {
          console.log(`Sending daily reminder to user ${doc.id}`);
          await sendFcmMessage(
            userFcmToken,
            "Hydration Reminder!",
            "It's time to drink some water and log your intake!"
          );
        }
      });
    } catch (error) {
      console.error("Error fetching users or sending daily reminders:", error);
    }
    return null;
  });

// You could have another function for interval-based reminders
// exports.sendIntervalReminders = functions.pubsub.schedule('every 15 minutes')
//  .onRun(async (context) => { /* ... logic to check user interval preferences ... */ });

// You can also create an HTTP-triggered function for testing
exports.testSendFCM = functions.https.onRequest(async (req, res) => {
  const targetToken = req.query.token; // Pass token as a query parameter for testing
  const title = req.query.title || "Test Title";
  const body = req.query.body || "This is a test FCM message!";

  if (!targetToken) {
    res
      .status(400)
      .send('Please provide an FCM token in the query parameter "token".');
    return;
  }

  await sendFcmMessage(targetToken, title, body);
  res.send(`Attempted to send message to token: ${escape(targetToken)}`);
});
