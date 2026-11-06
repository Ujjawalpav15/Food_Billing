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

### ✅ Completed (Module 1 — Foundation)
- Offline-first local database using Hive CE
- Complete data models with historical price preservation
- Repository-based data access layer
- Pure billing engine with accurate integer arithmetic (Paisa-based)
- Unit tests for billing calculations

### 🔄 In Progress
- App shell, navigation, and theming (Module 2)

### 📋 Planned
- Shop setup & onboarding
- Customer management (add, edit, search, deactivate)
- Menu management with categories
- Daily meal recording (fast entry workflow)
- Customer ledger with date filters
- Monthly bill generation and finalization
- Payment recording (partial, full, overpayment → credit)
- Dashboard with daily progress
- PDF bill generation & sharing
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
| M1 | Foundation & Data Layer | 🔄 In Progress |
| M2 | App Shell & Navigation | ⬜ Pending |
| M3 | Shop Settings & Onboarding | ⬜ Pending |
| M4 | Customer Management | ⬜ Pending |
| M5 | Menu Management | ⬜ Pending |
| M6 | Daily Meal Entry | ⬜ Pending |
| M7 | Customer Ledger | ⬜ Pending |
| M8 | Monthly Billing | ⬜ Pending |
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
