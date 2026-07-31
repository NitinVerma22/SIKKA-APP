import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:gal/gal.dart';
import 'package:webview_flutter/webview_flutter.dart';

class ReelDownloadResult {
  final bool success;
  final String message;
  final String? filePath;
  final String? debugInfo;

  const ReelDownloadResult({
    required this.success,
    required this.message,
    this.filePath,
    this.debugInfo,
  });
}

class ReelDownloadService {
  static final ReelDownloadService _instance = ReelDownloadService._();
  factory ReelDownloadService() => _instance;
  ReelDownloadService._();

  /// Extract the reel shortcode from an Instagram URL.
  String? extractShortcode(String url) {
    final patterns = [
      RegExp(r'/reel/([A-Za-z0-9_-]+)'),
      RegExp(r'/reels/([A-Za-z0-9_-]+)'),
      RegExp(r'/p/([A-Za-z0-9_-]+)'),
    ];
    for (final pattern in patterns) {
      final match = pattern.firstMatch(url);
      if (match != null && match.group(1) != null) {
        final code = match.group(1)!;
        if (code.length >= 5) return code;
      }
    }
    return null;
  }

  /// Get the video CDN URL using ALL available methods via the WebView.
  /// The WebView is on instagram.com with cookies — it has full access.
  Future<String?> _getVideoUrl(WebViewController controller, String shortcode) async {
    try {
      final jsResult = await controller.runJavaScriptReturningResult('''
        (async function() {
          var errors = [];
          
          // ── METHOD 1: Browser performance/resource entries ──
          // This captures actual CDN URLs from network traffic (like Chrome downloaders)
          try {
            var entries = performance.getEntriesByType('resource');
            var videoUrls = [];
            for (var i = entries.length - 1; i >= 0; i--) {
              var n = entries[i].name;
              if ((n.includes('.mp4') || n.includes('video') || n.includes('/v/')) &&
                  (n.includes('cdninstagram.com') || n.includes('fbcdn.net') || n.includes('instagram'))) {
                videoUrls.push(n);
              }
            }
            if (videoUrls.length > 0) {
              return videoUrls[0];
            }
            errors.push('perf:no_video_entries(' + entries.length + ' total)');
          } catch(e) {
            errors.push('perf:' + e.message);
          }

          // ── METHOD 2: Fetch the reel page HTML & parse og:video / JSON ──
          try {
            var resp = await fetch('https://www.instagram.com/reel/$shortcode/', {
              credentials: 'include',
              headers: { 'Accept': 'text/html' }
            });
            if (resp.ok) {
              var html = await resp.text();
              
              // Try og:video meta tag
              var ogMatch = html.match(/property="og:video"[^>]*content="([^"]+)"/);
              if (!ogMatch) ogMatch = html.match(/content="([^"]+)"[^>]*property="og:video"/);
              if (ogMatch && ogMatch[1]) {
                var u = ogMatch[1].replace(/&amp;/g, '&');
                return u;
              }
              
              // Try video_url in embedded JSON
              var vMatch = html.match(/"video_url":"(https?:[^"]+)"/);
              if (vMatch && vMatch[1]) {
                var u2 = vMatch[1].replace(/\\\\u0026/g, '&').replace(/\\\\\\//, '/');
                return u2;
              }
              
              errors.push('html:no_video_in_page');
            } else {
              errors.push('html:status_' + resp.status);
            }
          } catch(e) {
            errors.push('html:' + e.message);
          }

          // ── METHOD 3: Instagram internal API ──
          try {
            var resp2 = await fetch('https://www.instagram.com/api/v1/media/' + '$shortcode' + '/info/', {
              headers: {
                'X-IG-App-ID': '936619743392459',
                'X-Requested-With': 'XMLHttpRequest'
              },
              credentials: 'include'
            });
            if (resp2.ok) {
              var data = await resp2.json();
              if (data.items && data.items.length > 0) {
                var item = data.items[0];
                if (item.video_versions && item.video_versions.length > 0) {
                  return item.video_versions[0].url;
                }
              }
              errors.push('api1:no_video_versions');
            } else {
              errors.push('api1:status_' + resp2.status);
            }
          } catch(e) {
            errors.push('api1:' + e.message);
          }

          // ── METHOD 4: Shortcode to media_id conversion + clips API ──
          try {
            var alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_';
            var code = '$shortcode';
            var mediaId = BigInt(0);
            for (var i = 0; i < code.length; i++) {
              mediaId = mediaId * BigInt(64) + BigInt(alphabet.indexOf(code[i]));
            }
            var mediaIdStr = mediaId.toString();
            
            var resp3 = await fetch('https://i.instagram.com/api/v1/media/' + mediaIdStr + '/info/', {
              headers: {
                'X-IG-App-ID': '936619743392459',
                'X-Requested-With': 'XMLHttpRequest'
              },
              credentials: 'include'
            });
            if (resp3.ok) {
              var data3 = await resp3.json();
              if (data3.items && data3.items.length > 0) {
                var item3 = data3.items[0];
                if (item3.video_versions && item3.video_versions.length > 0) {
                  return item3.video_versions[0].url;
                }
              }
              errors.push('api2:no_video_versions');
            } else {
              errors.push('api2:status_' + resp3.status);
            }
          } catch(e) {
            errors.push('api2:' + e.message);
          }

          // ── METHOD 5: Embed page (usually works for public reels) ──
          try {
            var resp4 = await fetch('https://www.instagram.com/reel/$shortcode/embed/captioned/', {
              credentials: 'include'
            });
            if (resp4.ok) {
              var html2 = await resp4.text();
              var vm = html2.match(/"video_url":"(https?:[^"]+)"/);
              if (vm && vm[1]) {
                var u3 = vm[1].replace(/\\\\u0026/g, '&').replace(/\\\\\\//, '/');
                return u3;
              }
              errors.push('embed:no_video_url');
            } else {
              errors.push('embed:status_' + resp4.status);
            }
          } catch(e) {
            errors.push('embed:' + e.message);
          }
          
          // ── METHOD 6: Try __a=1 endpoint ──
          try {
            var resp5 = await fetch('https://www.instagram.com/p/$shortcode/?__a=1&__d=dis', {
              headers: {
                'X-IG-App-ID': '936619743392459',
                'X-Requested-With': 'XMLHttpRequest'
              },
              credentials: 'include'
            });
            if (resp5.ok) {
              var text = await resp5.text();
              var vm2 = text.match(/"video_url":"(https?:[^"]+)"/);
              if (!vm2) vm2 = text.match(/"video_versions":\\[\\{"url":"(https?:[^"]+)"/);
              if (vm2 && vm2[1]) {
                var u4 = vm2[1].replace(/\\\\u0026/g, '&').replace(/\\\\\\//, '/');
                return u4;
              }
              errors.push('a1:no_match');
            } else {
              errors.push('a1:status_' + resp5.status);
            }
          } catch(e) {
            errors.push('a1:' + e.message);
          }

          return 'ERROR:' + errors.join('|');
        })()
      ''').timeout(const Duration(seconds: 25));

      String result = jsResult.toString();
      result = result.replaceAll('"', '').replaceAll("'", '').trim();

      debugPrint('ReelDownload: JS result = $result');

      if (result.startsWith('ERROR:')) {
        debugPrint('ReelDownload: All methods failed: ${result.substring(6)}');
        return null;
      }

      if (result.isNotEmpty && result != 'null' && result.startsWith('http')) {
        // Unescape
        result = result.replaceAll(r'\u0026', '&');
        result = result.replaceAll(r'\/', '/');
        result = result.replaceAll('&amp;', '&');
        return result;
      }
    } catch (e) {
      debugPrint('ReelDownload: WebView JS exception: $e');
    }
    return null;
  }

