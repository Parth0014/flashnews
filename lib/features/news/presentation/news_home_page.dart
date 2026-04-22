import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/widgets/flashnews_logo.dart';
import '../domain/article.dart';
import '../domain/news_repository.dart';
import 'widgets/news_reel_card.dart';

class NewsHomePage extends StatefulWidget {
  const NewsHomePage({super.key, required this.repository});

  final NewsRepository repository;

  @override
  State<NewsHomePage> createState() => _NewsHomePageState();
}

class _NewsHomePageState extends State<NewsHomePage> {
  static const _bookmarksKey = 'flashnews.bookmarks';

  static const _categories = <({String label, String value})>[
    (label: 'Top', value: 'general'),
    (label: 'Sports', value: 'sports'),
    (label: 'Tech', value: 'technology'),
    (label: 'Business', value: 'business'),
    (label: 'Entertainment', value: 'entertainment'),
    (label: 'Health', value: 'health'),
    (label: 'Science', value: 'science'),
  ];

  // How many cards from the end triggers a background fetch
  static const _prefetchThreshold = 4;

  final PageController _pageController = PageController();
  String _selectedCategory = 'general';
  int _currentIndex = 0;

  // The live article list — grows as more pages load
  List<Article> _articles = [];

  bool _initialLoading = true;
  bool _loadingMore = false;
  bool _hasError = false;
  final bool _forceOptimization = true;
  Set<String> _bookmarkedArticleKeys = <String>{};
  Map<String, Article> _bookmarkedArticles = <String, Article>{};
  String _errorMessage = '';

