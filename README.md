# ChatApp

<div align="center">

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Android](https://img.shields.io/badge/Android-3DDC84?style=for-the-badge&logo=android&logoColor=white)
![iOS](https://img.shields.io/badge/iOS-000000?style=for-the-badge&logo=apple&logoColor=white)
![Web](https://img.shields.io/badge/Web-4285F4?style=for-the-badge&logo=google-chrome&logoColor=white)
![Windows](https://img.shields.io/badge/Windows-0078D6?style=for-the-badge&logo=windows&logoColor=white)

**A beautiful, feature-rich real-time chat application built with Flutter and Firebase for couples.**

[![Buy me a coffee](https://img.shields.io/badge/Buy_me_a_coffe-FFDD00?style=for-the-badge&logo=buy-me-a-coffee&logoColor=black)](https://buymeacoffee.com/gabcupe)

</div>

---

## ✨ Features Overview


| Real-time Messaging | Reactions & Confetti | Media Sharing |
| :---: | :---: | :---: |
| Instant message delivery with typing indicators | Heart animations and celebration effects | Images, stickers, and GIFs support |

| YouTube & TikTok | Love Messages | Push Notifications |
| :---: | :---: | :---: |
| Embedded video playback in chat | Romantic message generator with confetti | Background notifications for new messages |
---

## System Preview

| Login | ChatScreen | YouTubePlayer |
| :---: | :---: | :---: |
| ![Login](https://i.ibb.co/0yvZpnWD/image.png) | ![ChatScreen](https://i.ibb.co/wNhpZMX9/image.png) | ![YouTubePrayer](https://i.ibb.co/245Zvw5/image.png) |

##  Detailed Features

### 💬 Real-Time Chat
* **Instant Messaging:** Real-time message synchronization using Firebase Realtime Database.
* **Typing Indicators:** See when your partner is typing with animated dots.
* **Online Status:** Real-time presence system showing when users are active.
* **Message Replies:** Quote and reply to specific messages in conversations.
* **Message Editing:** Edit sent messages with edit history indicator.
* **Read Receipts:** Know when your messages have been seen.

###  Rich Media Support
* **Image Sharing:** Send images with full-screen interactive viewer (pinch to zoom).
* **Stickers & Emojis:** Firebase-powered sticker and emoji picker with categories.
* **GIF Support:** Send animated GIFs directly in chat.
* **YouTube Embedding:** Share YouTube links with embedded video player.
* **TikTok Videos:** TikTok link support with WebView integration.

### 💕 Romantic Features
* **Love Message Generator:** Special romantic message popup with elegant design.
* **Confetti Effects:** Celebration animations for special moments.
* **Heart Reactions:** Animated heart particles when reacting to messages.
* **Daily Quotes:** Inspirational rotating quotes on the login screen.

###  Notifications
* **Push Notifications:** Local notifications for incoming messages.
* **Activity Reminders:** Periodic notifications to keep conversations active.
* **Customizable Channels:** Separate channels for urgent and reminder notifications.

###  User Experience
* **Responsive Design:** Optimized layouts for mobile and desktop.
* **Smooth Animations:** Fluid transitions and micro-interactions throughout.
* **Keyboard Navigation:** Full keyboard support for desktop users.
* **Shimmer Loading:** Elegant loading placeholders for async content.

---

##  Tech Stack

<div align="center">

![Provider](https://img.shields.io/badge/Provider-02569B?style=flat-square&logo=flutter&logoColor=white)
![WebView](https://img.shields.io/badge/WebView-4285F4?style=flat-square&logo=google-chrome&logoColor=white)
![YouTube](https://img.shields.io/badge/YouTube_Player-FF0000?style=flat-square&logo=youtube&logoColor=white)
![Git](https://img.shields.io/badge/Git-F05032?style=flat-square&logo=git&logoColor=white)
![GitHub](https://img.shields.io/badge/GitHub-181717?style=flat-square&logo=github&logoColor=white)

</div>

* **State Management:** Provider Pattern with ChangeNotifier.
* **Backend:** Firebase Realtime Database.
* **Media:** Image Picker, Cached Network Image, Video Player.
* **Animations:** Flutter Animate, Confetti, Shimmer.
* **Notifications:** Flutter Local Notifications.
* **Fonts:** Google Fonts with custom Montserrat and Noto Sans.

---

## 📁 Project Architecture

```text
lib/
├── main.dart                 # App entry point with Provider setup
├── firebase_options.dart     # Firebase multi-platform configuration
├── screens/
│   ├── chat_screen.dart     # Main chat interface
│   ├── login_screen.dart    # Authentication screen
│   ├── login_form.dart      # Login form widget
│   └── fadeInWidget.dart    # Animated entrance widget
├── chat_addons/
│   ├── display/
│   │   ├── chat_bubble.dart   # Message bubble with media support
│   │   ├── image_viewer.dart  # Full-screen image viewer
│   │   ├── reply_bubble.dart  # Reply preview component
│   │   ├── reply_panel.dart   # Active reply panel
│   │   └── scroll.dart        # Custom scroll utilities
│   ├── effects/
│   │   ├── confetti_effect.dart     # Celebration animation
│   │   └── love_message_dialog.dart # Romantic popup
│   ├── input/
│   │   ├── message_input.dart   # Main input bar
│   │   ├── emoji.dart           # Emoji picker
│   │   ├── sticker.dart         # Sticker picker
│   │   ├── enter.dart           # Submit handlers
│   │   ├── message_menu.dart    # Context menu
│   │   └── typing_detector.dart # Typing state manager
│   └── logic/
│       ├── dialog_state.dart        # Dialog management
│       ├── image_service.dart       # Image upload service
│       └── love_message_generator.dart # Romantic messages
├── models/
│   ├── message_model.dart   # Message data class
│   └── user_model.dart      # User data class
├── services/
│   ├── auth_service.dart         # Authentication logic
│   ├── chat_message_service.dart # Message CRUD operations
│   ├── database_service.dart     # Firebase database layer
│   └── unread.dart               # Unread message tracking
└── notifications/
    ├── notification_service.dart # Local notifications
    ├── message_listener.dart     # Real-time message listener
    ├── timer.dart                # Periodic notifier
    └── timer_menu.dart           # Timer settings UI
```

---

## 📋 Requirements

* Flutter SDK v3.11.0 or higher.
* Firebase account with Realtime Database enabled.
* Android Studio / Xcode for mobile builds.

---

## 🔧 Installation

### 1. Clone the Repository
```bash
git clone https://github.com/Gab-Cupe/ChatApp.git
cd chatapp
```

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Configure Firebase
Use FlutterFire CLI to generate your Firebase configuration:
```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

### 4. Set Up Firebase Database Structure
Create the following nodes in your Firebase Realtime Database:
```json
{
  "messages": {},
  "users": {},
  "emojis": {},
  "stickers": {},
  "Frases": {}
}
```

### 5. Run the Application
```bash
flutter run
```

---

## 🎨 Color Palette

| Purpose | Color | Hex Code |
| --- | :---: | --- |
| Primary | 🔵 | `#42A5F5` |
| Secondary | 🔷 | `#BBDEFB` |
| Love Accent | 💗 | `#F8BBD0` |
| Deep Pink | 💖 | `#880E4F` |

---

## 📱 Supported Platforms

| Platform | Status |
| --- | :---: |
| Android | ✅ Supported |
| iOS | ✅ Supported |
| Web | ✅ Supported |
| Windows | ✅ Supported |
| macOS | ✅ Supported |
| Linux | ⚠️ Requires configuration |

---

## 📄 License

This project is distributed as open source software. Free to use for educational purposes and personal projects.

---

<div align="center">

**Made with ❤️ using flutter, dedicated to my dear Jandy**

</div>
