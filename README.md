# ReNosh App

## Overview

ReNosh is a Flutter-based mobile and web application designed to help food establishments manage surplus food, reduce waste, and promote sustainability. By leveraging AI-driven predictions and real-time data tracking, ReNosh empowers restaurants to optimize inventory, donate surplus food, and track sustainability metrics. The app integrates with Firebase for authentication and data storage, uses the ReNosh API and Gemini API for AI-powered insights, and provides visualizations with interactive charts.

## Features

- **AI-Powered Predictions**: Forecast daily food demand using the ReNosh API to minimize overproduction.
- **Surplus Management**: Track and manage surplus food items, with options to view details and donate.
- **Sustainability Tracking**: Visualize metrics like meals donated, food saved (kg), and waste reduction impact with interactive charts.
- **AI Insights**: Get actionable recommendations powered by the Gemini API to optimize operations and reduce waste.
- **Offline Support**: Access cached data when offline, with an offline mode indicator.
- **User Authentication**: Secure login for food establishments using Firebase Authentication.
- **Responsive Design**: Smooth animations and a modern UI with Google Fonts and gradient themes.

## Usage

### Login
- Launch the app and log in using your food establishment credentials (via Firebase Authentication).
- If no user is logged in, you’ll be redirected to the login screen.

### Dashboard
- View a personalized greeting and your establishment’s name.
- Check AI predictions for the day (e.g., predicted demand for dishes like Butter Chicken).
- Monitor surplus items and navigate to detailed views.
- Explore sustainability charts (meals donated, food saved, waste reduction impact).
- Tap the AI Insights card for actionable recommendations.

### Predictions
- Click "Predictions of the Day" to see detailed forecasts for each dish, including trends compared to yesterday.
- Refresh predictions if needed (supports offline mode with cached data).

### Sustainability Tracking
- View charts showing your impact over the last 7 days, including meals donated and food saved.

## Scalability

- **Cloud Integration**: Uses Firebase Firestore for real-time data storage, enabling seamless scaling as the user base grows.
- **API-Driven Predictions**: Relies on the ReNosh API (`https://renosh-api.onrender.com`) and Gemini API, which can be scaled independently.
- **Caching Mechanism**: Implements local caching with `shared_preferences` to reduce server load and ensure offline functionality.
- **Modular Design**: The app’s architecture allows for easy addition of new features.
- **Isolate for Heavy Tasks**: Uses Flutter’s `compute` function to offload heavy computations, ensuring UI responsiveness.

## Tech Stack

- **Frontend**: Flutter (Dart) for cross-platform mobile and web development.
- **Backend**: Firebase (Authentication, Firestore) for user management and data storage.
- **APIs**:
  - ReNosh API (`https://renosh-api.onrender.com`) for predictions.
  - Gemini API for AI insights.

## Tools

- Android Studio/Xcode for development.
- Git for version control.
- Firebase CLI for Firebase setup.

## Prerequisites

Ensure you have the following installed/configured:

- **Flutter SDK**: Version 3.0.0 or higher.
- **Dart**: Version 2.17.0 or higher.
- **Firebase Account**: For authentication and Firestore.
- **API Keys**:
  - ReNosh API key (contact project maintainers).
  - Gemini API key (optional, for AI insights).
- **Android Studio/Xcode**: For running the app locally.
- **Git**: To clone the repository.

## Installation

### 1. Clone the Repository
```bash
git clone https://github.com/sumanthd032/ReNosh-AI.git
cd ReNosh-AI
```

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Set Up Firebase

- Create a Firebase project in the Firebase Console.
- Add Android, iOS, and web apps to your Firebase project.

#### For Mobile (Android/iOS):
- Download `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) from Firebase Console.
- Place them in `android/app/` and `ios/Runner/`, respectively.

#### Firebase CLI Setup
```bash
npm install -g firebase-tools
dart pub global activate flutterfire_cli
```

#### For Web:
- Copy Firebase configuration from Firebase Console.
- Update `web/index.html` with Firebase SDK and config:

```html
<script src="https://www.gstatic.com/firebasejs/10.12.2/firebase-app.js"></script>
<script src="https://www.gstatic.com/firebasejs/10.12.2/firebase-auth.js"></script>
<script src="https://www.gstatic.com/firebasejs/10.12.2/firebase-firestore.js"></script>
<script>
  const firebaseConfig = {
    apiKey: "YOUR_API_KEY",
    authDomain: "YOUR_AUTH_DOMAIN",
    projectId: "YOUR_PROJECT_ID",
    storageBucket: "YOUR_STORAGE_BUCKET",
    messagingSenderId: "YOUR_MESSAGING_SENDER_ID",
    appId: "YOUR_APP_ID"
  };
  firebase.initializeApp(firebaseConfig);
</script>
```


### 4. Set Up API Keys

Create `lib/secrets.dart`:
```dart
final geminiApi = "YOUR API KEY"
```

### 5. Run the App Locally

#### For mobile:
```bash
flutter run
```

#### For web:
```bash
flutter run -d chrome
```

## Security Notes

- Sensitive files are excluded via `.gitignore`.
- API keys are stored securely and should never be committed.
- For production, use environment variables or secure config services.
- Regularly review Firebase Security Rules.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Contact

For support or inquiries, contact: [sumanthd032@gmail.com](mailto:sumanthd032@gmail.com)  
GitHub: [sumanthd032](https://github.com/sumanthd032)
