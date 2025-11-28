# Feline Focused 🐱📱
An application that reduces distractions and improves concentration by blocking apps and tracking focus sessions.

#Features

🔒 App blocking (including short-form content like YouTube Shorts)

⏱️ Customizable focus timer

📊 Statistics and streak tracking

🔑 Login/Signup with Firebase Authentication

⚙️ Settings page for permissions, logout, and history management


#System Requirements

🤖 Android (due to accessibility service limitations on iOS)

🕊️Flutter SDK (latest stable version)

🔥 Firebase project setup

#Technology Stack

Language: Dart

Framework: Flutter

Backend/Database: Firebase (Auth, Firestore, Google Sign-In)

Key Packages:

flutter_accessibility_service – detect blocked apps

flutter_overlay_window – display overlays

device_apps, android_intent_plus – exit blocked apps

provider – state management

firebase_auth, cloud_firestore – authentication & data storage

#Sample Screenshots

<img width="280" height="660" alt="image" src="https://github.com/user-attachments/assets/05490c71-e280-4341-afbf-67ac78e8eadd" />
<img width="291" height="660" alt="image" src="https://github.com/user-attachments/assets/d9d18d46-3dda-4b26-834f-923a7375c98e" />
<img width="311" height="660" alt="image" src="https://github.com/user-attachments/assets/89214837-1799-47f4-89ad-f55d528813a6" />



##Challenges & Limitations

Works only on Android (iOS restrictions).

Some bugs in overlay handling.

## Installation
1. Clone the repository:
   git clone https://github.com/NekoNoTabiTabi/FelineFocus.git

2. Navigate to the project folder:
   cd FelineFocus

3. Install dependencies:
   flutter pub get

4. Run the app:
   flutter run
## Contributors
- Ortilano, Justine Kyle T.
