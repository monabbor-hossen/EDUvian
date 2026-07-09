# EDUvian

A modern Flutter application designed with a beautiful user interface and built using a robust tech stack.

## 🚀 Features

- **Authentication**: Secure login and signup via Firebase Auth and Google Sign-In.
- **Database**: Real-time data sync using Cloud Firestore.
- **Push Notifications**: Integrated Firebase Cloud Messaging (FCM) and local notifications.
- **State Management**: Reactive and robust state management powered by Riverpod.
- **Routing**: Deep linking and declarative routing with GoRouter.
- **Theming**: Dynamic Light and Dark modes with a custom color scheme (Maroon/Red seed color) using Google Fonts (Inter).
- **Animations**: Smooth micro-animations using Flutter Animate.

## 🛠️ Tech Stack

- **Framework**: [Flutter](https://flutter.dev/) (SDK ^3.7.2)
- **State Management**: [Riverpod](https://riverpod.dev/) (`flutter_riverpod`)
- **Routing**: [GoRouter](https://pub.dev/packages/go_router)
- **Backend Services**: [Firebase](https://firebase.google.com/)
  - Firebase Core
  - Firebase Auth
  - Cloud Firestore
  - Firebase Messaging
- **UI/UX**:
  - `google_fonts`
  - `flutter_animate`
  - `cupertino_icons`

## 📦 Getting Started

### Prerequisites

- Flutter SDK (version ^3.7.2)
- Android Studio / VS Code
- A Firebase project with Auth and Firestore enabled

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/monabbor-hossen/EDUvian.git
   cd EDUvian
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Firebase Configuration**
   - Configure Firebase for this project using the [FlutterFire CLI](https://firebase.flutter.dev/docs/cli/).
   - Ensure you have the `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) in their respective directories.

4. **Run the App**
   ```bash
   flutter run
   ```

## 🏗️ Project Structure

- `lib/core/` - Core services like NotificationService.
- `lib/model/` - Data models and router configurations.
- `lib/main.dart` - Application entry point, initializing Firebase, Notifications, and configuring the app theme.

## 🎨 Design

The app uses `ThemeMode.system` by default to adapt to your device's preferences. It defines a custom `ColorScheme` seeded from `rgb(107, 0, 50)`.

## 📄 License

This project is licensed under the MIT License.
