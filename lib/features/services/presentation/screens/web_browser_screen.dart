import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/models/service_model.dart';

class GotchaaWebBrowserScreen extends ConsumerStatefulWidget {

  const GotchaaWebBrowserScreen({required this.service, super.key});
  final GotchaaService service;

  @override
  ConsumerState<GotchaaWebBrowserScreen> createState() => _GotchaaWebBrowserScreenState();
}

class _GotchaaWebBrowserScreenState extends ConsumerState<GotchaaWebBrowserScreen> {
  final GlobalKey webViewKey = GlobalKey();
  InAppWebViewController? webViewController;
  InAppWebViewSettings settings = InAppWebViewSettings(
    isInspectable: false,
    mediaPlaybackRequiresUserGesture: false,
    allowsInlineMediaPlayback: true,
    iframeAllow: 'camera; microphone; fullscreen; geolocation',
    iframeAllowFullscreen: true,
    geolocationEnabled: true,
    javaScriptEnabled: true,
    transparentBackground: true,
    useShouldOverrideUrlLoading: true,
    useOnLoadResource: true,
    useOnDownloadStart: true,
    javaScriptCanOpenWindowsAutomatically: true,
    supportMultipleWindows: true,
    disableContextMenu: false,
    databaseEnabled: true,
    domStorageEnabled: true,
    clearSessionCache: false,
    clearCache: false,
    userAgent: 'Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/116.0.0.0 Mobile Safari/537.36',
  );

  PullToRefreshController? pullToRefreshController;
  String url = '';
  double progress = 0;
  bool showInfoDialog = true;

  @override
  void initState() {
    super.initState();
    url = widget.service.url;
    
    pullToRefreshController = PullToRefreshController(
      settings: PullToRefreshSettings(
        color: AppColors.electricBlue,
      ),
      onRefresh: () async {
        if (Platform.isAndroid) {
          webViewController?.reload();
        } else if (Platform.isIOS) {
          webViewController?.loadUrl(urlRequest: URLRequest(url: await webViewController?.getUrl()));
        }
      },
    );
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.service.id == 'blinkit') {
        _handleBlinkitLocation();
      }
    });
  }

  late bool _isLoadingLocation = widget.service.id == 'blinkit';

  Future<void> _handleBlinkitLocation() async {
    // No need to setState true here, already true
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showBlinkitNoLocationMessage();
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showBlinkitNoLocationMessage();
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _showBlinkitNoLocationMessage();
      return;
    }

    try {
      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
        ),
      );
      // Even if URL params don't work, we ensure location service is active and permissions granted
      // We'll use the base URL but the site will now be able to request location via JS
      setState(() {
        _isLoadingLocation = false;
      });
    } catch (e) {
      _showBlinkitNoLocationMessage();
    }
  }

  void _showBlinkitNoLocationMessage() {
    setState(() {
      _isLoadingLocation = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Location needed for delivery — please enable in settings'),
        backgroundColor: Colors.orange,
        action: SnackBarAction(
          label: 'Retry',
          textColor: Colors.white,
          onPressed: _handleBlinkitLocation,
        ),
      )
    );
  }
  

  @override
  void dispose() {
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    if (webViewController != null) {
      if (await webViewController!.canGoBack()) {
        webViewController!.goBack();
        return false;
      }
    }
    return true;
  }

  @override
  Widget build(BuildContext context) => WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: widget.service.brandColor,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.white),
            onPressed: () => context.pop(),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.service.name,
                style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  const Icon(Icons.lock_rounded, size: 10, color: Colors.white70),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      url,
                      style: GoogleFonts.inter(color: Colors.white70, fontSize: 10),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.open_in_browser_rounded, color: Colors.white),
              onPressed: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(2),
            child: progress < 1.0
                ? LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.white24,
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  )
                : const SizedBox(height: 2),
          ),
        ),
        body: Stack(
          children: [
            if (_isLoadingLocation)
              const Center(child: CircularProgressIndicator(color: AppColors.electricBlue))
            else
              InAppWebView(
                key: webViewKey,
                initialUrlRequest: URLRequest(url: WebUri(url)),
              initialSettings: settings,
              pullToRefreshController: pullToRefreshController,
              onWebViewCreated: (controller) {
                webViewController = controller;
              },
              onLoadStart: (controller, url) {
                setState(() {
                  this.url = url.toString();
                });
              },
              onPermissionRequest: (controller, request) async => PermissionResponse(
                  resources: request.resources,
                  action: PermissionResponseAction.GRANT,
                ),
              onGeolocationPermissionsShowPrompt: (controller, origin) async => GeolocationPermissionShowPromptResponse(
                  origin: origin,
                  allow: true,
                  retain: true,
                ),
              shouldOverrideUrlLoading: (controller, navigationAction) async => NavigationActionPolicy.ALLOW,
              onLoadStop: (controller, url) async {
                pullToRefreshController?.endRefreshing();
                setState(() {
                  this.url = url.toString();
                });
              },
              onReceivedError: (controller, request, error) {
                pullToRefreshController?.endRefreshing();
                // Avoid showing error for canceled requests (like redirecting)
                if (error.type == WebResourceErrorType.CANCELLED) return;
                // Only show error for the main frame to avoid false positives from ads/analytics
                if (request.isForMainFrame != true) return;
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to load: ${widget.service.name}'),
                    backgroundColor: Colors.redAccent,
                    action: SnackBarAction(
                      label: 'Retry', 
                      textColor: Colors.white,
                      onPressed: () => controller.reload(),
                    ),
                  )
                );
              },
              onProgressChanged: (controller, progress) {
                if (progress == 100) {
                  pullToRefreshController?.endRefreshing();
                }
                setState(() {
                  this.progress = progress / 100;
                });
              },
              onUpdateVisitedHistory: (controller, url, androidIsReload) {
                setState(() {
                  this.url = url.toString();
                });
              },
            ),
          ],
        ),
        bottomNavigationBar: BottomAppBar(
          color: Colors.white,
          elevation: 8,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                onPressed: () async {
                  if (await webViewController?.canGoBack() ?? false) {
                    webViewController?.goBack();
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.arrow_forward_ios_rounded),
                onPressed: () async {
                  if (await webViewController?.canGoForward() ?? false) {
                    webViewController?.goForward();
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                onPressed: () => webViewController?.reload(),
              ),
              IconButton(
                icon: const Icon(Icons.share_rounded),
                onPressed: () => Share.share(url),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => context.pop(),
          backgroundColor: AppColors.electricBlue,
          child: const Icon(Icons.home_rounded, color: Colors.white),
        ),
      ),
    );
}
