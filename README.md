# Crypto Portfolio Tracker

## Overview
A Flutter app to efficiently manage and track your cryptocurrency portfolio.  
Features:
- Search and add coins from a large list.
- Real-time prices with 24h change.
- View total portfolio and individual asset values.
- Persistent local storage.
- Custom splash animations.
- Swipe to delete with confirmation.
- Sorting and manual/periodic price refreshing.

## Installation

### Prerequisites
- Flutter SDK >=3.1.0
- Dart SDK
- Android Studio / VS Code

### Steps
1. Clone: `git clone https://github.com/devduniya/crypto_portfolio_tracker_demo.git`
2. Get dependencies: `flutter pub get`
3. Run: `flutter run`

## Usage
- Add coins via search and specify holdings.
- Swipe to remove assets with confirmation.
- Tap menu icon to edit or remove assets.
- Sort portfolio by name, value, or 24h change.
- Refresh manually or rely on automated updates.

## Architecture
- BLoC for state management.
- API service for CoinGecko data fetching.
- Storage service using SharedPreferences.
- Null-safe models for data.
- Modular widget design and smooth animations.

## API Integration
- Coin List: https://api.coingecko.com/api/v3/coins/list
- Prices: https://api.coingecko.com/api/v3/simple/price
- Handles rate limiting and null values gracefully.

## Permissions
- Requires Internet permission on Android.
- No additional permissions needed.

## Dependencies
- flutter_bloc, intl, http, shared_preferences, flutter_staggered_animations, animations, rxdart

## Testing
- Includes unit tests for BLoCs and widgets.
- Run with `flutter test`.

## Future Improvements
- Push notifications for price alerts.
- Portfolio analytics charts.
- Multi-currency support.
- Cloud sync and enhanced offline mode.

## License
MIT License
"# crypto_portfolio_tracker" 
"# crypto_portfolio_tracker_demo" 


Build :-
https://drive.google.com/file/d/1qg17qEGuut3i_RT7sj--gQZuGSgL5jb-/view?usp=drivesdk
