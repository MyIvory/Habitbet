const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { onDocumentUpdated } = require("firebase-functions/v2/firestore");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");

initializeApp();

const db = getFirestore();

// Stripe setup — configure later:
// const stripe = require("stripe")(process.env.STRIPE_SECRET_KEY);

// ── Create Payment Intent ──
exports.createPaymentIntent = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "User must be authenticated");
  }

  const { amount, currency, challengeId } = request.data;

  if (!amount || !currency || !challengeId) {
    throw new HttpsError(
      "invalid-argument",
      "Missing required fields: amount, currency, challengeId"
    );
  }

  // TODO: Uncomment when Stripe is configured
  // const paymentIntent = await stripe.paymentIntents.create({
  //   amount,
  //   currency,
  //   capture_method: "manual",
  //   metadata: { challengeId, userId: request.auth.uid },
  // });
  // return {
  //   clientSecret: paymentIntent.client_secret,
  //   paymentIntentId: paymentIntent.id,
  // };

  return {
    clientSecret: `placeholder_secret_${challengeId}`,
    paymentIntentId: `pi_placeholder_${challengeId}`,
  };
});

// ── Capture Payment (challenge failed) ──
exports.capturePayment = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "User must be authenticated");
  }

  // const { paymentIntentId } = request.data;
  // TODO: await stripe.paymentIntents.capture(paymentIntentId);

  return { success: true };
});

// ── Cancel Payment Intent (challenge completed) ──
exports.cancelPaymentIntent = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "User must be authenticated");
  }

  // const { paymentIntentId } = request.data;
  // TODO: await stripe.paymentIntents.cancel(paymentIntentId);

  return { success: true };
});

// ── Resolve Challenges (scheduled) ──
exports.resolveChallenges = onSchedule("every day 00:00", async () => {
  const now = new Date();

  const snapshot = await db
    .collection("challenges")
    .where("status", "==", "active")
    .where("endDate", "<=", now.toISOString())
    .get();

  for (const doc of snapshot.docs) {
    const challenge = doc.data();

    const dayRecordsSnap = await db
      .collection("challenges")
      .doc(doc.id)
      .collection("dayRecords")
      .where("status", "==", "approved")
      .get();

    const approvedDays = dayRecordsSnap.size;
    const totalRequired = Math.ceil(
      (challenge.durationDays / 7) * challenge.requiredDaysPerWeek
    );

    const succeeded = approvedDays >= totalRequired;

    await doc.ref.update({
      status: succeeded ? "completed" : "failed",
      completedDays: approvedDays,
    });

    const userRef = db.collection("users").doc(challenge.creatorId);
    if (succeeded) {
      await userRef.update({
        challengesCompleted: FieldValue.increment(1),
      });
      // TODO: await stripe.paymentIntents.cancel(challenge.stripePaymentIntentId);
    } else {
      await userRef.update({
        challengesFailed: FieldValue.increment(1),
        totalLost: FieldValue.increment(challenge.stakeAmountCents),
      });
      // TODO: await stripe.paymentIntents.capture(challenge.stripePaymentIntentId);
    }
  }
});

// ── Send Reminders (scheduled) ──
exports.sendReminders = onSchedule("every day 20:00", async () => {
  const now = new Date();
  const todayStr = now.toISOString().split("T")[0];

  const snapshot = await db
    .collection("challenges")
    .where("status", "==", "active")
    .get();

  for (const doc of snapshot.docs) {
    const challenge = doc.data();

    const dayRecordsSnap = await db
      .collection("challenges")
      .doc(doc.id)
      .collection("dayRecords")
      .where("date", ">=", `${todayStr}T00:00:00.000`)
      .where("date", "<=", `${todayStr}T23:59:59.999`)
      .where("status", "==", "pending")
      .get();

    if (dayRecordsSnap.empty) continue;

    const userDoc = await db
      .collection("users")
      .doc(challenge.creatorId)
      .get();
    const fcmToken = userDoc.data()?.fcmToken;

    if (fcmToken) {
      await getMessaging().send({
        token: fcmToken,
        notification: {
          title: "Don't forget your challenge!",
          body: `Submit proof for "${challenge.title}" before midnight.`,
        },
        data: {
          challengeId: doc.id,
          type: "reminder",
        },
      });
    }
  }
});

// ── On Proof Submitted ──
exports.onProofSubmitted = onDocumentUpdated(
  "challenges/{challengeId}/dayRecords/{recordId}",
  async (event) => {
    const before = event.data.before.data();
    const after = event.data.after.data();

    if (before.status === "proofSubmitted" || after.status !== "proofSubmitted") {
      return;
    }

    const { challengeId } = event.params;

    const challengeDoc = await db
      .collection("challenges")
      .doc(challengeId)
      .get();
    const challenge = challengeDoc.data();

    if (!challenge || !challenge.arbiterId) return;

    const arbiterDoc = await db
      .collection("users")
      .doc(challenge.arbiterId)
      .get();
    const fcmToken = arbiterDoc.data()?.fcmToken;

    if (fcmToken) {
      await getMessaging().send({
        token: fcmToken,
        notification: {
          title: "Proof submitted!",
          body: `${challenge.creatorName} submitted proof for "${challenge.title}". Review it now.`,
        },
        data: {
          challengeId,
          type: "proof_submitted",
        },
      });
    }
  }
);
