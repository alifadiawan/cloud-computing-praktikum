const SPREADSHEET_ID = "1InjaYI_sq3QmA3BJIfcWJ_pmrEcNwS-_aptKMjwAYvU";

/* =========================
   MAIN HANDLER
========================= */

function doPost(e) {
  const path = e.parameter.path;
  const body = JSON.parse(e.postData.contents);

  if (path === "presence/qr/generate") {
    return handleGenerateQR(body);
  }

  if (path === "presence/checkin") {
    return handleCheckin(body);
  }

  // 👇 TAMBAHKAN BARIS INI UNTUK MODUL 2 POST
  if (path === "telemetry/accel") {
    return handlePostAccel(body);
  }

  return jsonError("endpoint_not_found");
}

function doGet(e) {
  const path = e.parameter.path;

  // Handle GET with data parameter (for Flutter Web / CORS workaround)
  if (e.parameter.data) {
    const body = JSON.parse(decodeURIComponent(e.parameter.data));

    if (path === "presence/qr/generate") {
      return handleGenerateQR(body);
    }

    if (path === "presence/checkin") {
      return handleCheckin(body);
    }
  }

  if (path === "presence/status") {
    return handleStatus(e.parameter);
  }

  // 👇 TAMBAHKAN BARIS INI UNTUK MODUL 2 GET
  if (path === "telemetry/accel/latest") {
    return handleGetAccelLatest(e.parameter);
  }

  return jsonError("endpoint_not_found");
}

/* =========================
   1️⃣ GENERATE QR
========================= */

function handleGenerateQR(body) {
  if (!body.course_id || !body.session_id || !body.ts) {
    return jsonError("missing_field");
  }

  const sheet =
    SpreadsheetApp.openById(SPREADSHEET_ID).getSheetByName("tokens");

  const qrToken =
    "TKN-" + Math.random().toString(36).substring(2, 8).toUpperCase();

  const expiresDate = new Date(Date.now() + 2 * 60 * 1000); // 2 menit
  const expiresAt = expiresDate.toISOString(); // keep ISO for frontend use

  // Format for Spreadsheet using WIB (GMT+7). Use single quote to store as raw text in sheets
  const expiresFormatted =
    "'" + Utilities.formatDate(expiresDate, "GMT+7", "yyyy-MM-dd HH:mm:ss");
  const tsFormatted =
    "'" +
    Utilities.formatDate(new Date(body.ts), "GMT+7", "yyyy-MM-dd HH:mm:ss");

  sheet.appendRow([
    qrToken,
    body.course_id,
    body.session_id,
    expiresFormatted,
    tsFormatted,
  ]);

  return jsonSuccess({
    qr_token: qrToken,
    expires_at: expiresAt,
  });
}

/* =========================
   2️⃣ CHECKIN
========================= */

function handleCheckin(body) {
  if (
    !body.user_id ||
    !body.device_id ||
    !body.course_id ||
    !body.session_id ||
    !body.qr_token ||
    !body.ts
  ) {
    return jsonError("missing_field");
  }

  const ss = SpreadsheetApp.openById(SPREADSHEET_ID);
  const tokenSheet = ss.getSheetByName("tokens");
  const presenceSheet = ss.getSheetByName("presence");

  const tokenData = tokenSheet.getDataRange().getValues();
  let tokenRow = null;

  // cari token
  for (let i = 1; i < tokenData.length; i++) {
    if (tokenData[i][0] === body.qr_token) {
      tokenRow = tokenData[i];
      break;
    }
  }

  if (!tokenRow) {
    return jsonError("token_invalid");
  }

  const courseId = tokenRow[1];
  const sessionId = tokenRow[2];

  let expiresAtStr = tokenRow[3];
  if (expiresAtStr instanceof Date) {
    expiresAtStr = Utilities.formatDate(
      expiresAtStr,
      "GMT+7",
      "yyyy-MM-dd HH:mm:ss",
    );
  }

  const nowStr = Utilities.formatDate(
    new Date(),
    "GMT+7",
    "yyyy-MM-dd HH:mm:ss",
  );

  if (nowStr > expiresAtStr) {
    return jsonError("token_expired");
  }

  if (courseId !== body.course_id || sessionId !== body.session_id) {
    return jsonError("token_invalid");
  }

  // optional: cek sudah absen belum
  const presenceData = presenceSheet.getDataRange().getValues();
  for (let i = 1; i < presenceData.length; i++) {
    if (
      presenceData[i][1] === body.user_id &&
      presenceData[i][3] === body.course_id &&
      presenceData[i][4] === body.session_id
    ) {
      return jsonError("already_checked_in");
    }
  }

  const presenceId =
    "PR-" + Math.random().toString(36).substring(2, 8).toUpperCase();

  const tsFormatted =
    "'" +
    Utilities.formatDate(new Date(body.ts), "GMT+7", "yyyy-MM-dd HH:mm:ss");

  presenceSheet.appendRow([
    presenceId,
    body.user_id,
    body.device_id,
    body.course_id,
    body.session_id,
    tsFormatted,
    "checked_in",
  ]);

  return jsonSuccess({
    presence_id: presenceId,
    status: "checked_in",
  });
}

/* =========================
   3️⃣ STATUS
========================= */

function handleStatus(params) {
  if (!params.user_id || !params.course_id || !params.session_id) {
    return jsonError("missing_field");
  }

  const sheet =
    SpreadsheetApp.openById(SPREADSHEET_ID).getSheetByName("presence");

  const data = sheet.getDataRange().getValues();

  for (let i = 1; i < data.length; i++) {
    if (
      String(data[i][1]) === String(params.user_id) &&
      String(data[i][3]) === String(params.course_id) &&
      String(data[i][4]) === String(params.session_id)
    ) {
      return jsonSuccess({
        user_id: data[i][1],
        course_id: data[i][3],
        session_id: data[i][4],
        status: data[i][6],
        last_ts: data[i][5],
      });
    }
  }

  return jsonSuccess({
    user_id: params.user_id,
    course_id: params.course_id,
    session_id: params.session_id,
    status: "not_found",
  });
}

/* =========================
   MODUL 2 STUB
========================= */

function handlePostAccel(body) {
  // TODO: Tambahkan implementasi untuk menyimpan data accelerometer (Modul 2)
  return jsonSuccess({ message: "telemetry received" });
}

function handleGetAccelLatest(params) {
  // TODO: Tambahkan implementasi untuk mengambil data accelerometer (Modul 2)
  return jsonSuccess({ x: 0, y: 0, z: 0, ts: new Date().toISOString() });
}

/* =========================
   RESPONSE FORMAT
========================= */

function jsonSuccess(data) {
  return ContentService.createTextOutput(
    JSON.stringify({ ok: true, data }),
  ).setMimeType(ContentService.MimeType.JSON);
}

function jsonError(message) {
  return ContentService.createTextOutput(
    JSON.stringify({ ok: false, error: message }),
  ).setMimeType(ContentService.MimeType.JSON);
}
