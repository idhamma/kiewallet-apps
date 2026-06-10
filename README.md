# KieWallet — Flutter (Web + Mobile)

Port Flutter dari aplikasi web React **kieWallet**. Satu codebase, tiga target build:

- **Android APK / Play Store**
- **iOS**
- **Web** (PWA, host di Netlify / Firebase Hosting / static server)

Data tersinkron via **Firebase project yang sama** (`kiewallet`):
- Login di web (React lama) → data tersedia di Flutter mobile.
- Login di mobile → langsung muncul di web.

## Struktur

```
kiewallet-apps/
├── pubspec.yaml
├── web/                      # Flutter Web (index.html, manifest)
├── lib/
│   ├── main.dart             # entrypoint + ChangeNotifierProvider(AppState)
│   ├── config/
│   │   ├── firebase_options.dart   # Firebase credentials (sama dengan React .env)
│   │   ├── constants.dart    # default akun, kategori, warna retro
│   │   └── theme.dart        # neobrutalism ThemeData
│   ├── models/               # Tx, Debt, Recurring, PortfolioItem, CustomBudget
│   ├── services/             # auth_service, firestore_service, market_api
│   ├── utils/                # format Rp, date helpers, csv import/export
│   ├── state/
│   │   └── app_state.dart    # state global (port dari React useState/useMemo)
│   ├── widgets/
│   │   ├── common/           # RetroBox, RetroButton, popup, date filter
│   │   └── charts/           # AdvancedCashFlow, PieDistribution (CustomPainter)
│   └── screens/
│       ├── root_screen.dart  # auth gate
│       ├── login_screen.dart
│       ├── home_screen.dart  # shell + nav tabs
│       └── tabs/             # dashboard, cashflow, transfer, invest, debt,
│                             # recurring, analysis, data
```

## Setup pertama kali

### 1. Install Flutter (>= 3.22)

```bash
# Ubuntu / Linux
sudo snap install flutter --classic
# macOS
brew install --cask flutter
# Manual: https://docs.flutter.dev/get-started/install

flutter doctor                # pastikan semua bagian OK
```

### 2. Inisialisasi platform native

Folder `android/`, `ios/`, `linux/`, `macos/`, `windows/` belum ada (di-gitignore karena auto-generated). Buat sekali:

```bash
cd "/home/insomniac/Univ/Personal Project/kiewallet-apps"
flutter create . --platforms=android,ios,web,linux \
  --org com.kiezu --project-name kiewallet
flutter pub get
```

### 3. Firebase native (Android/iOS) — opsional, hanya jika perlu mobile build

`lib/config/firebase_options.dart` sudah berisi credentials Web. Untuk Android/iOS native, jalankan FlutterFire CLI sekali:

```bash
dart pub global activate flutterfire_cli
flutterfire configure --project=kiewallet
```

Ini otomatis:
- Daftarkan app Android (`com.kiezu.kiewallet`) & iOS ke project Firebase.
- Overwrite `firebase_options.dart` dengan appId asli.
- Drop `google-services.json` ke `android/app/` dan `GoogleService-Info.plist` ke `ios/Runner/`.

> Hanya target Web? Lewati saja — config Web sudah hardcoded.

### 4. Enable Email/Password di Firebase Console

Project `kiewallet` → Authentication → Sign-in method → enable **Email/Password**. (Sudah aktif kalau React app sebelumnya jalan.)

## Run

```bash
flutter run -d chrome         # Web
flutter run -d android        # Android emulator/device
flutter run -d ios            # iOS (di macOS)
flutter run -d linux          # Linux desktop
```

## Build release

```bash
flutter build web --release           # output: build/web/
flutter build apk --release           # Android APK
flutter build appbundle --release     # Android App Bundle (Play Store)
flutter build ios --release           # iOS (lalu archive via Xcode)
```

### Deploy Web ke Firebase Hosting

```bash
npm i -g firebase-tools
firebase login
firebase init hosting          # pilih project `kiewallet`, public dir = build/web
flutter build web --release
firebase deploy --only hosting
```

