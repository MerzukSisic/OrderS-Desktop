# OrderS — Desktop Aplikacija
**Autor:** Merzuk Šišić (IB220060)  
**Predmet:** Razvoj softvera II  
**Akademska godina:** 2024/2025

---

## 📋 Sadržaj
1. [Opis aplikacije](#opis-aplikacije)
2. [Tehnologije](#tehnologije)
3. [Pokretanje aplikacije](#pokretanje-aplikacije)
4. [Login podaci](#login-podaci)
5. [Build Windows EXE](#build-windows-exe)
6. [Struktura projekta](#struktura-projekta)

---

## 🎯 Opis aplikacije

OrderS desktop aplikacija razvijena je u Flutteru za Windows/macOS i namijenjena je isključivo administratorima kafića. Koristi persistent sidebar navigaciju s IndexedStack arhitekturom — promjena sekcije ne uzrokuje rebuild sidebar-a.

### Funkcionalnosti:

**Dashboard:**
- ✅ Stat kartice — ukupni prihod, broj narudžbi, aktivni stolovi, prosječna vrijednost
- ✅ Revenue Chart — linijski grafikon prihoda po danima (fl_chart)
- ✅ Top 5 najprodavanijih proizvoda
- ✅ Tabela konobara s učinkom
- ✅ Low stock upozorenja

**Upravljanje proizvodima:**
- ✅ Data tabela s pretraživanjem i CRUD akcijama
- ✅ AccompanimentGroupManager — konfiguracija grupa prilagodbi
- ✅ Upravljanje kategorijama s Material ikonama

**Inventar:**
- ✅ Pregled stanja zaliha s filtriranjem po statusu i skladištu
- ✅ AdjustInventoryDialog — dodaj/oduzmi/postavi količinu
- ✅ InventoryLogsDialog — kompletna historija promjena
- ✅ Export PDF inventara (NotoSans font, otvara se u sistemskom pregledaču)

**Nabavka (Procurement):**
- ✅ Kreiranje narudžbi prema dobavljačima
- ✅ Stripe Checkout integracija za kartično plaćanje
- ✅ Automatsko ažuriranje statusa putem webhook-a

**Upravljanje stolovima:**
- ✅ CRUD operacije — kreiranje/uređivanje/brisanje stolova
- ✅ Filtriranje po statusu (Available/Occupied/Reserved)

**Upravljanje skladištima:**
- ✅ CRUD operacije — kreiranje/uređivanje/brisanje skladišta
- ✅ Pregled i upravljanje production inventarom po skladištu

**Upravljanje korisnicima:**
- ✅ CRUD operacije s filtiranjem po ulozi
- ✅ Aktivacija/deaktivacija naloga

**Statistike:**
- ✅ Multi-tab prikaz: prihodi (line chart), top proizvodi (bar chart), peak hours analiza
- ✅ Filtriranje po periodu (7/14/30 dana)
- ✅ Export PDF izvještaja (NotoSans font, otvara se u sistemskom pregledaču)

### Povezani repozitoriji:
- ⚙️ **Backend API:** [OrdersAPI repo]
- 📱 **Mobile aplikacija:** [orders_mobile repo]

---

## 🛠️ Tehnologije

- **Flutter 3.19+** — Cross-platform desktop (Windows/macOS)
- **Provider** — State management (ChangeNotifier pattern)
- **Dio** — HTTP klijent s interceptorima za JWT
- **shared_preferences** — Lokalno čuvanje JWT tokena
- **fl_chart** — Interaktivni grafikoni za statistike
- **pdf + printing** — Generisanje PDF izvještaja s Unicode (NotoSans) fontom

---

## 🚀 Pokretanje aplikacije

### Preduvjeti:
- Flutter SDK 3.19+ s Windows desktop podrškom
- Pokrenuti backend: `docker-compose up --build` u OrdersAPI repou

### Pokretanje iz source koda:
```bash
git clone <URL_OVOG_REPOA>
cd rs2-desktop

flutter pub get

# macOS
flutter run -d macos --dart-define=API_BASE_URL=http://localhost:5220/api --dart-define=SIGNALR_URL=http://localhost:5220/hubs/orders

# Windows
flutter run -d windows --dart-define=API_BASE_URL=http://localhost:5220/api --dart-define=SIGNALR_URL=http://localhost:5220/hubs/orders
```

### Pokretanje prebuilt EXE-a:
```bash
# Ekstraktovati build arhivu (šifra: fit)
7z x fit-build-26-02-22.zip

# Pokrenuti aplikaciju
cd build/windows/x64/runner/Release/
orders_flutter_desktop.exe
```

---

## 🔐 Login podaci

| Email | Lozinka | Uloga |
|---|---|---|
| admin@orders.com | password123 | Admin |

> **Napomena:** Desktop aplikacija je dostupna samo Admin korisnicima. Backend mora biti pokrenut na `localhost:5220`.

---

## 📦 Build Windows EXE

```bash
flutter clean
flutter build windows --release
```

**Lokacija outputa:** `build/windows/x64/runner/Release/`

Build arhiva se nalazi u root folderu repoa: `fit-build-26-02-22.zip` (split arhiva, šifra: `fit`).

---

## 📁 Struktura projekta

```
rs2-desktop/
├── lib/
│   ├── core/
│   │   ├── services/api/          # API servisi
│   │   └── config/                # EnvConfig — dart-define API adresa
│   ├── models/                    # Data modeli
│   ├── providers/                 # State management (Provider)
│   ├── screens/
│   │   ├── auth/                  # Login ekran
│   │   └── admin/                 # Dashboard, Proizvodi, Inventar,
│   │                              # Nabavka, Korisnici, Statistike,
│   │                              # Stolovi, Skladišta
│   ├── widgets/                   # Reusable komponente
│   │   ├── admin_sidebar.dart     # Persistent sidebar navigacija
│   │   └── ...
│   └── main.dart
├── build/windows/x64/runner/Release/  # EXE output
├── fit-build-26-02-22.zip             # Build arhiva (šifra: fit)
└── .env.zip                           # Konfiguracijski fajl (šifra: fit)
```

---

*OrderS — RS2 2024/2025 — Merzuk Šišić — IB220060*