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
      fullContent:
          'Major indexes closed higher after strong earnings reports from leading semiconductor and cloud companies. Analysts noted sustained demand for AI infrastructure and improved guidance for the next quarter.',
      url: 'https://example.com/business/markets-rally',
      author: 'A. Reporter',
      imageUrl:
          'https://images.unsplash.com/photo-1611974260368-a85a3f2c5986?w=500&h=300&fit=crop',
      category: 'business',
    ),
    (
      title: 'City Council Approves New Clean Transit Plan',
      source: 'Metro Daily',
      summary:
          'The proposal includes electric buses, expanded bike lanes, and a five-year rollout backed by federal grants.',
      fullContent:
          'The proposal includes electric buses, expanded bike lanes, and a five-year rollout backed by federal grants. City officials estimate emissions from urban commuting could drop by 18% by 2030.',
      url: 'https://example.com/general/clean-transit-plan',
      author: 'Metro Desk',
      imageUrl:
          'https://images.unsplash.com/photo-1570125909232-eb263c188f7e?w=500&h=300&fit=crop',
      category: 'general',
    ),
    (
      title: 'Scientists Report Breakthrough in Battery Recycling',
      source: 'Science Now',
      summary:
          'Researchers developed a process that recovers more than 90% of lithium and cobalt from used battery packs.',
      fullContent:
          'Researchers developed a process that recovers more than 90% of lithium and cobalt from used battery packs. The team says the approach can be integrated into existing recycling facilities with minimal retrofitting.',
      url: 'https://example.com/tech/battery-recycling',
      author: 'Science Bureau',
      imageUrl:
          'https://images.unsplash.com/photo-1581092918056-0c4c3acd3789?w=500&h=300&fit=crop',
      category: 'technology',
    ),
    (
      title: 'Champions League Final Set for Epic Clash',
      source: 'Sports Today',
      summary:
          'Two powerhouse clubs meet in what analysts are calling the most anticipated final in a decade.',
      fullContent:
          'Two powerhouse clubs meet in what analysts are calling the most anticipated final in a decade. Ticket demand and broadcast pre-registrations have broken previous records.',
      url: 'https://example.com/sports/champions-final',
      author: 'Sports Desk',
      imageUrl:
          'https://images.unsplash.com/photo-1508098682722-e99c43a406b2?w=500&h=300&fit=crop',
      category: 'sports',
    ),
    (
      title: 'New Study Links Sleep Quality to Productivity',
      source: 'Health Weekly',
      summary:
          'Researchers found workers with consistent sleep schedules outperformed peers by up to 20% on complex tasks.',
      fullContent:
          'Researchers found workers with consistent sleep schedules outperformed peers by up to 20% on complex tasks. The study tracked over 2,000 professionals for six months.',
      url: 'https://example.com/health/sleep-productivity',
      author: 'Health Weekly Lab',
      imageUrl:
          'https://images.unsplash.com/photo-1541781774459-bb2af2f05b55?w=500&h=300&fit=crop',
      category: 'health',
    ),
    (
      title: 'AI Model Beats Humans at Complex Strategy Game',
      source: 'TechPulse',
      summary:
          'The latest reinforcement learning model achieved superhuman performance without any prior training data.',
      fullContent:
          'The latest reinforcement learning model achieved superhuman performance without any prior training data. Independent evaluators confirmed results across multiple benchmark environments.',
      url: 'https://example.com/technology/ai-strategy-model',
      author: 'TechPulse Team',
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
            fullContent: d.fullContent,
            url: d.url,
            author: d.author,
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
