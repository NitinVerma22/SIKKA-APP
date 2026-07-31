import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sikkaplay/core/constants/app_colors.dart';
import 'package:sikkaplay/core/constants/app_sizes.dart';
import 'package:sikkaplay/features/profile/controllers/user_controller.dart';

class LinkOfferItem {
  final String id;
  final String title;
  final String url;
  final String estimatedTime;
  final int rewardAmount;
  int cooldownRemaining; // in seconds

  LinkOfferItem({
    required this.id,
    required this.title,
    required this.url,
    required this.estimatedTime,
    required this.rewardAmount,
    this.cooldownRemaining = 0,
  });
}

class VisitEarnScreen extends ConsumerStatefulWidget {
  const VisitEarnScreen({super.key});

  @override
  ConsumerState<VisitEarnScreen> createState() => _VisitEarnScreenState();
}

class _VisitEarnScreenState extends ConsumerState<VisitEarnScreen> {
  final Set<String> _visitedLinks = {};
  List<LinkOfferItem> _links = [];
  bool _isLoading = true;
  String? _error;
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();
    _loadLinks();
    _startCooldownTicker();
  }

  void _startCooldownTicker() {
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        for (var link in _links) {
          if (link.cooldownRemaining > 0) {
            link.cooldownRemaining--;
          }
        }
      });
      // Silent rebuild is triggered to tick down the display
    });
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadLinks() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final userServ = ref.read(userServiceProvider);
      final rawLinks = await userServ.getVisitLinks();
      if (rawLinks != null) {
        if (mounted) {
          setState(() {
            _links = rawLinks.map((l) => LinkOfferItem(
              id: l['id'] ?? '',
              title: l['title'] ?? '',
              url: l['url'] ?? '',
              estimatedTime: '8 Secs',
              rewardAmount: l['rewardAmount'] ?? 5,
              cooldownRemaining: l['cooldownRemaining'] ?? 0,
            )).toList();
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _error = 'Failed to load links from server';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error loading links: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _visitLink(LinkOfferItem link) {
    final isOnCooldown = link.cooldownRemaining > 0;
    if (_visitedLinks.contains(link.id) || isOnCooldown) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => WebVisitSimulatorScreen(
          link: link,
          onComplete: () {
            // 1. Optimistically update the UI state to mark the link as claimed/visited
            if (mounted) {
              setState(() {
                _visitedLinks.add(link.id);
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Coins Claimed! Earned ${link.rewardAmount} coins.'),
                  backgroundColor: AppColors.success,
                  duration: const Duration(seconds: 2),
                ),
              );
            }

            // 2. Perform backend claim asynchronously in the background
            final userServ = ref.read(userServiceProvider);
            userServ.claimVisitLink(link.id).then((success) async {
              if (success) {
                // Sync user profile coins silently
                ref.read(userProvider.notifier).refresh(silent: true);
                
                // Fetch latest links details (cooldowns, statuses) silently
                final rawLinks = await userServ.getVisitLinks();
                if (rawLinks != null && mounted) {
                  setState(() {
                    _links = rawLinks.map((l) => LinkOfferItem(
                      id: l['id'] ?? '',
                      title: l['title'] ?? '',
                      url: l['url'] ?? '',
                      estimatedTime: '8 Secs',
                      rewardAmount: l['rewardAmount'] ?? 5,
                      cooldownRemaining: l['cooldownRemaining'] ?? 0,
                    )).toList();
                  });
                }
              } else {
                // Revert optimistic state on failure
                if (mounted) {
                  setState(() {
                    _visitedLinks.remove(link.id);
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Failed to claim reward. Pls try again!'),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
              }
            }).catchError((error) {
              if (mounted) {
                setState(() {
                  _visitedLinks.remove(link.id);
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error claiming reward: $error'),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
            });
          },
        ),
      ),
    );
  }

  String _formatCooldown(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text(
          'Visit & Earn Coins',
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.amber.shade50,
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.amber, size: 20),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Instructions: Tap any link, stay on the webpage for at least 8 seconds, and do not exit. Your coins will be credited instantly!',
                    style: TextStyle(color: Colors.black87, fontSize: 12, height: 1.4, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  )
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(_error!, style: const TextStyle(color: Colors.red)),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadLinks,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : _links.isEmpty
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32.0),
                              child: Text(
                                'No sponsored links available yet.\nCheck back later!',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                              ),
                            ),
                          )
                        : ListView.builder(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.all(AppSizes.md),
                            itemCount: _links.length,
                            itemBuilder: (context, index) {
                              final link = _links[index];
                              final isOnCooldown = link.cooldownRemaining > 0;
                              final isVisited = _visitedLinks.contains(link.id) || isOnCooldown;

                              return Card(
                                elevation: 0,
                                margin: const EdgeInsets.only(bottom: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: const BorderSide(color: AppColors.borderLight, width: 1),
                                ),
                                color: Colors.white,
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: isVisited ? Colors.grey.withValues(alpha: 0.1) : AppColors.primary.withValues(alpha: 0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.link,
                                          color: isVisited ? Colors.grey : AppColors.primary,
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Task ${index + 1}: ${link.title}',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                                color: isVisited ? AppColors.textSecondary : AppColors.textPrimary,
                                                decoration: (isVisited && !isOnCooldown) ? TextDecoration.lineThrough : null,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Requires at least ${link.estimatedTime} stay time',
                                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      if (isOnCooldown)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: Colors.amber.shade50,
                                            borderRadius: BorderRadius.circular(16),
                                            border: Border.all(color: Colors.amber.shade200, width: 0.5),
                                          ),
                                          child: Text(
                                            'Retry: ${_formatCooldown(link.cooldownRemaining)}',
                                            style: TextStyle(
                                              color: Colors.amber.shade800,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 11,
                                            ),
                                          ),
                                        )
                                      else if (isVisited)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade100,
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: const Text(
                                            'Visited',
                                            style: TextStyle(
                                              color: Colors.grey,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                        )
                                      else
                                        Column(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              margin: const EdgeInsets.only(bottom: 6),
                                              decoration: BoxDecoration(
                                                color: AppColors.primary.withValues(alpha: 0.08),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    '+${link.rewardAmount}',
                                                    style: const TextStyle(
                                                      color: AppColors.primary,
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 11,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 2),
                                                  const Icon(Icons.monetization_on, color: AppColors.yellowGlow, size: 10),
                                                ],
                                              ),
                                            ),
                                            ElevatedButton(
                                              onPressed: () => _visitLink(link),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: AppColors.primary,
                                                foregroundColor: Colors.white,
                                                elevation: 0,
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                minimumSize: Size.zero,
                                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                              ),
                                              child: const Text('Visit', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                            ),
                                          ],
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}

class WebVisitSimulatorScreen extends StatefulWidget {
  final LinkOfferItem link;
  final VoidCallback onComplete;

  const WebVisitSimulatorScreen({
    super.key,
    required this.link,
    required this.onComplete,
  });

  @override
  State<WebVisitSimulatorScreen> createState() => _WebVisitSimulatorScreenState();
}

class _WebVisitSimulatorScreenState extends State<WebVisitSimulatorScreen> {
  int _secondsLeft = 8;
  Timer? _timer;
  bool _isClaimable = false;
  late final WebViewController _controller;
  bool _isPageLoaded = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            if (!_isPageLoaded && mounted) {
              setState(() {
                _isPageLoaded = true;
              });
              _startTimer();
            }
          },
          onNavigationRequest: (NavigationRequest request) {
            final url = request.url;
            final uri = Uri.parse(url);
            
            // Intercept non-http/https schemes (e.g. whatsapp://, tg://, intent://)
            if (uri.scheme != 'http' && uri.scheme != 'https') {
              _launchExternalUrl(url);
              return NavigationDecision.prevent;
            }
            
            // Intercept social and external target platforms
            final host = uri.host.toLowerCase();
            if (host.contains('t.me') || 
                host.contains('telegram.me') || 
                host.contains('telegram.dog') ||
                host.contains('whatsapp.com') || 
                host.contains('wa.me') || 
                host.contains('play.google.com') ||
                host.contains('youtube.com') ||
                host.contains('youtu.be') ||
                host.contains('instagram.com') ||
                host.contains('facebook.com') ||
                host.contains('twitter.com') ||
                host.contains('x.com')) {
              _launchExternalUrl(url);
              return NavigationDecision.prevent;
            }
            
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.link.url));
  }

  Future<void> _launchExternalUrl(String urlString) async {
    try {
      final Uri uri = Uri.parse(urlString);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Error launching external URL: $e');
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_secondsLeft > 1) {
          _secondsLeft--;
        } else {
          _secondsLeft = 0;
          _isClaimable = true;
          _timer?.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (!_isClaimable) {
          final shouldPop = await showDialog<bool>(
            context: context,
            builder: (dialogCtx) => AlertDialog(
              backgroundColor: const Color(0xFF1E1E2E),
              title: const Text('Exit early?', style: TextStyle(color: Colors.white)),
              content: const Text(
                'If you exit now, you will lose the reward coins. Are you sure you want to exit?',
                style: TextStyle(color: Colors.white70),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogCtx).pop(false),
                  child: const Text('Stay', style: TextStyle(color: AppColors.secondary)),
                ),
                TextButton(
                  onPressed: () => Navigator.of(dialogCtx).pop(true),
                  child: const Text('Exit & Lose Coins', style: TextStyle(color: Colors.redAccent)),
                ),
              ],
            ),
          );
          
          if (shouldPop == true && mounted) {
            Navigator.of(context).pop();
          }
        } else {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.grey.shade900,
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () {
              if (!_isClaimable) {
                // Trigger warning dialog
                Navigator.of(context).maybePop();
              } else {
                widget.onComplete();
                Navigator.of(context).pop();
              }
            },
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.link.title,
                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
              ),
              Text(
                widget.link.url,
                style: const TextStyle(color: Colors.white54, fontSize: 10, overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          actions: [
            Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _isClaimable
                  ? ElevatedButton(
                      onPressed: () {
                        widget.onComplete();
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      ),
                      child: const Text('Claim Reward', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                    )
                  : Text(
                      _isPageLoaded ? '⏱️ ${_secondsLeft}s left' : 'Loading...',
                      style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
            ),
          ],
        ),
        body: Column(
          children: [
            // Linear Progress Bar
            LinearProgressIndicator(
              value: _isPageLoaded ? (1.0 - (_secondsLeft / 8.0)) : 0.0,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(_isClaimable ? Colors.green : Colors.amber),
              minHeight: 4,
            ),
            // Real WebView Widget
            Expanded(
              child: Stack(
                children: [
                  WebViewWidget(controller: _controller),
                  if (!_isPageLoaded)
                    Container(
                      color: Colors.white,
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary)),
                            SizedBox(height: 16),
                            Text(
                              'Loading website contents...',
                              style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w500),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Reward timer will start after page is loaded.',
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
