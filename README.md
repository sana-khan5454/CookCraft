# CookCraft

CookCraft is a Flutter recipe sharing app where users can explore, search, and view recipes while admins can publish and manage new dishes. The project uses Firebase for authentication and recipe data storage, with image uploads handled through Cloudinary.

## Features

- User signup, login, and forgot-password flow with Firebase Authentication
- Separate user and admin dashboard experience
- Add new recipes with image, ingredients, description, and cooking steps
- Store and fetch recipes from Cloud Firestore
- Voice-enabled recipe search using `speech_to_text`
- Trending recipe section
- Recipe detail and profile/settings screens
- Light and dark theme support

## Tech Stack

- Flutter
- Dart
- Firebase Authentication
- Cloud Firestore
- Firebase Core
- Firebase Storage
- Cloudinary image upload API
- `speech_to_text`
- `http`
- `image_picker`
- `youtube_player_flutter`

## Project Structure

```text
lib/
  main.dart
  firebase_options.dart
  screens/
    admin_dashboard_screen.dart
    edit_recipe_screen.dart
    forgot_password_screen.dart
    home_screen.dart
    login_screen.dart
    post_recipe_screen.dart
    recipe_detail_screen.dart
    recommendation_screen.dart
    search_screen.dart
    settings_screen.dart
    signup_screen.dart
    splash_screen.dart
    user_dashboard_screen.dart
    user_profile_screen.dart
    view_recipes_screen.dart
```

## Getting Started

### Prerequisites

- Flutter SDK installed
- Dart SDK installed
- Android Studio or VS Code with Flutter support
- A Firebase project
- A Cloudinary account for recipe image uploads

### Installation

1. Clone the repository.
2. Open the project folder:

```bash
cd CookCraft/recipe_app
```

3. Install dependencies:

```bash
flutter pub get
```

4. Configure Firebase for your target platforms.
5. Update Cloudinary values inside [post_recipe_screen.dart](C:\Users\Sana Khan\OneDrive\Documents\New project\CookCraft\recipe_app\lib\screens\post_recipe_screen.dart) with your upload settings.
6. Run the app:

```bash
flutter run
```

## Firebase Setup

CookCraft depends on Firebase initialization through [firebase_options.dart](C:\Users\Sana Khan\OneDrive\Documents\New project\CookCraft\recipe_app\lib\firebase_options.dart).

Typical setup steps:

1. Create a Firebase project.
2. Enable Email/Password authentication.
3. Create a Firestore database.
4. Add your Android, iOS, or web app to Firebase.
5. Generate Flutter Firebase configuration with FlutterFire CLI.

## Cloudinary Setup

Recipe image uploads are handled in [post_recipe_screen.dart](C:\Users\Sana Khan\OneDrive\Documents\New project\CookCraft\recipe_app\lib\screens\post_recipe_screen.dart).

Before posting recipes, make sure you:

1. Create an unsigned upload preset in Cloudinary.
2. Replace the placeholder values with your own Cloudinary configuration.
3. Verify the upload URL matches your Cloudinary cloud name.

## Main Screens

- [login_screen.dart](C:\Users\Sana Khan\OneDrive\Documents\New project\CookCraft\recipe_app\lib\screens\login_screen.dart): Handles user authentication
- [admin_dashboard_screen.dart](C:\Users\Sana Khan\OneDrive\Documents\New project\CookCraft\recipe_app\lib\screens\admin_dashboard_screen.dart): Admin actions for posting and viewing recipes
- [user_dashboard_screen.dart](C:\Users\Sana Khan\OneDrive\Documents\New project\CookCraft\recipe_app\lib\screens\user_dashboard_screen.dart): Main area for users
- [search_screen.dart](C:\Users\Sana Khan\OneDrive\Documents\New project\CookCraft\recipe_app\lib\screens\search_screen.dart): Text and voice-based recipe search
- [recommendation_screen.dart](C:\Users\Sana Khan\OneDrive\Documents\New project\CookCraft\recipe_app\lib\screens\recommendation_screen.dart): Trending recipe feed
- [post_recipe_screen.dart](C:\Users\Sana Khan\OneDrive\Documents\New project\CookCraft\recipe_app\lib\screens\post_recipe_screen.dart): Recipe creation flow

## Future Improvements

- Favorites and saved recipes
- Recipe categories and filters
- Ratings and reviews
- Better trending logic based on engagement
- Secure admin role management through Firebase instead of local credential checks
- Video recipe integration enhancements

## Notes

- The app currently relies on Firebase and Cloudinary configuration before recipe posting works end to end.
- Some screens include UI text and icons that may need cleanup or polishing for production release.

## License

This project is for learning and portfolio use unless you add a separate license file.
