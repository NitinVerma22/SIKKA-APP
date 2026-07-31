import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:sikkaplay/core/constants/app_colors.dart';
import 'package:sikkaplay/features/reels/providers/reels_provider.dart';
import 'package:sikkaplay/features/reels/services/reel_download_service.dart';

/// A premium-styled centered dialog for downloading reels.
/// Shows format selection → animated progress → success/failure.
class ReelDownloadSheet extends ConsumerStatefulWidget {
  final String reelUrl;
  final WebViewController? webViewController;

  const ReelDownloadSheet({
    super.key,
    required this.reelUrl,
    this.webViewController,
  });

  /// Show the download dialog centered on screen.
  static Future<void> show(
    BuildContext context,
    String reelUrl, {
    WebViewController? webViewController,
  }) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Download',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return Center(
          child: ReelDownloadSheet(
            reelUrl: reelUrl,
            webViewController: webViewController,
          ),
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return ScaleTransition(
          scale: CurvedAnimation(
            parent: anim1,
            curve: Curves.easeOutBack,
          ),
          child: FadeTransition(
            opacity: anim1,
            child: child,
          ),
        );
      },
    );
  }

  @override
  ConsumerState<ReelDownloadSheet> createState() => _ReelDownloadSheetState();
}

enum _DownloadPhase { selectFormat, downloading, success, error }

