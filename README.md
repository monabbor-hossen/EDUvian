<div align="center">
  <img src="assets/icon/icon.png" width="120" alt="EDUvian Logo"/>
  <h1>EDUvian</h1>
  <p><strong>The Ultimate Academic Portal for East Delta University Students</strong></p>
</div>

EDUvian is a comprehensive, modern, and beautiful Flutter-based mobile application designed specifically for the students of East Delta University (EDU). It seamlessly integrates academic utilities, real-time communication, and schedule management into a single, beautifully designed application featuring glassmorphism and smooth micro-animations.

---

## ✨ Key Features

- **Exclusive Authentication**: Secure Login and Sign-up system powered by Firebase Authentication (Email & Google Sign-In) explicitly restricted to `@eastdelta.edu.bd` domain accounts.
- **Automated Academic Parsing**: Automatically identifies Regular (BSC in CSE) and Evening (EBSC in CSE) batches by parsing your institutional email format.
- **Section-Based Group Chats**: Automatically places students into dedicated, real-time group chats based on their exact batch and section (e.g., `7DCSE.2`) powered by Cloud Firestore.
- **Academic Calculators**: 
  - **GPA Calculator**: Calculate your Grade Point Average for the current semester effortlessly.
  - **CGPA Calculator**: Track your Cumulative Grade Point Average across multiple semesters.
  - **Credit Tracking**: Keep an accurate record of completed academic credits.
- **Routine Management**: A cloud-synced, real-time class routine and schedule manager for your specific batch.
- **Push Notifications**: Real-time announcements and class alerts via Firebase Cloud Messaging (FCM) using topic-based subscription routing.
- **Customizable UI/UX**: State-of-the-art UI featuring Light & Dark modes, glassmorphic containers, and fluid animations.

## 🛠️ Tech Stack

- **Framework**: [Flutter](https://flutter.dev/)
- **Language**: Dart
- **State Management**: [Riverpod 2.0](https://riverpod.dev/) (using `StateProvider`, `FutureProvider`, and `AsyncValue`)
- **Routing**: [GoRouter](https://pub.dev/packages/go_router) with `StatefulShellRoute` for seamless bottom navigation.
- **Backend (Firebase)**:
  - **Authentication**: Managing exclusive university email sign-ins.
  - **Cloud Firestore**: Real-time NoSQL database for saving routines, chat messages, and user onboarding state with strict security rules.
  - **Cloud Messaging (FCM)**: Push notifications.
- **Local Cache**: `shared_preferences` for lightning-fast session resumption.
- **UI Libraries**: `google_fonts` for beautiful typography, `flutter_animate` for UI transitions.

## 📐 Clean Architecture

EDUvian follows a strictly modular **Feature-First Clean Architecture**, making the codebase highly scalable and easily maintainable.

```text
lib/
├── core/
│   ├── models/           # Shared models (e.g., AcademicInfo, StudentBatchModel)
│   ├── router/           # GoRouter configuration
│   ├── services/         # FCM and third-party wrappers
│   ├── theme/            # App-wide color palettes and Dark/Light modes
│   ├── utils/            # Utilities (e.g., BatchParser, Validators)
│   └── widgets/          # Global reusable UI (GlassContainer, AppBackground)
│
└── features/
    ├── auth/             # Sign-in, Sign-up, Domain validation
    ├── calculator/       # GPA, CGPA, and Credit logic
    ├── chat/             # Real-time Firestore group messaging
    ├── dashboard/        # Main Layout, Bottom Nav, Overview Hub
    ├── routine/          # Schedule management
    └── settings/         # User profile, theme toggle, session management
```
*(Inside each feature: `presentation`, `domain`, and `data` layers are strictly separated).*

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (v3.19.0 or higher)
- Dart SDK
- Android Studio / Xcode
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

3. **Configure Firebase (Required):**
   - Use the [FlutterFire CLI](https://firebase.flutter.dev/docs/cli/) to configure your project.
   - Run `flutterfire configure` to generate the `firebase_options.dart` file.
   - Deploy the custom Firestore Security Rules:
     ```bash
     firebase deploy --only firestore:rules
     ```

4. **Run the app:**
   ```bash
   flutter run
   ```

## 🔐 Security & Database Rules

The app strictly relies on Firestore rules to isolate data:
- Only authenticated users can access the database.
- Chat data is secured so only group members can write messages.
- Academic profile fields (`1DCSE`, `7DCSE.2`) belong specifically to the owner's `users/{uid}` document.

## 🤝 Contributing
Contributions, issues, and feature requests are always welcome! Feel free to check the issues page or submit a Pull Request.

## 📄 License
This project is licensed under the MIT License.
