<div align="center">
  <img src="assets/icon/icon.png" width="120" alt="EDUvian Logo"/>
  <h1>EDUvian</h1>
  <p><strong>The Ultimate Academic Portal for East Delta University Students</strong></p>
</div>

EDUvian is a comprehensive, modern, and beautiful Flutter-based mobile application designed specifically for the students of East Delta University (EDU). It seamlessly integrates academic utilities, real-time communication, and schedule management into a single, beautifully designed application featuring glassmorphism and smooth micro-animations.

---

## 🎯 Project Objective
This project was built to solve the fragmentation of university student life. Instead of relying on multiple platforms for chatting, routine checking, and GPA calculation, EDUvian centralizes everything specifically tailored to the batch and section of the student. 

---

## ✨ Core Features & Functionality

### 1. Exclusive Authentication & Automated Parsing
- **What it does**: Allows users to sign up and log in securely using Firebase Authentication (Email/Password or Google Sign-In). 
- **How it works**: The app uses domain restriction to ensure only `@eastdelta.edu.bd` emails can register. Furthermore, it parses the student ID from the email (e.g., extracting "012" to determine they are from batch 12) and automatically assigns them to their correct academic groups.

### 2. Real-Time Chat System (Group & Direct)
- **What it does**: Connects students instantly with their classmates. 
- **How it works**: 
  - **Section Chats**: Once a user sets their academic info (e.g., Section `2`), they are automatically placed in a specific Firestore chat room (e.g., `7DCSE.2`). 
  - **Lazy Loading (Pagination)**: To save Firebase bandwidth, the chat initially loads the 50 newest messages. As the user scrolls up, it seamlessly fetches older messages using Firebase's `limit()` and `startAfter()` stream logic.
  - **Edit & Delete**: Users can long-press their own messages to edit or delete them. This updates the Firestore document instantly, syncing across all users' devices.
  - **Direct Messages**: Students can create custom private or group chats by searching for other registered members.

### 3. Academic Calculators (GPA, CGPA, Credits)
- **What it does**: Helps students track their academic performance dynamically.
- **How it works**: Powered by Riverpod state management. Users can dynamically add new courses, select their grades from dropdowns, and input credit hours. The app listens to these state changes and instantly recalculates the total GPA or CGPA on the fly without needing a database connection.

### 4. Routine & Schedule Management
- **What it does**: Displays the weekly class schedule for the student's specific section.
- **How it works**: Fetches data from Firestore collections (`routines/{sectionId}/classes`). It maps the data into `ClassEntry` objects and displays them on a beautifully animated UI, sorted by day and time.

### 5. Push Notifications
- **What it does**: Notifies users of new messages or academic announcements even when the app is closed.
- **How it works**: Uses Firebase Cloud Messaging (FCM). The app subscribes users to specific topics based on their section (e.g., `topic_7DCSE.2`), ensuring they only receive notifications relevant to their class.

---

## 🛠️ Technical Architecture

The app is built using **Feature-First Clean Architecture**. This means the code is divided by features (Auth, Chat, Routine) rather than layers (Models, Views, Controllers), making it highly scalable.

### Tech Stack
- **Framework**: [Flutter](https://flutter.dev/) (Dart)
- **State Management**: [Riverpod 2.0](https://riverpod.dev/). Used for dependency injection and managing complex asynchronous states (like Firebase streams).
- **Routing**: [GoRouter](https://pub.dev/packages/go_router). Handles complex deep-linking and stateful bottom navigation (keeping your scroll position when you switch tabs).
- **Backend**: **Firebase** (Auth, Firestore NoSQL Database, Cloud Messaging).
- **Local Storage**: `shared_preferences` to cache user sessions and academic info locally so the app loads instantly.

### Architecture Breakdown
Each feature folder (e.g., `lib/features/chat/`) contains 3 distinct layers:
1. **Domain Layer (`domain/`)**: The core logic. Contains pure Dart code, business entities (e.g., `ChatMessage` class), and abstract repository interfaces. It knows nothing about the UI or Firebase.
2. **Data Layer (`data/`)**: The bridge to the outside world. Implements the domain repositories. It connects to Firestore (`chat_remote_datasource.dart`), parses JSON into models, and handles network logic.
3. **Presentation Layer (`presentation/`)**: The UI. Contains Flutter widgets, screens, and Riverpod providers. It listens to the domain layer and reacts to state changes (e.g., showing a loading spinner while messages fetch).

---

## 📁 Directory Structure Overview

```text
lib/
├── core/
│   ├── models/           # Shared models across the whole app
│   ├── router/           # GoRouter configuration (Navigation)
│   ├── theme/            # App-wide color palettes (Dark/Light modes)
│   ├── utils/            # Helper functions (Time formatter, Batch parser)
│   └── widgets/          # Global reusable UI components (GlassContainers)
│
└── features/
    ├── auth/             # Login, Sign-up, Email domain validation
    ├── calculator/       # GPA, CGPA calculation logic & UI
    ├── chat/             # Real-time Firestore messaging, Pagination, Edit/Delete
    ├── dashboard/        # Main Layout & Bottom Navigation Bar
    ├── routine/          # Schedule fetching and displaying
    └── settings/         # Managing user profile and academic info
```

---

## 🔐 Security & Database Rules

The app uses strict **Firestore Security Rules** to ensure student data is safe:
- **Authentication Check**: No one can read or write to the database unless they are logged in.
- **Chat Validation**: A user can only write a message to a chat room if their `uid` is in the `memberIds` array of that chat room.
- **Message Ownership**: A user can only `update` or `delete` a specific message if the `senderId` matches their own `uid`.

---

## 🚀 Getting Started (Installation)

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
   - Use the [FlutterFire CLI](https://firebase.flutter.dev/docs/cli/) to configure your project (`flutterfire configure`).
   - Ensure Auth, Firestore, and FCM are enabled in your Firebase console.

4. **Run the app:**
   ```bash
   flutter run
   ```

## 🤝 Contributing
Contributions, issues, and feature requests are always welcome! Feel free to check the issues page or submit a Pull Request.

## 📄 License
This project is licensed under the MIT License.