class _ReelDownloadSheetState extends ConsumerState<ReelDownloadSheet>
    with TickerProviderStateMixin {
  _DownloadPhase _phase = _DownloadPhase.selectFormat;
  double _progress = 0.0;
  String _statusMessage = '';
  String? _filePath;
  bool _isVideo = true;
  String? _debugInfo;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _checkController;
  late Animation<double> _checkAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _checkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _checkAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _checkController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _checkController.dispose();
    super.dispose();
  }

  Future<void> _startDownload(bool isVideo) async {
    setState(() {
      _isVideo = isVideo;
      _phase = _DownloadPhase.downloading;
      _statusMessage = 'Finding media source...';
      _progress = 0.0;
    });

    final service = ReelDownloadService();
    ReelDownloadResult result;

    void onProgress(double progress) {
      if (mounted) {
        setState(() {
          _progress = progress;
          if (progress < 0.3) {
            _statusMessage = 'Finding media source...';
          } else if (progress < 0.5) {
            _statusMessage = isVideo ? 'Downloading video...' : 'Downloading audio...';
          } else if (progress < 0.75) {
            _statusMessage = 'Receiving data...';
          } else if (progress < 1.0) {
            _statusMessage = isVideo ? 'Saving to gallery...' : 'Saving audio file...';
          } else {
            _statusMessage = 'Done!';
          }
        });
      }
    }

    // Try DOM scraping via WebViewController first
    ReelDownloadResult? domResult;
    if (widget.webViewController != null) {
      final completer = Completer<ReelDownloadResult>();
      
      ref.read(reelsDownloadCallbackProvider.notifier).state = (String message) async {
        if (!mounted) return;
        
        if (message.startsWith('STATUS:')) {
          setState(() {
            _statusMessage = message.substring('STATUS:'.length);
          });
        } else if (message.startsWith('PROGRESS:')) {
          final val = double.tryParse(message.substring('PROGRESS:'.length)) ?? 0.0;
          onProgress(0.15 + (val * 0.70));
        } else if (message.startsWith('BYTES:')) {
          setState(() {
            _statusMessage = 'Downloading: ${message.substring('BYTES:'.length)} bytes';
          });
        } else if (message.startsWith('ERROR:')) {
          final errorMsg = message.substring('ERROR:'.length);
          if (!completer.isCompleted) {
            completer.complete(ReelDownloadResult(
              success: false,
              message: 'DOM search failed.',
              debugInfo: errorMsg,
            ));
          }
        } else if (message.startsWith('BASE64:')) {
          final data = message.substring('BASE64:'.length);
          String base64Str = data;
          if (data.contains(';base64,')) {
            base64Str = data.split(';base64,').last;
          }
          
          try {
            onProgress(0.88);
            final bytes = base64Decode(base64Str.trim());
            final saveRes = isVideo
                ? await service.saveVideoBytes(bytes, onProgress)
                : await service.saveAudioBytes(bytes, onProgress);
            if (!completer.isCompleted) {
              completer.complete(saveRes);
            }
          } catch (e) {
            if (!completer.isCompleted) {
              completer.complete(ReelDownloadResult(
                success: false,
                message: 'Failed to process downloaded data.',
                debugInfo: e.toString(),
              ));
            }
          }
        }
      };

      try {
        await widget.webViewController!.runJavaScript('''
          (async function() {
            try {
              var videos = Array.from(document.getElementsByTagName('video'));
              if (videos.length === 0) {
                window.SikkaPlayDownloadChannel.postMessage('ERROR:No video elements found on page.');
                return;
              }
              
              var activeVideo = null;
              // Check for playing video
              for (var i = 0; i < videos.length; i++) {
                var v = videos[i];
                if (!v.paused && v.currentTime > 0) {
                  activeVideo = v;
                  break;
                }
              }
              // Check for visible video in viewport
              if (!activeVideo) {
                var maxArea = 0;
                for (var i = 0; i < videos.length; i++) {
                  var v = videos[i];
                  var rect = v.getBoundingClientRect();
                  var visibleHeight = Math.min(rect.bottom, window.innerHeight) - Math.max(rect.top, 0);
                  var visibleWidth = Math.min(rect.right, window.innerWidth) - Math.max(rect.left, 0);
                  if (visibleHeight > 0 && visibleWidth > 0) {
                    var area = visibleHeight * visibleWidth;
                    if (area > maxArea) {
                      maxArea = area;
                      activeVideo = v;
                    }
                  }
                }
              }
              // Fallback
              if (!activeVideo) {
                activeVideo = videos[0];
              }
              
              var src = activeVideo.src;
              if (!src) {
                var sources = activeVideo.getElementsByTagName('source');
                if (sources.length > 0) {
                  src = sources[0].src;
                }
              }
              
              if (!src) {
                window.SikkaPlayDownloadChannel.postMessage('ERROR:No video source found.');
                return;
              }
              
              window.SikkaPlayDownloadChannel.postMessage('STATUS:Connecting to media source...');
              
              var response = await fetch(src);
              if (!response.ok) {
                window.SikkaPlayDownloadChannel.postMessage('ERROR:Failed to fetch media source: ' + response.statusText);
                return;
              }
              
              var contentLength = +response.headers.get('Content-Length') || 0;
              var receivedLength = 0;
              var chunks = [];
              var reader = response.body.getReader();
              
              while(true) {
                var {done, value} = await reader.read();
                if (done) break;
                chunks.push(value);
                receivedLength += value.length;
                if (contentLength > 0) {
                  var pct = (receivedLength / contentLength);
                  window.SikkaPlayDownloadChannel.postMessage('PROGRESS:' + pct);
                } else {
                  window.SikkaPlayDownloadChannel.postMessage('BYTES:' + receivedLength);
                }
              }
              
              window.SikkaPlayDownloadChannel.postMessage('STATUS:Saving media file...');
              var blob = new Blob(chunks, {type: 'video/mp4'});
              var fileReader = new FileReader();
              fileReader.onloadend = function() {
                var base64data = fileReader.result;
                window.SikkaPlayDownloadChannel.postMessage('BASE64:' + base64data);
              };
              fileReader.onerror = function(e) {
                window.SikkaPlayDownloadChannel.postMessage('ERROR:FileReader error: ' + e.message);
              };
              fileReader.readAsDataURL(blob);
              
            } catch (e) {
              window.SikkaPlayDownloadChannel.postMessage('ERROR:JS exception: ' + e.message);
            }
          })();
        ''');

        domResult = await completer.future.timeout(
          const Duration(seconds: 45),
          onTimeout: () => const ReelDownloadResult(
            success: false,
            message: 'DOM scraping timed out.',
            debugInfo: 'Timeout',
          ),
        );
      } catch (e) {
        debugPrint('ReelDownload: DOM scraper exception: $e');
        domResult = ReelDownloadResult(
          success: false,
          message: 'DOM scraper exception.',
          debugInfo: e.toString(),
        );
      } finally {
        ref.read(reelsDownloadCallbackProvider.notifier).state = null;
      }
    }

    if (domResult != null && domResult.success) {
      result = domResult;
    } else {
      debugPrint('ReelDownload: DOM scraper failed or unavailable. Trying standard download API fallback...');
      setState(() {
        _statusMessage = 'Fetching from fallback API...';
      });
      if (isVideo) {
        result = await service.downloadAsVideo(
          widget.reelUrl,
          webViewController: widget.webViewController,
          onProgress: onProgress,
        );
      } else {
        result = await service.downloadAsAudio(
          widget.reelUrl,
          webViewController: widget.webViewController,
          onProgress: onProgress,
        );
      }
    }

    if (!mounted) return;

    if (result.success) {
      setState(() {
        _phase = _DownloadPhase.success;
        _statusMessage = result.message;
        _filePath = result.filePath;
      });
      _checkController.forward();
      Future.delayed(const Duration(seconds: 2, milliseconds: 500), () {
        if (mounted && Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      });
    } else {
      setState(() {
        _phase = _DownloadPhase.error;
        _statusMessage = result.message;
        _debugInfo = result.debugInfo ?? 'URL: ${widget.reelUrl}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Material(
      color: Colors.transparent,
      child: Container(
        width: screenWidth * 0.88,
        constraints: const BoxConstraints(maxWidth: 380),
        decoration: BoxDecoration(
          color: const Color(0xFF16162A),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.08),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.15),
              blurRadius: 40,
              spreadRadius: 0,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top gradient accent line
              Container(
                height: 3,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.secondary, Color(0xFFC850C0)],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Content
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child: _buildContent(),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    switch (_phase) {
      case _DownloadPhase.selectFormat:
        return _buildFormatSelector();
      case _DownloadPhase.downloading:
        return _buildDownloading();
      case _DownloadPhase.success:
        return _buildSuccess();
      case _DownloadPhase.error:
        return _buildError();
    }
  }

  Widget _buildFormatSelector() {
    return Padding(
      key: const ValueKey('format'),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Title row
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6E5DE7), Color(0xFF00E5FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.download_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Save Reel',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Choose your preferred format',
                      style: GoogleFonts.outfit(
                        color: Colors.white38,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),

          // Video option
          _FormatOptionTile(
            icon: Icons.videocam_rounded,
            title: 'Video (MP4)',
            subtitle: 'Save reel with audio to gallery',
            gradientColors: const [Color(0xFF4158D0), Color(0xFFC850C0)],
            onTap: () => _startDownload(true),
          ),
          const SizedBox(height: 10),

          // Audio option
          _FormatOptionTile(
            icon: Icons.music_note_rounded,
            title: 'Audio (MP3)',
            subtitle: 'Extract and save the audio track',
            gradientColors: const [Color(0xFFFF6B6B), Color(0xFFFF9A9E)],
            onTap: () => _startDownload(false),
          ),
        ],
      ),
    );
  }

  Widget _buildDownloading() {
    return Padding(
      key: const ValueKey('downloading'),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          // Animated progress ring
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Glow
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.secondary.withValues(alpha: 0.15),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                    ),
                    // Ring
                    SizedBox(
                      width: 88,
                      height: 88,
                      child: CircularProgressIndicator(
                        value: _progress > 0 ? _progress.clamp(0.0, 1.0) : null,
                        strokeWidth: 5,
                        strokeCap: StrokeCap.round,
                        backgroundColor: Colors.white.withValues(alpha: 0.06),
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.secondary),
                      ),
                    ),
                    // Icon
                    Icon(
                      _isVideo ? Icons.videocam_rounded : Icons.music_note_rounded,
                      color: AppColors.secondary,
                      size: 30,
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          // Percentage
          if (_progress > 0)
            Text(
              '${(_progress * 100).toInt()}%',
              style: GoogleFonts.outfit(
                color: AppColors.secondary,
                fontSize: 26,
                fontWeight: FontWeight.w800,
              ),
            ),
          const SizedBox(height: 6),
          // Status
          Text(
            _statusMessage,
            style: GoogleFonts.outfit(
              color: Colors.white54,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 20),
          // Progress bar
          Container(
            height: 4,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              color: Colors.white.withValues(alpha: 0.06),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 350),
                      width: constraints.maxWidth * _progress.clamp(0.0, 1.0),
                      height: 4,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, AppColors.secondary],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccess() {
    return Padding(
      key: const ValueKey('success'),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          AnimatedBuilder(
            animation: _checkAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _checkAnimation.value,
                child: Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00C853), Color(0xFF69F0AE)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00C853).withValues(alpha: 0.35),
                        blurRadius: 24,
                        spreadRadius: 3,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.check_rounded, color: Colors.white, size: 38),
                ),
              );
            },
          ),
          const SizedBox(height: 18),
          Text(
            _isVideo ? 'Video Saved!' : 'Audio Saved!',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _isVideo
                ? 'Reel has been saved to your gallery'
                : 'Audio file saved successfully',
            style: GoogleFonts.outfit(
              color: Colors.white54,
              fontSize: 13,
            ),
          ),
          if (_filePath != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.folder_outlined, color: Colors.white30, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _filePath!.split('/').last,
                      style: GoogleFonts.outfit(color: Colors.white30, fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildError() {
    return Padding(
      key: const ValueKey('error'),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.red.withValues(alpha: 0.08),
              border: Border.all(color: Colors.red.withValues(alpha: 0.25), width: 2),
            ),
            child: const Icon(Icons.cloud_off_rounded, color: Colors.redAccent, size: 34),
          ),
          const SizedBox(height: 18),
          Text(
            'Download Failed',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _statusMessage,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              color: Colors.white54,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          if (_debugInfo != null) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: Text(
                _debugInfo!,
                style: GoogleFonts.outfit(
                  color: Colors.white24,
                  fontSize: 10,
                  height: 1.3,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
          const SizedBox(height: 20),
          // Buttons row
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                    ),
                  ),
                  child: Text(
                    'Close',
                    style: GoogleFonts.outfit(
                      color: Colors.white54,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, Color(0xFF8F00FF)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextButton(
                    onPressed: () {
                      setState(() {
                        _phase = _DownloadPhase.selectFormat;
                      });
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      'Try Again',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A format option tile with gradient icon.
class _FormatOptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color> gradientColors;
  final VoidCallback onTap;

  const _FormatOptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradientColors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: AppColors.primary.withValues(alpha: 0.1),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white.withValues(alpha: 0.03),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(13),
                  gradient: LinearGradient(
                    colors: gradientColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: gradientColors.first.withValues(alpha: 0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      subtitle,
                      style: GoogleFonts.outfit(
                        color: Colors.white30,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white24,
                size: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
