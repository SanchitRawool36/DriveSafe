# DriveSafe

DriveSafe is a Flutter application for road safety reporting and digital driving-license management. It allows users to register, submit road incident complaints with GPS-tagged photo evidence, track complaint progress, manage their profile, and request license renewal. It also includes a dedicated admin dashboard for reviewing complaints, updating complaint status, and processing renewal requests.

## Overview

DriveSafe is built as a Firebase-backed mobile and web app with separate user and admin flows.

Core goals:

- Make road incident reporting simple and fast.
- Capture richer complaint evidence with image attachments and GPS coordinates.
- Let users monitor their submitted complaints.
- Provide a simple admin panel for moderation and renewal processing.
- Support a digital driving-license profile and renewal workflow in one app.

## Features

### User features

- Email/password registration and login with Firebase Auth.
- Dashboard with complaint overview and quick actions.
- Submit complaints with:
	- title
	- incident type
	- description
	- optional image attachment
	- GPS coordinates
- Photo attachment flow with two options:
	- Click Image
	- Upload From Gallery
- Automatic GPS attachment for photo-based reports.
- Complaint tracking screen for end users.
- Profile management.
- Settings management.
- In-app notifications for complaint and renewal-related updates.
- Driving-license profile creation and editing.
- License renewal request flow with renewal history.

### Admin features

- Dedicated admin login flow.
- Admin dashboard for viewing all complaints.
- Complaint filtering and reporter search by name, email, or phone.
- Admin-only complaint status updates.
- Supported complaint statuses:
	- Pending
	- In Progress
	- Accepted
	- Rejected
	- Resolved
- Complaint detail view with map preview and coordinates.
- Renewal request review for user license profiles.
- Renewal test date scheduling.
- Renewal approval and rejection.
- User contact shortcuts via SMS and email from the admin panel.

## Complaint workflow

1. A user signs in.
2. The user opens Report Incident.
3. The user fills in title, incident type, and description.
4. The user may attach a photo either from the camera or from the gallery.
5. When a photo is attached, DriveSafe captures GPS coordinates and stores them with the complaint.
6. The complaint is saved to Firestore and the image is uploaded to Firebase Storage.
7. The user can track the complaint from the Track screen.
8. Only the admin can change complaint status.

## Digital license workflow

1. The user completes the license profile.
2. The user submits a renewal request with an optional note.
3. The admin reviews the renewal request.
4. The admin can assign a renewal test date.
5. The admin can approve or reject the renewal.
6. The user sees status and renewal history in the license screen and notifications screen.

## Tech stack

- Flutter
- Dart
- Firebase Auth
- Cloud Firestore
- Firebase Storage
- SharedPreferences
- Geolocator
- Image Picker
- flutter_map
- OpenStreetMap tiles
- url_launcher

## Project structure

```text
lib/
	main.dart
	firebase_options.dart
	models/
	screens/
	services/
	utils/
	widgets/
test/
android/
ios/
web/
windows/
linux/
macos/
```

Important areas:

- `lib/main.dart`: app bootstrap, Firebase initialization, routing, and session gate.
- `lib/screens/`: user and admin screens.
- `lib/services/auth_service.dart`: Firebase auth and profile persistence.
- `lib/services/firestore_service.dart`: complaint storage, query, and status updates.
- `lib/services/complaint_repository.dart`: complaint data abstraction.
- `lib/services/local_storage_service.dart`: settings and legacy/local storage helpers.
- `lib/screens/admin_dashboard.dart`: admin complaint and renewal management.
- `lib/screens/report_issue_screen.dart`: complaint submission with image and GPS support.
- `lib/screens/dl_screen.dart`: digital license and renewal request flow.

## Screens and routes

The app currently exposes these main routes:

- `/login`
- `/register`
- `/dashboard`
- `/admin`
- `/report`
- `/track`
- `/profile`
- `/dl`
- `/notifications`
- `/settings`

## Authentication and roles

DriveSafe supports two types of sessions:

- Normal user session
- Admin session

