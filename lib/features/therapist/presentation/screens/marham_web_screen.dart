import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class MarhamWebScreen extends StatefulWidget {
  const MarhamWebScreen({super.key});

  static Future<void> open(BuildContext context) {
    return Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MarhamWebScreen()),
    );
  }

  @override
  State<MarhamWebScreen> createState() => _MarhamWebScreenState();
}

class _MarhamWebScreenState extends State<MarhamWebScreen> {
  late final WebViewController _controller;
  int _loadingProgress = 0;
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  void _initWebView() {
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..enableZoom(true)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) {
            if (mounted) {
              setState(() => _loadingProgress = progress);
            }
          },
          onPageStarted: (url) {
            if (mounted) {
              setState(() {
                _loadingProgress = 10;
                _hasError = false;
              });
            }
          },
          onPageFinished: (url) {
            if (mounted) {
              setState(() => _loadingProgress = 100);
              // Inject responsive viewport metadata
              _controller.runJavaScript("""
                document.body.style.overflow = 'auto';
                document.documentElement.style.overflow = 'auto';
                var meta = document.createElement('meta');
                meta.name = 'viewport';
                meta.content = 'width=device-width, initial-scale=1.0, maximum-scale=2.0, user-scalable=yes';
                document.getElementsByTagName('head')[0].appendChild(meta);
              """);
            }
          },
          onWebResourceError: (error) {
            if (mounted && error.isForMainFrame == true) {
              setState(() {
                _hasError = true;
                _errorMessage = error.description;
              });
            }
          },


        ),
      );

    if (Platform.isAndroid) {
      final androidController =
          controller.platform as AndroidWebViewController;
      androidController.setMediaPlaybackRequiresUserGesture(false);
    }

    _controller = controller;
    _loadPortal();
  }

  void _loadPortal() {
    _controller.loadRequest(
      Uri.parse(AppConstants.marhamConsultationUrl),
    );
  }

  Future<void> _openExternalBrowser() async {
    final uri = Uri.parse(AppConstants.marhamConsultationUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (await _controller.canGoBack()) {
          _controller.goBack();
        } else if (context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Text(
                  'MARHAM',
                  style: AppTextStyles.caption.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  'Speech Specialists',
                  style: AppTextStyles.titleSmall.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Reload Page',
              onPressed: () => _controller.reload(),
            ),
            IconButton(
              icon: const Icon(Icons.open_in_browser_rounded),
              tooltip: 'Open in Browser',
              onPressed: _openExternalBrowser,
            ),
          ],
          bottom: _loadingProgress < 100
              ? PreferredSize(
                  preferredSize: const Size.fromHeight(3),
                  child: LinearProgressIndicator(
                    value: _loadingProgress / 100.0,
                    backgroundColor: AppColors.surfaceVariant,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.primary,
                    ),
                  ),
                )
              : null,
        ),
        body: _hasError
            ? Center(
                child: Padding(
                  padding: EdgeInsets.all(24.w),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.wifi_off_rounded,
                        size: 64.sp,
                        color: AppColors.error,
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        'Unable to connect to Marham Portal',
                        style: AppTextStyles.titleMedium.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        _errorMessage ??
                            'Please check your internet connection and try again.',
                        style: AppTextStyles.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 20.h),
                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() => _hasError = false);
                          _loadPortal();
                        },
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Try Again'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      SizedBox(height: 12.h),
                      TextButton.icon(
                        onPressed: _openExternalBrowser,
                        icon: const Icon(Icons.open_in_browser_rounded),
                        label: const Text('Open via Chrome / Browser'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primaryDark,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : WebViewWidget(controller: _controller),
      ),
    );
  }
}
