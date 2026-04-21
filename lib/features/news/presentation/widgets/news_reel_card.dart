import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../domain/article.dart';

class NewsReelCard extends StatelessWidget {
  const NewsReelCard({
    super.key,
    required this.article,
    required this.isActive,
    this.onReadMore,
    this.onShare,
    this.onBookmark,
  });

  final Article article;
  final bool isActive;
  final VoidCallback? onReadMore;
  final VoidCallback? onShare;
  final VoidCallback? onBookmark;

  static const Map<String, Color> _categoryColors = {
    'general': Color(0xFF005BBB),
    'sports': Color(0xFF0F9D58),
    'technology': Color(0xFF1A73E8),
    'business': Color(0xFFE37400),
  };

  // Breakpoints
  static bool _isTablet(double width) => width >= 600 && width < 1024;
  static bool _isDesktop(double width) => width >= 1024;

  @override
  Widget build(BuildContext context) {
    final categoryColor =
        _categoryColors[article.category] ?? const Color(0xFF005BBB);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isTablet = _isTablet(width);
        final isDesktop = _isDesktop(width);

        // Responsive values
        final titleFontSize = isDesktop
            ? 38.0
            : isTablet
            ? 32.0
            : 26.0;
        final summaryFontSize = isDesktop
            ? 17.0
            : isTablet
            ? 16.0
            : 14.0;
        final contentRightInset = isDesktop
            ? width * 0.30
            : isTablet
            ? 120.0
            : 88.0;
        final contentLeftInset = isDesktop
            ? 48.0
            : isTablet
            ? 32.0
            : 18.0;
        final contentBottomInset = isDesktop
            ? 72.0
            : isTablet
            ? 64.0
            : 52.0;
        final actionRightInset = isDesktop
            ? 24.0
            : isTablet
            ? 20.0
            : 14.0;
        final actionBottomInset = isDesktop
            ? 78.0
            : isTablet
            ? 68.0
            : 58.0;
        final tagTopInset = isDesktop
            ? 64.0
            : isTablet
            ? 58.0
            : 52.0;
        final tagLeftInset = isDesktop
            ? 48.0
            : isTablet
            ? 32.0
            : 16.0;
        final tagRightInset = isDesktop
            ? 48.0
            : isTablet
            ? 32.0
            : 16.0;
        final iconSize = isDesktop
            ? 56.0
            : isTablet
            ? 52.0
            : 48.0;
        final maxSummaryLines = isDesktop
            ? 6
            : isTablet
            ? 5
            : 4;

        return Stack(
          fit: StackFit.expand,
          children: [
            // Background image
            if ((article.imageUrl ?? '').isNotEmpty)
              Image.network(
                article.imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: categoryColor.withValues(alpha: 0.22),
                    child: Center(
                      child: Icon(
                        Icons.image_not_supported_outlined,
                        color: Colors.white.withValues(alpha: 0.3),
                        size: isDesktop ? 64 : 48,
                      ),
                    ),
                  );
                },
              )
            else
              Container(color: categoryColor.withValues(alpha: 0.22)),

            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.50),
                    Colors.black.withValues(alpha: 0.84),
                  ],
                  stops: const [0.15, 0.6, 1],
                ),
              ),
            ),

            // Top bar: category tag + source
            Positioned(
              top: tagTopInset,
              left: tagLeftInset,
              right: tagRightInset,
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
                      horizontal: isDesktop ? 14 : 10,
                      vertical: isDesktop ? 7 : 5,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      color: Colors.black.withValues(alpha: 0.30),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.18),
                      ),
                    ),
                    child: Text(
                      article.source,
                      style: TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                        fontSize: isDesktop ? 15 : 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Main content: title + summary + button
            Positioned(
              left: contentLeftInset,
              right: contentRightInset,
              bottom: contentBottomInset,
              child: AnimatedOpacity(
                opacity: isActive ? 1 : 0.88,
                duration: const Duration(milliseconds: 240),
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
                    SizedBox(height: isDesktop ? 16 : 12),
                    Text(
                      article.summary,
                      maxLines: maxSummaryLines,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: summaryFontSize,
                        height: 1.4,
                      ),
                    ),
                    SizedBox(height: isDesktop ? 20 : 16),
                    FilledButton.tonal(
                      onPressed: onReadMore,
                      style: FilledButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          horizontal: isDesktop ? 24 : 18,
                          vertical: isDesktop ? 14 : 10,
                        ),
                        backgroundColor: Colors.white.withValues(alpha: 0.16),
                      ),
                      child: Text(
                        'Read Summary',
                        style: TextStyle(fontSize: isDesktop ? 15 : 13),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Action icons: bookmark + share
            Positioned(
              right: actionRightInset,
              bottom: actionBottomInset,
              child: Column(
                children: [
                  _ActionIcon(
                    icon: Icons.bookmark_border,
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