The app uses Firebase Auth for sign-in. User profile data is stored in Firestore under the `users` collection.

There is also a reserved admin flow in code. Before using this project in production, review and change the reserved admin credentials and any hardcoded admin logic in:

- `lib/services/auth_service.dart`
- `lib/services/local_storage_service.dart`

Do not keep development or demo admin credentials in a public production deployment.

## Firebase usage

This app depends on Firebase for core functionality:

- Firebase Auth: user and admin login
- Cloud Firestore: user profiles, complaints, renewal workflow data
- Firebase Storage: complaint image uploads

The app initializes Firebase through `firebase_options.dart`.

If you clone this repository for a new Firebase project, make sure to:

1. Create a Firebase project.
2. Enable Email/Password authentication.
3. Create Firestore Database.
4. Enable Firebase Storage.
5. Reconfigure the app with FlutterFire.
6. Update platform-specific Firebase config files if needed.
7. Apply Firestore and Storage security rules appropriate for authenticated users and admin-only moderation.

## Permissions

DriveSafe requires permissions related to reporting and media capture.

### Android

- Camera
- Fine location
- Coarse location

### iOS

- Camera usage
- Photo library usage
- Location when in use

### What the app asks for

- Location permission is requested when GPS capture is needed.
- Camera permission is requested when the user chooses Click Image.
- Photo library permission is requested when the user chooses Upload From Gallery.

## GPS and image behavior

- GPS assistance is controlled through app settings.
- If GPS assistance is disabled, the app blocks photo attachment for complaint evidence.
- If a user attaches a photo, the complaint must also include GPS coordinates.
- GPS coordinates are stored with the complaint record.
- Users can still manually capture GPS from the report screen before submission.

## Running the app locally

### Prerequisites

- Flutter SDK installed
- Dart SDK installed through Flutter
- Android Studio or VS Code with Flutter support
- Chrome for Flutter web testing
- Firebase project configured

### Install dependencies

```bash
flutter pub get
```

### Run on Chrome

```bash
flutter run -d chrome
```

### Run on Android device or emulator

```bash
flutter run -d android
```

### Run tests

```bash
flutter test
```

## Building a release APK

To create a release APK:

```bash
flutter build apk --release
```

Generated APK path:

```text
build/app/outputs/flutter-apk/app-release.apk
```

This is the file to upload to Google Drive if you want to share the Android app directly.

Do not upload:

```text
build/app/outputs/flutter-apk/app-release.apk.sha1
```

The `.sha1` file is only a checksum file, not the installable Android application.

## Data model summary

### User profile data includes

- name
- email
- phone
- license information
- address and bio
- role
- profile image data
- renewal request fields
- renewal history

### Complaint data includes

- complaint id
- title
- description
- incident type
- status
- created time
- reporter metadata
- optional image reference
- optional image bytes during upload flow
- optional GPS location

## Admin moderation rules in the app

- Users can view and track their complaints.
- Users cannot update complaint status.
- Complaint status changes are restricted to the admin dashboard UI.
- Session-sensitive complaint reads are guarded so invalid sessions redirect back to login instead of exposing raw Firestore permission errors.

## Current status of the project

This repository currently includes:

- Firebase-backed authentication
- Firebase-backed complaint persistence
- Firebase Storage image upload support
- GPS-based complaint evidence flow
- Admin complaint moderation
- Embedded location handling in complaint details
- License renewal request lifecycle
- Signed Android release build support

## Development notes

- The app still contains some development-oriented behavior and demo-friendly assumptions.
- Review authentication, Firebase rules, admin credential handling, and branding before a public production launch.
- If you are publishing publicly, remove any test accounts and rotate any demo credentials.

## Recommended improvements before public production launch

- Replace any hardcoded admin credentials with a secure role-based backend setup.
- Add stronger backend authorization checks for every admin-only action.
- Add integration tests for complaint reporting and renewal workflows.
- Add app screenshots to this README.
- Add CI for test and release validation.
- Add crash reporting and analytics if needed.

## License

No license has been added to this repository yet. Add a license file if you plan to publish or share this project publicly.
