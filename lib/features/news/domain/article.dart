class Article {
  const Article({
    required this.title,
    required this.source,
    required this.publishedAt,
    required this.summary,
    required this.category,
    this.fullContent,
    this.url,
    this.author,
    this.imageUrl,
  });

  final String title;
  final String source;
  final DateTime publishedAt;
  final String summary;
  final String category;
  final String? fullContent;
  final String? url;
  final String? author;
  final String? imageUrl;

  factory Article.fromJson(Map<String, dynamic> json) {
    return Article(
      title: (json['title'] as String?) ?? 'Untitled',
      source: (json['source'] as String?) ?? 'Unknown source',
      publishedAt:
          DateTime.tryParse(json['publishedAt'] as String? ?? '') ??
          DateTime.now(),
      summary: (json['summary'] as String?) ?? 'No summary available.',
      category: (json['category'] as String?) ?? 'general',
      fullContent: json['fullContent'] as String?,
      url: json['url'] as String?,
      author: json['author'] as String?,
      imageUrl: json['imageUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'source': source,
      'publishedAt': publishedAt.toIso8601String(),
      'summary': summary,
      'category': category,
      'fullContent': fullContent,
      'url': url,
      'author': author,
      'imageUrl': imageUrl,
    };
  }
}
