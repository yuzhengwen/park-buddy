# Park Buddy

Park Buddy is a Flutter mobile app built for managing parking sessions in Singapore. It combines HDB carpark location and availability data with Supabase-backed user authentication, session tracking, car management, and notification support.

## Key Features

- Supabase authentication with:
  - Magic Link email login
  - GitHub OAuth login
  - Anonymous sign-in fallback
- Interactive map view with nearby HDB carparks and availability data
- Start and manage parking sessions with:
  - car selection
  - location selection
  - session name and description
  - rate threshold alerts
  - photo uploads
- My Parking tab to view cars and recent parking activity
- Profile tab for editing user profile, managing cars, family members, and account deletion
- Local asset support for HDB carpark data plus live availability via Singapore open data APIs
- Push notification handling for parking alerts and session detail navigation

## Project Structure

- `lib/main.dart`: App entrypoint and Supabase initialization.
- `lib/screens/`: UI screens such as login, profile, parking session flow, and session details.
- `lib/tabs/`: Main bottom navigation tabs: My Parking, Map, Profile.
- `lib/services/`: Network, Supabase, storage, notifications, location, and parking session services.
- `lib/controllers/`: State controllers for map and parking session behavior.
- `lib/models/`: Domain models like `Carpark`, `ParkingSession`, and `ParkingRate`.
- `lib/UI/`: Custom widgets and map presentation components.
- `lib/utils/`: Utility helpers including parking fee calculations, location search, and geometry utilities.
- `assets/`: Static data files and app icons.

## Dependencies

This app uses the following important packages:

- `flutter`
- `provider`
- `supabase_flutter`
- `share_plus`
- `flutter_dotenv`
- `geolocator`
- `flutter_map`
- `flutter_map_animations`
- `http`
- `latlong2`
- `image_picker`
- `string_similarity`
- `font_awesome_flutter`
- `flutter_local_notifications`
- `timezone`
- `intl`

## Setup and Run

1. Install dependencies:

```bash
flutter pub get
```

2. Verify assets are included in `pubspec.yaml`:

- `assets/hdb_carparks.json`
- `assets/app_icon.png`

3. Configure Supabase:

- `lib/main.dart` currently initializes Supabase with a fixed URL and anon key.
- For production use, replace the hardcoded values with secure environment configuration or `.env` handling.

4. Run the app:

```bash
flutter run
```

5. If targeting Android or iOS, ensure the app has the following permissions configured:

- Location access
- Camera access
- Storage access

## Notes

- The app loads HDB carpark location data from `assets/hdb_carparks.json`.
- Real-time carpark availability is fetched from Singapore's open transport data API.
- User data and parking sessions are stored in Supabase tables such as `users`, `cars`, and `parkingsession`.
- Notification scheduling is handled via `flutter_local_notifications` and the `timezone` package.
- `flutter_dotenv` is listed in dependencies but the current codebase does not yet use dotenv loading; this is a good place to add secure environment support.

## Team

This repository includes contributions from the following team members:

- [Brian Su](https://github.com/brian-su-jl)
- [Yu Zhengwen](https://github.com/yuzhengwen)
- [Wei Hao](https://github.com/WeiHaoChin)
- [Bian Lingzhu](https://github.com/bianlingzhu058)
- [Hitansh](https://github.com/hitansh-45)
- [Nuvaan Murugesan](https://github.com/Nuvaan879)

## Contact

This project is maintained in the `park-buddy` repository.
