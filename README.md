
# ReNosh App

## Overview

ReNosh is a Flutter-based mobile application designed to help food establishments manage surplus food, reduce waste, and promote sustainability. By leveraging AI-driven predictions and real-time data tracking, ReNosh empowers restaurants to optimize their inventory, donate surplus food, and track their sustainability metrics.

The app integrates with Firebase for authentication and data storage, uses the Gemini API for AI insights, and provides visualizations with charts.

---

## Features

- **AI-Powered Predictions**: Forecast daily food demand using the ReNosh API to minimize overproduction.
- **Surplus Management**: Track and manage surplus food items, with options to view details and donate.
- **Sustainability Tracking**: Visualize metrics like meals donated, food saved (kg), and waste reduction impact with interactive charts.
- **AI Insights**: Get actionable recommendations powered by the Gemini API to optimize operations and reduce waste.
- **Offline Support**: Access cached data when offline, with an offline mode indicator.
- **User Authentication**: Secure login for food establishments using Firebase Authentication.
- **Responsive Design**: Smooth animations and a modern UI with Google Fonts and gradient themes.

---

## Usage

### Login

- Launch the app and log in using your food establishment credentials (via Firebase Authentication).
- If no user is logged in, you’ll be redirected to the login screen.

### Dashboard

- View a greeting and your establishment’s name.
- Check AI predictions for the day (e.g., predicted demand for dishes like Butter Chicken).
- Monitor surplus items and navigate to detailed views.
- Explore sustainability charts (meals donated, food saved, waste reduction impact).
- Tap the AI Insights card to get actionable recommendations.

### Predictions

- Click "Predictions of the Day" to see detailed forecasts for each dish, including trends compared to yesterday.
- Refresh predictions if needed (supports offline mode with cached data).

### Sustainability Tracking

- View charts showing your impact over the last 7 days, including meals donated and food saved.

---

## Scalability

- **Cloud Integration**: Uses Firebase Firestore for real-time data storage, enabling seamless scaling as the user base grows.
- **API-Driven Predictions**: The prediction system relies on an external API (`https://renosh-api.onrender.com`), which can be scaled independently.
- **Caching Mechanism**: Implements local caching with `shared_preferences` to reduce server load and ensure offline functionality.
- **Modular Design**: The app’s modular architecture allows for easy addition of new features.
- **Isolate for Heavy Tasks**: Uses Flutter’s `compute` function to offload heavy computations, ensuring UI responsiveness.

---

## Tech Stack

- **Frontend**: Flutter (Dart) for cross-platform mobile development.
- **Backend**: Firebase (Authentication, Firestore) for user management and data storage.
- **API**: ReNosh API (`https://renosh-api.onrender.com`) for predictions; Gemini API for AI insights.

### Libraries Used

- `firebase_auth`: Secure user authentication.
- `cloud_firestore`: Real-time database operations.
- `google_fonts`: Custom typography.
- `fl_chart`: Interactive charts.
- `carousel_slider`: Sustainability chart carousel.
- `http`: API requests.
- `shared_preferences`: Local caching.

### Tools

- Android Studio/Xcode for development
- Git for version control

---

## Prerequisites

Ensure you have the following installed/configured:

- Flutter SDK: Version 3.0.0 or higher
- Dart: Version 2.17.0 or higher
- Firebase Account: For authentication and Firestore
- Gemini API Key (Optional): For AI insights
- Android Studio/Xcode: For running the app
- Git: To clone the repository

---

## Installation

### 1. Clone the Repository

```bash
git clone https://github.com/yourusername/renosh-app.git
cd renosh-app
```

### 2. Install Dependencies

Run the following command to install the required Flutter packages:

```bash
flutter pub get
```

### 3. Set Up Firebase

- Create a Firebase project at [Firebase Console](https://console.firebase.google.com/).
- Add Android/iOS apps to your Firebase project.
- Download and place:
  - `google-services.json` into `android/app/`
  - `GoogleService-Info.plist` into `ios/Runner/`
- Enable Firebase Authentication (Email/Password) and Firestore.


### 4. Run the App

```bash
flutter run
```

---

## Contributing

1. Fork the repository.
2. Create a new branch:
```bash
git checkout -b feature/your-feature
```
3. Commit your changes:
```bash
git commit -m "Add your feature"
```
4. Push your branch:
```bash
git push origin feature/your-feature
```
5. Open a Pull Request.

---

## Known Issues

- **Gemini API Integration**: Currently uses simulated data for AI insights. Replace with real API calls in `_fetchAIInsights`.
- **Offline Mode**: May show stale data if offline too long.
- **Image Asset**: Ensure `assets/logo.jpg` exists or update the path in `establishment_dashboard.dart`.

---

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## Contact

For support or inquiries, contact us at:  
📧 **sumanthd032@gmail.com**
