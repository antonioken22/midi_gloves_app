<div align="center">
  <img src="assets/app_icon/midi_gloves_icon.png" alt="MIDI Gloves Logo" width="120" height="120" />
  <h1>MIDI Gloves</h1>
  <p><strong>MACHINE LEARNING-TRAINED GESTURE-CONTROLLED MIDI GLOVES</strong></p>
  <p>A Thesis Project by Tres Juans</p>

  <p>
    <a href="#features">Features</a> •
    <a href="#tech-stack">Tech Stack</a> •
    <a href="#getting-started">Getting Started</a> •
    <a href="#download">Download</a>
  </p>
</div>

---

## 🎹 About the Project

**MIDI Gloves** is an innovative mobile application that transforms hand gestures into MIDI signals. Designed as a thesis project, it allows musicians and performers to control digital audio workstations (DAWs) wirelessly using custom-built sensor gloves.

The app serves as the central hub, bridging the physical gloves with your music production software via Bluetooth Low Energy (BLE).

## ✨ Key Features

### 🎛️ Interactive Dashboard

Monitor your performance in real-time. The dashboard visualizes sensor data and active MIDI notes, ensuring you stay in control of your sound.

<div align="center">
  <img src="assets/demo/photos/dashboard_landscape.jpg" alt="Dashboard Landscape" width="80%" />
</div>

### 🔗 Seamless Connectivity

Connect your MIDI Gloves effortlessly using Bluetooth Low Energy. The app scans, pairs, and maintains a stable low-latency connection for live performance reliability.

<div align="center">
  <img src="assets/demo/photos/connection_portrait.jpg" alt="Connection Screen" width="30%" />
  <img src="assets/demo/photos/dashboard_portrait.jpg" alt="Dashboard Logic" width="30%" />
</div>

### ⚙️ Deep Customization

Tailor the experience to your playing style. Adjust sensor sensitivity, map specific gestures to MIDI channels, and configure control change (CC) messages directly from the settings.

<div align="center">
   <img src="assets/demo/photos/settings_portrait.jpg" alt="Settings Screen" width="30%" />
</div>

## 🛠️ Tech Stack

Built with performance and reliability in mind:

- **Framework**: [Flutter](https://flutter.dev/) (Dart)
- **Connectivity**: Bluetooth Low Energy (Flutter Blue Plus)
- **Audio/MIDI**: `flutter_midi_pro`, `dart_melty_soundfont`
- **State Management**: Provider

## 🚀 Getting Started

### Prerequisites

- Android Device (Android 5.0+)
- MIDI Gloves Hardware (Prototype)
- DAW (Ableton Live, FL Studio, Logic Pro, etc.)

### Installation

1.  **Download** the latest APK from the [Releases Page](../../releases).
2.  **Install** the APK on your Android device (ensure "Install from Unknown Sources" is enabled).
3.  **Launch** the app and grant Bluetooth permissions.

## 📦 Download

Ready to try it out? Download the latest stable release:

[![Download APK](https://img.shields.io/badge/Download-APK-green?style=for-the-badge&logo=android)](../../releases)

## 👥 Credits

**Tres Juans**

- _Developer & Hardware Logic_
- _Thesis Authors_

---

<div align="center">
  <sub>Built with ❤️ using Flutter.</sub>
</div>
