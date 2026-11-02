const functions = require("firebase-functions");
const admin = require("firebase-admin");
const nodemailer = require("nodemailer");

admin.initializeApp();

// Consistent region matching Flutter client: asia-southeast1
const REGION = "asia-southeast1";

/**
 * 1. sendTopupOtp
 * Callable function to generate/record top-up OTP and email it to the student.
 */
exports.sendTopupOtp = functions.region(REGION).https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "Must be signed in to request a top-up OTP."
    );
  }

  const { requestId, email, amount, otp: clientOtp } = data;
  if (!requestId || !email || !amount) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Missing required parameters (requestId, email, or amount)."
    );
  }

  const otp = clientOtp || Math.floor(100000 + Math.random() * 900000).toString();
  const expiresAt = new Date(Date.now() + 10 * 60 * 1000); // 10 minutes from now

  const db = admin.firestore();
  const reqRef = db.collection("credit_topup_requests").doc(requestId);

  await reqRef.set(
    {
      otp: otp,
      expiresAt: admin.firestore.Timestamp.fromDate(expiresAt),
      status: "pending",
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true }
  );

  // Email delivery via SMTP / Gmail if configured in environment
  const smtpUser = process.env.SMTP_EMAIL || functions.config().smtp?.email;
  const smtpPass = process.env.SMTP_PASSWORD || functions.config().smtp?.password;

  let emailSent = false;
  let emailError = null;

  if (smtpUser && smtpPass) {
    try {
      const transporter = nodemailer.createTransport({
        service: "gmail",
        auth: {
          user: smtpUser,
          pass: smtpPass,
        },
      });

      const mailOptions = {
        from: `"CPC Canteen" <${smtpUser}>`,
        to: email,
        subject: "Your Canteen Top-up OTP Code",
        html: `
          <div style="font-family: Arial, sans-serif; max-width: 500px; margin: auto; padding: 24px; border: 1px solid #e0e0e0; border-radius: 12px; background-color: #ffffff;">
            <h2 style="color: #1e7b3b; margin-top: 0;">Canteen Credit Top-up</h2>
            <p style="color: #555; font-size: 14px;">
              A counter top-up of <strong>₱${Number(amount).toFixed(2)}</strong> has been requested for your account.
            </p>
            <p style="color: #555; font-size: 14px;">Please read or show this 6-digit verification code to the cashier:</p>
            <div style="background-color: #f1f8e9; border: 1.5px dashed #43a047; padding: 16px; font-size: 28px; font-weight: bold; letter-spacing: 6px; color: #1e7b3b; text-align: center; border-radius: 8px; margin: 16px 0;">
              ${otp}
            </div>
            <p style="color: #888; font-size: 12px; margin-bottom: 0;">
              This code will expire in 10 minutes. If you did not make this request at the counter, please inform the canteen administration immediately.
            </p>
          </div>
        `,
      };

      await transporter.sendMail(mailOptions);
      emailSent = true;
    } catch (err) {
      console.warn("SMTP email dispatch failed:", err);
      emailError = err.message;
    }
  }

  return {
    ok: true,
    emailSent: emailSent,
    message: emailSent
      ? "OTP email sent successfully."
      : "OTP recorded. (Configure SMTP_EMAIL and SMTP_PASSWORD to enable email delivery).",
    error: emailError,
  };
});

/**
 * 2. verifyTopupOtp
 * Callable function to verify the OTP and credit the student atomically.
 */
exports.verifyTopupOtp = functions.region(REGION).https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "Must be signed in as admin to verify top-up OTP."
    );
  }

  const { requestId, otp } = data;
  if (!requestId || !otp) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Missing requestId or otp."
    );
  }

  const db = admin.firestore();
  const reqRef = db.collection("credit_topup_requests").doc(requestId);
  const reqDoc = await reqRef.get();

  if (!reqDoc.exists) {
    throw new functions.https.HttpsError("not-found", "Top-up request not found.");
  }

  const reqData = reqDoc.data();
  if (reqData.status !== "pending") {
    throw new functions.https.HttpsError(
      "failed-precondition",
      `Request is already ${reqData.status}.`
    );
  }

  if (reqData.expiresAt && reqData.expiresAt.toDate() < new Date()) {
    await reqRef.update({ status: "expired" });
    throw new functions.https.HttpsError("deadline-exceeded", "OTP has expired.");
  }

  if (String(reqData.otp).trim() !== String(otp).trim()) {
    throw new functions.https.HttpsError("invalid-argument", "Incorrect OTP.");
  }

  const uid = reqData.uid;
  const amount = Number(reqData.amount);
  const note = reqData.note || "Counter top-up";

  const userRef = db.collection("users").doc(uid);
  const txRef = db.collection("credit_transactions").doc();

  await db.runTransaction(async (t) => {
    const userDoc = await t.get(userRef);
    if (!userDoc.exists) {
      throw new functions.https.HttpsError("not-found", "Student user not found.");
    }

    const currentCredits = Number(userDoc.data().credits || 0);
    const newCredits = currentCredits + amount;

    t.update(userRef, {
      credits: newCredits,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    t.set(txRef, {
      uid: uid,
      type: "credit",
      amount: amount,
      balanceAfter: newCredits,
      note: note,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
    });

    t.update(reqRef, {
      status: "confirmed",
      confirmedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  });

  return { ok: true, message: `Successfully added ₱${amount.toFixed(2)} to student account.` };
});

