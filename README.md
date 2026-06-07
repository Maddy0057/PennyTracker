# PennyTracker

PennyTracker is a modern, feature-rich personal expense tracking application built with Flutter. It helps you manage your finances with ease, featuring automated transaction parsing and intuitive visualizations.

## 📱 App Screenshots

<table style="width:100%; text-align:center;">
  <tr>
    <th width="33%">Light Mode Home</th>
    <th width="33%">Dark Mode Home</th>
    <th width="33%">Analytics Dashboard</th>
  </tr>
  <tr>
    <td><img src="assets/screenshots/Screenshot_1780854693.png" alt="Light Mode Home"></td>
    <td><img src="assets/screenshots/Screenshot_1780854698.png" alt="Dark Mode Home"></td>
    <td><img src="assets/screenshots/Screenshot_1780854820.png" alt="Analytics Dashboard Top"></td>
  </tr>
  <tr>
    <th width="33%">Transaction History</th>
    <th width="33%">Visual Insights</th>
    <th width="33%">Settings & Tools</th>
  </tr>
  <tr>
    <td><img src="assets/screenshots/Screenshot_1780854717.png" alt="Transactions Page"></td>
    <td><img src="assets/screenshots/Screenshot_1780854866.png" alt="Analytics Dashboard Bottom"></td>
    <td><img src="assets/screenshots/Screenshot_1780854876.png" alt="Settings Page"></td>
  </tr>
</table>

## 🚀 Features

- **Automated Parsing:** Support for parsing transaction statements (including PhonePe, GPay, and Paytm).
- **Interactive Charts:** Visualize your spending patterns with `fl_chart`.
- **Smart Categorization:** Automatically categorize your expenses using intelligent matching.
- **Local Storage:** Fast and secure data persistence using Hive (Local-first, private).
- **Modern UI:** Clean, responsive design with full Light and Dark mode support.
- **Notifications:** Keep track of your budget with local notifications.
- **Data Portability:** Export/Import PDF statements and full backup/restore functionality.

---

## 🛠️ How it Works

### 🤖 Automated Transaction Parsing
PennyTracker eliminates manual entry by intelligently extracting financial data from multiple sources:
*   **SMS Parsing:** The `SMSParserService` uses sophisticated regular expressions to scan incoming bank and UPI notifications. It automatically extracts the **amount**, **merchant**, and **date**, while filtering out non-transactional messages.
*   **PDF Statement Import:** Users can bulk-import history from bank or UPI (PhonePe, GPay, Paytm) PDF statements. The `PdfImportService` utilizes `syncfusion_flutter_pdf` for text extraction and specialized logic to handle various bank formats, including automatic duplicate detection.

### 📦 Data Persistence with Hive
For storage, the app leverages **Hive**, a lightweight and blazing fast key-value database written in pure Dart:
*   **Performance:** Hive is highly optimized for mobile, providing near-instant read/write operations without the complexity of SQL.
*   **Type Safety:** All data—including transactions, budgets, and user categories—is stored using generated TypeAdapters, ensuring structural integrity.
*   **Local-First:** All financial data stays strictly on your device, ensuring maximum privacy and offline availability.

### 🏗️ State Management with Riverpod
The application’s reactive UI is powered by **Riverpod**, ensuring a smooth and predictable user experience:
*   **Reactive UI:** Screens automatically rebuild when transactions are added or budgets are updated, keeping everything in sync.
*   **Decoupled Logic:** Business logic is isolated in providers (e.g., `ExpenseProvider`, `AnalyticsProvider`), making the codebase modular and easier to maintain.
*   **Efficiency:** Riverpod's caching and provider-scoping ensure that only the necessary parts of the UI are updated, optimizing battery and performance.

### 📊 Visualizations with fl_chart
Complex financial data is transformed into actionable insights using the **fl_chart** library:
*   **Interactive Charts:** Tap on the Donut Chart to see specific category totals or explore the Bar Chart to identify spending peaks during the week.
*   **Theming:** Every visualization is custom-styled to perfectly match the app's Light and Dark themes, utilizing smooth animations and gradients.
*   **Dynamic Intelligence:** Charts automatically scale and adjust based on the selected filtering period (monthly, weekly, or custom ranges).

---

## 🛠️ Tech Stack

- **Framework:** [Flutter](https://flutter.dev)
- **State Management:** [Riverpod](https://riverpod.dev)
- **Local Database:** [Hive](https://docs.hivedb.dev/)
- **Navigation:** [GoRouter](https://pub.dev/packages/go_router)
- **Styling:** [Google Fonts](https://pub.dev/packages/google_fonts), [Flutter Animate](https://pub.dev/packages/flutter_animate)

## 📦 Getting Started

### Prerequisites

- Flutter SDK (^3.10.7)
- Dart SDK

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/Maddy0057/PennyTracker.git
   ```
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Run the application:
   ```bash
   flutter run
   ```

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.
