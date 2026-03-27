import 'package:flutter/material.dart';
import '../theme/app_styles.dart';
import '../utils/asset_path.dart';

/// Network or bundle image with graceful loading shimmer and error fallback.
class SafeNetworkOrAssetImage extends StatefulWidget {
  final String path;
  final BoxFit fit;
  final Alignment alignment;

  const SafeNetworkOrAssetImage({
    super.key,
    required this.path,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
  });

  @override
  State<SafeNetworkOrAssetImage> createState() => _SafeNetworkOrAssetImageState();
}

class _SafeNetworkOrAssetImageState extends State<SafeNetworkOrAssetImage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmer;

  @override
  void initState() {
    super.initState();
    _shimmer = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))
      ..repeat();
  }

  @override
  void dispose() {
    _shimmer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = normalizeBundleAssetPath(widget.path);
    if (p.isEmpty) {
      return const _ImageFallback();
    }
    if (p.startsWith('http://') || p.startsWith('https://')) {
      return Image.network(
        p,
        fit: widget.fit,
        alignment: widget.alignment,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _Shimmer(anim: _shimmer);
        },
        errorBuilder: (_, __, ___) => const _ImageFallback(),
      );
    }
    return Image.asset(
      p,
      fit: widget.fit,
      alignment: widget.alignment,
      errorBuilder: (_, __, ___) => const _ImageFallback(),
    );
  }
}

class _Shimmer extends StatelessWidget {
  final Animation<double> anim;

  const _Shimmer({required this.anim});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: anim,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(-1 + anim.value * 2, 0),
              end: Alignment(anim.value * 2, 0),
              colors: [
                AppStyles.bgLight,
                AppStyles.primaryBlue.withOpacity(0.12),
                AppStyles.bgLight,
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppStyles.bgLight,
      child: const Center(
        child: Icon(Icons.person_rounded, color: AppStyles.textSecondary, size: 32),
      ),
    );
  }
}
