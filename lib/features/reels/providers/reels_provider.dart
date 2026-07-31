import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';

// Global provider for accessing the active WebViewController reference from UI overlays
final reelsWebViewControllerProvider =
    StateProvider<WebViewController?>((ref) => null);

// Global provider to communicate download callbacks from WebView back to the Screen
final reelsDownloadCallbackProvider =
    StateProvider<void Function(String)?>((ref) => null);

class ReelsState {
  final String currentUrl;
  final bool isLoading;
  final bool isMuted;
  final int elapsedSeconds;
  final bool isNavHidden;

  const ReelsState({
    required this.currentUrl,
    required this.isLoading,
    required this.isMuted,
    required this.elapsedSeconds,
    required this.isNavHidden,
  });

  ReelsState copyWith({
    String? currentUrl,
    bool? isLoading,
    bool? isMuted,
    int? elapsedSeconds,
    bool? isNavHidden,
  }) {
    return ReelsState(
      currentUrl: currentUrl ?? this.currentUrl,
      isLoading: isLoading ?? this.isLoading,
      isMuted: isMuted ?? this.isMuted,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      isNavHidden: isNavHidden ?? this.isNavHidden,
    );
  }
}

class ReelsNotifier extends StateNotifier<ReelsState> {
  ReelsNotifier()
      : super(
          const ReelsState(
            currentUrl: 'https://www.instagram.com/reels/',
            isLoading: false,
            isMuted: false,
            elapsedSeconds: 0,
            isNavHidden: false,
          ),
        );

  void toggleMute() {
    state = state.copyWith(isMuted: !state.isMuted);
  }

  void refreshFeed(WebViewController? controller) {
    controller?.reload();
  }

  void setLoading(bool loading) {
    state = state.copyWith(isLoading: loading);
  }

  void updateUrl(String url) {
    state = state.copyWith(currentUrl: url);
  }

  void setElapsedSeconds(int seconds) {
    state = state.copyWith(elapsedSeconds: seconds);
  }

  void setNavHidden(bool hidden) {
    state = state.copyWith(isNavHidden: hidden);
  }
}

final reelsProvider = StateNotifierProvider<ReelsNotifier, ReelsState>((ref) {
  return ReelsNotifier();
});
