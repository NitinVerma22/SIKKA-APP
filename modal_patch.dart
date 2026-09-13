  Widget _buildWinModal() {
    final isMilestone = _currentLevelNum % 5 == 0;
    int rewardAmount = 0;
    if (_currentLevelNum == 5) rewardAmount = 30;
    if (_currentLevelNum == 10) rewardAmount = 70;
    if (_currentLevelNum == 15) rewardAmount = 150;

    if (!isMilestone) {
      return Container(
        color: Colors.black87,
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(28),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF181B22),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFF76ED12), width: 2),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'LEVEL CLEARED! 🚀',
                  style: GoogleFonts.bebasNeue(fontSize: 36, color: const Color(0xFF76ED12)),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF76ED12),
                    foregroundColor: Colors.black,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () {
                    // Show Interstitial on normal levels
                    AdService.instance.showInterstitialAd(
                      onAdDismissed: () {
                        if (mounted) {
                          _loadLevel(_currentLevelNum + 1);
                        }
                      }
                    );
                  },
                  child: Text(
                    'NEXT LEVEL ➔',
                    style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // MILESTONE FULL SCREEN CLAIM UI
    return Scaffold(
      backgroundColor: Colors.black87,
      body: Column(
        children: [
          const SizedBox(height: 40),
          const GameBannerAd(), // Thin Banner at the top
          Expanded(
            child: Center(
              child: Container(
                margin: const EdgeInsets.all(28),
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A1B38),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.purpleAccent, width: 2),
                  boxShadow: [
                    BoxShadow(color: Colors.purpleAccent.withOpacity(0.4), blurRadius: 20)
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'MILESTONE REACHED!',
                      style: GoogleFonts.bebasNeue(fontSize: 36, color: Colors.white),
                    ),
                    const SizedBox(height: 20),
                    const Icon(Icons.card_giftcard_rounded, color: Colors.amber, size: 60),
                    const SizedBox(height: 12),
                    Text(
                      '+\$rewardAmount COINS',
                      style: GoogleFonts.orbitron(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.amber),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Watch a short video to claim your reward!',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(fontSize: 16, color: Colors.white70),
                    ),
                    const SizedBox(height: 30),
                    _isClaiming
                        ? const CircularProgressIndicator(color: Colors.purpleAccent)
                        : ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purpleAccent,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 56),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            icon: const Icon(Icons.play_circle_fill_rounded, size: 28),
                            label: Text(
                              'WATCH VIDEO',
                              style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            onPressed: () {
                              AdService.instance.showRewardedAd(
                                context: context,
                                userId: 'arrow_escape_milestone',
                                onAdDismissed: () {
                                  // Ad closed
                                },
                                onUserEarnedReward: (reward) async {
                                  if (mounted) setState(() => _isClaiming = true);
                                  
                                  // Call backend to claim
                                  await _service.claimLevelReward(
                                    levelNumber: _currentLevelNum,
                                    isMilestoneClaim: true,
                                    sessionId: _sessionId,
                                  );

                                  if (mounted) {
                                    ref.read(userProvider.notifier).addDirectCoins(rewardAmount);
                                    GameNotifications.showCoinUpdate(context, '+\$rewardAmount Sikka');
                                    setState(() => _isClaiming = false);
                                    
                                    // Reset to level 1 if 15, else next level
                                    if (_currentLevelNum == 15) {
                                       Navigator.pop(context); // Go back to level select since it's a reset
                                    } else {
                                       _loadLevel(_currentLevelNum + 1);
                                    }
                                  }
                                }
                              );
                            },
                          ),
                  ],
                ),
              ),
            ),
          ),
          const GameBannerAd(), // Thin Banner at the bottom
          const SizedBox(height: 20),
        ],
      ),
    );
  }
