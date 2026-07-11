import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sbg_profesores/theme/app_theme.dart';

bool get _supportsLiquidBlur {
  return defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.macOS;
}

class LiquidGlassPanel extends StatelessWidget {
  const LiquidGlassPanel({
    super.key,
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(18)),
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.clipBehavior = Clip.antiAlias,
    this.blurSigma = 18,
    this.opacity,
    this.borderColor,
    this.boxShadow,
  });

  final Widget child;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final Clip clipBehavior;
  final double blurSigma;
  final double? opacity;
  final Color? borderColor;
  final List<BoxShadow>? boxShadow;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final effectiveOpacity = opacity ?? (isDark ? 0.58 : 0.72);
    final fill = context.appPanel.withValues(alpha: effectiveOpacity);
    final border =
        borderColor ?? Colors.white.withValues(alpha: isDark ? 0.12 : 0.38);
    final shadows =
        boxShadow ??
        [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.24 : 0.12),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ];

    Widget content = DecoratedBox(
      decoration: BoxDecoration(
        color: fill,
        borderRadius: borderRadius,
        border: Border.all(color: border),
        boxShadow: shadows,
      ),
      child: Padding(padding: padding ?? EdgeInsets.zero, child: child),
    );

    if (_supportsLiquidBlur) {
      content = ClipRRect(
        borderRadius: borderRadius,
        clipBehavior: clipBehavior,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: content,
        ),
      );
    } else {
      content = ClipRRect(
        borderRadius: borderRadius,
        clipBehavior: clipBehavior,
        child: content,
      );
    }

    return Container(
      width: width,
      height: height,
      margin: margin,
      child: content,
    );
  }
}
