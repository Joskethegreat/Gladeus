# Gladeus

**Personal Automated Workout Logger.** An Android app that counts your reps through the phone camera, so you don't have to type in every set.

Gladeus runs pose estimation on the device itself. Camera frames and body keypoints are processed locally and are never uploaded.

| | |
|---|---|
| **Project** | Final Year Project, Bachelor of Software Engineering (Honours), TAR UMT |
| **Student** | Joshua Lau Hao Jie |
| **Supervisor** | Ts. Marina binti Hassan, CTFL |
| **Moderator** | Dr. Tioh Keat Soon |
| **Platform** | Android (Flutter) |
| **Status** | Early prototype (FYP1). Camera rep counting works for three exercises. |

---

## Contents

1. [How it works](#how-it-works)
2. [Current status](#current-status)
3. [Supported exercises](#supported-exercises)
4. [Tech stack](#tech-stack)
5. [Project structure](#project-structure)
6. [Install and run on Android](#install-and-run-on-android)
7. [Using the app](#using-the-app)
8. [Troubleshooting](#troubleshooting)
9. [Known limitations](#known-limitations)
10. [Roadmap](#roadmap)

---

## How it works

```
Camera frame ─► Background isolate ─► MoveNet Lightning ─► 17 keypoints ─► Rep counter ─► Session saved
 (camera)        (convert, rotate,      (TFLite, 192×192)    (x, y, score)    (joint-angle    (on-device,
                  resize)                                                      state machine)  JSON)
```

1. The `camera` plugin streams frames from the back or front camera.
2. Each frame is sent to a **background isolate**, which converts it to RGB, rotates it upright and resizes it to 192×192. This keeps the UI smooth while inference runs.
3. **MoveNet Lightning** (TensorFlow Lite, via `tflite_flutter`) returns 17 body keypoints, each with a confidence score.
4. The **rep counter** picks whichever side of the body (left or right) the model is more confident about. It then tracks one joint angle, or the nose-to-wrist height for pull-ups, through a full down-and-up cycle. A rep is counted when the cycle completes.
5. When the user stops, the session is saved to on-device storage and appears in History.

---

## Current status

Development is iterative and incremental: a working prototype is built first and extended module by module, with features refined after each supervisor review. The table below maps the code to the seven modules in the FYP report.

| # | Module (from FYP report) | Status | What exists now |
|---|---|---|---|
| 1 | Capture and Pose Estimation | ✅ Working | MoveNet Lightning on a background isolate; front/back camera switch; debug overlay with skeleton, FPS, inference time and the model's input image |
| 2 | Exercise Recognition | ⬜ Not started | The user picks the exercise from a dropdown before starting |
| 3 | Repetition Counting | ✅ Working (not yet validated) | Two-phase state machine for push-up, squat and pull-up; not yet benchmarked against labelled video |
| 4 | Form Quality and Injury Risk | ⬜ Not started | No form scoring or injury flags yet |
| 5 | Session and Workout Logging | ✅ Working | Camera and manual logging; edit and delete; data persists across app restarts |
| 6 | Progress and History | 🟡 Partial | History grouped by day with a day-detail view; no progress comparison or trends yet |
| 7 | Account and Sync | ⬜ Not started | Supabase sync is planned; everything is local for now |

The **Home**, **Workouts** and **Profile** tabs are placeholders.

---

## Supported exercises

Counting thresholds are defined in `lib/pose/rep_counter.dart`. The app shows the same rules on screen when **Nerd mode** is turned on.

| Exercise | Joints tracked | Camera placement | Counted as one rep |
|---|---|---|---|
| Push-up | Shoulder, elbow, wrist (one side) | Side view, whole upper body in frame, camera at floor or chest height | Elbow angle drops below 90°, then rises above 160° |
| Squat | Hip, knee, ankle (one side) | Side view, legs fully in frame from hip to ankle | Knee angle drops below 100°, then rises above 160° |
| Pull-up | Nose and one wrist | Front or side view, head and hands visible at the bar | Nose rises above the wrist, then drops back below it |

A frame is ignored if any tracked joint has a confidence score below 0.3. Nerd mode shows which joint was too uncertain.

---

## Tech stack

| Layer | Choice |
|---|---|
| Framework | Flutter (Dart SDK `^3.12.2`) |
| Pose estimation | MoveNet SinglePose Lightning (`assets/models/movenet_lightning.tflite`) |
| Inference runtime | `tflite_flutter` (4 CPU threads) |
| Camera | `camera`, with `permission_handler` for the runtime camera permission |
| Image processing | `image` (frame conversion, rotation, resizing) |
| Local storage | `shared_preferences` (sessions stored as a JSON list) |
| UI | Material 3 dark theme, Inter font via `google_fonts` |
| Android build | Android Gradle Plugin 9.0.1, Gradle 9.1.0, Kotlin 2.3.20, Java 17 |

---

## Project structure

```
lib/
├── main.dart                      App entry point and theme
├── root_shell.dart                Bottom navigation; owns the session list and saving
├── models/
│   └── workout_session.dart       WorkoutType enum and WorkoutSession data model
├── data/
│   └── workout_repository.dart    Loads and saves sessions with shared_preferences
├── pose/
│   ├── movenet_pose_detector.dart MoveNet wrapper: input buffers and keypoint output
│   ├── pose_worker.dart           Background isolate for frame conversion and inference
│   ├── rep_counter.dart           Per-exercise rules and rep-counting state machine
│   └── pose_debug_widgets.dart    Skeleton painter, debug and requirements panels
├── screens/
│   ├── logging_choice_screen.dart Choose Camera or Manual logging
│   ├── camera_log_screen.dart     Setup → live tracking → session summary
│   ├── add_session_screen.dart    Manual entry form, also used for editing
│   ├── history_screen.dart        Sessions grouped by day
│   ├── day_detail_screen.dart     One day's sessions, with edit and delete
│   └── home / workouts / profile  Placeholders
└── widgets/                       App header, glass card, glass navigation bar
assets/
├── models/movenet_lightning.tflite
└── images/home_banner.png
```

---

## Install and run on Android

### Prerequisites

| Requirement | Notes |
|---|---|
| **Flutter SDK** (stable channel) | Must include Dart 3.12.2 or newer. Check with `flutter --version`. |
| **Android Studio** | Provides the Android SDK, platform tools (`adb`) and a bundled JDK. Install the Flutter and Dart plugins. |
| **JDK 17 or newer** | Android Studio's bundled JDK is fine. |
| **Physical Android phone with a camera** | Strongly recommended. The emulator's virtual camera can't show a real person, so pose tracking can't be tested properly. |
| **USB cable**, or wireless debugging (Android 11+) | |
| **Tripod or phone stand** | Recommended for repeatable camera placement. |

### Step 1: Check your Flutter setup

```bash
flutter doctor
```

Fix anything marked ✗ under **Flutter** and **Android toolchain**. If Android licences aren't accepted yet, run:

```bash
flutter doctor --android-licenses
```

### Step 2: Clone the repository

```bash
git clone https://github.com/Joskethegreat/Gladeus.git
cd Gladeus
```

### Step 3: Install dependencies

```bash
flutter pub get
```

This also creates `android/local.properties`, which tells Gradle where your Flutter SDK is.

### Step 4: Prepare your phone

1. Open **Settings → About phone** and tap **Build number** seven times to enable Developer options.
2. Open **Settings → Developer options** and turn on **USB debugging**.
3. Connect the phone by USB and accept the **Allow USB debugging?** prompt on the phone.
4. Confirm the phone is detected:

   ```bash
   flutter devices
   ```

   Your phone should appear in the list. If you have more than one device connected, note its ID.

### Step 5: Run the app

For the most accurate frame rate, use release mode:

```bash
flutter run --release
```

For development with hot reload, use debug mode. Expect a noticeably lower frame rate:

```bash
flutter run
```

If several devices are connected, add `-d <device-id>`.

The first build downloads Gradle 9.1.0 and the Android dependencies, so it can take several minutes. Later builds are much faster.

### Optional: Build an APK to install without a computer

```bash
flutter build apk --release
```

The APK is created at:

```
build/app/outputs/flutter-apk/app-release.apk
```

Install it with:

```bash
adb install build/app/outputs/flutter-apk/app-release.apk
```

Alternatively, copy the APK to the phone and open it. You may need to allow **Install unknown apps** for your file manager.

> This APK is signed with the debug key (see `android/app/build.gradle.kts`). That is fine for testing and demos, but it can't be published to Google Play.

---

## Using the app

1. Tap the **centre button** on the bottom navigation bar.
2. Choose **Camera** for automatic counting, or **Manual** to type in sets and reps.
3. **Camera logging:**
   1. Pick the exercise (Push-up, Pull-up or Squat).
   2. Optionally turn on **Nerd mode** to see the camera placement and counting rules.
   3. Tap **Start** and allow camera access when prompted.
   4. Place the phone as described in [Supported exercises](#supported-exercises), so your whole body is visible, and train. The rep count updates live.
   5. Use the on-screen buttons to switch cameras, toggle the debug overlay (skeleton, FPS, timings) or toggle Nerd mode.
   6. Tap **Stop**, check the summary, then tap **Save**.
4. Saved sessions appear in the **History** tab, grouped by day. Tap a day to edit or delete its sessions.

---

## Troubleshooting

| Problem | Fix |
|---|---|
| `flutter.sdk not set in local.properties` | Run `flutter pub get` from the project root to regenerate `android/local.properties`. |
| Gradle fails with a Java or JDK version error | Point Flutter to JDK 17 or newer, such as Android Studio's bundled JDK: `flutter config --jdk-dir "<path-to-jdk>"`. |
| Phone not shown by `flutter devices` | Check USB debugging is on, set the USB mode to **File transfer**, re-accept the debugging prompt, or try another cable. |
| "Camera permission denied." | Go to **Settings → Apps → gladeus → Permissions** and allow Camera, then try again. |
| Reps are not counting | Turn on Nerd mode. If it shows "low confidence", move the phone so the listed joints are fully visible, improve lighting, or move further back. |
| Low FPS | Use `flutter run --release`. Debug mode is much slower. |

---

## Known limitations

- **No automatic exercise detection yet.** The user selects the exercise before starting.
- **One set per camera session.** Each camera session is saved as one set with the counted reps.
- **Counting accuracy has not been formally measured.** Benchmarking against manually labelled video is planned.
- **Camera placement matters.** Counting depends on side or front views with the tracked joints clearly visible.
- **One person in frame.** MoveNet SinglePose tracks one person only.
- **Android only.** iOS is out of scope for this FYP.

---

## Roadmap

These follow the module plan in the FYP report and may change after supervisor reviews.

| Next | Work |
|---|---|
| Evaluation | Record labelled test videos and measure rep-count accuracy and sustained FPS on the test device |
| Module 2 | Exercise classifier on keypoint time-series (TFLite), with manual override when confidence is low |
| Module 4 | Rule-based form scoring and injury-risk flags using joint-angle thresholds per exercise |
| Module 5 | Multiple sets per session |
| Module 6 | Progress comparison and per-exercise trends |
| Module 7 | Account and optional metadata sync (Supabase), offline-first |
| UI | Home, Workouts and Profile screens |

---

*Tested on: `<device model>`, Android `<version>`, Flutter `<version>`.*
