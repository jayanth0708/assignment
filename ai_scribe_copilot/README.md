# AI Scribe Copilot: Medical Transcription App

This repository contains the source code for the AI Scribe Copilot, a Flutter application designed for real-time audio recording and streaming of medical consultations. It's built to be resilient to common interruptions like phone calls, network outages, and app switching.

## Project Overview

This project is a submission for the Attack Capital Mobile Engineering Challenge. It consists of two main components:

1.  **A Flutter Mobile Application:** A cross-platform app that handles audio recording, background processing, chunked streaming, and interruption recovery.
2.  **A Mock Backend:** A Python Flask server that simulates the API endpoints required for session management and audio chunk uploads.

### Core Features
*   **Real-time Audio Streaming:** Records audio and uploads it in chunks during the recording session.
*   **Background Recording:** Continues to record even when the app is minimized or the phone is locked.
*   **Interruption Handling:** Designed to automatically pause and resume recording during phone calls or when the app is backgrounded.
*   **Network Resilience:** Failed audio chunk uploads are automatically queued locally and retried when network connectivity is restored.
*   **Native Feature Integration:** Includes audio level visualization, system notifications, a native share sheet, and haptic feedback.

## Setup and Installation

### 1. Backend Setup (Docker)

The backend is a mock server built with Flask and is containerized using Docker for easy setup.

**Prerequisites:**
*   Docker and Docker Compose installed.

**Instructions:**

1.  Navigate to the root of the project directory.
2.  Run the following command to build and start the backend server:
    ```bash
    docker-compose up --build -d
    ```
3.  The backend API will be accessible at `http://localhost:5000`.

**Note:** The Docker build may fail due to Docker Hub's unauthenticated pull rate limits in some environments. If this occurs, you may need to log in to a Docker account (`docker login`) before running the command.

### 2. Frontend Setup (Flutter)

The mobile application is built with Flutter.

**Prerequisites:**
*   Flutter SDK installed (recommended version: 3.7.x or newer).
*   A configured IDE (like VS Code or Android Studio) with the Flutter plugin.
*   An Android emulator or physical device.
*   For iOS, Xcode and CocoaPods are required.

**Instructions:**

1.  Navigate to the `frontend` directory:
    ```bash
    cd ai_scribe_copilot/frontend
    ```
2.  Install the required dependencies:
    ```bash
    flutter pub get
    ```
3.  Run the application:
    ```bash
    flutter run
    ```

## Deliverables

*   **Android APK:** Due to environment limitations, I cannot build the APK myself. However, you can generate a release APK by running the following command from the `frontend` directory:
    ```bash
    flutter build apk --release
    ```
    The generated APK will be located at `frontend/build/app/outputs/flutter-apk/app-release.apk`.

*   **iOS Loom Video:** As a text-based AI, I cannot create a video recording. To test on iOS, please build and run the app on an iOS simulator or a physical device and record a demo covering the test scenarios.

*   **Backend Deployment URL:** The backend is designed for local deployment via Docker. There is no live public URL.

## Technical Details

*   **Flutter Version:** This project was developed without direct access to the `flutter` command-line tool. It is written to be compatible with **Flutter SDK version 3.7.0** and **Dart SDK version 2.19.0**.

*   **API Documentation:** The backend implements the endpoints described in the challenge documentation.
    *   **Mock API Documentation:** [https://docs.google.com/document/d/1hzfry0fg7qQQb39cswEychYMtBiBKDAqIg6LamAKENI/edit?usp=sharing](https://docs.google.com/document/d/1hzfry0fg7qQQb39cswEychYMtBiBKDAqIg6LamAKENI/edit?usp=sharing)
    *   **Mock Postman Collection:** [https://drive.google.com/file/d/1rnEjRzH64ESlIi5VQekG525Dsf8IQZTP/view?usp=sharing](https://drive.google.com/file/d/1rnEjRzH64ESlIi5VQekG525Dsf8IQZTP/view?usp=sharing)

## Pass/Fail Test Scenarios

To verify the app's functionality, perform the following tests:

1.  **Locked Screen Test:** Start a recording, lock the phone, and wait a few minutes. Unlock the phone and stop the recording. Verify that the backend received the audio chunks.
2.  **Phone Call Interruption:** Start a recording and simulate an incoming phone call. The recording should pause. End the call, and the recording should resume.
3.  **Network Outage:** Start a recording, then enable Airplane Mode. The app should queue chunks locally. Disable Airplane Mode, and the app should automatically upload the queued chunks.
4.  **App Switching:** While recording, switch to another app and then return. The recording should continue seamlessly.
5.  **Graceful Recovery:** The app queues failed uploads. To test this, stop the backend server, record a session, and then restart the server. The queued chunks should be uploaded upon the next app launch or when network connectivity is detected.