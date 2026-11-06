import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// A redirect is only a hint to fetch payment status from our backend.
class PayOSCallback {
  final String paymentCode;
  final bool cancelled;
  const PayOSCallback(this.paymentCode, {this.cancelled = false});

  static PayOSCallback? parse(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null || !['http', 'https'].contains(uri.scheme)) return null;
    const successPath = String.fromEnvironment('PAYOS_SUCCESS_PATH',
        defaultValue: '/thanh-toan/thanh-cong');
    const cancelPath = String.fromEnvironment('PAYOS_CANCEL_PATH',
        defaultValue: '/thanh-toan/that-bai');
    if (uri.path != successPath && uri.path != cancelPath) return null;
    final code = uri.queryParameters['orderCode'];
    if (code == null || !RegExp(r'^\d+$').hasMatch(code)) return null;
    return PayOSCallback(code,
        cancelled: uri.queryParameters['cancel'] == 'true' ||
            uri.queryParameters['status'] == 'CANCELLED');
  }
}

class PayOSPaymentScreen extends StatefulWidget {
  final Uri checkoutUrl;
  const PayOSPaymentScreen({super.key, required this.checkoutUrl});

  @override
  State<PayOSPaymentScreen> createState() => _PayOSPaymentScreenState();
}

class _PayOSPaymentScreenState extends State<PayOSPaymentScreen> {
  late final WebViewController _controller;
  bool _returned = false;
  bool _loading = true;
  String? _error;

  bool _handleCallback(String url) {
    final callback = PayOSCallback.parse(url);
    if (callback == null) return false;
    if (!_returned && mounted) {
      _returned = true;
      Navigator.of(context).pop(callback);
    }
    return true;
  }

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onNavigationRequest: (request) {
          if (request.isMainFrame && _handleCallback(request.url)) {
            return NavigationDecision.prevent;
          }
          final uri = Uri.tryParse(request.url);
          if (uri == null || !['https', 'http'].contains(uri.scheme)) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text(
                    'Vui lòng thanh toán bằng mã QR hoặc thông tin chuyển khoản trên trang PayOS.'),
              ));
            }
            return NavigationDecision.prevent;
          }
          return NavigationDecision.navigate;
        },
        onUrlChange: (change) {
          if (change.url != null) _handleCallback(change.url!);
        },
        onPageStarted: (_) {
          if (mounted) {
            setState(() {
              _loading = true;
              _error = null;
            });
          }
        },
        onPageFinished: (_) {
          if (mounted) setState(() => _loading = false);
        },
        onWebResourceError: (error) {
          if (error.isForMainFrame == true && mounted) {
            setState(() {
              _loading = false;
              _error = 'Không thể tải trang thanh toán. Vui lòng thử lại.';
            });
          }
        },
      ))
      ..loadRequest(widget.checkoutUrl);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Thanh toán cọc PayOS'), actions: [
          IconButton(
              onPressed: () => _controller.reload(),
              icon: const Icon(Icons.refresh),
              tooltip: 'Tải lại'),
        ]),
        body: Column(children: [
          if (_loading) const LinearProgressIndicator(),
          if (_error != null)
            Padding(padding: const EdgeInsets.all(16), child: Text(_error!)),
          Expanded(child: WebViewWidget(controller: _controller)),
        ]),
      );
}
