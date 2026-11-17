# JalKavach

JalKavach is a Flutter app for flood preparedness and emergency awareness in India. It brings flood-risk information, weather, hazard maps, disaster alerts, shelters, safety guidance, and emergency contacts into one interface.

## Demo data

The app runs without a backend using simulated demonstration data by default. This data is not a live forecast or emergency alert. The client includes a FastAPI integration layer; a compatible backend must be configured before using live data.

## Run locally

Install the Flutter SDK, then from the project directory run:

```sh
flutter pub get
flutter run -d chrome
```

To run on another available target, list devices with `flutter devices` and replace `chrome` with its device ID. Windows desktop builds may require enabling Windows Developer Mode to allow symlinks.

## Branding

This project uses the JalKavach identity and shield-style logo to reflect a stronger Indian public-safety brand.

## Test

```sh
flutter test
```
