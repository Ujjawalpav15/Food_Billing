# 📊 Mess Billing Manager — Progress & Details

> **Project:** Offline Mess Billing Manager (Flutter + Hive)
> **Target:** Small hostel messes, food shops near colleges in Nepal
> **Platform:** Android (primary), offline-first, single-device

---

## 🗂️ Module Breakdown

| # | Module | Description | Status |
|---|--------|-------------|--------|
| **M1** | Foundation & Data Layer | pubspec, Hive models, repositories, billing engine, unit tests | ✅ Complete |
| **M2** | App Shell & Navigation | main.dart, theme, bottom nav, routing, app structure | 🔄 Next Up |
| **M3** | Shop Settings & Onboarding | Owner profile, shop name, prices, logo, first-run setup | ⬜ Pending |
| **M4** | Customer Management | Add/edit/deactivate customers, search, customer list screen | ⬜ Pending |
| **M5** | Menu Management | Add/edit/deactivate menu items, categories, prices | ⬜ Pending |
| **M6** | Daily Meal Entry | Date picker, quick meal recording per customer, corrections | ⬜ Pending |
| **M7** | Customer Ledger | Itemized ledger per customer, date filters, balance view | ⬜ Pending |
| **M8** | Monthly Billing | Generate statements, finalize bills, reopen/amend bills | ⬜ Pending |
| **M9** | Payment Management | Record payments, partial/full/overpayment, payment history | ⬜ Pending |
| **M10** | Dashboard | Summary stats, today's progress, quick actions | ⬜ Pending |
| **M11** | PDF & Export | PDF bill generation, CSV export, share functionality | ⬜ Pending |
| **M12** | Backup & Restore | Local backup to file, restore with validation | ⬜ Pending |

---

## 🏗️ Architecture Decisions

### State Management
- **Provider** — lightweight, appropriate for this scale

### Database
- **Hive** (`hive_ce` — community edition, actively maintained)
- Separate boxes per model; TypeAdapters generated via build_runner

### Money Handling
- All monetary values stored as **integers in Paisa** (1 NPR = 100 Paisa)
- No floating-point arithmetic in billing calculations

### Folder Structure
```
lib/
├── core/
│   ├── constants/
│   ├── theme/
│   └── utils/
├── data/
│   ├── models/          ← Hive models with TypeAdapters
│   └── repositories/    ← Data access layer
├── domain/
│   └── billing_engine.dart  ← Pure business logic, no UI/Hive deps
├── providers/           ← Provider state classes
├── screens/
│   ├── dashboard/
│   ├── daily_entry/
│   ├── customers/
│   ├── menu/
│   ├── billing/
│   ├── payments/
│   └── settings/
└── widgets/             ← Reusable UI components
```

### Hive Type IDs

| Model | TypeId |
|-------|--------|
| ShopProfile | 0 |
| Customer | 1 |
| MenuItem | 2 |
| MealEntry | 3 |
| AdditionalItemEntry | 4 |
| Payment | 5 |
| Adjustment | 6 |
| MonthlyBill | 7 |
| AuditEntry | 8 |

---

## 📦 Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| `hive_ce` | ^2.x | Local NoSQL database |
| `hive_ce_flutter` | ^2.x | Flutter Hive integration |
| `hive_ce_generator` | dev | TypeAdapter code gen |
| `build_runner` | dev | Code generation |
| `provider` | ^6.x | State management |
| `uuid` | ^4.x | Stable unique IDs |
| `intl` | ^0.19 | Date/number formatting |
| `pdf` | ^3.x | PDF generation |
| `printing` | ^5.x | PDF preview & print |
| `share_plus` | ^10.x | Share files |
| `path_provider` | ^2.x | File system paths |
| `image_picker` | ^1.x | Shop logo upload |
| `file_picker` | ^8.x | Backup restore |

---

## 🧪 Test Coverage Plan

- [ ] Billing engine: both meals consumed
- [ ] Billing engine: single meal
- [ ] Billing engine: skipped days
- [ ] Billing engine: multiple additional items
- [ ] Historical price preservation after menu edit
- [ ] Edit/delete incorrect entries, recalc totals
- [ ] Partial payments and balances
- [ ] Overpayment → customer credit
- [ ] Month-end totals
- [ ] Reopen finalized bill
- [ ] Persistence after restart
- [ ] Backup and restore roundtrip
- [ ] Inactive customers with historical data

---

## 📋 Module 1 — Foundation & Data Layer

**Goal:** Set up all data models, Hive boxes, repositories, and billing engine with passing unit tests. No UI.

### Files to Create
- `pubspec.yaml` — updated with all dependencies
- `lib/core/constants/app_constants.dart`
- `lib/data/models/*.dart` — 9 Hive models + generated adapters
- `lib/data/repositories/*.dart` — 8 repositories
- `lib/domain/billing_engine.dart`
- `test/billing_engine_test.dart`

### Status
- [x] Architecture planned
- [x] pubspec.yaml updated
- [x] Models created (9 Hive models + generated adapters)
- [x] Repositories created (9 repositories)
- [x] Billing engine created
- [x] Unit tests written and passing (29/29 ✅)

---

## 📋 Module 2 — App Shell & Navigation
_Pending Module 1 completion_

---

## 📝 Change Log

| Date | Module | Description |
|------|--------|-------------|
| 2026-11-06 | Planning | Project analyzed, architecture designed, modules defined |
| 2026-11-06 | M1 | pubspec.yaml updated with all dependencies |
| 2026-11-06 | M1 | All 9 Hive data models + TypeAdapters generated |
| 2026-11-06 | M1 | All 9 repositories created |
| 2026-11-06 | M1 | BillingEngine (pure Dart, no Hive) created |
| 2026-11-06 | M1 | 29/29 unit tests passing ✅ |
| 2026-11-06 | M1 | README.md written |

