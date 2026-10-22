# Project: Flutter Expense Tracker Upgrade & Refactor

## Architecture
Flutter Expense Tracker architecture with Provider state management, Firebase Firestore backend, and native Android services.
- **Data Layer**:
  - `TransactionModel` (`lib/models/transaction.dart`): Transaction entity extended with `paidByUserId`, `paidByName`, `splitType`, `splitAmounts`.
  - `FamilyModel` & `ExpenseShare` (`lib/models/`): Family and debt-sharing data structures.
  - `TransactionProvider`: Manages personal and family transaction streams, sync, and adaptive quick log exposure.
  - `FamilyProvider` & `SettingsProvider`: Family state and application configuration (wake-word, theme, currency).
- **Service Layer**:
  - `AdaptiveQuickLogService` (`lib/services/adaptive_quick_log_service.dart`): Frequency-recency scoring algorithm.
  - `PdfStatementService` (`lib/services/pdf_statement_service.dart`): Duration filters (1D, 1W, 1M, 1Y, Custom) and PDF generation.
  - `WakeWordForegroundService` (Android Native Kotlin) + `WakeWordService` (Dart): Custom wake-word background listening and overlay trigger.
  - `FamilyService` & `ExpenseShareService`: Invite codes, atomic join transaction, split calculation (cents remainder allocation), and debt settlement (min-cash-flow).
- **UI Layer**:
  - `HomeScreen`: Adaptive quick logs grid.
  - `AddTransactionScreen`: Redesigned frictionless UI with inline description, visual category selector, and strict validation.
  - `CalculatorScreen`: Integrated flow with mandatory description & category prompt before save.
  - `VoiceAssistantModal`: Classic voice modal overlay with dot-matrix visualizer, real-time transcription, and transaction confirmation card.
  - `StatementExportModal`: Duration filter chips and PDF download/share actions.

## Feature Inventory
| # | Feature | Description | Milestone | Source |
|---|---------|-------------|-----------|--------|
| 1 | Adaptive Quick Logs | Frequency & recency weighted scoring, removing hardcoded preset precedence once data exists | M1 | ORIGINAL_REQUEST §R1 |
| 2 | Classic Voice Modal Overlay | Replace chat UI with classic voice modal, visualizer, live transcript, and expense confirmation card | M2 | ORIGINAL_REQUEST §R2 |
| 3 | Wake-Word Background Service | Android foreground service with microphone type for custom wake-word listening even when app is backgrounded | M2 | ORIGINAL_REQUEST §R2 |
| 4 | Formatted PDF Statement Export | PDF generation with duration filters (1D, 1W, 1M, 1Y, Custom), period summaries, category breakdowns, and formatted currency | M3 | ORIGINAL_REQUEST §R3 |
| 5 | Redesigned Add Expense Screen | Frictionless UI with inline description, visual category selector, and strict validation | M4 | ORIGINAL_REQUEST §R4 |
| 6 | Calculator Validation Flow | Prompt and enforce description and category before saving expense from calculator | M4 | ORIGINAL_REQUEST §R4 |
| 7 | Multi-User Family Invite & Join | Fix `addMember` admin check so join by invitation code succeeds reliably without auth collision | M5 | ORIGINAL_REQUEST §R5 |
| 8 | Real-Time Family Sync | Synchronize shared expenses across all family member devices via Firestore streams | M5 | ORIGINAL_REQUEST §R5 |
| 9 | Accurate Expense Splitting & Debt Settlement | Remainder cents allocation for equal split, floating-point tolerance, and min-cash-flow debt settlement | M5 | ORIGINAL_REQUEST §R5 |
| 10 | Comprehensive Test Suite & Clean Analysis | Unit and widget tests covering R1-R5, clean `flutter analyze` | M6 / E2E | ORIGINAL_REQUEST §AC |

## Milestones
| # | Name | Scope | Dependencies | Status |
|---|------|-------|-------------|--------|
| M1 | Adaptive Quick Logs | `AdaptiveQuickLogService`, `home_screen.dart` quick log integration, unit tests | none | IN_PROGRESS (worker_m1: 53b857b5) |
| M2 | Voice Assistant & Wake-Word | `VoiceAssistantModal` classic overlay, `WakeWordForegroundService` (Android), `SettingsProvider` wake-word config | none | IN_PROGRESS (worker_m2: faae3f1d) |
| M3 | Formatted PDF Statement Export | `PdfStatementService`, `StatementExportModal`, daily log export trigger, unit tests | none | IN_PROGRESS (worker_m3: 5044e41a) |
| M4 | Add Expense & Calculator Flow | Redesigned `AddTransactionScreen`, `CalculatorScreen` prompt modal & strict validation, widget tests | none | IN_PROGRESS (worker_m4: 2bc8f0c5) |
| M5 | Family Module Stabilization | Fix `FamilyService.joinFamilyByCode`, `ExpenseShareService` math & settlement, `TransactionProvider` family sync, `TransactionModel` payer fields, remove anonymous auth hijack, unit tests | none | IN_PROGRESS (worker_m5: 87e2e71e) |
| M6 | Test Suite & Code Quality | Comprehensive test suite (Tiers 1-4), fix analysis issues (`flutter analyze`), publication of `TEST_READY.md` | M1-M5 | PLANNED |

## Code Layout & Write Boundaries
- **M1**: `lib/services/adaptive_quick_log_service.dart`, `lib/home_screen.dart`, `test/unit/adaptive_quick_logs_test.dart`
- **M2**: `lib/widgets/voice_assistant_modal.dart`, `lib/services/wake_word_service.dart`, `android/app/src/main/AndroidManifest.xml`, `android/app/src/main/kotlin/com/example/expense_tracker/WakeWordForegroundService.kt`, `android/app/src/main/kotlin/com/example/expense_tracker/MainActivity.kt`, `lib/providers/settings_provider.dart`, `lib/screens/settings_screen.dart`, `test/unit/wake_word_test.dart`
- **M3**: `lib/services/pdf_statement_service.dart`, `lib/widgets/statement_export_modal.dart`, `lib/screens/daily_log_screen.dart`, `test/unit/pdf_statement_filter_test.dart`
- **M4**: `lib/add_transaction_screen.dart`, `lib/screens/calculator_screen.dart`, `lib/widgets/calculator_expense_prompt_sheet.dart`, `test/widget/calculator_flow_test.dart`, `test/widget/add_expense_screen_test.dart`
- **M5**: `lib/models/transaction.dart`, `lib/services/family_service.dart`, `lib/services/expense_share_service.dart`, `lib/providers/family_provider.dart`, `lib/providers/transaction_provider.dart`, `lib/main.dart`, `firestore.rules`, `pubspec.yaml`, `test/unit/family_split_settlement_test.dart`