  /// Download bytes from a CDN URL.
  Future<List<int>?> _downloadBytes(String url, void Function(double)? onProgress) async {
    try {
      final request = http.Request('GET', Uri.parse(url));
      request.headers.addAll({
        'User-Agent': 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
        'Referer': 'https://www.instagram.com/',
      });

      final streamedResponse = await request.send().timeout(const Duration(seconds: 60));

      if (streamedResponse.statusCode != 200) {
        debugPrint('ReelDownload: CDN returned ${streamedResponse.statusCode}');
        return null;
      }

      onProgress?.call(0.55);

      final contentLength = streamedResponse.contentLength ?? 0;
      final List<int> bytes = [];
      int received = 0;

      await for (final chunk in streamedResponse.stream) {
        bytes.addAll(chunk);
        received += chunk.length;
        if (contentLength > 0) {
          final downloadProgress = 0.55 + (received / contentLength) * 0.3;
          onProgress?.call(downloadProgress.clamp(0.55, 0.85));
        }
      }

      if (bytes.length < 5000) {
        debugPrint('ReelDownload: Too small: ${bytes.length} bytes');
        return null;
      }

      return bytes;
    } catch (e) {
      debugPrint('ReelDownload: Download exception: $e');
      return null;
    }
  }

  /// Download a reel as MP4 video to the gallery.
  Future<ReelDownloadResult> downloadAsVideo(
    String reelUrl, {
    WebViewController? webViewController,
    void Function(double progress)? onProgress,
  }) async {
    debugPrint('ReelDownload: Starting video download for URL: $reelUrl');

    final shortcode = extractShortcode(reelUrl);
    if (shortcode == null) {
      return ReelDownloadResult(
        success: false,
        message: 'No reel found on this page.\nSwipe to a specific reel first.',
        debugInfo: 'URL: $reelUrl — no shortcode extracted',
      );
    }

    debugPrint('ReelDownload: Shortcode = $shortcode');
    onProgress?.call(0.1);

    if (webViewController == null) {
      return const ReelDownloadResult(
        success: false,
        message: 'WebView not available.\nPlease try again.',
      );
    }

    onProgress?.call(0.15);

    final videoUrl = await _getVideoUrl(webViewController, shortcode);

    if (videoUrl == null) {
      return ReelDownloadResult(
        success: false,
        message: 'Could not find video URL.\nThis reel may be protected or unavailable.',
        debugInfo: 'Shortcode: $shortcode',
      );
    }

    debugPrint('ReelDownload: Got CDN URL (${videoUrl.length} chars)');
    onProgress?.call(0.4);

    final bytes = await _downloadBytes(videoUrl, onProgress);
    if (bytes == null) {
      return const ReelDownloadResult(
        success: false,
        message: 'Failed to download video data.\nPlease check your connection and try again.',
      );
    }

    return saveVideoBytes(bytes, onProgress);
  }

