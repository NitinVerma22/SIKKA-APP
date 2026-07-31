import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:sikkaplay/features/reels/providers/reels_provider.dart';

class ReelsWebView extends ConsumerStatefulWidget {
  const ReelsWebView({super.key});

  @override
  ConsumerState<ReelsWebView> createState() => _ReelsWebViewState();
}

class _ReelsWebViewState extends ConsumerState<ReelsWebView> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();

    // Explicitly initialize Android WebView platform if required
    try {
      WebViewPlatform.instance ??= AndroidWebViewPlatform();
    } catch (e) {
      debugPrint('WebView platform initialization error: $e');
    }

    late final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is AndroidWebViewPlatform) {
      params = AndroidWebViewControllerCreationParams();
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    // Initialize the WebViewController
    _controller = WebViewController.fromPlatformCreationParams(params)
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(
        'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            ref.read(reelsProvider.notifier).updateUrl(url);
            ref.read(reelsProvider.notifier).setLoading(true);
          },
          onUrlChange: (UrlChange change) {
            if (change.url != null) {
              ref.read(reelsProvider.notifier).updateUrl(change.url!);
            }
          },
          onPageFinished: (String url) {
            ref.read(reelsProvider.notifier).setLoading(false);
            
            // Inject JS to prevent overscroll, hide IG bottom nav, force autoplay, and track URLs
            _controller.runJavaScript('''
              (function() {
                var style = document.createElement('style');
                style.innerHTML = `
                  /* Improve smooth scrolling and prevent pull-to-refresh bounce */
                  body {
                    overscroll-behavior-y: none !important;
                    overscroll-behavior-x: none !important;
                  }
                  
                  /* Specifically hide Instagram bottom navigation bar */
                  div[role="tablist"],
                  footer,
                  nav {
                    display: none !important;
                  }
                `;
                document.head.appendChild(style);

                // Attempt to auto-play any video elements
                setTimeout(function() {
                  var videos = document.getElementsByTagName('video');
                  for(var i=0; i<videos.length; i++) {
                    var v = videos[i];
                    v.setAttribute('playsinline', 'playsinline');
                    v.play().catch(function(e){});
                  }
                }, 500);

                // Observe Instagram dialogs (e.g. Share, Comments) to toggle our bottom nav bar
                window.lastDialogOpen = false;
                var observer = new MutationObserver(function(mutations) {
                  var dialogs = document.querySelectorAll('div[role="dialog"]');
                  var dialogOpen = false;
                  for(var i = 0; i < dialogs.length; i++) {
                    if (dialogs[i].clientHeight > 0) {
                      dialogOpen = true;
                      break;
                    }
                  }
                  if (window.lastDialogOpen !== dialogOpen) {
                     window.lastDialogOpen = dialogOpen;
                     if (window.SikkaPlayApp) {
                        window.SikkaPlayApp.postMessage(dialogOpen ? 'hide_nav' : 'show_nav');
                     }
                  }
                });
                observer.observe(document.body, { childList: true, subtree: true });

                // Detect SPA URL changes and push to Flutter
                function checkUrlChange() {
                  if (window.SikkaPlayApp) {
                    window.SikkaPlayApp.postMessage('URL_CHANGE:' + window.location.href);
                  }
                }
                
                var originalPush = history.pushState;
                history.pushState = function() {
                  originalPush.apply(this, arguments);
                  checkUrlChange();
                };
                
                var originalReplace = history.replaceState;
                history.replaceState = function() {
                  originalReplace.apply(this, arguments);
                  checkUrlChange();
                };
                
                window.addEventListener('popstate', checkUrlChange);
                setInterval(checkUrlChange, 1000);
              })();
            ''');
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('WebView Resource Error: ${error.description}');
          },
          onNavigationRequest: (NavigationRequest request) {
            // Allow all requests within Instagram to navigate normally
            return NavigationDecision.navigate;
          },
        ),
      )
      ..addJavaScriptChannel(
        'SikkaPlayApp',
        onMessageReceived: (JavaScriptMessage message) {
          final msg = message.message;
          if (msg == 'hide_nav') {
            ref.read(reelsProvider.notifier).setNavHidden(true);
          } else if (msg == 'show_nav') {
            ref.read(reelsProvider.notifier).setNavHidden(false);
          } else if (msg.startsWith('URL_CHANGE:')) {
            final url = msg.substring('URL_CHANGE:'.length);
            ref.read(reelsProvider.notifier).updateUrl(url);
          }
        },
      )
      ..addJavaScriptChannel(
        'SikkaPlayDownloadChannel',
        onMessageReceived: (JavaScriptMessage message) {
          final callback = ref.read(reelsDownloadCallbackProvider);
          if (callback != null) {
            callback(message.message);
          }
        },
      )
      ..loadRequest(Uri.parse('https://www.instagram.com/reels/'));

    if (_controller.platform is AndroidWebViewController) {
      (_controller.platform as AndroidWebViewController)
          .setMediaPlaybackRequiresUserGesture(false);
    }

    // Expose the controller to other widgets via the Riverpod provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(reelsWebViewControllerProvider.notifier).state = _controller;
    });
  }

  @override
  void dispose() {
    // Clear the global controller reference upon disposal
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(reelsWebViewControllerProvider.notifier).state = null;
      }
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black, // Dark immersive background matching Reels theme
      child: SafeArea(
        top: false,
        bottom: false,
        child: WebViewWidget(controller: _controller),
      ),
    );
  }
}
