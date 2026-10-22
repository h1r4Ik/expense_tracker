# Original User Request

## 2026-10-16T12:51:24Z

Refactor and upgrade the Flutter Expense Tracker application to provide adaptive quick logs, a classic custom wake-word voice assistant, multi-period PDF statement export, an overhauled Add Expense screen with calculator-prompt flow, and verified multi-user family sync.

Working directory: /home/hardik/Desktop/Hermes/expense_tracker
Integrity mode: development

## Requirements

### R1. Adaptive Quick Logs
Replace the hardcoded quick logs with dynamic, adaptive quick logs computed from the user's transaction frequency and recency. The quick suggestions must update automatically as new expenses are logged.

### R2. Voice Assistant Wake-Word & Classic Modal
Remove the chat-style voice interface and restore the classic voice modal overlay. Implement a configurable custom wake-word detection mechanism using an Android foreground service so the assistant can wake on the user-defined phrase even when the app is backgrounded or closed.

### R3. Formatted PDF Statement & History Export
Implement a downloadable, cleanly styled PDF transaction statement. Support duration filters for:
- Last 1 Day
- Last Week
- Last Month
- One Year
- Custom Date Range
Statements must include period summaries, category breakdowns, timestamps, and formatted currency amounts.

### R4. Redesigned Add Expense Screen & Calculator Flow
Redesign the Add Expense screen from scratch for intuitive, streamlined UX. Integrate the calculator functionality such that when an expense is calculated, the system prompts and requires the expense name/description and category before finalizing the log.

### R5. Multi-User Family Module Stabilization
Audit and fix the multi-user family feature:
- Reliable family group creation, invitation code generation, and joining flow
- Real-time Firestore synchronization of shared expenses across all family member devices
- Accurate expense splitting and settlement calculations between members

## Acceptance Criteria

### Quick Logs
- [ ] Adaptive quick log suggestions update dynamically based on transaction history without hardcoded fallback items taking precedence once data exists.

### Voice Assistant
- [ ] Classic voice assistant modal replaces the chat interface.
- [ ] Wake-word configuration allows the user to specify a custom trigger phrase with background listening capability via an Android foreground service.

### PDF Export
- [ ] PDF generation produces a well-structured document with summary totals and itemized transactions for 1 Day, 1 Week, 1 Month, 1 Year, and Custom Date Range filters.

### Add Expense & Calculator
- [ ] The Add Expense screen provides a polished, frictionless UI.
- [ ] Logging an expense via the calculator requires specifying category/description before the transaction is saved.

### Family & Multi-User
- [ ] Invitation codes can be generated and joined by another user account without authentication or Firestore permission failures.
- [ ] Adding an expense in a shared family group reflects across all family member feeds in real-time.
- [ ] Split calculations and net balances among members compute mathematically correct totals.

### Verification & Code Quality
- [ ] Unit and widget tests cover the adaptive logs algorithm, PDF date filtering, calculator validation flow, and family split calculations.
- [ ] Flutter analysis (`flutter analyze`) executes cleanly without syntax or compilation errors.


## 2026-10-16T13:20:37Z

URGENT USER INSTRUCTION: EXPEDITE IMPLEMENTATION IMMEDIATELY.

The user has explicitly instructed to fast-track:
- Conclude/skip remaining exploratory surveys immediately.
- Dispatch implementation milestones (M1 through M5) concurrently and write the code directly without multi-round deliberations.
- Prioritize rapid delivery: Adaptive Quick Logs, Classic Voice Modal with custom wake word, PDF Statement Export, Redesigned Add Expense UI & Calculator flow, and Multi-user Family sync fixes.
- Run tests and verification immediately upon implementation.
