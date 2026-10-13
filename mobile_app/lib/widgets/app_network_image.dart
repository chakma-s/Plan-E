import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/app_theme.dart';

class AppNetworkImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
  final Widget? errorWidget;
  final IconData fallbackIcon;

  const AppNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
    this.fallbackIcon = Icons.image,
  });

  Widget _buildPlaceholder(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: width,
      height: height,
      color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade200,
      child: const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.brandColor),
        ),
      ),
    );
  }

  Widget _buildErrorWidget(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: width,
      height: height,
      color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade300,
      child: Center(
        child: Icon(fallbackIcon, size: 36, color: Colors.grey.shade500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final effectivePlaceholder = placeholder ?? _buildPlaceholder(context);
    final effectiveError = errorWidget ?? _buildErrorWidget(context);

    // Sanitize image URL or fallback to reliable high-res travel photo
    final url = imageUrl.trim().isNotEmpty
        ? imageUrl.trim()
        : 'https://images.unsplash.com/photo-1566073771259-6a8506099945?auto=format&fit=crop&w=1200&q=80';

    Widget image;

    if (kIsWeb) {
      // On Web, use Image.network to avoid flutter_cache_manager IndexedDB / raw byte fetch failures
      image = Image.network(
        url,
        width: width,
        height: height,
        fit: fit,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return effectivePlaceholder;
        },
        errorBuilder: (context, error, stackTrace) {
          return effectiveError;
        },
      );
    } else {
      image = CachedNetworkImage(
        imageUrl: url,
        width: width,
        height: height,
        fit: fit,
        placeholder: (context, url) => effectivePlaceholder,
        errorWidget: (context, url, error) => effectiveError,
      );
    }

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: image,
      );
    }

    return image;
  }
}

ImageProvider appNetworkImageProvider(String url) {
  final cleanUrl = url.trim().isNotEmpty
      ? url.trim()
      : 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=400&q=80';
  if (kIsWeb) {
    return NetworkImage(cleanUrl);
  }
  return CachedNetworkImageProvider(cleanUrl);
}
