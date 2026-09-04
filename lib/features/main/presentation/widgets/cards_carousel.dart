import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/features/main/presentation/models/card_data.dart';
import 'package:muhasib/features/main/presentation/widgets/finance_card.dart';

class CardsCarousel extends StatefulWidget {
  final List<CardData> cards;
  final bool showBalance;
  final int activeIndex;
  final Function(int) onPageChanged;
  final VoidCallback onToggleBalance;
  final VoidCallback? onSendTransfer;
  final VoidCallback? onReceiveTransfer;
  final VoidCallback? onAccountOperations;

  // Customization controls for inactive side cards effects
  final double inactiveOpacity; // Opacity for un-active cards (e.g. 0.60)
  final double inactiveScale; // Scale for un-active cards (e.g. 0.88)
  final double
  maxArchDrop; // Max vertical drop along the dome curve (e.g. 36.0)
  final double maxRotationAngle; // Tangential tilt angle in radians (e.g. 0.16)
  final bool
  hideInactiveButtons; // Whether to fade out action buttons on side cards
  final bool
  dimInactiveCards; // Whether to apply soft depth dimming overlay on side cards

  const CardsCarousel({
    super.key,
    required this.cards,
    required this.showBalance,
    required this.activeIndex,
    required this.onPageChanged,
    required this.onToggleBalance,
    this.onSendTransfer,
    this.onReceiveTransfer,
    this.onAccountOperations,
    this.inactiveOpacity = 1,
    this.inactiveScale = 0.97,
    this.maxArchDrop = 24.0,
    this.maxRotationAngle = 0.16,
    this.hideInactiveButtons = true,
    this.dimInactiveCards = true,
    this.viewportFraction = 0.85, // Closer spacing / smaller gap between cards
  });

  final double viewportFraction;

  @override
  State<CardsCarousel> createState() => _CardsCarouselState();
}

class _CardsCarouselState extends State<CardsCarousel> {
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      initialPage: widget.activeIndex,
      viewportFraction: widget.viewportFraction,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hintColor = Theme.of(context).colorScheme.onSurfaceVariant
        .withValues(alpha: 0.55);
    // Provide clean compact vertical room for the sleek compact card height
    final carouselHeight = (size.height * 0.17).clamp(135.0, 155.0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Top "اسحب للأسفل للتحديث" prompt
        Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.keyboard_double_arrow_down_rounded,
                size: 14,
                color: hintColor,
              ),
              const SizedBox(width: 4),
              Text(
                'اسحب للأسفل للتحديث',
                style: TextStyle(
                  fontSize: 11.5,
                  color: hintColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.keyboard_double_arrow_down_rounded,
                size: 14,
                color: hintColor,
              ),
            ],
          ),
        ),

        // Arc Dome Cards Carousel
        SizedBox(
          height: carouselHeight,
          child: AnimatedBuilder(
            animation: _pageController,
            builder: (context, child) {
              final double currentPage =
                  _pageController.hasClients &&
                      _pageController.position.haveDimensions
                  ? _pageController.page ?? widget.activeIndex.toDouble()
                  : widget.activeIndex.toDouble();

              return PageView.builder(
                controller: _pageController,
                itemCount: widget.cards.length,
                clipBehavior: Clip.none,
                padEnds: true,
                onPageChanged: widget.onPageChanged,
                itemBuilder: (context, index) {
                  final pageOffset = currentPage - index;
                  final absOffset = pageOffset.abs();
                  final clampedAbs = absOffset.clamp(0.0, 1.0);

                  // =================================================================
                  // MATHEMATICAL DOME ARCH (⌒) MODELING:
                  //
                  // 1. Vertical Displacement Curve dy(x):
                  //    - Peak at x = 0: dy = 0 (top-most point)
                  //    - Smooth Cosine/Harmonic drop: dy = H * sin²(π/2 * clamp(|x|, 0, 1))
                  // =================================================================
                  final double sinVal = math.sin((math.pi / 2.0) * clampedAbs);
                  final double dy =
                      (widget.maxArchDrop * sinVal * sinVal) +
                      (absOffset > 1.0 ? (absOffset - 1.0) * 28.0 : 0.0);

                  // =================================================================
                  // 2. 3D Cylindrical Wheel Arc Rotation (Top corners show, bottom corners tuck in):
                  //    - Pivot is near the bottom (Alignment(0.0, 0.65)):
                  //      * Left card tilts counter-clockwise: TOP-LEFT corner swings OUT & UP,
                  //        while bottom-right corner tucks behind center card.
                  //      * Right card tilts clockwise: TOP-RIGHT corner swings OUT & UP,
                  //        while bottom-left corner tucks behind center card.
                  // =================================================================
                  final double rotationZ =
                      -pageOffset.sign *
                      widget.maxRotationAngle *
                      math.sin((math.pi / 2.0) * clampedAbs);

                  final double rotateY =
                      -pageOffset *
                      0.15 *
                      math.sin((math.pi / 2.0) * clampedAbs);

                  // =================================================================
                  // 3. Dynamic Scale & Opacity controlled by parameters:
                  // =================================================================
                  final double scaleFactor = 1.0 - widget.inactiveScale;
                  final double scale = (1.0 - (scaleFactor * sinVal * sinVal))
                      .clamp(0.70, 1.0);

                  final double opacityFactor = 1.0 - widget.inactiveOpacity;
                  final double opacity = (1.0 - (opacityFactor * clampedAbs))
                      .clamp(0.0, 1.0);

                  // Active ratio from 1.0 (center) to 0.0 (side card)
                  final double activeProgress = (1.0 - clampedAbs).clamp(
                    0.0,
                    1.0,
                  );

                  return Transform(
                    alignment: const Alignment(0.0, 0.80),
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001) // 3D depth perspective
                      ..translate(0.0, -dy, 0.0) // curves upwards on sides
                      ..rotateZ(
                        rotationZ,
                      ) // top swings outwards, bottom tucks in
                      ..rotateY(rotateY) // 3D cylindrical wheel depth
                      ..scale(scale),
                    child: Opacity(
                      opacity: opacity,
                      child: FinanceCard(
                        data: widget.cards[index],
                        showBalance: widget.showBalance,
                        isActive: absOffset < 0.5,
                        activeProgress: activeProgress,
                        // hideInactiveButtons: widget.hideInactiveButtons,
                        dimInactive: widget.dimInactiveCards,
                        onToggleBalance: widget.onToggleBalance,
                        onSendTransfer: widget.onSendTransfer,
                        onReceiveTransfer: widget.onReceiveTransfer,
                        onAccountOperations: widget.onAccountOperations,
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),

        const SizedBox(height: 10),

        // Modern Capsule Indicator Dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.cards.length, (index) {
            final isActive = widget.activeIndex == index;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: isActive ? 24 : 6,
              height: 5.5,
              decoration: BoxDecoration(
                color: isActive
                    ? (isDark ? AppColors.primaryLight : AppColors.primary)
                    : (isDark
                          ? Colors.white.withValues(alpha: 0.25)
                          : AppColors.slate300),
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
      ],
    );
  }
}
