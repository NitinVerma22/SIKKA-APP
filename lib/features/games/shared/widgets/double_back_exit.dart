import 'package:flutter/material.dart';

class DoubleBackExit extends StatefulWidget {
  final Widget child;
  final VoidCallback onExitConfirmed;

  const DoubleBackExit({
    super.key,
    required this.child,
    required this.onExitConfirmed,
  });

  @override
  State<DoubleBackExit> createState() => _DoubleBackExitState();
}

class _DoubleBackExitState extends State<DoubleBackExit> {
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        // Trigger the exit confirmation callback immediately
        widget.onExitConfirmed();
      },
      child: widget.child,
    );
  }
}
