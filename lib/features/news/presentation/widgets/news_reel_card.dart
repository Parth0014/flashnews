import 'package:flutter/material.dart';

import '../../domain/article.dart';

class NewsReelCard extends StatelessWidget {
  const NewsReelCard({
    super.key,
    required this.article,
    required this.isActive,
    this.optimizeForPerformance = false,
    this.isBookmarked = false,
    this.onReadMore,
    this.onShare,
    this.onBookmark,
  });

  final Article article;
  final bool isActive;
  final bool optimizeForPerformance;
  final bool isBookmarked;
  final VoidCallback? onReadMore;
  final VoidCallback? onShare;
  final VoidCallback? onBookmark;

  static const Map<String, Color> _categoryColors = {
    'general': Color(0xFF005BBB),
    'sports': Color(0xFF0F9D58),
    'technology': Color(0xFF1A73E8),
    'business': Color(0xFFE37400),
    'entertainment': Color(0xFF9C27B0),
    'health': Color(0xFF00897B),
    'science': Color(0xFF1565C0),
  };

  static bool _isTablet(double width) => width >= 600 && width < 1024;
  static bool _isDesktop(double width) => width >= 1024;

  @override
  Widget build(BuildContext context) {
    final categoryColor =
        _categoryColors[article.category] ?? const Color(0xFF005BBB);
    final dpr = MediaQuery.of(context).devicePixelRatio;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isTablet = _isTablet(width);
        final isDesktop = _isDesktop(width);

        final titleFontSize = isDesktop
            ? 36.0
            : isTablet
            ? 30.0
            : 24.0;
        final summaryFontSize = isDesktop
            ? 16.0
            : isTablet
            ? 15.0
            : 13.0;

        // Adjusted insets for contained design
        final contentRightInset = isDesktop
            ? width * 0.25
            : isTablet
            ? 100.0
            : 80.0;
        final contentLeftInset = isDesktop
            ? 32.0
            : isTablet
            ? 24.0
            : 16.0;
        final contentBottomInset = isDesktop
            ? 60.0
            : isTablet
            ? 52.0
            : 44.0;
        final actionRightInset = isDesktop
            ? 20.0
            : isTablet
            ? 16.0
            : 12.0;
        final actionBottomInset = isDesktop
            ? 68.0
            : isTablet
            ? 60.0
            : 52.0;
        final tagTopInset = isDesktop
            ? 52.0
            : isTablet
            ? 48.0
            : 44.0;
        final tagHorizontal = isDesktop
            ? 32.0
            : isTablet
            ? 24.0
            : 14.0;
        final iconSize = isDesktop
            ? 52.0
            : isTablet
            ? 48.0
            : 44.0;
        final maxSummaryLines = isDesktop
            ? 5
            : isTablet
            ? 4
            : 3;

        return RepaintBoundary(
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background image
              if ((article.imageUrl ?? '').isNotEmpty)
                Image.network(
                  article.imageUrl!,
                  fit: BoxFit.cover,
                  cacheWidth: (width * dpr).round(),
                  filterQuality: FilterQuality.low,
                  frameBuilder:
                      (context, child, frame, wasSynchronouslyLoaded) {
                        if (wasSynchronouslyLoaded || frame != null) {
                          return child;
                        }
                        return _ImageSkeleton(
                          categoryColor: categoryColor,
                          animate: !optimizeForPerformance,
                        );
                      },
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: categoryColor.withValues(alpha: 0.22),
                    child: Center(
                      child: Icon(
                        Icons.image_not_supported_outlined,
                        color: Colors.white.withValues(alpha: 0.3),
                        size: isDesktop ? 64 : 48,
                      ),
                    ),
                  ),
                )
              else
                Container(color: categoryColor.withValues(alpha: 0.22)),

              // Gradient overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: optimizeForPerformance
                        ? [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.55),
                            Colors.black.withValues(alpha: 0.82),
                          ]
                        : [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.30),
                            Colors.black.withValues(alpha: 0.70),
                            Colors.black.withValues(alpha: 0.88),
                          ],
                    stops: optimizeForPerformance
                        ? const [0.1, 0.6, 1]
                        : const [0.0, 0.4, 0.7, 1],
                  ),
                ),
              ),

              // Top bar: category + source
              Positioned(
                top: tagTopInset,
                left: tagHorizontal,
                right: tagHorizontal,
                child: Row(
                  children: [
                    _Tag(
                      label: article.category.toUpperCase(),
                      color: categoryColor,
                      isLarge: isDesktop || isTablet,
                    ),
                    const Spacer(),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isDesktop ? 12 : 9,
                        vertical: isDesktop ? 6 : 4,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        color: Colors.black.withValues(alpha: 0.45),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Text(
                        article.source,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontWeight: FontWeight.w600,
                          fontSize: isDesktop ? 13 : 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Main content
              Positioned(
                left: contentLeftInset,
                right: contentRightInset,
                bottom: contentBottomInset,
                child: AnimatedOpacity(
                  opacity: isActive ? 1 : 0.9,
                  duration: optimizeForPerformance
                      ? Duration.zero
                      : const Duration(milliseconds: 240),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        article.title,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: titleFontSize,
                          fontWeight: FontWeight.w800,
                          height: 1.08,
                        ),
                      ),
                      SizedBox(height: isDesktop ? 14 : 10),
                      Text(
                        article.summary,
                        maxLines: maxSummaryLines,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.95),
                          fontSize: summaryFontSize,
                          height: 1.5,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      SizedBox(height: isDesktop ? 18 : 14),
                      FilledButton.tonal(
                        onPressed: onReadMore,
                        style: FilledButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            horizontal: isDesktop ? 22 : 16,
                            vertical: isDesktop ? 12 : 9,
                          ),
                          backgroundColor: Colors.white.withValues(alpha: 0.18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'Read Summary',
                          style: TextStyle(
                            fontSize: isDesktop ? 14 : 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Action icons
              Positioned(
                right: actionRightInset,
                bottom: actionBottomInset,
                child: Column(
                  children: [
                    _ActionIcon(
                      icon: isBookmarked
                          ? Icons.bookmark
                          : Icons.bookmark_border,
                      onTap: onBookmark,
                      size: iconSize,
                    ),
                    SizedBox(height: isDesktop ? 16 : 12),
                    _ActionIcon(
                      icon: Icons.share_outlined,
                      onTap: onShare,
                      size: iconSize,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ActionIcon extends StatelessWidget {
  const _ActionIcon({required this.icon, this.onTap, this.size = 48});

  final IconData icon;
  final VoidCallback? onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(icon, color: Colors.white, size: size * 0.5),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label, required this.color, this.isLarge = false});

  final String label;
  final Color color;
  final bool isLarge;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isLarge ? 16 : 12,
        vertical: isLarge ? 8 : 6,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: color.withValues(alpha: 0.22),
        border: Border.all(color: color.withValues(alpha: 0.8)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          letterSpacing: 1,
          fontSize: isLarge ? 13 : 11,
        ),
      ),
    );
  }
}

class _ImageSkeleton extends StatefulWidget {
  const _ImageSkeleton({required this.categoryColor, this.animate = true});

  final Color categoryColor;
  final bool animate;

  @override
  State<_ImageSkeleton> createState() => _ImageSkeletonState();
}

class _ImageSkeletonState extends State<_ImageSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _pulse = Tween<double>(
      begin: 0.55,
      end: 0.85,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.animate) {
      return Container(color: widget.categoryColor.withValues(alpha: 0.2));
    }

    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, _) {
        return Container(
          color: widget.categoryColor.withValues(alpha: 0.18),
          child: Opacity(
            opacity: _pulse.value,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.12),
                    Colors.white.withValues(alpha: 0.22),
                    Colors.white.withValues(alpha: 0.12),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
