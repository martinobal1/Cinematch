import 'package:flutter/material.dart';

class MoodPaletteBar extends StatelessWidget {
  const MoodPaletteBar({super.key, required this.colors});

  final List<int> colors;

  @override
  Widget build(BuildContext context) {
    final palette = colors.isEmpty
        ? [0xFF1a1a2e, 0xFF533483, 0xFFe94560]
        : colors;

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        height: 12,
        child: Row(
          children: [
            for (final color in palette.take(5))
              Expanded(
                child: Container(color: Color(0xFF000000 | color)),
              ),
          ],
        ),
      ),
    );
  }
}
