const { onSchedule } = require("firebase-functions/v2/scheduler");
const { onDocumentUpdated, onDocumentCreated } = require("firebase-functions/v2/firestore");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");
const crypto = require("crypto");

initializeApp();

const db = getFirestore();

// ── i18n strings for push notifications ──
const i18n = {
  en: {
    reminder_title: "Don't forget your challenge!",
    reminder_body: (title) => `Submit proof for "${title}" before midnight.`,
    arbiter_invite_title: "Arbiter invitation",
    arbiter_invite_body: (creator, title) => `${creator} invites you to arbitrate "${title}"`,
    arbiter_accepted_title: "Arbiter accepted!",
    arbiter_accepted_body: (arbiter, title) => `${arbiter} accepted to arbitrate "${title}". Your challenge starts tomorrow!`,
    arbiter_declined_title: "Arbiter declined",
    arbiter_declined_body: (arbiter, title) => `${arbiter} declined to arbitrate "${title}"`,
    payment_proof_title: "Donation receipt submitted",
    payment_proof_body: (creator, title) => `${creator} submitted a donation receipt for "${title}". Review it now.`,
    proof_submitted_title: "Proof submitted!",
    proof_submitted_body: (creator, title) => `${creator} submitted proof for "${title}". Review it now.`,
  },
  uk: {
    reminder_title: "Не забудьте про челендж!",
    reminder_body: (title) => `Подайте доказ для "${title}" до опівночі.`,
    arbiter_invite_title: "Запрошення арбітром",
    arbiter_invite_body: (creator, title) => `${creator} запрошує вас арбітром для "${title}"`,
    arbiter_accepted_title: "Арбітр прийняв!",
    arbiter_accepted_body: (arbiter, title) => `${arbiter} прийняв арбітраж для "${title}". Челендж починається завтра!`,
    arbiter_declined_title: "Арбітр відхилив",
    arbiter_declined_body: (arbiter, title) => `${arbiter} відхилив арбітраж для "${title}"`,
    payment_proof_title: "Підтвердження пожертви надіслано",
    payment_proof_body: (creator, title) => `${creator} надіслав підтвердження пожертви для "${title}". Перевірте зараз.`,
    proof_submitted_title: "Доказ подано!",
    proof_submitted_body: (creator, title) => `${creator} подав доказ для "${title}". Перевірте зараз.`,
  },
};

function t(locale, key) {
  return (i18n[locale] || i18n.en)[key] || i18n.en[key];
}

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

    const missedSnap = await db
      .collection("challenges")
      .doc(doc.id)
      .collection("dayRecords")
      .where("status", "==", "missed")
      .get();

    await doc.ref.update({
      status: succeeded ? "completed" : "failed",
      completedDays: approvedDays,
      missedDays: missedSnap.size,
      paymentProofStatus: succeeded ? "none" : "pending",
    });

    const userRef = db.collection("users").doc(challenge.creatorId);
    if (succeeded) {
      await userRef.update({
        challengesCompleted: FieldValue.increment(1),
      });
    } else {
      await userRef.update({
        challengesFailed: FieldValue.increment(1),
        totalLost: FieldValue.increment(challenge.stakeAmountCents),
      });
    }
  }
});

