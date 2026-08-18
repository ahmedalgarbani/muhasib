import 'package:flutter/material.dart';
import 'package:muhasib/core/theme/app_radius.dart';
import 'package:muhasib/features/main/presentation/models/card_data.dart';

/// Clipper that creates the smooth Annular Sector / Dome Arc geometry for the finance card:
/// - Narrower top edge with gentle smile arc.
/// - Wider bottom edge with concentric smile arc.
/// - Smooth rounded corners.
class CurvedCardClipper extends CustomClipper<Path> {
  final double topArcHeight;
  final double bottomArcHeight;
  final double sideSlope;
  final double cornerRadius;

  const CurvedCardClipper({
    this.topArcHeight = 6.0,
    this.bottomArcHeight = 6.0,
    this.sideSlope = 8.0,
    this.cornerRadius = 18.0,
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

    // 1. Start on left slanted edge just below top-left corner
    path.moveTo(s, ta + r);

    // 2. Top-Left rounded corner into Top Smile Arc
    path.quadraticBezierTo(s, ta * 0.25, s + r, ta * 0.25);

    // 3. Top Smile Arc: Dips gently in center to (w/2, ta)
    path.quadraticBezierTo(w / 2, ta, w - s - r, ta * 0.25);

    // 4. Top-Right rounded corner into Right Slanted Edge
    path.quadraticBezierTo(w - s, ta * 0.25, w - s + (r * 0.25), ta + r);

    // 5. Right Slanted Edge down to bottom-right corner
    path.lineTo(w, h - ba - r);

    // 6. Bottom-Right rounded corner into Bottom Smile Arc
    path.quadraticBezierTo(w, h - (ba * 0.25), w - r, h - (ba * 0.25));

    // 7. Bottom Smile Arc: Concentric smile curve dipping to (w/2, h)
    path.quadraticBezierTo(w / 2, h, r, h - (ba * 0.25));

    // 8. Bottom-Left rounded corner into Left Slanted Edge
    path.quadraticBezierTo(0, h - (ba * 0.25), 0, h - ba - r);

    // 9. Close path
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
    this.topArcHeight = 6.0,
    this.bottomArcHeight = 6.0,
    this.sideSlope = 8.0,
    this.cornerRadius = 18.0,
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
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10.0);

    canvas.drawPath(path.shift(const Offset(0, 4)), paint);
  }

  @override
  bool shouldRepaint(covariant CurvedCardShadowPainter oldDelegate) =>
      oldDelegate.shadowColor != shadowColor ||
      oldDelegate.topArcHeight != topArcHeight ||
      oldDelegate.bottomArcHeight != bottomArcHeight ||
      oldDelegate.sideSlope != sideSlope;
}

class FinanceCard extends StatelessWidget {
  final CardData data;
  final bool showBalance;
  final bool isActive;
  final double
  activeProgress; // 1.0 = center active card, 0.0 = inactive side card
  final bool dimInactive;
  final VoidCallback onToggleBalance;
  final VoidCallback? onTap;
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
    this.onTap,
    this.onSendTransfer,
    this.onReceiveTransfer,
    this.onAccountOperations,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final cardHeight = (size.height * 0.135).clamp(100.0, 120.0);

    // Continuous geometry interpolation based on activeProgress
    final topArc = 4.0 + (3.0 * activeProgress);
    final bottomArc = 4.0 + (3.0 * activeProgress);
    final sideSlope = 4.0 + (6.0 * activeProgress);
    const radius = 18.0;

    return Center(
      child: SizedBox(
        height: cardHeight,
        width: double.infinity,
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: CustomPaint(
            painter: CurvedCardShadowPainter(
              shadowColor: data.gradientColors.first.withValues(
                alpha: (0.32 * activeProgress).clamp(0.08, 0.35),
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
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: data.gradientColors,
                  ),
                ),
                child: Stack(
                  children: [
                    // Background subtle circular glowing decorations
                    Positioned(
                      top: -24,
                      right: -16,
                      child: Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -30,
                      left: -20,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.06),
                        ),
                      ),
                    ),

                    // Soft depth dimming overlay on inactive side cards
                    if (dimInactive && activeProgress < 0.98)
                      Positioned.fill(
                        child: Container(
                          color: Colors.black.withValues(
                            alpha: ((1.0 - activeProgress) * 0.25).clamp(
                              0.0,
                              0.35,
                            ),
                          ),
                        ),
                      ),

                    // Card Content: Name and Amount
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
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
                                horizontal: 8,
                                vertical: 2,
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
                                      alpha: (0.92 * activeProgress).clamp(
                                        0.55,
                                        0.92,
                                      ),
                                    ),
                                    size: 14.5,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    data.title.isNotEmpty
                                        ? data.title
                                        : 'الرصيد الحالي',
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: (0.92 * activeProgress).clamp(
                                          0.65,
                                          0.92,
                                        ),
                                      ),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 5),

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
                                        alpha: (1.0 * activeProgress).clamp(
                                          0.75,
                                          1.0,
                                        ),
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
                                          0.65,
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
          ),
        ),
      ),
    );
  }
}
