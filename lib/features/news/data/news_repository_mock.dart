import 'package:flutter/foundation.dart';

import '../domain/article.dart';
import '../domain/news_repository.dart';

class MockNewsRepository implements NewsRepository {
  String _normalizeCategory(String category) {
    return switch (category) {
      'sports' => 'sports',
      'technology' => 'technology',
      'business' => 'business',
      _ => 'general',
    };
  }

  @override
  Future<List<Article>> fetchTopHeadlines({String category = 'general'}) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final normalizedCategory = _normalizeCategory(category);
    debugPrint('[FLashNewS:Mock] Returning demo data for $normalizedCategory');

    return <Article>[
      Article(
        title: 'Global Markets Rally as Tech Stocks Lead Gains',
        source: 'FlashWire',
        publishedAt: DateTime.now().subtract(const Duration(minutes: 24)),
        summary:
            'Major indexes closed higher after strong earnings reports '
            'from leading semiconductor and cloud companies.',
        category: normalizedCategory,
        imageUrl:
            'https://images.unsplash.com/photo-1611974260368-a85a3f2c5986?w=500&h=300&fit=crop',
      ),
      Article(
        title: 'City Council Approves New Clean Transit Plan',
        source: 'Metro Daily',
        publishedAt: DateTime.now().subtract(const Duration(hours: 1)),
        summary:
            'The proposal includes electric buses, expanded bike lanes, '
            'and a five-year rollout backed by federal grants.',
        category: normalizedCategory,
        imageUrl:
            'https://images.unsplash.com/photo-1548574505-5e269830-a58a-4e2c-a00d-f53ddafbaf50?w=500&h=300&fit=crop',
      ),
      Article(
        title: 'Scientists Report Breakthrough in Battery Recycling',
        source: 'Science Now',
        publishedAt: DateTime.now().subtract(const Duration(hours: 2)),
        summary:
            'Researchers developed a process that recovers more than 90% '
            'of lithium and cobalt from used battery packs.',
        category: normalizedCategory,
        imageUrl:
            'https://images.unsplash.com/photo-1581092918056-0c4c3acd3789?w=500&h=300&fit=crop',
      ),
    ];
  }

  @override
  Future<void> clearCache() async {
    debugPrint('[FLashNewS:Mock] No cache to clear');
  }
}
