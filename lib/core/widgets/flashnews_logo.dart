import 'package:flutter/material.dart';

class FlashNewsLogo extends StatelessWidget {
  const FlashNewsLogo({
    super.key,
    this.size = 42,
    this.showWordmark = true,
    this.wordmarkColor = Colors.white,
  });

  final double size;
  final bool showWordmark;
  final Color wordmarkColor;

  @override
  Widget build(BuildContext context) {
    final icon = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.26),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1B6BFF), Color(0xFF00B7A8)],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x551B6BFF),
            blurRadius: 14,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(
            'F',
            style: TextStyle(
              fontSize: size * 0.56,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 1,
            ),
          ),
          Positioned(
            right: size * 0.12,
            top: size * 0.1,
            child: Icon(
              Icons.bolt_rounded,
              size: size * 0.43,
              color: const Color(0xFFFFD347),
              shadows: const [Shadow(color: Color(0x99FF9F1A), blurRadius: 8)],
            ),
          ),
        ],
      ),
    );

    if (!showWordmark) return icon;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        icon,
        const SizedBox(width: 10),
        Text(
          'FlashNews',
          style: TextStyle(
            color: wordmarkColor,
            fontSize: size * 0.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}
