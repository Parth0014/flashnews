import 'package:flutter/foundation.dart';

import '../domain/article.dart';
import '../domain/news_repository.dart';

class MockNewsRepository implements NewsRepository {
  int _page = 1;

  static const _mockData = [
    (
      title: 'Global Markets Rally as Tech Stocks Lead Gains',
      source: 'FlashWire',
      summary:
          'Major indexes closed higher after strong earnings reports from leading semiconductor and cloud companies.',
      imageUrl:
          'https://images.unsplash.com/photo-1611974260368-a85a3f2c5986?w=500&h=300&fit=crop',
      category: 'business',
    ),
    (
      title: 'City Council Approves New Clean Transit Plan',
      source: 'Metro Daily',
      summary:
          'The proposal includes electric buses, expanded bike lanes, and a five-year rollout backed by federal grants.',
      imageUrl:
          'https://images.unsplash.com/photo-1570125909232-eb263c188f7e?w=500&h=300&fit=crop',
      category: 'general',
    ),
    (
      title: 'Scientists Report Breakthrough in Battery Recycling',
      source: 'Science Now',
      summary:
          'Researchers developed a process that recovers more than 90% of lithium and cobalt from used battery packs.',
      imageUrl:
          'https://images.unsplash.com/photo-1581092918056-0c4c3acd3789?w=500&h=300&fit=crop',
      category: 'technology',
    ),
    (
      title: 'Champions League Final Set for Epic Clash',
      source: 'Sports Today',
      summary:
          'Two powerhouse clubs meet in what analysts are calling the most anticipated final in a decade.',
      imageUrl:
          'https://images.unsplash.com/photo-1508098682722-e99c43a406b2?w=500&h=300&fit=crop',
      category: 'sports',
    ),
    (
      title: 'New Study Links Sleep Quality to Productivity',
      source: 'Health Weekly',
      summary:
          'Researchers found workers with consistent sleep schedules outperformed peers by up to 20% on complex tasks.',
      imageUrl:
          'https://images.unsplash.com/photo-1541781774459-bb2af2f05b55?w=500&h=300&fit=crop',
      category: 'health',
    ),
    (
      title: 'AI Model Beats Humans at Complex Strategy Game',
      source: 'TechPulse',
      summary:
          'The latest reinforcement learning model achieved superhuman performance without any prior training data.',
      imageUrl:
          'https://images.unsplash.com/photo-1677442135703-1787eea5ce01?w=500&h=300&fit=crop',
      category: 'technology',
    ),
  ];

  List<Article> _buildBatch(int page) {
    return _mockData
        .map(
          (d) => Article(
            title: '${d.title} (p$page)',
            source: d.source,
            publishedAt: DateTime.now().subtract(Duration(minutes: page * 30)),
            summary: d.summary,
            category: d.category,
            imageUrl: d.imageUrl,
          ),
        )
        .toList();
  }

  @override
  Future<List<Article>> fetchTopHeadlines({String category = 'general'}) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    _page = 1;
    debugPrint('[FLashNewS:Mock] Returning demo data page 1');
    return _buildBatch(1);
  }

  @override
  Future<List<Article>> fetchNextPage({String category = 'general'}) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    _page++;
    debugPrint('[FLashNewS:Mock] Returning demo data page $_page');
    return _buildBatch(_page);
  }

  @override
  Future<void> clearCache() async {
    _page = 1;
    debugPrint('[FLashNewS:Mock] Cache cleared');
  }
}