  /// Save bytes as a video file to the gallery.
  Future<ReelDownloadResult> saveVideoBytes(List<int> bytes, void Function(double progress)? onProgress) async {
    onProgress?.call(0.88);
    try {
      final tempDir = await getTemporaryDirectory();
      final tempPath = '${tempDir.path}/reel_${DateTime.now().millisecondsSinceEpoch}.mp4';
      final file = File(tempPath);
      await file.writeAsBytes(bytes);

      await Gal.putVideo(tempPath);

      try { await file.delete(); } catch (_) {}

      onProgress?.call(1.0);
      return const ReelDownloadResult(success: true, message: 'Video saved to gallery!');
    } catch (e) {
      debugPrint('ReelDownload: Save error: $e');
      return ReelDownloadResult(
        success: false,
        message: 'Failed to save to gallery.\n${_friendlyError(e)}',
      );
    }
  }

  /// Download a reel's audio as MP3.
  Future<ReelDownloadResult> downloadAsAudio(
    String reelUrl, {
    WebViewController? webViewController,
    void Function(double progress)? onProgress,
  }) async {
    debugPrint('ReelDownload: Starting audio download for URL: $reelUrl');

    final shortcode = extractShortcode(reelUrl);
    if (shortcode == null) {
      return ReelDownloadResult(
        success: false,
        message: 'No reel found on this page.\nSwipe to a specific reel first.',
        debugInfo: 'URL: $reelUrl — no shortcode extracted',
      );
    }

    onProgress?.call(0.1);

    if (webViewController == null) {
      return const ReelDownloadResult(
        success: false,
        message: 'WebView not available.\nPlease try again.',
      );
    }

    onProgress?.call(0.15);

    final videoUrl = await _getVideoUrl(webViewController, shortcode);

    if (videoUrl == null) {
      return ReelDownloadResult(
        success: false,
        message: 'Could not find media URL.\nThis reel may be protected or unavailable.',
        debugInfo: 'Shortcode: $shortcode',
      );
    }

    onProgress?.call(0.4);

    final bytes = await _downloadBytes(videoUrl, onProgress);
    if (bytes == null) {
      return const ReelDownloadResult(
        success: false,
        message: 'Failed to download audio data.\nPlease check your connection and try again.',
      );
    }

    return saveAudioBytes(bytes, onProgress);
  }

  /// Save bytes as an audio file.
  Future<ReelDownloadResult> saveAudioBytes(List<int> bytes, void Function(double progress)? onProgress) async {
    onProgress?.call(0.88);
    try {
      final appDocDir = await getApplicationDocumentsDirectory();
      final outputDir = Directory('${appDocDir.path}/SikkaPlay/Audio');
      if (!await outputDir.exists()) {
        await outputDir.create(recursive: true);
      }
      final outputPath = '${outputDir.path}/reel_audio_${DateTime.now().millisecondsSinceEpoch}.mp3';
      final file = File(outputPath);
      await file.writeAsBytes(bytes);

      onProgress?.call(1.0);
      return ReelDownloadResult(
        success: true,
        message: 'Audio saved!',
        filePath: outputPath,
      );
    } catch (e) {
      return ReelDownloadResult(
        success: false,
        message: 'Failed to save audio.\n${_friendlyError(e)}',
      );
    }
  }

  String _friendlyError(Object e) {
    final msg = e.toString();
    if (msg.contains('TimeoutException')) return 'Connection timed out.';
    if (msg.contains('SocketException')) return 'No internet connection.';
    if (msg.contains('Permission')) return 'Storage permission required.';
    return 'Please try again.';
  }
}
