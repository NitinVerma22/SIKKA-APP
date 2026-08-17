import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../engine/water_sort_engine.dart';
import '../models/water_sort_models.dart';
import '../services/water_sort_service.dart';
import '../services/water_sort_audio_service.dart';
import '../widgets/water_sort_tube_widget.dart';
import '../widgets/water_sort_pour_overlay.dart';
import '../../shared/widgets/game_banner_ad.dart';
import '../../../../core/ads/ad_service.dart';

class WaterSortGameScreen extends StatefulWidget {
  final int levelNumber;
  final int multiplier;

  const WaterSortGameScreen({
    super.key,
    required this.levelNumber,
    this.multiplier = 2,
  });

  @override
  State<WaterSortGameScreen> createState() => _WaterSortGameScreenState();
}

class _WaterSortGameScreenState extends State<WaterSortGameScreen> with TickerProviderStateMixin {
  final WaterSortService _service = WaterSortService();
  late WaterSortGameState _gameState;
  final List<WaterSortGameState> _history = [];
  final Map<int, GlobalKey> _tubeKeys = {};

  int? _selectedTubeIndex;
  bool _isLevelWon = false;
  bool _isClaiming = false;
  bool _isPouring = false;
  int _earnedCoins = 0;

  // Active Pouring Animation Data
  Offset? _srcOffset;
  Offset? _dstOffset;
  int? _pourColorId;
  int? _pourFromIdx;
  int? _pourToIdx;

  // Power-up Usage Allocations
  int _freeUndosRemaining = 1;
  int _freeHintsRemaining = 1;
  int _extraBottlesAdded = 0;

  WaterSortMove? _activeHintMove;
  late AnimationController _pourController;

  @override
  void initState() {
    super.initState();
    _pourController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _pourController.addListener(() {
      setState(() {});
    });
    WaterSortAudioService.instance.startBgm();
    _initLevel();
  }

  @override
  void dispose() {
    _pourController.dispose();
    WaterSortAudioService.instance.stopBgm();
    super.dispose();
  }

  void _initLevel() {
    setState(() {
      _gameState = WaterSortEngine.generateLevel(widget.levelNumber);
      _history.clear();
      _selectedTubeIndex = null;
      _isLevelWon = false;
      _isClaiming = false;
      _isPouring = false;
      _earnedCoins = 0;
      _freeUndosRemaining = 1;
      _freeHintsRemaining = 1;
      _extraBottlesAdded = 0;
      _activeHintMove = null;

      _tubeKeys.clear();
      for (int i = 0; i < _gameState.tubes.length; i++) {
        _tubeKeys[i] = GlobalKey();
      }
    });
  }

  void _showRewardedAdHelper(VoidCallback onEarned) {
    if (!AdService.instance.isRewardedAdLoaded()) {
      AdService.instance.loadRewardedAd();
    }

    AdService.instance.showRewardedAd(
      context: context,
      userId: 'water_sort_user',
      onAdDismissed: () {},
      onUserEarnedReward: (reward) {
        onEarned();
      },
    );
  }

  Future<void> _onTubeTap(int index) async {
    if (_isLevelWon || _isPouring) return;

    if (_selectedTubeIndex == null) {
      if (_gameState.tubes[index].isNotEmpty) {
        setState(() {
          _selectedTubeIndex = index;
          _activeHintMove = null;
        });
      }
    } else if (_selectedTubeIndex == index) {
      setState(() {
        _selectedTubeIndex = null;
      });
    } else {
      final from = _selectedTubeIndex!;
      final to = index;

      if (WaterSortEngine.canPour(_gameState, from, to)) {
        // Measure global screen positions for smooth floating pour animation!
        final srcKey = _tubeKeys[from];
        final dstKey = _tubeKeys[to];

        Offset? srcPos;
        Offset? dstPos;

        if (srcKey?.currentContext != null && dstKey?.currentContext != null) {
          final srcBox = srcKey!.currentContext!.findRenderObject() as RenderBox;
          final dstBox = dstKey!.currentContext!.findRenderObject() as RenderBox;
          srcPos = srcBox.localToGlobal(Offset.zero);
          dstPos = dstBox.localToGlobal(Offset.zero);
        }

        final pourColor = _gameState.tubes[from].last;

        setState(() {
          _isPouring = true;
          _srcOffset = srcPos;
          _dstOffset = dstPos;
          _pourColorId = pourColor;
          _pourFromIdx = from;
          _pourToIdx = to;
        });

        _pourController.forward(from: 0.0);

        // Phase 1: Lift & Travel (0-250ms)
        await Future.delayed(const Duration(milliseconds: 250));

        // Phase 2: Liquid Stream Active -> Start Pour SFX!
        WaterSortAudioService.instance.playPourSfx();
        await Future.delayed(const Duration(milliseconds: 550));

        // Phase 2 Ends -> Stop Pour SFX immediately!
        WaterSortAudioService.instance.stopPourSfx();

        // Phase 3: Un-tilt & Return to grid (200ms)
        await Future.delayed(const Duration(milliseconds: 200));

        if (!mounted) return;

        setState(() {
          _history.add(_gameState.clone());

          WaterSortEngine.executePour(_gameState, from, to);
          _selectedTubeIndex = null;
          _isPouring = false;
          _srcOffset = null;
          _dstOffset = null;

          // Check if target tube complete
          final targetTube = _gameState.tubes[to];
          if (targetTube.length == _gameState.capacity && targetTube.every((c) => c == targetTube.first)) {
            WaterSortAudioService.instance.playBottleCompleteSfx();
          }

          if (WaterSortEngine.isLevelComplete(_gameState)) {
            _onLevelComplete();
          }
        });
      } else {
        setState(() {
          if (_gameState.tubes[index].isNotEmpty) {
            _selectedTubeIndex = index;
          } else {
            _selectedTubeIndex = null;
          }
        });
      }
    }
  }

