# 🍽️ Mess Billing Manager

> A fully offline Flutter application for small hostel messes, student food shops, and monthly meal providers in Nepal.

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart)](https://dart.dev)
[![License](https://img.shields.io/badge/License-Private-red)]()
[![Platform](https://img.shields.io/badge/Platform-Android-green?logo=android)]()

---

## 📖 Overview

Mess owners in Nepal currently record student meals and extra purchases in notebooks and calculate monthly bills by hand. **Mess Billing Manager** digitizes this workflow — tracking daily breakfast and dinner attendance, additional item orders, payments, and generating professional monthly bills — all **100% offline**, no internet required.

### Who is this for?
- Small hostel mess owners
- Local restaurants serving students on monthly billing
- Food shops tracking individual customer consumption

---

## ✨ Features

### ✅ Completed (Modules 1, 2, 3, 4, 5, 6, 7)
- Offline-first local database using Hive CE
- Complete data models with historical price preservation
- Repository-based data access layer
- Pure billing engine with accurate integer arithmetic (Paisa-based)
- Unit tests for billing calculations
- App shell, navigation, and theming (Module 2)
- Shop setup, onboarding wizard, and settings profile management (Module 3)
- Customer management: active/inactive tabs, live search, add/edit modal, details screen, and history-safe deactivation (Module 4)
- Menu management: categories, units, price configuration in NPR/Paisa, default seeds, and order-safe deactivation (Module 5)
- Daily meal entry: date picker, fast meal matrix, breakfast/dinner toggles, price snapshots, extras stepper, and bulk actions (Module 6)
- Customer ledger: itemized chronological records, running balance, month & date range filtering, charges vs payments breakdown (Module 7)

### 🔄 In Progress
- Monthly bill generation and finalization (Module 8)

### 📋 Planned
- Payment recording (partial, full, overpayment → credit) (Module 9)
- Dashboard with daily progress (Module 10)
- PDF bill generation & sharing (Module 11)
- Local backup & restore (Module 12)
- CSV export
- Local backup & restore

---

## 🏗️ Architecture

```
lib/
├── core/
│   ├── constants/        # App-wide constants, Hive box names, type IDs
│   ├── theme/            # App theme configuration
│   └── utils/            # Money formatting, date helpers
├── data/
│   ├── models/           # Hive data models (9 entities)
│   └── repositories/     # Data access layer (one repo per model)
├── domain/
│   └── billing_engine.dart  # Pure business logic, no UI/DB deps
├── providers/            # Provider state management
├── screens/              # Feature screens
│   ├── dashboard/
│   ├── daily_entry/
│   ├── customers/
│   ├── menu/
│   ├── billing/
│   ├── payments/
│   └── settings/
└── widgets/              # Reusable UI components
```

### Key Design Decisions

| Decision | Choice | Reason |
|----------|--------|--------|
| Database | Hive CE | Offline-first, fast, well-maintained |
| State Management | Provider | Lightweight, appropriate for scale |
| Money arithmetic | Integer Paisa | No floating-point rounding errors |
| Historical prices | Snapshot at time of entry | Menu changes don't affect old bills |
| Customer deletion | Soft deactivate only | Preserves billing history |
| Payment records | Soft void only | Maintains audit trail |

---

## 📦 Data Models

| Model | Description |
|-------|-------------|
| `ShopProfile` | Owner and shop configuration |
| `Customer` | Customer records (soft-deactivate) |
| `MenuItem` | Menu items with categories and prices |
| `MealEntry` | Daily breakfast/dinner attendance |
| `AdditionalItemEntry` | Extra item orders per customer per day |
| `Payment` | Payment records (soft-void) |
| `Adjustment` | Manual adjustments (discount, credit) |
| `MonthlyBill` | Finalized monthly statements |
| `AuditEntry` | Correction audit log |

---

## 💰 Billing Formula

```
Meal charges        = (breakfast count × price) + (dinner count × price)
Additional charges  = Σ (quantity × unit_price_at_time_of_entry)
Total charges       = meal charges + additional charges + adjustments
Outstanding balance = previous balance + total charges − payments received
```

> **All prices are recorded at the time of entry.** Changing a menu price later does NOT affect historical charges.

---

## 🛠️ Tech Stack

| Package | Version | Purpose |
|---------|---------|---------|
| `hive_ce` | ^2.9 | Local NoSQL database |
| `hive_ce_flutter` | ^2.2 | Flutter Hive integration |
| `provider` | ^6.1 | State management |
| `uuid` | ^4.5 | Stable unique IDs |
| `intl` | ^0.19 | Date & number formatting |
| `pdf` | ^3.11 | PDF generation |
| `printing` | ^5.13 | PDF preview & share |
| `share_plus` | ^10.1 | File sharing |
| `path_provider` | ^2.1 | File system access |
| `image_picker` | ^1.1 | Shop logo upload |
| `file_picker` | ^8.1 | Backup restore |

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK ≥ 3.5.0
- Android device or emulator (Android 5.0+)

### Setup

```bash
# Clone the repository
git clone <repo-url>
cd food_billing

# Install dependencies
flutter pub get

# Generate Hive TypeAdapters
dart run build_runner build --delete-conflicting-outputs

# Run the app
flutter run
```

---

## 🧪 Running Tests

```bash
# Run all tests
flutter test

# Run billing engine tests only
flutter test test/billing_engine_test.dart
```

---

## 📱 Screenshots

> _Coming after Module 2 (UI Shell) is complete_

---

## 🗺️ Development Roadmap

| Module | Description | Status |
|--------|-------------|--------|
| M1 | Foundation & Data Layer | ✅ Complete |
| M2 | App Shell & Navigation | ✅ Complete |
| M3 | Shop Settings & Onboarding | ✅ Complete |
| M4 | Customer Management | ✅ Complete |
| M5 | Menu Management | ✅ Complete |
| M6 | Daily Meal Entry | ✅ Complete |
| M7 | Customer Ledger | ✅ Complete |
| M8 | Monthly Billing | 🔄 Next Up |
| M9 | Payment Management | ⬜ Pending |
| M10 | Dashboard | ⬜ Pending |
| M11 | PDF & Export | ⬜ Pending |
| M12 | Backup & Restore | ⬜ Pending |

---

## 🔮 Future Scope (not in v1)
- Cloud backup & sync
- Multi-device support
- Owner authentication & staff roles
- Online bill delivery to customers
- Multi-shop management

---

## 📄 License

Private — All rights reserved.
