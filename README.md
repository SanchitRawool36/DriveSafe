# DriveSafe

DriveSafe is a Flutter app for road incident reporting and ambulance support. Users can report accidents with photos and GPS, request ambulance help, book private ambulance service with fake live tracking, and view complaint updates. Admins can review complaints, change complaint status, and see ambulance bookings with route progress.

## Overview

The current app has two main product areas:

- Road incident reporting
- Ambulance service and tracking

The ambulance module now replaces the old licence workflow in the active app flow.

## Features

### User features

- Email/password sign in and registration with Firebase Auth
- Complaint reporting with title, type, description, photo, and GPS
- Camera or gallery upload for complaint evidence
- Complaint tracking with status visibility
- Profile and settings management
- Ambulance service screen with two flows:
	- Government ambulance: call directly
	- Private ambulance: book and pay in-app
- Fake live ambulance tracking map with:
	- moving ambulance marker
	- route line
	- ETA
	- travel status updates
- Ambulance notifications using the latest booking state

### Admin features

- Complaint moderation dashboard
- Complaint search by reporter name, email, or phone
- Complaint status actions:
	- Pending
	- In Progress
	- Accepted
	- Rejected
	- Resolved
- Ambulance booking admin view with:
	- who booked
	- patient name
	- phone and email
	- emergency reason
	- pickup location
	- booked time
	- payment method
	- ETA
	- fake live route map preview

## Ambulance service flow

### Government flow

1. Open Ambulance Service
2. Select Government
3. Tap call to contact emergency ambulance support

### Private flow

1. Open Ambulance Service
2. Select Private
3. Choose a provider from the client-approved local operator list
4. Enter patient name, pickup location, and emergency reason
5. Choose payment method
6. Book and pay
7. Watch the fake live map update with ambulance movement and ETA

## Local ambulance providers included

The current app includes these client-requested providers:

- Jeevan Jyot Ambulance, Kudal
- Arekar Ambulance, Sawantwadi
- Hemant Marathe Ambulance, Malewad
- Janseva Ambulance, Kolhapur
- Rawool Ambulance, Shiroda
- Naik Ambulance, Tulas
- 108 Emergency Ambulance for Government support

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

## Firebase usage

This app uses Firebase for:

- Authentication
- Complaint storage
- User profile storage
- Ambulance booking storage
- Complaint image uploads

Main Firestore collections used by the active app flow:

- users
- complaints
- ambulance_bookings

Firestore rules were updated to allow:

- users to read and write their own ambulance bookings
- admins to read all ambulance bookings

## Important files

- `lib/main.dart`: app startup and route registration
- `lib/screens/dashboard_screen.dart`: user dashboard
- `lib/screens/report_issue_screen.dart`: complaint submission flow
- `lib/screens/track_screen.dart`: complaint tracking flow
- `lib/screens/ambulance_screen.dart`: ambulance booking and fake live tracking
- `lib/screens/admin_dashboard.dart`: complaint moderation and ambulance booking review
- `lib/screens/profile_screen.dart`: profile and ambulance entry point
- `lib/services/firestore_service.dart`: complaint Firestore operations
- `lib/services/ambulance_service.dart`: ambulance provider catalog, Firestore booking persistence, and fake route progression
- `lib/models/ambulance_models.dart`: ambulance provider and booking models
- `firestore.rules`: Firestore access rules

## Routes

- `/login`
- `/register`
- `/dashboard`
- `/admin`
- `/report`
- `/track`
- `/profile`
- `/ambulance`
- `/notifications`
- `/settings`

`/dl` currently redirects to the ambulance screen for compatibility with older navigation paths.

## Running locally

### Install dependencies

```bash
flutter pub get
```

### Run on Chrome

```bash
flutter run -d chrome
```

### Run on Android

```bash
flutter run -d android
```

## Build release APK

```bash
flutter build apk --release
```

Release APK output:

```text
build/app/outputs/flutter-apk/app-release.apk
```

This is the file to upload to Google Drive.

Do not upload:

```text
build/app/outputs/flutter-apk/app-release.apk.sha1
```

The `.sha1` file is only a checksum.

## Permissions

### Android

- Camera
- Fine location
- Coarse location

### iOS

- Camera usage
- Photo library usage
- Location when in use

The app asks for location when GPS-based complaint reporting is used, and camera or gallery permission when image upload is used.

## Notes

- Ambulance travel on the map is intentionally fake but functional for product demo purposes.
- Existing old licence-related data fields may still exist in the backend model for compatibility, but the active app flow has been switched to ambulance service.
- Review hardcoded admin credentials and any demo assumptions before public production release.

## License

No repository license file has been added yet. Add one if you plan to publish this project publicly on GitHub.
