# 💸 Expense Tracker

A feature-rich, cross-platform personal finance management app built with **Flutter** and powered by **Firebase**. Track expenses, manage recurring bills, set savings goals, and get AI-powered voice assistance — all in one place.

---

## ✨ Features

| Feature | Description |
|---|---|
| 📊 **Dashboard & Analytics** | Visual charts (fl_chart) showing spending trends and category breakdowns |
| ➕ **Add Transactions** | Quickly log income and expenses with category tagging |
| 🔁 **Recurring Bills** | Manage subscriptions and scheduled payments automatically |
| 🎯 **Savings Goals** | Set and track financial goals with progress indicators |
| 🗓️ **Daily Log** | View a day-by-day history of all your transactions |
| 🧮 **Built-in Calculator** | In-app calculator for quick computations |
| 🎤 **AI Voice Assistant** | Log expenses hands-free using natural speech (speech_to_text + flutter_tts) |
| 🔒 **Biometric Lock** | Protect your data with fingerprint / face unlock (local_auth) |
| 🔔 **Push Notifications** | Reminders for bills and budget alerts via Firebase Cloud Messaging |
| 🌍 **Localization** | Multi-language support via Flutter localizations |
| ⚙️ **Settings** | Customize themes, currency, and app preferences |
| 🛠️ **Admin Panel** | Administrative view for advanced management |

---

## 🏗️ Architecture

```
lib/
├── main.dart                    # App entry point & Firebase initialization
├── main_screen.dart             # Root navigation shell
├── auth_wrapper.dart            # Authentication state handler
├── home_screen.dart             # Main dashboard with charts & overview
├── add_transaction_screen.dart  # Transaction creation flow
├── app_categories.dart          # Predefined expense categories
├── transaction_item.dart        # Reusable transaction list tile
│
├── models/                      # Data models
│   ├── transaction.dart
│   ├── recurring_expense.dart
│   └── quick_log_item.dart
│
├── screens/                     # Feature screens
│   ├── daily_log_screen.dart
│   ├── recurring_bills_screen.dart
│   ├── savings_goals_screen.dart
│   ├── calculator_screen.dart
│   ├── biometric_lock_screen.dart
│   ├── settings_screen.dart
│   └── admin_panel_screen.dart
│
├── services/                    # Business logic & external integrations
│   ├── ai_voice_assistant.dart
│   ├── voice_service.dart
│   ├── voice_parser.dart
│   ├── notification_service.dart
│   └── biometric_service.dart
│
├── providers/                   # State management (Provider)
├── theme/                       # App theming & color palette
├── utils/                       # Helper utilities
├── widgets/                     # Reusable UI components
└── l10n/                        # Localization ARB files
```

---

## 🛠️ Tech Stack

| Layer | Technology |
|---|---|
| **Framework** | Flutter (SDK `^3.12.2`) |
| **State Management** | Provider `^6.1.5` |
| **Backend / Auth** | Firebase Auth, Cloud Firestore, Firebase Storage |
| **Push Notifications** | Firebase Cloud Messaging + flutter_local_notifications |
| **Charts** | fl_chart `^1.2.0` |
| **Voice** | speech_to_text, flutter_tts |
| **Biometrics** | local_auth `^3.0.2` |
| **Animations** | flutter_animate `^4.5.2` |
| **Fonts** | Google Fonts `^8.2.1` |
| **Localization** | flutter_localizations (intl `^0.20.2`) |
| **Storage** | shared_preferences |
| **Image** | image_picker |
| **Icons** | iconsax |

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK `>=3.12.2`
- Dart SDK `>=3.0.0`
- A Firebase project (with Firestore, Auth, Storage, and FCM enabled)
- Android Studio / VS Code with Flutter plugin

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/your-username/expense_tracker.git
   cd expense_tracker
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase**

   - Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
   - Add Android / iOS apps to the project
   - Download `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
   - Place them in `android/app/` and `ios/Runner/` respectively
   - Update `lib/firebase_options.dart` with your project credentials (or use the FlutterFire CLI)

   ```bash
   # Optional: Use FlutterFire CLI to auto-configure
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```

4. **Run the app**
   ```bash
   flutter run
   ```

---

## 📱 Platform Support

| Platform | Supported |
|---|---|
| Android | ✅ |
| iOS | ✅ |
| Web | ✅ |
| Linux | ✅ |
| macOS | ✅ |
| Windows | ✅ |

---

## 🔐 Firebase Setup Checklist

- [ ] Enable **Email/Password** authentication in Firebase Console
- [ ] Create a **Cloud Firestore** database
- [ ] Enable **Firebase Storage** for image uploads
- [ ] Set up **Firebase Cloud Messaging** for push notifications
- [ ] Configure Firestore **Security Rules** for your data model

---

## 📦 Key Dependencies

```yaml
firebase_core: ^4.13.0
firebase_auth: ^6.5.7
cloud_firestore: ^6.8.0
firebase_messaging: ^16.5.0
provider: ^6.1.5
fl_chart: ^1.2.0
flutter_animate: ^4.5.2
speech_to_text: ^7.3.0
local_auth: ^3.0.2
google_fonts: ^8.2.1
```

---

## 🧪 Running Tests

```bash
flutter test
```

---

## 🤝 Contributing

1. Fork the project
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## 📄 License

This project is private and not published to pub.dev.

---

> Built with ❤️ using Flutter & Firebase