  void _handleUndo() {
    if (_history.isEmpty || _isPouring || _isLevelWon) return;

    if (_freeUndosRemaining > 0) {
      setState(() {
        _freeUndosRemaining--;
        _gameState = _history.removeLast();
        _selectedTubeIndex = null;
        _activeHintMove = null;
      });
    } else {
      _showRewardedAdHelper(() {
        setState(() {
          _freeUndosRemaining++;
          _gameState = _history.removeLast();
          _selectedTubeIndex = null;
          _activeHintMove = null;
        });
      });
    }
  }

  void _handleHint() {
    if (_isPouring || _isLevelWon) return;

    if (_freeHintsRemaining > 0) {
      final hint = WaterSortEngine.findHint(_gameState);
      if (hint != null) {
        setState(() {
          _freeHintsRemaining--;
          _activeHintMove = hint;
          _selectedTubeIndex = hint.fromIndex;
        });
      }
    } else {
      _showRewardedAdHelper(() {
        final hint = WaterSortEngine.findHint(_gameState);
        if (hint != null) {
          setState(() {
            _freeHintsRemaining++;
            _activeHintMove = hint;
            _selectedTubeIndex = hint.fromIndex;
          });
        }
      });
    }
  }

  void _handleAddExtraBottle() {
    if (_isPouring || _isLevelWon) return;

    if (_extraBottlesAdded >= 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum 2 extra bottles allowed per level!')),
      );
      return;
    }

