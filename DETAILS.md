# 📊 Mess Billing Manager — Progress & Details

> **Project:** Offline Mess Billing Manager (Flutter + Hive)
> **Target:** Small hostel messes, food shops near colleges in Nepal
> **Platform:** Android (primary), offline-first, single-device

---

## 🗂️ Module Breakdown

| # | Module | Description | Status |
|---|--------|-------------|--------|
| **M1** | Foundation & Data Layer | pubspec, Hive models, repositories, billing engine, unit tests | ✅ Complete |
| **M2** | App Shell & Navigation | main.dart, theme, bottom nav, routing, app structure | ✅ Complete |
| **M3** | Shop Settings & Onboarding | Owner profile, shop name, prices, logo, first-run setup, profile edit | ✅ Complete |
| **M4** | Customer Management | Add/edit/deactivate customers, search, customer list screen | ✅ Complete |
| **M5** | Menu Management | Add/edit/deactivate menu items, categories, prices | ✅ Complete |
| **M6** | Daily Meal Entry | Date picker, quick meal recording per customer, corrections | ✅ Complete |
| **M7** | Customer Ledger | Itemized ledger per customer, date filters, balance view | 🔄 Next Up |
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
- [x] Theme and AppRoutes configured
- [x] MainShell bottom navigation (5 tabs) created
- [x] Base placeholder screens created

---

## 📋 Module 3 — Shop Settings & Onboarding
- [x] ShopProfileProvider state management
- [x] 3-step OnboardingScreen with validation
- [x] SettingsScreen displaying profile and default meal prices
- [x] EditShopProfileScreen with full edit capabilities

---

## 📋 Module 4 — Customer Management
- [x] CustomerRepository enhanced with `hasHistory` and history-safe `deleteCustomer`
- [x] CustomerProvider state management (search, active/inactive lists, CRUD)
- [x] MultiProvider updated in main.dart
- [x] AddEditCustomerDialog modal sheet with full validation
- [x] CustomerDetailScreen with profile details, copy actions, and status toggling
- [x] CustomersScreen with TabBar (Active vs Inactive) and integrated live search
- [x] Unit tests in customer_management_test.dart

---

## 📋 Module 5 — Menu Management
- [x] MenuItemRepository with `hasHistory`, `deleteMenuItem`, and `seedDefaultsIfEmpty`
- [x] MenuItemProvider state management (category filters, search, active/inactive lists)
- [x] MultiProvider registered in main.dart
- [x] AddEditMenuItemDialog modal sheet with categories, prices in NPR, and unit suggestions
- [x] MenuScreen with Category filter chips, Active/Inactive tabs, and item cards
- [x] Menu navigation tile in SettingsScreen
- [x] Unit tests in menu_management_test.dart

---

## 📋 Module 6 — Daily Meal Entry
- [x] AdditionalItemEntryRepository enhanced with `getAllEntriesForDay`
- [x] DailyEntryProvider state management (date navigation, meal toggles, bulk actions, extra items)
- [x] MultiProvider updated in main.dart
- [x] AddExtraItemsDialog modal sheet with live stepper, totals, and available menu items
- [x] DailyEntryScreen with date navigation, daily summary statistics, bulk operations, and fast meal matrix
- [x] Unit tests in daily_entry_test.dart

---

## 📋 Module 7 — Customer Ledger
_Next Up_

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
| 2026-11-06 | M2 | App shell, navigation, themes, and route constants implemented |
| 2026-11-09 | M3 | Shop profile provider, onboarding wizard, settings and profile editing implemented |
| 2026-11-20 | M4 | Customer provider, customer list with search/tabs, add/edit dialog, detail screen, and tests |
| 2026-11-20 | M5 | Menu provider, category chips, add/edit modal, menu management screen, settings link, and tests |
| 2026-11-20 | M6 | Daily entry provider, date picker, meal matrix, bulk actions, extras modal, and tests |

