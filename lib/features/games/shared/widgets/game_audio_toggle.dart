import 'package:flutter/material.dart';
import 'package:sikkaplay/features/games/shared/audio/game_audio.dart';

class GameAudioToggle extends StatelessWidget {
  const GameAudioToggle({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: GameAudio.isMuted,
      builder: (context, isMuted, child) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.3),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 1.5,
            ),
          ),
          child: IconButton(
            icon: Icon(
              isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
              color: isMuted ? Colors.white54 : Colors.white,
              size: 24,
            ),
            onPressed: () {
              GameAudio.toggleMute();
            },
            tooltip: isMuted ? 'Unmute' : 'Mute',
          ),
        );
      },
    );
  }
}
