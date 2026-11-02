import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/image_utils.dart';

class UserAvatar extends StatelessWidget {
  final String? avatarUrl;
  final String name;
  final double radius;

  const UserAvatar({
    super.key,
    required this.avatarUrl,
    required this.name,
    this.radius = 17,
  });

  @override
  Widget build(BuildContext context) {
    final double size = radius * 2;
    final fallbackChar = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : 'K';

    Widget buildFallback() => Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            fallbackChar,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
              fontSize: radius * 0.82,
            ),
          ),
        );

    final url = avatarUrl?.trim();
    if (url == null || url.isEmpty) {
      return buildFallback();
    }

    final safeUrl = ImageUtils.getSafeImageUrl(url);

    return ClipOval(
      child: Image.network(
        safeUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => buildFallback(),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return buildFallback();
        },
      ),
    );
  }
}
