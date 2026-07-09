# EDUvian

EDUvian is a comprehensive Flutter-based mobile application designed for students to manage their academic life efficiently. It offers tools for calculating grades, managing class routines, and staying updated with real-time notifications, all within a sleek and responsive user interface.

## 🚀 Features

- **Authentication**: Secure Login and Sign-up system powered by Firebase Authentication (including Google Sign-In).
- **Dashboard**: A central hub providing a quick overview of academic progress, upcoming routines, and important messages.
- **Academic Calculators**: 
  - **GPA Calculator**: Easily calculate your Grade Point Average for the current semester.
  - **CGPA Calculator**: Track your Cumulative Grade Point Average across multiple semesters.
  - **Credit Tracking**: Keep track of completed credits.
- **Routine Management**: View and manage daily class schedules and routines.
- **Push Notifications**: Real-time announcements and messages using Firebase Cloud Messaging (FCM).
- **Settings & Profile**: Customizable user settings for a personalized experience.

## 🛠️ Tech Stack & Architecture

- **Framework**: [Flutter](https://flutter.dev/) (Dart)
- **State Management**: [Riverpod](https://riverpod.dev/) for robust and scalable state handling.
- **Routing**: [GoRouter](https://pub.dev/packages/go_router) for declarative routing.
- **Backend & Cloud**:
  - **Firebase Authentication**: User identity and secure access.
  - **Cloud Firestore**: Real-time NoSQL database for storing routines, messages, and user data.
  - **Firebase Cloud Messaging**: Sending and receiving push notifications.
- **Local Storage**: `shared_preferences` for caching local user settings.
- **UI & Animations**: `google_fonts` for typography and `flutter_animate` for smooth micro-animations.

## 📁 Project Structure

```text
lib/
├── core/         # Core utilities, constants, and themes
├── model/        # Data models for the application
├── screen/       # UI Screens (Login, Dashboard, Routine, GPA/CGPA, Settings)
├── ui/           # Reusable custom UI components and widgets
├── main.dart     # Application entry point
└── firebase_options.dart # Firebase configuration
```

## ⚙️ Getting Started

### Prerequisites

- Flutter SDK (v3.7.2 or higher)
- Dart SDK
- Android Studio / Xcode for running emulators
- A Firebase Project (with Auth, Firestore, and Cloud Messaging enabled)

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/monabbor-hossen/EDUvian.git
   cd EDUvian
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase:**
   Make sure you have your `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) configured correctly if you are setting up your own Firebase environment.

4. **Run the app:**
   ```bash
   flutter run
   ```

## 🤝 Contributing

Contributions, issues, and feature requests are welcome! 
Feel free to check the issues page if you want to contribute.

## 📄 License

This project is licensed under the MIT License.
