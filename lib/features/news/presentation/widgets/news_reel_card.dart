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

  @override
  Widget build(BuildContext context) {
    final categoryColor =
        _categoryColors[article.category] ?? const Color(0xFF005BBB);

    return Stack(
      fit: StackFit.expand,
      children: [
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
                    size: 48,
                  ),
                ),
              );
            },
          )
        else
          Container(color: categoryColor.withValues(alpha: 0.22)),
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
        Positioned(
          top: 52,
          left: 16,
          right: 16,
          child: Row(
            children: [
              _Tag(label: article.category.toUpperCase(), color: categoryColor),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
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
                  style: const TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          left: 18,
          right: 88,
          bottom: 52,
          child: AnimatedOpacity(
            opacity: isActive ? 1 : 0.88,
            duration: const Duration(milliseconds: 240),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  article.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    height: 1.08,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  article.summary,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 15,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.tonal(
                  onPressed: onReadMore,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 10,
                    ),
                    backgroundColor: Colors.white.withValues(alpha: 0.16),
                  ),
                  child: const Text('Read Summary'),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          right: 14,
          bottom: 58,
          child: Column(
            children: [
              _ActionIcon(icon: Icons.bookmark_border, onTap: onBookmark),
              const SizedBox(height: 12),
              _ActionIcon(icon: Icons.share_outlined, onTap: onShare),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActionIcon extends StatelessWidget {
  const _ActionIcon({required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          width: 48,
          height: 48,
          child: Icon(icon, color: Colors.white),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
        ),
      ),
    );
  }
}
