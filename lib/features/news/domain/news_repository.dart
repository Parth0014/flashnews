import 'article.dart';

abstract class NewsRepository {
  Future<List<Article>> fetchTopHeadlines({String category = 'general'});
  Future<void> clearCache();
}
