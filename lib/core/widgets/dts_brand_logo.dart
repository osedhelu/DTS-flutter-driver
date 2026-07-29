import 'package:flutter/material.dart';

/// Logo DTS Delivery según el brillo del tema (light / dark).
class DtsBrandLogo extends StatelessWidget {
  const DtsBrandLogo({
    super.key,
    this.size = 96,
    this.forceDark,
  });

  /// Ancho/alto del logo en logical pixels.
  final double size;

  /// Si no es null, fuerza variante oscura (`true`) o clara (`false`).
  final bool? forceDark;

  static const lightAsset = 'assets/images/logo_light.png';
  static const darkAsset = 'assets/images/logo_dark.png';

  @override
  Widget build(BuildContext context) {
    final useDark = forceDark ??
        Theme.of(context).brightness == Brightness.dark;
    return Image.asset(
      useDark ? darkAsset : lightAsset,
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      semanticLabel: 'DTS Delivery',
    );
  }
}
