import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme/app_styles.dart';
import '../utils/asset_path.dart';

class SafeSvgAsset extends StatelessWidget {
  final String assetPath;
  final double width;
  final double height;
  final ColorFilter? colorFilter;

  const SafeSvgAsset({
    super.key,
    required this.assetPath,
    required this.width,
    required this.height,
    this.colorFilter,
  });

  @override
  Widget build(BuildContext context) {
    final path = normalizeBundleAssetPath(assetPath);
    if (path.isEmpty) {
      return SizedBox(width: width, height: height, child: const Icon(Icons.image_not_supported_outlined, color: AppStyles.textSecondary, size: 22));
    }
    return SvgPicture.asset(
      path,
      width: width,
      height: height,
      colorFilter: colorFilter,
      placeholderBuilder: (_) => SizedBox(
        width: width,
        height: height,
        child: Center(child: SizedBox(width: width * 0.4, height: width * 0.4, child: const CircularProgressIndicator(strokeWidth: 2, color: AppStyles.primaryBlue))),
      ),
    );
  }
}
