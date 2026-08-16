import 'package:flutter/material.dart';
import '../models/water_sort_models.dart';
import 'water_sort_painter.dart';

class WaterSortTubeWidget extends StatefulWidget {
  final TubeState tube;
  final int capacity;
  final bool isSelected;
  final bool isCompleted;
  final VoidCallback onTap;
  final double tubeWidth;
  final double tubeHeight;

  const WaterSortTubeWidget({
    super.key,
    required this.tube,
    required this.capacity,
    required this.isSelected,
    required this.isCompleted,
    required this.onTap,
    this.tubeWidth = 64.0,
    this.tubeHeight = 180.0,
  });

  @override
  State<WaterSortTubeWidget> createState() => _WaterSortTubeWidgetState();
}

class _WaterSortTubeWidgetState extends State<WaterSortTubeWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );

    _offsetAnimation = Tween<double>(begin: 0.0, end: -20.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
  }

  @override
  void didUpdateWidget(covariant WaterSortTubeWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected && !_controller.isCompleted) {
      _controller.forward();
    } else if (!widget.isSelected && _controller.isAnimating) {
      _controller.reverse();
    } else if (!widget.isSelected && _controller.isCompleted) {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _offsetAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _offsetAnimation.value),
            child: SizedBox(
              width: widget.tubeWidth,
              height: widget.tubeHeight,
              child: CustomPaint(
                painter: WaterSortTubePainter(
                  tube: widget.tube,
                  capacity: widget.capacity,
                  isSelected: widget.isSelected,
                  isCompleted: widget.isCompleted,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
