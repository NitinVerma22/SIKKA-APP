import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'arrow_escape_game_screen.dart';
import '../services/arrow_escape_service.dart';
import '../../../../core/ads/ad_service.dart';

class NativeArrowEscapeLevelSelectScreen extends StatefulWidget {
  const NativeArrowEscapeLevelSelectScreen({super.key});

  @override
  State<NativeArrowEscapeLevelSelectScreen> createState() =>
      _NativeArrowEscapeLevelSelectScreenState();
}

class _NativeArrowEscapeLevelSelectScreenState
    extends State<NativeArrowEscapeLevelSelectScreen> {
  final ArrowEscapeService _service = ArrowEscapeService();

  int _currentLevel = 1;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    setState(() => _isLoading = true);
    final progress = await _service.loadProgress();
    if (mounted) {
      setState(() {
        _currentLevel = progress.maxUnlockedLevel;
        if (_currentLevel < 1 || _currentLevel > 15) {
           _currentLevel = 1;
        }
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0F12),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0F12),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'LEVEL SELECT',
          style: GoogleFonts.bebasNeue(
            color: Colors.white,
            fontSize: 24,
            letterSpacing: 1.5,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF76ED12)))
          : GridView.builder(
              padding: const EdgeInsets.all(20),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.85,
              ),
              itemCount: 15,
              itemBuilder: (context, index) {
                final levelNum = index + 1;
                // Strict progression: ONLY the current level is unlocked.
                final isCurrent = levelNum == _currentLevel;
                final isLocked = !isCurrent;
                final isMilestone = levelNum % 5 == 0;

                int rewardAmount = 0;
                if (levelNum == 5) rewardAmount = 30;
                if (levelNum == 10) rewardAmount = 70;
                if (levelNum == 15) rewardAmount = 150;

                return InkWell(
                  onTap: isCurrent
                      ? () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => NativeArrowEscapeGameScreen(
                                initialLevel: levelNum,
                              ),
                            ),
                          );
                          _loadProgress();
                        }
                      : null,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isCurrent
                          ? (isMilestone ? const Color(0xFF2A1B38) : const Color(0xFF1E261B))
                          : const Color(0xFF101217),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isCurrent
                            ? (isMilestone ? Colors.purpleAccent : const Color(0xFF76ED12))
                            : const Color(0xFF1A1D24),
                        width: isCurrent ? 2 : 1,
                      ),
                      boxShadow: isCurrent
                          ? [
                              BoxShadow(
                                color: isMilestone ? Colors.purpleAccent.withOpacity(0.3) : const Color(0xFF76ED12).withOpacity(0.3),
                                blurRadius: 8,
                                spreadRadius: 1,
                              )
                            ]
                          : null,
                    ),
                    child: isLocked
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.lock_rounded,
                                color: Color(0xFF282C36),
                                size: 28,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Lvl $levelNum',
                                style: GoogleFonts.poppins(
                                  color: const Color(0xFF282C36),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          )
                        : (isMilestone
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.card_giftcard_rounded,
                                    color: Colors.purpleAccent,
                                    size: 32,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$rewardAmount',
                                    style: GoogleFonts.bebasNeue(
                                      color: Colors.amber,
                                      fontSize: 22,
                                    ),
                                  ),
                                  Text(
                                    'COINS',
                                    style: GoogleFonts.bebasNeue(
                                      color: Colors.amberAccent,
                                      fontSize: 12,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '$levelNum',
                                    style: GoogleFonts.bebasNeue(
                                      fontSize: 32,
                                      color: Colors.white,
                                      height: 1,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'PLAY',
                                    style: GoogleFonts.bebasNeue(
                                      fontSize: 16,
                                      color: const Color(0xFF76ED12),
                                      letterSpacing: 2,
                                    ),
                                  ),
                                ],
                              )),
                  ),
                );
              },
            ),
    );
  }
}
