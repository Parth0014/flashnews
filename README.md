# FLashNewS

Flutter-based news app repository initialized with a production-friendly starter structure.

## Tech Stack

- Flutter 3.38+
- Dart 3.10+
- Material 3

## Run Locally

```bash
flutter pub get
flutter run
```

## NewsAPI Setup

1. Create a free key at https://newsapi.org.
2. Run the app with your key:

```bash
flutter run --dart-define=NEWS_API_KEY=your_api_key_here
```

If no key is provided, the app falls back to mock headlines.

## Caching Strategy

The app uses local device caching (via `shared_preferences`) with a 24-hour TTL. Fresh articles are fetched from NewsAPI and cached locally. If a cache hit occurs, articles are shuffled on display for variety. If the cache expires and the network is unavailable, stale cached articles are shown as a fallback.

## Project Structure

```text
lib/
	app.dart
	core/
		theme/
			app_theme.dart
	features/
		news/
			data/
				news_api_repository.dart
				news_repository_mock.dart
			domain/
				article.dart
				news_repository.dart
			presentation/
				news_home_page.dart
	main.dart

backend/
	cloudflare-worker/
		README.md
		src/
			index.ts
```

## Next Steps

- Add state management (`provider`, `bloc`, or `riverpod`).
- Introduc