  static bool _isTablet(double width) => width >= 600 && width < 1024;
  static bool _isDesktop(double width) => width >= 1024;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );
    _loadPreferences();
    _loadInitial();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // ─── Data loading ─────────────────────────────────────────────────────────

  Future<void> _loadInitial() async {
    setState(() {
      _initialLoading = true;
      _hasError = false;
      _articles = [];
      _currentIndex = 0;
    });

    try {
      final articles = await widget.repository.fetchTopHeadlines(
        category: _selectedCategory,
      );
      if (mounted) {
        setState(() {
          _articles = articles;
          _initialLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _initialLoading = false;
          _hasError = true;
          _errorMessage = e.toString();
        });
      }
    }
  }

  Future<void> _loadNextPage() async {
    if (_loadingMore) return;
    setState(() => _loadingMore = true);

    try {
      final more = await widget.repository.fetchNextPage(
        category: _selectedCategory,
      );
      if (mounted && more.isNotEmpty) {
        setState(() {
          _articles.addAll(more);
        });
        debugPrint('[FLashNewS] Feed extended to ${_articles.length} articles');
      }
    } catch (e) {
      debugPrint('[FLashNewS] fetchNextPage failed: $e');
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  void _onPageChanged(int index) {
    if (_currentIndex != index && mounted) {
      setState(() => _currentIndex = index);
    }

    // Prefetch when near the end of real articles
    final realIndex = index % (_articles.isEmpty ? 1 : _articles.length);
    final distanceFromEnd = _articles.length - realIndex;
    if (distanceFromEnd <= _prefetchThreshold && !_loadingMore) {
      _loadNextPage();
    }
  }

  Future<void> _onRefresh() async {
    await widget.repository.clearCache();
    if (mounted) {
      if (_pageController.hasClients) _pageController.jumpToPage(0);
      _showActionToast('Cache cleared. Fetching fresh data...');
      await _loadInitial();
    }
  }

  void _onCategoryChanged(String newCategory) {
    if (_selectedCategory == newCategory) return;
    setState(() {
      _selectedCategory = newCategory;
      _currentIndex = 0;
    });
    if (_pageController.hasClients) _pageController.jumpToPage(0);
    _loadInitial();
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final isTablet = _isTablet(width);
          final isDesktop = _isDesktop(width);

          if (_initialLoading) {
            return const Center(child: CircularProgressIndicator.adaptive());
          }

          if (_hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.wifi_off_rounded,
                      size: 48,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Failed to load headlines.',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _errorMessage,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                      textAlign: TextAlign.center,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: _loadInitial,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (_articles.isEmpty) {
            return const Center(child: Text('No headlines available.'));
          }

          return Column(
            children: [
              // ── Header Container ───────────────────────────────────────
              Container(
                color: Colors.black.withValues(alpha: 0.7),
                padding: EdgeInsets.fromLTRB(
                  isDesktop
                      ? 48
                      : isTablet
                      ? 24
                      : 16,
                  MediaQuery.of(context).padding.top + 12,
                  isDesktop
                      ? 48
                      : isTablet
                      ? 24
                      : 16,
                  16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    FlashNewsLogo(
                      size: isDesktop
                          ? 48
                          : isTablet
                          ? 44
                          : 40,
                    ),
                    const SizedBox(height: 16),
                    // Categories & Refresh
                    _buildTopBar(isDesktop: isDesktop, isTablet: isTablet),
                  ],
                ),
              ),

              // ── Content Container ──────────────────────────────────────
              Expanded(
                child: Container(
                  margin: EdgeInsets.symmetric(
                    horizontal: isDesktop
                        ? 48
                        : isTablet
                        ? 24
                        : 12,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      if (!_forceOptimization)
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Stack(
                      children: [
                        // ── Infinite PageView ─────────────────────────────
                        PageView.builder(
                          controller: _pageController,
                          scrollDirection: Axis.vertical,
                          itemCount: null, // truly infinite
                          onPageChanged: _onPageChanged,
                          itemBuilder: (context, index) {
                            // cycle through real articles infinitely
                            final article = _articles[index % _articles.length];
                            // detect when we're on the last real card (before cycling)
                            final isLastReal =
                                (index % _articles.length) ==
                                _articles.length - 1;

                            return Stack(
                              children: [
                                NewsReelCard(
                                  article: article,
                                  isActive: index == _currentIndex,
                                  optimizeForPerformance: _forceOptimization,
                                  isBookmarked: _bookmarkedArticleKeys.contains(
                                    _articleKey(article),
                                  ),
                                  onReadMore: () =>
                                      _showArticleSheet(article, isDesktop),
                                  onShare: () => _shareArticle(article),
                                  onBookmark: () => _toggleBookmark(article),
                                ),
                                // "Loading more" pill shown on last real card
                                if (isLastReal && _loadingMore)
                                  Positioned(
                                    bottom: 16,
                                    left: 0,
                                    right: 0,
                                    child: Center(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.black54,
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            SizedBox(
                                              width: 14,
                                              height: 14,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white,
                                              ),
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              'Loading more...',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),

                        // ── Scroll dots indicator ──────────────────────────
                        Positioned(
                          right: 16,
                          top: 0,
                          bottom: 0,
                          child: Center(child: _buildScrollDots()),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ─── Sub-widgets ──────────────────────────────────────────────────────────

  Widget _buildTopBar({required bool isDesktop, required bool isTablet}) {
    if (isDesktop) {
      return Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _categories
                    .map(
                      (cat) => Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: _buildChip(cat),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
          const SizedBox(width: 16),
          _buildBookmarksButton(isDesktop: isDesktop),
          const SizedBox(width: 8),
          _buildRefreshButton(),
        ],
      );
    }
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: isTablet ? 46 : 42,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, i) => _buildChip(_categories[i]),
            ),
          ),
        ),
        const SizedBox(width: 8),
        _buildBookmarksButton(isDesktop: isDesktop),
        const SizedBox(width: 8),
        _buildRefreshButton(),
      ],
    );
  }

  Widget _buildBookmarksButton({required bool isDesktop}) {
    final count = _bookmarkedArticles.length;
    return Container(
      decoration: BoxDecoration(
        color: Colors.orange.shade600,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          IconButton(
            onPressed: _showBookmarksSheet,
            icon: const Icon(Icons.bookmarks_rounded, color: Colors.white),
            tooltip: 'Bookmarks',
            iconSize: 20,
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          ),
          if (count > 0)
            Positioned(
              right: -4,
              top: -4,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? 6 : 5,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: Colors.red.shade600,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$count',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildChip(({String label, String value}) category) {
    return ChoiceChip(
      label: Text(category.label),
      selected: _selectedCategory == category.value,
      onSelected: (selected) {
        if (selected) _onCategoryChanged(category.value);
      },
      selectedColor: Colors.blue.shade600,
      backgroundColor: Colors.grey[700],
      labelStyle: TextStyle(
        color: _selectedCategory == category.value
            ? Colors.white
            : Colors.grey[300],
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildRefreshButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.blue.shade600,
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        onPressed: _onRefresh,
        icon: const Icon(Icons.refresh, color: Colors.white),
        tooltip: 'Clear cache and refresh',
        iconSize: 20,
        constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
      ),
    );
  }

  Widget _buildScrollDots() {
    const dotCount = 10;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(dotCount, (i) {
          final isActive = i == (_currentIndex % dotCount);
          return AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            margin: const EdgeInsets.symmetric(vertical: 2),
            height: isActive ? 18 : 7,
            width: isActive ? 4 : 3,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              color: isActive ? Colors.white : Colors.white38,
            ),
          );
        }),
      ),
    );
  }

  // ─── Article sheet ────────────────────────────────────────────────────────

  void _showArticleSheet(Article article, bool isDesktop) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: isDesktop ? 460 : 380,
            maxHeight: isDesktop ? 360 : 320,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Quick Summary',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Colors.blueGrey,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  article.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${article.source} • ${_relativeTime(article.publishedAt)}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: SingleChildScrollView(
                    child: Text(
                      article.summary,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(height: 1.45),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final bookmarks = prefs.getStringList(_bookmarksKey) ?? <String>[];
    final parsed = <String, Article>{};
    for (final raw in bookmarks) {
      try {
        final json = jsonDecode(raw) as Map<String, dynamic>;
        final article = Article.fromJson(json);
        parsed[_articleKey(article)] = article;
      } catch (_) {
        // Ignore malformed bookmark entries.
      }
    }

    if (mounted) {
      setState(() {
        _bookmarkedArticles = parsed;
        _bookmarkedArticleKeys = parsed.keys.toSet();
      });
    }
  }

  String _articleKey(Article article) {
    return '${article.title}|${article.source}|${article.publishedAt.toIso8601String()}';
  }

  Future<void> _toggleBookmark(Article article) async {
    final key = _articleKey(article);
    final next = Set<String>.from(_bookmarkedArticleKeys);
    final nextArticles = Map<String, Article>.from(_bookmarkedArticles);
    final added = next.add(key);
    if (!added) {
      next.remove(key);
      nextArticles.remove(key);
    } else {
      nextArticles[key] = article;
    }

    if (mounted) {
      setState(() {
        _bookmarkedArticleKeys = next;
        _bookmarkedArticles = nextArticles;
      });
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _bookmarksKey,
      nextArticles.values.map((a) => jsonEncode(a.toJson())).toList(),
    );

    if (mounted) {
      _showActionToast(added ? 'Saved to bookmarks.' : 'Removed bookmark.');
    }
  }

  Future<void> _shareArticle(Article article) async {
    final text = [
      article.title,
      '',
      article.summary,
      '',
      'Source: ${article.source}',
    ].join('\n');

    await Share.share(text, subject: article.title);
  }

  Future<void> _showBookmarksSheet() async {
    if (_bookmarkedArticles.isEmpty) {
      _showActionToast('No bookmarks yet.');
      return;
    }

    final isDesktop = _isDesktop(MediaQuery.of(context).size.width);
    final saved = _bookmarkedArticles.values.toList()
      ..sort((a, b) => b.publishedAt.compareTo(a.publishedAt));

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text(
                    'Bookmarks',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${saved.length} saved',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.55,
                child: ListView.separated(
                  itemCount: saved.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final article = saved[i];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      leading: const Icon(Icons.bookmark, color: Colors.orange),
                      title: Text(
                        article.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        '${article.source} • ${_relativeTime(article.publishedAt)}',
                      ),
                      trailing: IconButton(
                        tooltip: 'Remove bookmark',
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _toggleBookmark(article),
                      ),
                      onTap: () {
                        Navigator.of(sheetContext).pop();
                        _showArticleSheet(article, isDesktop);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showActionToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  String _relativeTime(DateTime publishedAt) {
    final diff = DateTime.now().difference(publishedAt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
