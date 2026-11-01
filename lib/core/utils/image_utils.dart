import 'package:flutter/foundation.dart';

class ImageUtils {
  static const String defaultFoodImage =
      'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=800&q=80';

  /// Chuẩn hóa URL ảnh trên Flutter Web để tránh lỗi CORS hoặc URL 404/403
  static String getSafeImageUrl(String? url) {
    if (url == null || url.trim().isEmpty) {
      return defaultFoodImage;
    }

    final trimmed = url.trim();

    // Link Pinterest 484d528ef3ea81fa4d4ad7aa7550ca22 trong dữ liệu seed bị lỗi 403 Forbidden trên server gốc
    if (trimmed.contains('484d528ef3ea81fa4d4ad7aa7550ca22')) {
      return defaultFoodImage;
    }

    // Trên nền tảng Web, các host như pinimg.com chặn XMLHttpRequest do thiếu Access-Control-Allow-Origin header
    // Proxy thông qua weserv.nl (miễn phí, open-source trên Cloudflare) giúp bổ sung CORS và nén ảnh mượt mà
    if (kIsWeb && trimmed.contains('pinimg.com')) {
      return 'https://images.weserv.nl/?url=${Uri.encodeComponent(trimmed)}';
    }

    return trimmed;
  }
}
