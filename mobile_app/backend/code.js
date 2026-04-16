const SPREADSHEET_ID = "1InjaYI_sq3QmA3BJIfcWJ_pmrEcNwS-_aptKMjwAYvU";

/* =========================
   MAIN HANDLER
========================= */

function doPost(e) {
  const path = e.parameter.path;
  if (!path) return jsonError("missing_path");

  let body = {};
  try {
    if (e.postData && e.postData.contents) {
      body = JSON.parse(e.postData.contents);
    } else {
      return jsonError("missing_body");
    }
  } catch (err) {
    return jsonError("invalid_json");
  }

  if (path === "presence/qr/generate") return handleGenerateQR(body);
  if (path === "presence/checkin") return handleCheckin(body);
  if (path === "telemetry/gps") return Gps.handlePostGps(body);
  if (path === "telemetry/accel") return Accel.handlePostAccel(body); 

  return jsonError("endpoint_not_found");
}

function doGet(e) {
  const path = e.parameter.path;
  if (path === "presence/status") return handleStatus(e.parameter);
  if (path === "telemetry/accel/latest") return Accel.handleGetAccelLatest(e.parameter);
  if (path === "telemetry/gps/latest") return Gps.handleGetGpsLatest(e.parameter);
  if (path === "telemetry/gps/history") return Gps.handleGetGpsHistory(e.parameter);
  if (path === "telemetry/gps/all") return Gps.handleGetAllGpsLatest();
  return jsonError("endpoint_not_found");
}

/* =========================
   1️⃣ GENERATE QR
========================= */

function handleGenerateQR(body) {
  const sheet = SpreadsheetApp.openById(SPREADSHEET_ID).getSheetByName("tokens");

  // BUAT ID MATKUL & SESI NGACAK (Permintaan User untuk Testing)
  const courseId = "CR-" + Math.floor(Math.random() * 900 + 100); // Contoh: CR-452
  const sessionId = "Sesi-" + Math.floor(Math.random() * 10 + 1); // Contoh: Sesi-3

  const qrToken = body.custom_token || 
    ("TKN-" + Math.random().toString(36).substring(2, 8).toUpperCase());

  // Kadaluarsa dalam 60 detik (pas untuk rotasi QR setiap 30 detik)
  const expiresAt = new Date(Date.now() + 1 * 60 * 1000).toISOString(); 

  sheet.appendRow([
    qrToken,
    courseId,   // Menggunakan ID acak
    sessionId,  // Menggunakan Sesi acak
    expiresAt,
    body.ts || new Date().toISOString()
  ]);

  return jsonSuccess({
    qr_token: qrToken,
    course_id: courseId, // Kirim balik ke aplikasi
    session_id: sessionId,
    expires_at: expiresAt
  });
}

/* =========================
   2️⃣ CHECKIN
========================= */

function handleCheckin(body) {
  if (!body.user_id || !body.course_id || !body.session_id || !body.qr_token) {
    return jsonError("missing_field");
  }

  const lock = LockService.getScriptLock();
  try {
    lock.waitLock(10000); 

    const ss = SpreadsheetApp.openById(SPREADSHEET_ID);
    const tokenSheet = ss.getSheetByName("tokens");
    const presenceSheet = ss.getSheetByName("presence");

    const tokenData = tokenSheet.getDataRange().getValues();
    let tokenRow = null;

    // 1. Verifikasi Token
    for (let i = 1; i < tokenData.length; i++) {
      if (String(tokenData[i][0]) === String(body.qr_token)) {
        tokenRow = tokenData[i];
        break;
      }
    }

    if (!tokenRow) return jsonError("token_invalid");

    const courseId = String(tokenRow[1]);
    const sessionId = String(tokenRow[2]);
    const expiresAt = new Date(tokenRow[3]);

    if (new Date() > expiresAt) return jsonError("token_expired");

    // Pastikan token cocok dengan Matkul/Sesi
    if (courseId !== String(body.course_id) || sessionId !== String(body.session_id)) {
      return jsonError("token_mismatch");
    }

    // 2. CEK DUPLIKAT (HANYA NIM + MATKUL + SESI)
    // Sesuai permintaan: Device id boleh sama, yang penting NIM beda.
    const presenceData = presenceSheet.getDataRange().getValues();
    const targetUserId = String(body.user_id).trim();
    const targetCourseId = String(body.course_id).trim();
    const targetSessionId = String(body.session_id).trim();

    for (let i = 1; i < presenceData.length; i++) {
      if (
        String(presenceData[i][1]).trim() === targetUserId &&
        String(presenceData[i][3]).trim() === targetCourseId &&
        String(presenceData[i][4]).trim() === targetSessionId
      ) {
        return jsonError("already_checked_in"); // Nim ini sudah absen di matkul ini
      }
    }

    // 3. Simpan
    const presenceId = "PR-" + Math.random().toString(36).substring(2, 8).toUpperCase();
    presenceSheet.appendRow([
      presenceId,
      body.user_id,
      body.device_id || "unknown",
      body.course_id,
      body.session_id,
      body.ts || new Date().toISOString(),
      "checked_in"
    ]);

    return jsonSuccess({ presence_id: presenceId, status: "checked_in" });

  } catch (e) {
    return jsonError("system_error: " + e.message);
  } finally {
    lock.releaseLock();
  }
}

/* =========================
   3️⃣ STATUS
========================= */

function handleStatus(params) {
  if (!params.user_id || !params.course_id || !params.session_id) return jsonError("missing_field");

  const sheet = SpreadsheetApp.openById(SPREADSHEET_ID).getSheetByName("presence");
  const data = sheet.getDataRange().getValues();
  const targetUserId = String(params.user_id).trim();
  const targetCourseId = String(params.course_id).trim();
  const targetSessionId = String(params.session_id).trim();

  for (let i = 1; i < data.length; i++) {
    if (
      String(data[i][1]).trim() === targetUserId &&
      String(data[i][3]).trim() === targetCourseId &&
      String(data[i][4]).trim() === targetSessionId
    ) {
      return jsonSuccess({
        user_id: data[i][1],
        course_id: data[i][3],
        session_id: data[i][4],
        status: data[i][6],
        last_ts: data[i][5]
      });
    }
  }

  return jsonSuccess({ status: "not_found" });
}

/* =========================
   RESPONSE FORMAT
========================= */

function jsonSuccess(data) {
  return ContentService.createTextOutput(JSON.stringify({ ok: true, data })).setMimeType(ContentService.MimeType.JSON);
}

function jsonError(message) {
  return ContentService.createTextOutput(JSON.stringify({ ok: false, error: message })).setMimeType(ContentService.MimeType.JSON);
}
