/**
 * Cloud Functions stub for MediSync (TRD §5, §8).
 *
 * `extractPrescription` is the callable the app uses for Bangla/cloud OCR:
 *   image -> Cloud Vision OCR -> (optional) LLM structuring -> JSON.
 *
 * This is a STUB. Wire Google Cloud Vision + an LLM here, keeping API keys
 * server-side. Until deployed, the client's CloudOcrService catches the error
 * and falls back to on-device ML Kit (English) — capture never blocks.
 */
const functions = require("firebase-functions");

exports.extractPrescription = functions.https.onCall(async (data, context) => {
  // Per-user auth (Security Rules cover Firestore; validate here for callables).
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "Sign-in required."
    );
  }

  // TODO: decode data.imageBase64, call Cloud Vision (with Bengali support),
  // optionally pass rawText to an LLM to produce { medicines, tests, instructions }
  // with per-field confidence. Return rawText (+ structured) to the client.
  //
  // const vision = require("@google-cloud/vision");
  // const client = new vision.ImageAnnotatorClient();
  // const [result] = await client.documentTextDetection({ image: { content: data.imageBase64 } });
  // const rawText = result.fullTextAnnotation?.text ?? "";

  throw new functions.https.HttpsError(
    "unimplemented",
    "extractPrescription is not deployed yet — see functions/index.js."
  );
});
