import 'package:flutter/material.dart';
import 'package:muhasib/core/theme/app_radius.dart';
import 'package:muhasib/features/main/presentation/models/card_data.dart';

/// Clipper that creates the exact Annular Sector geometry matching the blue reference image:
/// - Compact height (name and amount only)
/// - Top edge is SMALLER (narrower width) and curves in a concentric smile arc.
/// - Bottom edge is BIGGER (wider width) and curves in a concentric smile arc.
/// - Sides slope outwards from top to bottom.
/// - All 4 corners are smoothly rounded.
class CurvedCardClipper extends CustomClipper<Path> {
  final double topArcHeight;
  final double bottomArcHeight;
  final double sideSlope;
  final double cornerRadius;

  const CurvedCardClipper({
    this.topArcHeight = 8.0,
    this.bottomArcHeight = 8.0,
    this.sideSlope = 14.0,
    this.cornerRadius = 16.0,
  });

  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;
    final r = cornerRadius;
    final ta = topArcHeight;
    final ba = bottomArcHeight;
    final s = sideSlope;

    final path = Path();

    // 1. Top-Left: Start on left slanted edge just below top-left corner
    path.moveTo(s, ta + r);

    // 2. Top-Left rounded corner into Top Smile Arc
    path.quadraticBezierTo(s, ta * 0.3, s + r, ta * 0.3);

    // 3. Top Smile Arc: Dips downwards in center to (w/2, ta), ends at (w - s - r, ta * 0.3)
    path.quadraticBezierTo(w / 2, ta, w - s - r, ta * 0.3);

    // 4. Top-Right rounded corner into Right Slanted Edge
    path.quadraticBezierTo(w - s, ta * 0.3, w - s + (r * 0.2), ta + r);

    // 5. Right Slanted Edge: Slopes OUTWARDS from x = (w - s) at top to x = w at bottom (Bottom is BIGGER)
    path.lineTo(w, h - ba - r);

    // 6. Bottom-Right rounded corner into Bottom Smile Arc
    path.quadraticBezierTo(w, h - (ba * 0.3), w - r, h - (ba * 0.3));

    // 7. Bottom Smile Arc: Concentric smile curve dipping to (w/2, h), ending at (r, h - ba * 0.3)
    path.quadraticBezierTo(w / 2, h, r, h - (ba * 0.3));

    // 8. Bottom-Left rounded corner into Left Slanted Edge
    path.quadraticBezierTo(0, h - (ba * 0.3), 0, h - ba - r);

    // 9. Left Slanted Edge: Slopes INWARDS from x = 0 at bottom up to x = s at top (Top is SMALLER)
    path.close();

    return path;
  }

  @override
  bool shouldReclip(covariant CurvedCardClipper oldClipper) =>
      oldClipper.topArcHeight != topArcHeight ||
      oldClipper.bottomArcHeight != bottomArcHeight ||
      oldClipper.sideSlope != sideSlope ||
      oldClipper.cornerRadius != cornerRadius;
}

class CurvedCardShadowPainter extends CustomPainter {
  final Color shadowColor;
  final double topArcHeight;
  final double bottomArcHeight;
  final double sideSlope;
  final double cornerRadius;

  const CurvedCardShadowPainter({
    required this.shadowColor,
    this.topArcHeight = 8.0,
    this.bottomArcHeight = 8.0,
    this.sideSlope = 14.0,
    this.cornerRadius = 16.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final clipper = CurvedCardClipper(
      topArcHeight: topArcHeight,
      bottomArcHeight: bottomArcHeight,
      sideSlope: sideSlope,
      cornerRadius: cornerRadius,
    );
    final path = clipper.getClip(size);

    final paint = Paint()
      ..color = shadowColor
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12.0);

    canvas.drawPath(path.shift(const Offset(0, 5)), paint);
  }

  @override
  bool shouldRepaint(covariant CurvedCardShadowPainter oldDelegate) =>
      oldDelegate.shadowColor != shadowColor;
}

class FinanceCard extends StatelessWidget {
  final CardData data;
  final bool showBalance;
  final bool isActive;
  final double activeProgress; // 1.0 = fully active center, 0.0 = inactive side
  final bool dimInactive;
  final VoidCallback onToggleBalance;
  final VoidCallback? onSendTransfer;
  final VoidCallback? onReceiveTransfer;
  final VoidCallback? onAccountOperations;

  const FinanceCard({
    super.key,
    required this.data,
    required this.showBalance,
    required this.isActive,
    this.activeProgress = 1.0,
    this.dimInactive = true,
    required this.onToggleBalance,
    this.onSendTransfer,
    this.onReceiveTransfer,
    this.onAccountOperations,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    // Compact, smaller height showing only name and amount
    final cardHeight = (size.height * 0.13).clamp(95.0, 115.0);

    const topArc = 10.0;
    const bottomArc = 8.0;
    final sideSlope = isActive ? 14.0 : 4.0;
    const radius = 16.0;

    return CustomPaint(
      painter: CurvedCardShadowPainter(
        shadowColor: data.gradientColors.first.withValues(
          alpha: (0.35 * activeProgress).clamp(0.12, 0.35),
        ),
        topArcHeight: topArc,
        bottomArcHeight: bottomArc,
        sideSlope: sideSlope,
        cornerRadius: radius,
      ),
      child: ClipPath(
        clipper: CurvedCardClipper(
          topArcHeight: topArc,
          bottomArcHeight: bottomArc,
          sideSlope: sideSlope,
          cornerRadius: radius,
        ),
        child: Container(
          height: cardHeight,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: data.gradientColors,
            ),
          ),
          child: Stack(
            children: [
              // Background subtle circular glowing decorations
              Positioned(
                top: -20,
                right: -15,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.06),
                  ),
                ),
              ),
              Positioned(
                bottom: -25,
                left: -15,
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                ),
              ),

              // Soft depth dimming overlay on inactive side cards
              if (dimInactive && activeProgress < 0.95)
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withValues(
                      alpha: ((1.0 - activeProgress) * 0.22).clamp(0.0, 0.35),
                    ),
                  ),
                ),

              // Card Content: Name and Amount only
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Top Title & Eye Toggle
                    InkWell(
                      onTap: onToggleBalance,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              showBalance
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: Colors.white.withValues(
                                alpha: (0.9 * activeProgress).clamp(0.5, 0.9),
                              ),
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              data.title.isNotEmpty
                                  ? data.title
                                  : 'الرصيد الحالي',
                              style: TextStyle(
                                color: Colors.white.withValues(
                                  alpha: (0.9 * activeProgress).clamp(0.6, 0.9),
                                ),
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 4),

                    // Amount & Currency Display
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Directionality(
                        textDirection: TextDirection.ltr,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              showBalance ? data.balance : '••••••••',
                              style: TextStyle(
                                color: Colors.white.withValues(
                                  alpha: (1.0 * activeProgress).clamp(0.7, 1.0),
                                ),
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.6,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              data.currency,
                              style: TextStyle(
                                color: Colors.white.withValues(
                                  alpha: (0.95 * activeProgress).clamp(
                                    0.6,
                                    0.95,
                                  ),
                                ),
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
