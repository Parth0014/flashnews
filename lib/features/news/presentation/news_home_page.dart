import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  static const _categories = <({String label, String value})>[
    (label: 'Top', value: 'general'),
    (label: 'Sports', value: 'sports'),
    (label: 'Tech', value: 'technology'),
    (label: 'Business', value: 'business'),
  ];

  final PageController _pageController = PageController();
  String _selectedCategory = 'general';
  int _currentIndex = 0;
  late Future<List<Article>> _headlinesFuture;

  // Breakpoints
  static bool _isTablet(double width) => width >= 600 && width < 1024;
  static bool _isDesktop(double width) => width >= 1024;

  @override
  void initState() {
    super.initState();
    _headlinesFuture = _loadHeadlines();
  }

  Future<List<Article>> _loadHeadlines() {
    return widget.repository.fetchTopHeadlines(category: _selectedCategory);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final isTablet = _isTablet(width);
          final isDesktop = _isDesktop(width);

          return FutureBuilder<List<Article>>(
            future: _headlinesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(
                  child: CircularProgressIndicator.adaptive(),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Failed to load headlines.'),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: () {
                            setState(() {
                              _headlinesFuture = _loadHeadlines();
                            });
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final articles = snapshot.data ?? <Article>[];
              if (articles.isEmpty) {
                return const Center(child: Text('No headlines available.'));
              }

              return Stack(
                children: [
                  // Main page view
                  PageView.builder(
                    controller: _pageController,
                    scrollDirection: Axis.vertical,
                    itemCount: articles.length,
                    onPageChanged: (index) {
                      if (!kIsWeb) {
                        HapticFeedback.selectionClick();
                      }
                      setState(() {
                        _currentIndex = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      final article = articles[index];
                      return NewsReelCard(
                        article: article,
                        isActive: index == _currentIndex,
                        onReadMore: () => _showArticleSheet(article, isDesktop),
                        onShare: () =>
                            _showActionToast('Share is ready to plug in.'),
                        onBookmark: () =>
                            _showActionToast('Saved to bookmarks.'),
                      );
                    },
                  ),

                  // Top bar: chips + refresh
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 8,
                    left: isDesktop
                        ? 48
                        : isTablet
                        ? 24
                        : 12,
                    right: isDesktop
                        ? 48
                        : isTablet
                        ? 24
                        : 56,
                    child: _buildTopBar(
                      isDesktop: isDesktop,
                      isTablet: isTablet,
                    ),
                  ),

                  // Refresh button (only shown on non-desktop where it fits
                  // separately from chips)
                  if (!isDesktop)
                    Positioned(
                      top: MediaQuery.of(context).padding.top + 8,
                      right: isTablet ? 16 : 12,
                      child: _buildRefreshButton(),
                    ),

                  // Scroll indicator dots
                  Positioned(
                    right: isDesktop
                        ? 24
                        : isTablet
                        ? 16
                        : 8,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: _buildScrollIndicator(articles.length),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildTopBar({required bool isDesktop, required bool isTablet}) {
    if (isDesktop) {
      // On desktop, show chips and refresh in one row
      return Row(
        children: [
          ..._categories.map(
            (category) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _buildChip(category),
            ),
          ),
          const Spacer(),
          _buildRefreshButton(),
        ],
      );
    }

    // Phone and tablet: chips in scrollable row
    return SizedBox(
      height: isTablet ? 46 : 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) => _buildChip(_categories[index]),
      ),
    );
  }

  Widget _buildChip(({String label, String value}) category) {
    return ChoiceChip(
      label: Text(category.label),
      selected: _selectedCategory == category.value,
      onSelected: (selected) {
        if (!selected || _selectedCategory == category.value) return;
        HapticFeedback.selectionClick();
        setState(() {
          _selectedCategory = category.value;
          _currentIndex = 0;
          _headlinesFuture = _loadHeadlines();
        });
      },
    );
  }

  Widget _buildRefreshButton() {
    return IconButton(
      onPressed: () async {
        await widget.repository.clearCache();
        if (mounted) {
          setState(() {
            _currentIndex = 0;
            _headlinesFuture = _loadHeadlines();
          });
          _showActionToast('Cache cleared. Fetching fresh data...');
        }
      },
      icon: const Icon(Icons.refresh, color: Colors.white),
      tooltip: 'Clear cache and refresh',
    );
  }

  Widget _buildScrollIndicator(int total) {
    final count = total > 10 ? 10 : total;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(count, (i) {
        final isActive = i == (_currentIndex % 10);
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
    );
  }

  void _showActionToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  void _showArticleSheet(Article article, bool isDesktop) {
    if (isDesktop) {
      // On desktop use a dialog instead of bottom sheet
      showDialog<void>(
        context: context,
        builder: (context) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680, maxHeight: 560),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    article.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${article.source} • ${_relativeTime(article.publishedAt)}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Text(
                        article.summary,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
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
      return;
    }

    // Phone & tablet: bottom sheet with max width constraint
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.65,
              minChildSize: 0.4,
              maxChildSize: 0.92,
              builder: (context, scrollController) {
                return ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                  children: [
                    Text(
                      article.title,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${article.source} • ${_relativeTime(article.publishedAt)}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      article.summary,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  String _relativeTime(DateTime publishedAt) {
    final diff = DateTime.now().difference(publishedAt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
