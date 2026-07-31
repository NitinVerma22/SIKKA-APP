import 'package:flutter/material.dart';
import 'package:sikkaplay/core/constants/app_colors.dart';
import 'package:sikkaplay/core/constants/app_sizes.dart';

class PremiumButton extends StatefulWidget {
  final String text;
  final VoidCallback? onTap;
  final IconData? icon;
  final bool isLoading;
  final bool isSecondary;
  final Gradient? customGradient;
  final double? width;
  final double height;
  final double borderRadius;

  const PremiumButton({
    super.key,
    required this.text,
    this.onTap,
    this.icon,
    this.isLoading = false,
    this.isSecondary = false,
    this.customGradient,
    this.width,
    this.height = 54.0,
    this.borderRadius = AppSizes.radiusMd,
  });

  @override
  State<PremiumButton> createState() => _PremiumButtonState();
}

class _PremiumButtonState extends State<PremiumButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scaleController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.95,
      upperBound: 1.0,
    );
    _scaleController.value = 1.0;
    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.onTap != null && !widget.isLoading) {
      _scaleController.reverse();
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.onTap != null && !widget.isLoading) {
      _scaleController.forward();
    }
  }

  void _onTapCancel() {
    if (widget.onTap != null && !widget.isLoading) {
      _scaleController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasCallback = widget.onTap != null;

    Widget buttonContent = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.isLoading) ...[
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(width: AppSizes.sm),
        ] else if (widget.icon != null) ...[
          Icon(widget.icon,
              size: 20,
              color: widget.isSecondary ? AppColors.primary : Colors.white),
          const SizedBox(width: AppSizes.sm),
        ],
        Text(
          widget.text,
          style: theme.textTheme.titleMedium?.copyWith(
            color: widget.isSecondary ? AppColors.primary : Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: AppSizes.getResponsiveFontSize(context, 16),
          ),
        ),
      ],
    );

    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        onTap: widget.isLoading ? null : widget.onTap,
        child: Opacity(
          opacity: hasCallback ? 1.0 : 0.6,
          child: Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              gradient: widget.isSecondary
                  ? null
                  : (widget.customGradient ?? AppColors.primaryGradient),
              color: widget.isSecondary ? Colors.white : null,
              border: widget.isSecondary
                  ? Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      width: 1.5)
                  : null,
              boxShadow: widget.isSecondary
                  ? null
                  : [
                      BoxShadow(
                        color: (widget.customGradient?.colors.first ??
                                AppColors.primary)
                            .withValues(alpha: 0.25),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            alignment: Alignment.center,
            child: buttonContent,
          ),
        ),
      ),
    );
  }
}
