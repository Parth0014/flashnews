import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/article.dart';
import '../domain/news_repository.dart';

class NewsApiRepository implements NewsRepository {
  NewsApiRepository({required this.apiKey, this.country = 'us'});

  final String apiKey;
  final String country;

  static const Duration _cacheTtl = Duration(hours: 24);
  static const int _pageSize = 20;
  static const List<String> _allCategories = [
    'general',
    'sports',
    'technology',
    'business',
    'entertainment',
    'health',
    'science',
  ];

  // In-memory page tracker per category (resets on app restart)
  final Map<String, int> _nextPage = {};

  // ─── Cache helpers ────────────────────────────────────────────────────────

  String _cacheArticlesKey(String category) =>
      'newsapi.cache.articles.$country.$category';
  String _cacheUpdatedAtKey(String category) =>
      'newsapi.cache.updatedAt.$country.$category';

  Future<List<Article>?> _readCache(
    String category, {
    required bool allowStale,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(_cacheArticlesKey(category));
      final updatedAtMillis = prefs.getInt(_cacheUpdatedAtKey(category));
      if (cached == null || updatedAtMillis == null) return null;

      final updatedAt = DateTime.fromMillisecondsSinceEpoch(updatedAtMillis);
      final isExpired = DateTime.now().difference(updatedAt) > _cacheTtl;
      if (!allowStale && isExpired) return null;

      final decoded = jsonDecode(cached) as List<dynamic>;
      final articles = decoded
          .whereType<Map<String, dynamic>>()
          .map(Article.fromJson)
          .toList(growable: false);

      return articles.isEmpty ? null : articles;
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeCache(String category, List<Article> articles) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _cacheArticlesKey(category),
      jsonEncode(articles.map((a) => a.toJson()).toList()),
    );
    await prefs.setInt(
      _cacheUpdatedAtKey(category),
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  // ─── Fetch a single category (one page) ──────────────────────────────────

  Future<List<Article>> _fetchCategory(String category, {int page = 1}) async {
    debugPrint('[FLashNewS:API] Fetching $category page $page...');
    final uri = Uri.https('newsapi.org', '/v2/top-headlines', {
      'country': country,
      'category': category,
      'apiKey': apiKey,
      'pageSize': '$_pageSize',
      'page': '$page',
    });

    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw Exception('NewsAPI ${response.statusCode} for $category p$page');
    }

    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    if ((payload['status'] as String?) != 'ok') {
      throw Exception('NewsAPI error: ${payload['message'] ?? 'Unknown'}');
    }

    final rawArticles = (payload['articles'] as List<dynamic>? ?? <dynamic>[]);

    String normalizeContent(String? value) {
      if (value == null) return '';
      return value.replaceAll(RegExp(r'\s*\[\+\d+\schars\]\s*4'), '').trim();
    }

    return rawArticles
        .whereType<Map<String, dynamic>>()
        .where(
          (item) =>
              (item['title'] as String?)?.trim().isNotEmpty == true &&
              (item['title'] as String) != '[Removed]',
        )
        .map(
          (item) => Article(
            title: (item['title'] as String).trim(),
            source:
                ((item['source'] as Map<String, dynamic>?)?['name']
                    as String?) ??
                'Unknown source',
            publishedAt:
                DateTime.tryParse(item['publishedAt'] as String? ?? '') ??
                DateTime.now(),
            summary: (() {
              final description = ((item['description'] as String?) ?? '')
                  .trim();
              final content = normalizeContent(item['content'] as String?);
              if (description.isNotEmpty && content.isNotEmpty) {
                return '$description\n\n$content';
              }
              if (description.isNotEmpty) return description;
              if (content.isNotEmpty) return content;
              return 'No summary available.';
            })(),
            category: category,
            fullContent: normalizeContent(item['content'] as String?),
            url: (item['url'] as String?) ?? '',
            author: (item['author'] as String?) ?? '',
            imageUrl: (item['urlToImage'] as String?) ?? '',
          ),
        )
        .toList(growable: false);
  }

  // ─── Public: fetch top headlines (all categories merged) ─────────────────

  @override
  Future<List<Article>> fetchTopHeadlines({String category = 'general'}) async {
    // On first load: fetch ALL categories in parallel for a rich feed
    final freshCache = await _readCache(category, allowStale: false);
    if (freshCache != null) {
      debugPrint('[FLashNewS:API] Cache hit for $category');
      return _shuffled(freshCache);
    }

    try {
      if (category == 'general') {
        // Parallel fetch of all categories → merged feed
        final results = await Future.wait(
          _allCategories.map((cat) => _fetchCategory(cat, page: 1)),
        );
        final merged = results.expand((list) => list).toList();
        merged.shuffle(Random());

        // Cache each category slice separately
        for (var i = 0; i < _allCategories.length; i++) {
          if (results[i].isNotEmpty) {
            await _writeCache(_allCategories[i], results[i]);
          }
        }
        // Also cache merged under 'general'
        await _writeCache('general', merged);

        debugPrint(
          '[FLashNewS:API] Fetched ${merged.length} articles across all categories',
        );
        return merged;
      } else {
        final articles = await _fetchCategory(category, page: 1);
        await _writeCache(category, articles);
        return _shuffled(articles);
      }
    } catch (error) {
      debugPrint('[FLashNewS:API] Error: $error — trying stale cache');
      final stale = await _readCache(category, allowStale: true);
      if (stale != null) return _shuffled(stale);
      rethrow;
    }
  }

  // ─── Public: fetch next page (called when user nears end of feed) ─────────

  @override
  Future<List<Article>> fetchNextPage({String category = 'general'}) async {
    final page = (_nextPage[category] ?? 1) + 1;
    _nextPage[category] = page;

    try {
      if (category == 'general') {
        // Cycle through all categories for next page
        final results = await Future.wait(
          _allCategories.map((cat) => _fetchCategory(cat, page: page)),
        );
        final merged = results.expand((list) => list).toList()
          ..shuffle(Random());
        debugPrint(
          '[FLashNewS:API] Next page $page: ${merged.length} more articles',
        );
        return merged;
      } else {
        final articles = await _fetchCategory(category, page: page);
        debugPrint(
          '[FLashNewS:API] Next page $page for $category: ${articles.length} articles',
        );
        return articles;
      }
    } catch (error) {
      debugPrint('[FLashNewS:API] fetchNextPage error: $error');
      // On error reset page counter so next attempt retries same page
      _nextPage[category] = page - 1;
      return [];
    }
  }

  // ─── Clear cache ──────────────────────────────────────────────────────────

  @override
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      for (final key in keys) {
        if (key.startsWith('newsapi.cache.')) await prefs.remove(key);
      }
      _nextPage.clear();
      debugPrint('[FLashNewS:API] Cache cleared');
    } catch (e) {
      debugPrint('[FLashNewS:API] Error clearing cache: $e');
    }
  }

  List<Article> _shuffled(List<Article> articles) {
    final copied = List<Article>.from(articles);
    copied.shuffle(Random());
    return copied;
  }
}
