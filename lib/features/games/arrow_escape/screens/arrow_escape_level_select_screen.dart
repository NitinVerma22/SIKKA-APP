import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'arrow_escape_game_screen.dart';
import '../services/arrow_escape_service.dart';

class NativeArrowEscapeLevelSelectScreen extends StatefulWidget {
  const NativeArrowEscapeLevelSelectScreen({super.key});

  @override
  State<NativeArrowEscapeLevelSelectScreen> createState() =>
      _NativeArrowEscapeLevelSelectScreenState();
}

class _NativeArrowEscapeLevelSelectScreenState
    extends State<NativeArrowEscapeLevelSelectScreen> {
  final ArrowEscapeService _service = ArrowEscapeService();

  int _maxUnlockedLevel = 1;
  Map<int, int> _starsMap = {};
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
        _maxUnlockedLevel = progress.maxUnlockedLevel;
        _starsMap = progress.starsMap;
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
          'SELECT LEVEL',
          style: GoogleFonts.bebasNeue(
            fontSize: 28,
            letterSpacing: 2.0,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF76ED12)))
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.88,
              ),
              itemCount: 200,
              itemBuilder: (context, index) {
                final levelNum = index + 1;
                final isUnlocked = levelNum <= _maxUnlockedLevel;
                final stars = _starsMap[levelNum] ?? 0;
                final isCurrent = levelNum == _maxUnlockedLevel;

                return InkWell(
                  onTap: isUnlocked
                      ? () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => NativeArrowEscapeGameScreen(
                                initialLevel: levelNum,
                              ),
                            ),
                          );
                          // Reload progress when returning from game
                          _loadProgress();
                        }
                      : null,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isCurrent
                          ? const Color(0xFF1E261B)
                          : (isUnlocked
                              ? const Color(0xFF161920)
                              : const Color(0xFF101217)),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isCurrent
                            ? const Color(0xFF76ED12)
                            : (isUnlocked
                                ? const Color(0xFF282C36)
                                : const Color(0xFF1A1D24)),
                        width: isCurrent ? 2 : 1,
                      ),
                    ),
                    child: isUnlocked
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '$levelNum',
                                style: GoogleFonts.bebasNeue(
                                  fontSize: 24,
                                  color: isCurrent
                                      ? const Color(0xFF76ED12)
                                      : Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(3, (starIdx) {
                                  return Icon(
                                    Icons.star_rounded,
                                    size: 14,
                                    color: starIdx < stars
                                        ? const Color(0xFFFFEA00)
                                        : Colors.white24,
                                  );
                                }),
                              ),
                            ],
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.lock_rounded,
                                size: 22,
                                color: Colors.white30,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$levelNum',
                                style: GoogleFonts.bebasNeue(
                                  fontSize: 16,
                                  color: Colors.white30,
                                ),
                              ),
                            ],
                          ),
                  ),
                );
              },
            ),
    );
  }
}
