import 'package:flutter/foundation.dart';

class ImageUtils {
  /// Chuẩn hóa URL ảnh trên Flutter Web để tránh lỗi CORS từ các CDN chặn browser cross-origin (như Pinterest i.pinimg.com)
  static String getSafeImageUrl(String? url) {
    if (url == null || url.trim().isEmpty) {
      return 'https://images.unsplash.com/photo-1544025162-d76694265947?w=800&q=80';
    }

    final trimmed = url.trim();

    // Trên nền tảng Web, các host như pinimg.com chặn XMLHttpRequest do thiếu Access-Control-Allow-Origin header
    // Proxy thông qua weserv.nl (miễn phí, open-source trên Cloudflare) giúp bổ sung CORS và nén ảnh mượt mà
    if (kIsWeb && trimmed.contains('pinimg.com')) {
      return 'https://images.weserv.nl/?url=${Uri.encodeComponent(trimmed)}';
    }

    return trimmed;
  }
}