// ── Mark Missed Days (scheduled) ──
exports.markMissedDays = onSchedule("every day 00:05", async () => {
  const yesterday = new Date();
  yesterday.setDate(yesterday.getDate() - 1);
  const yStr = yesterday.toISOString().split("T")[0];

  const snapshot = await db
    .collection("challenges")
    .where("status", "==", "active")
    .get();

  for (const doc of snapshot.docs) {
    const dayRecordsSnap = await db
      .collection("challenges")
      .doc(doc.id)
      .collection("dayRecords")
      .where("date", ">=", `${yStr}T00:00:00.000`)
      .where("date", "<=", `${yStr}T23:59:59.999`)
      .where("status", "==", "pending")
      .get();

    for (const rec of dayRecordsSnap.docs) {
      await rec.ref.update({ status: "missed" });
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
    const userData = userDoc.data();
    const fcmToken = userData?.fcmToken;
    const locale = userData?.locale || "en";

    if (fcmToken) {
      await getMessaging().send({
        token: fcmToken,
        notification: {
          title: t(locale, "reminder_title"),
          body: t(locale, "reminder_body")(challenge.title),
        },
        data: {
          challengeId: doc.id,
          type: "reminder",
        },
      });
    }
  }
});

// ── On Challenge Created — notify arbiter ──
exports.onChallengeCreated = onDocumentCreated(
  "challenges/{challengeId}",
  async (event) => {
    const challenge = event.data.data();
    if (!challenge || !challenge.arbiterId) return;

    const arbiterDoc = await db
      .collection("users")
      .doc(challenge.arbiterId)
      .get();
    const arbiterData = arbiterDoc.data();
    const fcmToken = arbiterData?.fcmToken;
    const locale = arbiterData?.locale || "en";

    if (fcmToken) {
      await getMessaging().send({
        token: fcmToken,
        notification: {
          title: t(locale, "arbiter_invite_title"),
          body: t(locale, "arbiter_invite_body")(challenge.creatorName, challenge.title),
        },
        data: {
          challengeId: event.params.challengeId,
          type: "arbiter_request",
        },
      });
    }
  }
);

// ── On Arbiter Status Changed — notify creator, recalculate dates ──
exports.onArbiterStatusChanged = onDocumentUpdated(
  "challenges/{challengeId}",
  async (event) => {
    const before = event.data.before.data();
    const after = event.data.after.data();

    if (
      before.arbiterStatus === after.arbiterStatus ||
      after.arbiterStatus === "pending"
    ) {
      return;
    }

    const challengeId = event.params.challengeId;
    const challengeRef = event.data.after.ref;

    // ── Accepted: activate challenge, recalculate dates, recreate dayRecords ──
    if (after.arbiterStatus === "accepted") {
      const now = new Date();
      const tomorrow = new Date(now.getFullYear(), now.getMonth(), now.getDate() + 1);
      const endDate = new Date(tomorrow);
      endDate.setDate(endDate.getDate() + after.durationDays);

      // Update challenge dates and status
      await challengeRef.update({
        status: "active",
        startDate: tomorrow.toISOString(),
        endDate: endDate.toISOString(),
      });

      // Delete old dayRecords
      const oldRecords = await db
        .collection("challenges")
        .doc(challengeId)
        .collection("dayRecords")
        .get();
      const batch = db.batch();
      for (const doc of oldRecords.docs) {
        batch.delete(doc.ref);
      }
      await batch.commit();

      // Create new dayRecords
      const newBatch = db.batch();
      for (let i = 0; i < after.durationDays; i++) {
        const date = new Date(tomorrow);
        date.setDate(date.getDate() + i);
        const recordId = crypto.randomUUID();
        const ref = db
          .collection("challenges")
          .doc(challengeId)
          .collection("dayRecords")
          .doc(recordId);
        newBatch.set(ref, {
          id: recordId,
          challengeId,
          date: date.toISOString(),
          status: "pending",
          proofImageUrl: null,
          proofNote: null,
          rejectionReason: null,
          submittedAt: null,
          reviewedAt: null,
          proofAttempts: 0,
        });
      }
      await newBatch.commit();
    }

    // ── Declined: cancel the challenge ──
    if (after.arbiterStatus === "declined" && after.status !== "cancelled") {
      await challengeRef.update({ status: "cancelled" });
    }

    // ── Notify creator ──
    const creatorDoc = await db
      .collection("users")
      .doc(after.creatorId)
      .get();
    const creatorData = creatorDoc.data();
    const fcmToken = creatorData?.fcmToken;
    const locale = creatorData?.locale || "en";

    if (fcmToken) {
      const accepted = after.arbiterStatus === "accepted";
      await getMessaging().send({
        token: fcmToken,
        notification: {
          title: accepted
            ? t(locale, "arbiter_accepted_title")
            : t(locale, "arbiter_declined_title"),
          body: accepted
            ? t(locale, "arbiter_accepted_body")(after.arbiterName, after.title)
            : t(locale, "arbiter_declined_body")(after.arbiterName, after.title),
        },
        data: {
          challengeId,
          type: "arbiter_response",
        },
      });
    }
  }
);

// ── On Payment Proof Submitted — notify arbiter ──
exports.onPaymentProofSubmitted = onDocumentUpdated(
  "challenges/{challengeId}",
  async (event) => {
    const before = event.data.before.data();
    const after = event.data.after.data();

    if (
      before.paymentProofStatus === after.paymentProofStatus ||
      after.paymentProofStatus !== "submitted"
    ) {
      return;
    }

    const arbiterDoc = await db
      .collection("users")
      .doc(after.arbiterId)
      .get();
    const arbiterData = arbiterDoc.data();
    const fcmToken = arbiterData?.fcmToken;
    const locale = arbiterData?.locale || "en";

    if (fcmToken) {
      await getMessaging().send({
        token: fcmToken,
        notification: {
          title: t(locale, "payment_proof_title"),
          body: t(locale, "payment_proof_body")(after.creatorName, after.title),
        },
        data: {
          challengeId: event.params.challengeId,
          type: "payment_proof_submitted",
        },
      });
    }
  }
);

// ── On Proof Submitted ──
exports.onProofSubmitted = onDocumentUpdated(
  "challenges/{challengeId}/dayRecords/{recordId}",
  async (event) => {
    const before = event.data.before.data();
    const after = event.data.after.data();

    if (after.status !== "proofSubmitted") {
      return;
    }
    // Skip if status didn't change (e.g. only other fields updated)
    if (before.status === after.status) {
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
    const arbiterData = arbiterDoc.data();
    const fcmToken = arbiterData?.fcmToken;
    const locale = arbiterData?.locale || "en";

    if (fcmToken) {
      await getMessaging().send({
        token: fcmToken,
        notification: {
          title: t(locale, "proof_submitted_title"),
          body: t(locale, "proof_submitted_body")(challenge.creatorName, challenge.title),
        },
        data: {
          challengeId,
          type: "proof_submitted",
        },
      });
    }
  }
);
