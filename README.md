````markdown
# 📝 Task Manager App (Flutter + Firebase)

A modern task management application built with Flutter, Firebase, and MVVM architecture. Users can sign in, create and manage their tasks, toggle dark/light mode, and receive real-time updates.

---

## 🚀 Features

- **User Authentication**
  - Sign up / Sign in with email and password (Firebase Auth)

- **Task Management**
  - Add, edit, delete tasks using a clean bottom sheet interface
  - Task attributes: title, description, due date, completion status
  - Real-time updates using Firestore stream

- **UI & UX**
  - Beautiful Material Design interface
  - Dark mode toggle in AppBar
  - Circular user avatar with logout option

- **Architecture**
  - MVVM (Model-View-ViewModel) for clean code separation
  - State management using `Provider`

- **Database**
  - Tasks stored in Firestore, per user (with `userId`)
  - Uses Firestore collection group queries with indexing

---

## 🛠️ Setup Instructions

### 1. Clone the Repository

```bash
git clone https://github.com/your-username/task-manager-flutter.git
cd task-manager-flutter
````

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Configure Firebase

* Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
* Add Android/iOS/web support and download the `google-services.json` / `GoogleService-Info.plist`
* Place it in the appropriate `/android/app/` or `/ios/Runner/` folder
* Run:

```bash
flutterfire configure
```

This will generate the `firebase_options.dart` file.

### 4. Create Firestore Index

To support the Firestore query:

```dart
.collectionGroup('tasks')
.where('userId', isEqualTo: userId)
.orderBy('dueDate')
```

You must create a **composite index** in Firestore:

* Go to [Firestore Indexes](https://console.firebase.google.com/firestore/indexes)
* Create an index for:

  * **Collection group:** `tasks`
  * **Fields:**

    * `userId` — Ascending
    * `dueDate` — Ascending

---

## ▶️ Run the App

```bash
flutter run
```

---

## 🔐 Firestore Rules (Development)

```js
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /tasks/{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

---

## 📦 Dependencies

* firebase\_core
* firebase\_auth
* cloud\_firestore
* provider
* google\_fonts

---

## 🔧 Flutter Environment

```
Flutter 3.29.2 • channel stable • https://github.com/flutter/flutter.git  
Framework • revision c236373904 (8 weeks ago) • 2025-03-13 16:17:06 -0400  
Engine • revision 18b71d647a  
Tools • Dart 3.7.2 • DevTools 2.42.3  
```

---

## 🧠 Contribution

Pull requests and feature suggestions are welcome!

---

**© 2025 Navid Farahmandian — All rights reserved**

```

---

Let me know if you'd like to auto-generate a `pubspec.yaml` summary or export this as a `.md` file for upload.
```