    _showRewardedAdHelper(() {
      setState(() {
        final newIdx = _gameState.tubes.length;
        _gameState.tubes.add([]);
        _tubeKeys[newIdx] = GlobalKey();
        _extraBottlesAdded++;
      });
    });
  }

  Future<void> _onLevelComplete() async {
    WaterSortAudioService.instance.playVictorySfx();

    setState(() {
      _isLevelWon = true;
      _isClaiming = true;
    });

    final int stars = _gameState.movesCount <= 18 ? 3 : (_gameState.movesCount <= 28 ? 2 : 1);
    
    final progress = await _service.loadProgress();
    final int nextMax = _service.max(progress.maxUnlockedLevel, widget.levelNumber + 1);
    final Map<int, int> newStars = Map<int, int>.from(progress.starsMap);
    newStars[widget.levelNumber] = stars;
    await _service.saveLocalProgress(nextMax, newStars);

    final result = await _service.claimLevelReward(
      levelNumber: widget.levelNumber,
      stars: stars,
      movesCount: _gameState.movesCount,
    );

    // 3. Show Interstitial / Milestone Ad every 10 completed levels!
    if (widget.levelNumber % 10 == 0) {
      if (!AdService.instance.isInterstitialAdLoaded()) {
        AdService.instance.loadInterstitialAd();
      }
      AdService.instance.showInterstitialAd(onAdDismissed: () {});
    }

    if (mounted) {
      setState(() {
        _earnedCoins = result['coinsEarned'] ?? (widget.levelNumber * widget.multiplier);
        _isClaiming = false;
      });
    }
  }

  void _handleExit() {
    AdService.instance.showInterstitialAd(
      onAdDismissed: () {
        if (mounted) Navigator.pop(context);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleExit();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        body: Stack(
          children: [
            SafeArea(
              child: Column(
                children: [
                  // Top Bar Header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    color: const Color(0xFF1E293B),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: _handleExit,
                          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Level ${widget.levelNumber}',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              WaterSortAudioService.instance.toggleMute();
                            });
                          },
                          icon: Icon(
                            WaterSortAudioService.instance.isMuted
                                ? Icons.volume_off_rounded
                                : Icons.volume_up_rounded,
                            color: Colors.white70,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF334155),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Moves: ${_gameState.movesCount}',
                            style: GoogleFonts.outfit(
                              color: const Color(0xFF94A3B8),
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Game Canvas Board (Bottles Grid)
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 16,
                          runSpacing: 24,
                          children: List.generate(_gameState.tubes.length, (index) {
                            final tube = _gameState.tubes[index];
                            final isSelected = _selectedTubeIndex == index;
                            final isCompleted = tube.length == _gameState.capacity &&
                                tube.isNotEmpty &&
                                tube.every((c) => c == tube.first);

                            return WaterSortTubeWidget(
                              key: _tubeKeys[index],
                              tube: tube,
                              capacity: _gameState.capacity,
                              isSelected: isSelected,
                              isCompleted: isCompleted,
                              onTap: () => _onTubeTap(index),
                            );
                          }),
                        ),
                      ),
                    ),
                  ),

                  // Game Banner Ad
                  const GameBannerAd(),

                  // Power-ups Bar
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    decoration: const BoxDecoration(
                      color: Color(0xFF1E293B),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildPowerUpBtn(
                          icon: Icons.undo_rounded,
                          label: 'Undo',
                          badge: _freeUndosRemaining > 0 ? 'Free' : 'Ad',
                          onTap: _handleUndo,
                        ),
                        _buildPowerUpBtn(
                          icon: Icons.lightbulb_rounded,
                          label: 'Hint',
                          badge: _freeHintsRemaining > 0 ? 'Free' : 'Ad',
                          onTap: _handleHint,
                        ),
                        _buildPowerUpBtn(
                          icon: Icons.add_rounded,
                          label: '+Bottle',
                          badge: 'Ad 📺',
                          isAdRequired: true,
                          onTap: _handleAddExtraBottle,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 3. Floating Tilted Bottle Pouring Animation Overlay
            if (_isPouring && _srcOffset != null && _dstOffset != null && _pourColorId != null)
              WaterSortPourOverlay(
                srcPos: _srcOffset!,
                dstPos: _dstOffset!,
                liquidColorId: _pourColorId!,
                srcTube: _gameState.tubes[_pourFromIdx!],
                dstTube: _gameState.tubes[_pourToIdx!],
                capacity: _gameState.capacity,
                progress: _pourController.value,
              ),
          ],
        ),

        // Victory Dialog Overlay
        bottomSheet: _isLevelWon
            ? Container(
                height: 320,
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: Color(0xFF1E1B4B),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                  boxShadow: [
                    BoxShadow(color: Colors.black54, blurRadius: 20, spreadRadius: 5),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('🎉', style: TextStyle(fontSize: 48)),
                    const SizedBox(height: 8),
                    Text(
                      'LEVEL CLEARED!',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFFFACC15),
                        fontWeight: FontWeight.w800,
                        fontSize: 24,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_isClaiming)
                      const CircularProgressIndicator(color: Color(0xFFFACC15))
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF059669).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF34D399)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('🪙', style: TextStyle(fontSize: 20)),
                            const SizedBox(width: 8),
                            Text(
                              '+$_earnedCoins Sikka Coins',
                              style: GoogleFonts.outfit(
                                color: const Color(0xFF34D399),
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8B5CF6),
                        minimumSize: const Size(200, 52),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () {
                        AdService.instance.showInterstitialAd(
                          onAdDismissed: () {
                            if (!mounted) return;
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => WaterSortGameScreen(
                                  levelNumber: widget.levelNumber + 1,
                                  multiplier: widget.multiplier,
                                ),
                              ),
                            );
                          },
                        );
                      },
                      child: Text(
                        'NEXT LEVEL',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildPowerUpBtn({
    required IconData icon,
    required String label,
    required String badge,
    bool isAdRequired = false,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isAdRequired
              ? const Color(0xFF0284C7).withValues(alpha: 0.2)
              : const Color(0xFF334155),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isAdRequired
                ? const Color(0xFF38BDF8).withValues(alpha: 0.5)
                : const Color(0xFF475569),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isAdRequired ? const Color(0xFF38BDF8) : Colors.white, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: isAdRequired
                    ? const Color(0xFF0284C7)
                    : (badge == 'Free' ? const Color(0xFF059669) : const Color(0xFFD97706)),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                badge,
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