### Deploy Web ke Netlify

Build command: `flutter build web --release`. Publish dir: `build/web`.

## Sinkronisasi dengan React app

Kedua app pakai struktur Firestore yang sama persis:

- **Path**: `artifacts/retrofin-app-pribadi/users/{uid}/appData/state`
- **Fields**: `accounts`, `expenseCats`, `transactions`, `debts`, `recurring`, `portfolio`, `customBudgets`
- **Format tanggal**: ISO `YYYY-MM-DD`
- **Format jam**: `HH:MM` (24h) WIB / Asia/Jakarta

Tambah transaksi di mobile → real-time muncul di tab browser yang sedang buka React app, dan sebaliknya.

## Market API (live prices)

- **CoinGecko** (Crypto, IDR)
- **Yahoo Finance** (.JK untuk saham IDX)
- **logam-mulia-api** (emas Antam)

Di Web, request Yahoo dilewatkan via `corsproxy.io` (sama seperti React). Di mobile native tidak butuh proxy.

## Scan AI (struk / QRIS / invoice → transaksi otomatis)

Tab **Scan AI** menerima foto/screenshot struk belanja, pembayaran QRIS, invoice,
atau bukti transfer, lalu mengekstraknya menjadi pemasukan/pengeluaran memakai
**Claude API** (vision + structured output, model `claude-opus-4-8`).

Cara pakai:

1. Buat API key di [console.anthropic.com](https://console.anthropic.com).
2. Buka tab **Scan AI** → tempel API key (tersimpan di Firestore akun Anda,
   tersinkron antar perangkat). Alternatif: bake saat build dengan
   `--dart-define=ANTHROPIC_API_KEY=sk-ant-...`.
3. Pilih gambar → **Scan dengan AI** → review hasil (jenis, nominal, tanggal,
   akun, kategori, rincian item) → **Simpan Transaksi**.

Catatan teknis: gambar di-resize maks 1568px & dikompres JPEG (paket `image`)
sebelum dikirim base64 ke `POST /v1/messages`; respons dipaksa berbentuk JSON
via `output_config.format` (json_schema), termasuk hint akun (mis. bayar pakai
GoPay → akun "GoPay") dan kategori yang dipetakan ke kategori milikmu.

## Fitur yang diport

- ✅ Auth Firebase Email/Password
- ✅ Dashboard: summary kas, net worth, history, top pengeluaran, chart cash flow (custom paint dengan mode combo/bar/area/line)
- ✅ Catat Pemasukan / Pengeluaran (+ Split Bill otomatis bikin Piutang)
- ✅ **Scan AI**: struk belanja / QRIS / invoice / bukti transfer → transaksi otomatis (Claude vision)
- ✅ Mutasi/Transfer antar akun (+ biaya admin opsional, pie distribusi liquid)
- ✅ Investasi (Saham/Crypto/Emas/Reksadana/Tabungan Bank), refresh harga live, jual aset, perhitungan P/L
- ✅ Utang/Piutang dengan tombol Lunas
- ✅ Tagihan Rutin (bulanan/mingguan) + Bayar Sekarang
- ✅ Analisis multi-kategori dengan filter akun & rentang tanggal
- ✅ Backup/Restore CSV (format sama dengan React export)
- ✅ Manajemen Akun, Kategori, Custom Budget

## Desain UI

Tema **retro minimalism**: latar kertas hangat (`#F5F1E6`), tinta pekat
(`#22201B`) dengan border 1px, aksen pudar ala cetakan lawas (mustard, lumut,
bata, slate), tipografi monospace + label kapital ber-letter-spacing, dan
bayangan keras kecil hanya pada elemen interaktif. Token warna ada di
`lib/config/constants.dart` (`RetroColor`), komponen dasar di
`lib/widgets/common/retro.dart` (`RetroBox`, `RetroButton`,
`RetroSectionTitle`, dst).

## Lisensi
Personal use, ikuti repo asli kieWallet.
