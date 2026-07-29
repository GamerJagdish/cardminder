# CardMinder

CardMinder is a privacy-focused Android application built with Flutter designed to prevent credit and debit card deactivation resulting from inactivity.

Many financial institutions automatically deactivate payment cards if no transaction is performed within a 365-day period. CardMinder tracks transaction dates, calculates countdown deadlines, schedules local notification reminders, and provides a multi-card Android Home Screen widget.

---

## Key Features

- **Modern User Interface**: Designed with a clean light theme, interactive card carousels, dynamic color gradient previews, and structured card lists.
- **Multi-Card Native Android Widget (4x2)**: Displays up to 5 payment cards on the Android Home Screen with real-time countdown counters.
- **365-Day Inactivity Countdown**: Automatically computes remaining days and target deactivation dates based on the most recent transaction date.
- **Scheduled Push Notifications**: Configurable local alerts triggered at 30, 14, 7, and 1 day prior to card deactivation.
- **Notification History Logs**: Dedicated timeline view tracking all generated alerts with unread status indicators.
- **Customization Options**:
  - Personalized header greeting.
  - Configurable widget card capacity (3, 5, 10, or All).
  - Urgency-based widget filtering (All Cards, Less than 90 Days, Less than 30 Days).
  - Sorting options by urgency or card name.
- **Supported Payment Networks**: Full support for Visa, Mastercard, RuPay, American Express, and Discover brand logos.
- **Offline & Private**: Built on Hive local storage with zero server communication, zero telemetry, and zero remote tracking.

---

## Application Architecture

1. **Dashboard (Home Screen)**:
   - User header greeting with edit capability.
   - Interactive payment card carousel with page indicators.
   - Urgency-sorted card list featuring status indicators (Safe, Warning, Urgent).
   - Custom navigation bar with a centered action button for adding cards.
2. **Card Details Screen**:
   - Visual card preview with real-time metadata.
   - Circular progress indicator showing remaining active days.
   - 2x2 metadata grid containing Last Transaction, Deadline, Network, and Expiration.
   - Action button to register a transaction and reset the 365-day timer.
   - Editing and deletion capabilities.
3. **Add and Edit Card Screen**:
   - Interactive live card graphic reflecting form entries in real time.
   - Color gradient theme selector.
   - Form inputs for nickname, last four digits, expiration month and year, and transaction date.
   - Horizontal pill selector for card networks.
4. **Settings Screen**:
   - Controls for widget capacity, urgency filtering, and sort order.
   - Notification master switch and reminder interval toggles.
   - Manual synchronization trigger for widget and reminder updates.
   - Developer information and project links.
5. **Notification Logs Screen**:
   - History of all past reminder notifications with status badges and clear functionality.

---

## Tech Stack

- **Framework**: Flutter (Dart)
- **State Management**: Riverpod
- **Local Database**: Hive
- **Notifications**: flutter_local_notifications
- **Home Screen Widget**: home_widget integration with Android AppWidgetProvider and RemoteViews
- **Timezone Management**: timezone package
- **Vector Graphics**: flutter_svg

---

## Getting Started

### Prerequisites

- Flutter SDK (v3.29.0 or higher)
- Android Studio / Android SDK (API Level 21 or higher)
- Java Development Kit (JDK 17 or higher)

### Installation and Build

1. Clone the repository:
   ```bash
   git clone https://github.com/GamerJagdish/cardminder.git
   cd cardminder
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Run on a connected Android device or emulator:
   ```bash
   flutter run
   ```

4. Build the debug APK:
   ```bash
   flutter build apk --debug
   ```
   The generated APK will be available at `build/app/outputs/flutter-apk/app-debug.apk`.

---

## Testing and Quality Verification

Run the automated test suite:
```bash
flutter test --no-pub --reporter compact
```

Run static code analysis:
```bash
flutter analyze
```

---

## Developer and Project Information

- Developer: **GamerJagdish**
- Repository: [https://github.com/GamerJagdish/cardminder](https://github.com/GamerJagdish/cardminder)

Contributions, issue reports, and feature requests are welcome.

---

## License

This project is licensed under the MIT License. Refer to the LICENSE file for details.
