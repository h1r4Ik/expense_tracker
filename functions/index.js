const { onDocumentCreated, onDocumentUpdated, onDocumentDeleted } = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");

admin.initializeApp();

/**
 * Helper to fetch all valid FCM tokens for a user and send push notifications.
 */
async function sendNotificationToUser(userId, notificationPayload, dataPayload = {}) {
  try {
    const tokensSnapshot = await admin
      .firestore()
      .collection("users")
      .doc(userId)
      .collection("fcmTokens")
      .get();

    if (tokensSnapshot.empty) {
      console.log(`No FCM tokens found for user ${userId}`);
      return;
    }

    const tokens = [];
    tokensSnapshot.forEach((doc) => {
      const data = doc.data();
      if (data && data.token) {
        tokens.push(data.token);
      }
    });

    if (tokens.length === 0) {
      console.log(`No valid FCM tokens found for user ${userId}`);
      return;
    }

    const message = {
      notification: {
        title: notificationPayload.title,
        body: notificationPayload.body,
      },
      data: dataPayload,
      tokens: tokens,
    };

    const response = await admin.messaging().sendEachForMulticast(message);
    console.log(`Successfully sent FCM notification to user ${userId}:`, response.successCount, "successes");

    // Clean up stale / invalid tokens if any failed
    if (response.failureCount > 0) {
      const failedTokens = [];
      response.responses.forEach((resp, idx) => {
        if (!resp.success) {
          const errCode = resp.error?.code;
          if (
            errCode === "messaging/invalid-registration-token" ||
            errCode === "messaging/registration-token-not-registered"
          ) {
            failedTokens.push(tokens[idx]);
          }
        }
      });

      // Delete stale token docs from Firestore
      const deletePromises = failedTokens.map((token) =>
        admin.firestore().collection("users").doc(userId).collection("fcmTokens").doc(token).delete()
      );
      await Promise.all(deletePromises);
      console.log(`Cleaned up ${failedTokens.length} invalid FCM tokens for user ${userId}`);
    }
  } catch (error) {
    console.error(`Error sending notification to user ${userId}:`, error);
  }
}

/**
 * Format brief transaction summary string
 */
function formatTransactionSummary(data) {
  if (!data) return "Transaction";
  const typeLabel = data.type === "income" ? "Income" : "Expense";
  const amountStr = data.amount != null ? `₹${Number(data.amount).toFixed(2)}` : "₹0.00";
  const desc = data.description ? data.description : data.category || "Entry";
  const category = data.category ? ` (${data.category})` : "";
  return `${typeLabel}: ${amountStr} - ${desc}${category}`;
}

/**
 * 1. Trigger when a transaction entry is ADDED
 */
exports.onTransactionCreated = onDocumentCreated(
  "users/{userId}/transactions/{transactionId}",
  async (event) => {
    const snap = event.data;
    if (!snap) return;
    const data = snap.data();
    const userId = event.params.userId;
    const transactionId = event.params.transactionId;

    const summary = formatTransactionSummary(data);
    const notificationPayload = {
      title: "Transaction Added",
      body: summary,
    };

    const dataPayload = {
      action: "ADD",
      transactionId: transactionId,
      amount: String(data.amount || 0),
      category: String(data.category || ""),
      type: String(data.type || "expense"),
    };

    await sendNotificationToUser(userId, notificationPayload, dataPayload);
  }
);

/**
 * 2. Trigger when a transaction entry is EDITED / UPDATED
 */
exports.onTransactionUpdated = onDocumentUpdated(
  "users/{userId}/transactions/{transactionId}",
  async (event) => {
    const snap = event.data;
    if (!snap) return;
    const dataAfter = snap.after.data();
    const userId = event.params.userId;
    const transactionId = event.params.transactionId;

    const summary = formatTransactionSummary(dataAfter);
    const notificationPayload = {
      title: "Transaction Updated",
      body: summary,
    };

    const dataPayload = {
      action: "EDIT",
      transactionId: transactionId,
      amount: String(dataAfter.amount || 0),
      category: String(dataAfter.category || ""),
      type: String(dataAfter.type || "expense"),
    };

    await sendNotificationToUser(userId, notificationPayload, dataPayload);
  }
);

/**
 * 3. Trigger when a transaction entry is DELETED
 */
exports.onTransactionDeleted = onDocumentDeleted(
  "users/{userId}/transactions/{transactionId}",
  async (event) => {
    const snap = event.data;
    if (!snap) return;
    const dataBefore = snap.data();
    const userId = event.params.userId;
    const transactionId = event.params.transactionId;

    const summary = formatTransactionSummary(dataBefore);
    const notificationPayload = {
      title: "Transaction Deleted",
      body: summary,
    };

    const dataPayload = {
      action: "DELETE",
      transactionId: transactionId,
      amount: String(dataBefore.amount || 0),
      category: String(dataBefore.category || ""),
      type: String(dataBefore.type || "expense"),
    };

    await sendNotificationToUser(userId, notificationPayload, dataPayload);
  }
);
