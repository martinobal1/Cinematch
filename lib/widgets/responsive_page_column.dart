import 'package:flutter/material.dart';

/// Na širokých obrazovkách obmedzuje šírku obsahu (typicky 70 %), namodruje k stredu.
/// Na mobiloch / úzkych oknách plná šírka s bočným paddingom.
class ResponsivePageColumn extends StatelessWidget {
  const ResponsivePageColumn({
    super.key,
    required this.child,
    this.wideBreakpoint = 900,
    this.wideWidthFactor = 0.7,
    this.narrowHorizontalPadding = 20,
  });

  final Widget child;

  /// Od tejto šírky sa použije [wideWidthFactor].
  final double wideBreakpoint;

  /// Podiel šírky viewportu na veľkých obrazovkách (napr. 0.7 = 70 %).
  final double wideWidthFactor;

  final double narrowHorizontalPadding;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth;
        final isWide = maxW >= wideBreakpoint;
        final contentW = isWide ? maxW * wideWidthFactor : maxW;

        return Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: contentW,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isWide ? 0 : narrowHorizontalPadding,
              ),
              child: child,
            ),
          ),
        );
      },
    );
  }
}
