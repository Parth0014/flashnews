import 'package:flutter/material.dart';

import 'core/config/app_config.dart';
import 'core/theme/app_theme.dart';
import 'features/news/data/news_api_repository.dart';
import 'features/news/data/news_repository_mock.dart';
import 'features/news/domain/news_repository.dart';
import 'features/news/presentation/news_home_page.dart';

class FlashNewsApp extends StatelessWidget {
  const FlashNewsApp({super.key, this.repository});

  final NewsRepository? repository;

  @override
  Widget build(BuildContext context) {
    final resolvedRepository =
        repository ??
        (AppConfig.hasNewsApiKey
            ? NewsApiRepository(apiKey: AppConfig.newsApiKey)
            : MockNewsRepository());

    if (resolvedRepository is NewsApiRepository) {
      debugPrint('[FLashNewS] Using live NewsAPI data source');
    } else {
      debugPrint('[FLashNewS] Using demo/mock data source');
    }

    return MaterialApp(
      title: 'FLashNewS',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: NewsHomePage(repository: resolvedRepository),
    );
  }
}
