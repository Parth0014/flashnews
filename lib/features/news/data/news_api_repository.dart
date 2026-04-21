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

  String _normalizeCategory(String category) {
    return switch (category) {
      'sports' => 'sports',
      'technology' => 'technology',
      'business' => 'business',
      _ => 'general',
    };
  }

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
      if (cached == null || updatedAtMillis == null) {
        return null;
      }

      final updatedAt = DateTime.fromMillisecondsSinceEpoch(updatedAtMillis);
      final isExpired = DateTime.now().difference(updatedAt) > _cacheTtl;
      if (!allowStale && isExpired) {
        return null;
      }

      final decoded = jsonDecode(cached) as List<dynamic>;
      final articles = decoded
          .whereType<Map<String, dynamic>>()
          .map(Article.fromJson)
          .toList(growable: false);

      if (articles.isEmpty) {
        return null;
      }
      return articles;
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeCache(String category, List<Article> articles) async {
    final prefs = await SharedPreferences.getInstance();
    final payload = jsonEncode(
      articles.map((article) => article.toJson()).toList(),
    );
    await prefs.setString(_cacheArticlesKey(category), payload);
    await prefs.setInt(
      _cacheUpdatedAtKey(category),
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  List<Article> _shuffled(List<Article> articles) {
    final copied = List<Article>.from(articles);
    copied.shuffle(Random());
    return copied;
  }

  @override
  Future<List<Article>> fetchTopHeadlines({String category = 'general'}) async {
    final normalizedCategory = _normalizeCategory(category);

    final freshCache = await _readCache(normalizedCategory, allowStale: false);
    if (freshCache != null) {
      debugPrint(
        '[FLashNewS:API] Serving $normalizedCategory from fresh local cache',
      );
      return _shuffled(freshCache);
    }

    debugPrint(
      '[FLashNewS:API] Fetching $normalizedCategory from newsapi.org...',
    );
    final uri = Uri.https('newsapi.org', '/v2/top-headlines', {
      'country': country,
      'category': normalizedCategory,
      'apiKey': apiKey,
      'pageSize': '20',
    });

    try {
      final response = await http.get(uri);
      if (response.statusCode != 200) {
        throw Exception(
          'NewsAPI request failed with status ${response.statusCode}.',
        );
      }

      final Map<String, dynamic> payload =
          jsonDecode(response.body) as Map<String, dynamic>;
      final status = payload['status'] as String?;
      if (status != 'ok') {
        final message = payload['message'] as String? ?? 'Unknown API error';
        throw Exception('NewsAPI error: $message');
      }

      final rawArticles =
          (payload['articles'] as List<dynamic>? ?? <dynamic>[]);
      final articles = rawArticles
          .whereType<Map<String, dynamic>>()
          .map(
            (item) => Article(
              title: (item['title'] as String?)?.trim().isNotEmpty == true
                  ? (item['title'] as String)
                  : 'Untitled',
              source:
                  ((item['source'] as Map<String, dynamic>?)?['name']
                      as String?) ??
                  'Unknown source',
              publishedAt:
                  DateTime.tryParse(item['publishedAt'] as String? ?? '') ??
                  DateTime.now(),
              summary:
                  (item['description'] as String?) ?? 'No summary available.',
              category: normalizedCategory,
              imageUrl: (item['urlToImage'] as String?) ?? '',
            ),
          )
          .toList(growable: false);

      await _writeCache(normalizedCategory, articles);
      debugPrint(
        '[FLashNewS:API] Successfully fetched ${articles.length} articles for $normalizedCategory',
      );
      return _shuffled(articles);
    } catch (error) {
      debugPrint(
        '[FLashNewS:API] Error fetching from API: $error. Trying stale cache...',
      );
      final staleCache = await _readCache(normalizedCategory, allowStale: true);
      if (staleCache != null) {
        debugPrint(
          '[FLashNewS:API] Serving $normalizedCategory from stale cache as fallback',
        );
        return _shuffled(staleCache);
      }
      rethrow;
    }
  }

  @override
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      for (final key in keys) {
        if (key.startsWith('newsapi.cache.')) {
          await prefs.remove(key);
        }
      }
      debugPrint('[FLashNewS:API] Cache cleared');
    } catch (e) {
      debugPrint('[FLashNewS:API] Error clearing cache: $e');
    }
  }
}
