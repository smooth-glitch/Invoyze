# Smart Inventory App

Smart Inventory App is a cross-platform inventory management solution built with Flutter. It enables users to efficiently manage, scan, and track inventory items across Android, iOS, Web, Windows, macOS, and Linux platforms.

## Features

- Inventory item management (add, edit, delete)
- Barcode/QR code scanning (mobile_scanner)
- Cloud Firestore integration for real-time data sync
- User authentication with Firebase Auth
- File selection and opening (file_selector, open_file)
- PDF generation and export
- Cross-platform support: Android, iOS, Web, Windows, macOS, Linux

## Screenshots

<!-- Add screenshots here if available -->
<!-- ![Screenshot](screenshots/screen1.png) -->

## Getting Started

### Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install)
- Dart SDK (comes with Flutter)
- Android Studio, Xcode, or Visual Studio (for platform-specific builds)
- Firebase project (for authentication and Firestore)

### Installation

1. **Clone the repository:**
   ```sh
   git clone https://github.com/yourusername/smart_inventory_app.git
   cd smart_inventory_app
   ```

2. **Install dependencies:**
   ```sh
   flutter pub get
   ```

3. **Configure Firebase:**
   - Follow the [FlutterFire documentation](https://firebase.flutter.dev/docs/overview/) to add your `google-services.json` (Android) and `GoogleService-Info.plist` (iOS).
   - Update Firebase configuration for other platforms as needed.

4. **Run the app:**
   ```sh
   flutter run
   ```

### Building for Desktop

- **Windows:**  
  `flutter build windows`
- **macOS:**  
  `flutter build macos`
- **Linux:**  
  `flutter build linux`

### Building for Web

```sh
flutter build web
```

## Project Structure

- `lib/`  
  Main Dart source code for the Flutter app.
  - `main.dart` – App entry point.
  - Other Dart files and folders for features, UI, and logic.

- `android/`  
  Android platform-specific code and configuration.
  - `app/` – Main Android app module.
    - `build.gradle.kts` – Android build configuration.
    - `src/` – Java/Kotlin source code.
  - `build.gradle.kts`, `settings.gradle.kts` – Project-level Gradle configs.

- `ios/`  
  iOS platform-specific code and configuration.
  - `Runner/` – Main iOS app module.
    - `AppDelegate.swift` – iOS app entry point.
    - `Runner-Bridging-Header.h` – Swift/Obj-C bridging.
    - `Info.plist` – iOS app configuration.

- `macos/`  
  macOS platform-specific code.
  - `Flutter/GeneratedPluginRegistrant.swift` – macOS plugin registration.

- `windows/`  
  Windows platform-specific code.
  - `runner/` – Windows app runner (C++ sources, resources).
    - `main.cpp`, `flutter_window.cpp`, `utils.cpp` – App entry and helpers.
    - `resource.h` – App icon and resources.
  - `flutter/` – Windows Flutter plugin registration.

- `linux/`  
  Linux platform-specific code.
  - `runner/` – Linux app runner (C++ sources).
    - `my_application.cc`, `my_application.h` – App entry and helpers.
  - `flutter/` – Linux Flutter plugin registration.

- `web/`  
  Web platform-specific files.
  - `index.html` – Main HTML entry point.
  - `manifest.json`, icons, etc.

- `pubspec.yaml`  
  Project manifest: dependencies, assets, fonts, and metadata.

- `analysis_options.yaml`  
  Dart static analysis and lint rules.

- `README.md`  
  Project documentation (this file).

## Dependencies

Key packages used:
- `cloud_firestore`
- `firebase_auth`
- `firebase_core`
- `mobile_scanner`
- `file_selector`
- `open_file`
- `path_provider`
- `pdf`

See [`pubspec.yaml`](pubspec.yaml) for the full list.

## Contributing

Contributions are welcome! Please open issues or submit pull requests for improvements and bug fixes.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## Acknowledgements

- [Flutter](https://flutter.dev/)
- [Firebase](https://firebase.google.com/)
- [FlutterFire](https://firebase.flutter.dev/)
