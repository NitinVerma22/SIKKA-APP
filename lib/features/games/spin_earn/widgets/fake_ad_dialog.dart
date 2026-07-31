import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sikkaplay/core/constants/app_colors.dart';

class FakeAdDialog extends StatefulWidget {
  final String title;
  final String message;
  final VoidCallback onComplete;

  const FakeAdDialog({
    super.key,
    required this.title,
    required this.message,
    required this.onComplete,
  });

  @override
  State<FakeAdDialog> createState() => _FakeAdDialogState();
}

class _FakeAdDialogState extends State<FakeAdDialog> {
  int _timeLeft = 3;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() async {
    while (_timeLeft > 0) {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        setState(() {
          _timeLeft--;
        });
      }
    }
    if (mounted) {
      Navigator.of(context).pop();
      widget.onComplete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A24),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.play_circle_fill_rounded,
                size: 64, color: AppColors.accent),
            const SizedBox(height: 24),
            Text(
              widget.title,
              textAlign: TextAlign.center,
              style: GoogleFonts.orbitron(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '${widget.message} (Wait $_timeLeft s)',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 32),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }
}
