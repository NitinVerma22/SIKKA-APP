import 'package:flutter/material.dart';
import 'package:sikkaplay/core/animations/custom_animations.dart';
import 'package:sikkaplay/core/constants/app_colors.dart';
import 'package:sikkaplay/core/constants/app_sizes.dart';

class GullakOrb extends StatefulWidget {
  final VoidCallback onTap;
  final double size;

  const GullakOrb({
    super.key,
    required this.onTap,
    this.size = 140.0,
  });

  @override
  State<GullakOrb> createState() => _GullakOrbState();
}

class _GullakOrbState extends State<GullakOrb>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scaleController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
      lowerBound: 0.90,
      upperBound: 1.0,
    );
    _scaleController.value = 1.0;
    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeOutBack,
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _scaleController.reverse();
  }

  void _onTapUp(TapUpDetails details) {
    _scaleController.forward();
  }

  void _onTapCancel() {
    _scaleController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return HoverWidget(
      offset: 8.0,
      duration: const Duration(seconds: 3),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: GestureDetector(
          onTapDown: _onTapDown,
          onTapUp: _onTapUp,
          onTapCancel: _onTapCancel,
          onTap: widget.onTap,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer Glow Ring (Performance-friendly shadow container)
              Container(
                width: widget.size + 16,
                height: widget.size + 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.18),
                      Colors.transparent,
                    ],
                    stops: const [0.6, 1.0],
                  ),
                ),
              ),
              // Main Orb Sphere
              Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    colors: [
                      Color(0xFF8F00FF),
                      AppColors.primary,
                      Color(0xFF4B34BD),
                    ],
                    center: Alignment(-0.3, -0.3),
                    radius: 0.8,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.35),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                      spreadRadius: 2,
                    ),
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.2),
                      blurRadius: 10,
                      offset: const Offset(-2, -4),
                    ),
                  ],
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Shinning Gullak/Coin symbol
                      PulseWidget(
                        duration: const Duration(milliseconds: 1800),
                        scaleFactor: 0.08,
                        child: Container(
                          padding: const EdgeInsets.all(AppSizes.sm),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.15),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                              width: 1.5,
                            ),
                          ),
                          child: const Icon(
                            Icons.monetization_on,
                            color: AppColors.yellowGlow,
                            size: 40,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSizes.xs),
                      Text(
                        'TAP GULLAK',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                              fontSize:
                                  AppSizes.getResponsiveFontSize(context, 10),
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
