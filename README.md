# Praktikum Komputasi Awan
## API Contract Simple v1 – Versi A (Google Apps Script + Google Sheets)

Project ini merupakan implementasi client (Flutter) dan backend (Google Apps Script + Google Sheets) untuk tugas Praktikum Komputasi Awan.

---

## 👥 Anggota Kelompok
1. Nama 1 – NIM – Role
2. Nama 2 – NIM – Role
3. Nama 3 – NIM – Role
4. Nama 4 – NIM – Role

---

## 🌐 Base URL (Backend GAS)

```
{{BASE_URL}} = https://script.google.com/macros/s/ISI_DEPLOYMENT_ID/exec
```

Semua endpoint menggunakan base URL di atas.

---

# 📌 Modul 1 – Presensi QR Dinamis

### 1️⃣ Generate QR Token
**POST** `/presence/qr/generate`

Contoh Request:
```json
{
  "course_id": "cloud-101",
  "session_id": "sesi-02",
  "ts": "2026-02-18T10:00:00Z"
}
```

---

### 2️⃣ Check-in
**POST** `/presence/checkin`

Contoh Request:
```json
{
  "user_id": "2023xxxx",
  "device_id": "dev-001",
  "course_id": "cloud-101",
  "session_id": "sesi-02",
  "qr_token": "TKN-XXXX",
  "ts": "2026-02-18T10:01:10Z"
}
```

---

### 3️⃣ Cek Status
**GET** `/presence/status?user_id=...&course_id=...&session_id=...`

---

# 📊 Modul 2 – Accelerometer Telemetry

### 1️⃣ Kirim Batch Accelerometer
**POST** `/telemetry/accel`

Contoh Request:
```json
{
  "device_id": "dev-001",
  "ts": "2026-02-18T10:15:30Z",
  "samples": [
    { "t": "2026-02-18T10:15:29.100Z", "x": 0.12, "y": 0.01, "z": 9.70 },
    { "t": "2026-02-18T10:15:29.300Z", "x": 0.15, "y": 0.02, "z": 9.68 }
  ]
}
```

---

### 2️⃣ Ambil Data Terbaru
**GET** `/telemetry/accel/latest?device_id=...`

---

# 📍 Modul 3 – GPS Tracking + Peta

### 1️⃣ Log GPS Point
**POST** `/telemetry/gps`

Contoh Request:
```json
{
  "device_id": "dev-001",
  "ts": "2026-02-18T10:15:30Z",
  "lat": -7.2575,
  "lng": 112.7521,
  "accuracy_m": 12.5
}
```

---

### 2️⃣ Ambil GPS Terbaru (Marker)
**GET** `/telemetry/gps/latest?device_id=...`

### 3️⃣ Ambil GPS History (Polyline)
**GET** `/telemetry/gps/history?device_id=...&limit=200`

---

# 📱 Client (Flutter)

Folder utama client:
```
mobile_app/
```

Struktur utama:
```
lib/
  core/
  modules/
    presence/
    accel/
    gps/
```

---

# ▶️ Cara Menjalankan Project

1. Masuk ke folder client:
```
cd mobile_app
```

2. Install dependency:
```
flutter pub get
```

3. Jalankan aplikasi:
```
flutter run
```

---

# 🔁 Swap Testing

Project ini mengikuti API Contract Simple v1.
Client dapat diuji dengan server kelompok lain selama endpoint dan format JSON sesuai kontrak.

---

# 📄 Dokumentasi

Dokumentasi tambahan tersedia di folder:
```
docs/
```

---

## ✅ Status Pengembangan

- [ ] Backend GAS Aktif
- [ ] Endpoint Presensi Jalan
- [ ] Endpoint Accelerometer Jalan
- [ ] Endpoint GPS Jalan
- [ ] Client Demo Siap
- [ ] Dokumentasi Final
