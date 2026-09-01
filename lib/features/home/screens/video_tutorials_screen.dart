import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:sikkaplay/core/auth/auth_service.dart';
import 'package:url_launcher/url_launcher.dart';

class VideoTutorialsScreen extends ConsumerStatefulWidget {
  const VideoTutorialsScreen({super.key});

  @override
  ConsumerState<VideoTutorialsScreen> createState() => _VideoTutorialsScreenState();
}

class _VideoTutorialsScreenState extends ConsumerState<VideoTutorialsScreen> {
  List<dynamic> _videos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchVideos();
  }

  Future<void> _fetchVideos() async {
    try {
      final baseUrl = AuthService.baseUrl.replaceAll('/auth', '/video-tutorials');
      final res = await http.get(Uri.parse(baseUrl));
      if (res.statusCode == 200) {
        if (mounted) {
          setState(() {
            _videos = json.decode(res.body);
            _isLoading = false;
          });
        }
      } else {
        throw Exception('Failed to load videos');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String? _extractYoutubeId(String url) {
    final regExp = RegExp(
        r'^.*(youtu\.be\/|v\/|u\/\w\/|embed\/|watch\?v=|\&v=)([^#\&\?]*).*',
        caseSensitive: false);
    final match = regExp.firstMatch(url);
    if (match != null && match.groupCount >= 2) {
      return match.group(2);
    }
    return null;
  }

  Future<void> _openVideo(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Video Tutorials', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF1E222B),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: const Color(0xFF121418),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: Colors.red))
          : _videos.isEmpty 
            ? Center(child: Text('No tutorials available', style: GoogleFonts.outfit(color: Colors.white54, fontSize: 16)))
            : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _videos.length,
              itemBuilder: (context, index) {
                final video = _videos[index];
                final videoId = _extractYoutubeId(video['url'] ?? '');
                final thumbnailUrl = videoId != null 
                    ? 'https://img.youtube.com/vi/$videoId/hqdefault.jpg' 
                    : null;

                return GestureDetector(
                  onTap: () => _openVideo(video['url']),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E222B),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Thumbnail Area
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            if (thumbnailUrl != null)
                              Image.network(
                                thumbnailUrl,
                                height: 180,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  height: 180,
                                  color: Colors.black26,
                                  child: const Icon(Icons.video_library, color: Colors.white24, size: 60),
                                ),
                              )
                            else
                              Container(
                                height: 180,
                                color: Colors.black26,
                                width: double.infinity,
                                child: const Icon(Icons.video_library, color: Colors.white24, size: 60),
                              ),
                            
                            // Play button overlay
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.6),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.play_arrow_rounded, color: Colors.redAccent, size: 48),
                            ),
                          ],
                        ),
                        // Title and Description Area
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                video['title'] ?? 'Watch Video',
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(Icons.ondemand_video, color: Colors.redAccent, size: 14),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Watch on YouTube',
                                    style: GoogleFonts.outfit(
                                      color: Colors.white54,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ],
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
