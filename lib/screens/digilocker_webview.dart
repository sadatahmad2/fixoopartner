import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class DigilockerWebView extends StatefulWidget {
  final String authUrl;
  final Function(String) onComplete;

  const DigilockerWebView({super.key, required this.authUrl, required this.onComplete});

  @override
  State<DigilockerWebView> createState() => _DigilockerWebViewState();
}

class _DigilockerWebViewState extends State<DigilockerWebView> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() => _isLoading = true),
          onPageFinished: (_) => setState(() => _isLoading = false),
          onNavigationRequest: (request) {
            // Check for redirect URL from your KYC provider
            if (request.url.contains('success') || request.url.contains('callback')) {
              widget.onComplete(request.url);
              Navigator.pop(context);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.authUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DigiLocker Verification'),
        backgroundColor: const Color(0xFF040C18),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(child: CircularProgressIndicator(color: Color(0xFF00D1FF))),
        ],
      ),
    );
  }
}
