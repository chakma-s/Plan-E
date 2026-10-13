import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class PlanELogoIcon extends StatelessWidget {
  final double size;
  final Color? color;
  final bool useAsset;

  const PlanELogoIcon({
    super.key,
    this.size = 28,
    this.color,
    this.useAsset = true,
  });

  const PlanELogoIcon.vector({
    super.key,
    this.size = 28,
    this.color,
  }) : useAsset = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = color ?? (isDark ? Colors.white : AppTheme.logoDark);

    if (useAsset) {
      return SizedBox(
        width: size,
        height: size,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Opacity(
              opacity: isDark ? 0.0 : 1.0,
              child: SvgPicture.asset(
                'assets/images/logo_icon_light.svg',
                width: size,
                height: size,
                fit: BoxFit.contain,
                colorFilter: color != null
                    ? ColorFilter.mode(color!, BlendMode.srcIn)
                    : null,
              ),
            ),
            Opacity(
              opacity: isDark ? 1.0 : 0.0,
              child: SvgPicture.asset(
                'assets/images/logo_icon_dark.svg',
                width: size,
                height: size,
                fit: BoxFit.contain,
                colorFilter: color != null
                    ? ColorFilter.mode(color!, BlendMode.srcIn)
                    : null,
              ),
            ),
          ],
        ),
      );
    }

    // Vector-only mode: draw directly with CustomPainter
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _PlanELogoPainter(iconColor),
      ),
    );
  }
}

class PlanELogo extends StatelessWidget {
  final double? height;
  final double iconSize;
  final double fontSize;
  final bool showText;
  final Color? iconColor;
  final Color? textColor;
  final bool useAsset;

  const PlanELogo({
    super.key,
    this.height,
    this.iconSize = 28,
    this.fontSize = 20,
    this.showText = true,
    this.iconColor,
    this.textColor,
    this.useAsset = true,
  });

  const PlanELogo.vector({
    super.key,
    this.height,
    this.iconSize = 28,
    this.fontSize = 20,
    this.showText = true,
    this.iconColor,
    this.textColor,
  }) : useAsset = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = textColor ?? (isDark ? Colors.white : AppTheme.logoDark);

    if (useAsset && showText && iconColor == null && textColor == null) {
      final effectiveHeight = height ?? iconSize;
      final effectiveWidth = effectiveHeight * (702.0 / 160.0);

      return SizedBox(
        width: effectiveWidth,
        height: effectiveHeight,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Opacity(
              opacity: isDark ? 0.0 : 1.0,
              child: SvgPicture.asset(
                'assets/images/logo_light.svg',
                width: effectiveWidth,
                height: effectiveHeight,
                fit: BoxFit.contain,
              ),
            ),
            Opacity(
              opacity: isDark ? 1.0 : 0.0,
              child: SvgPicture.asset(
                'assets/images/logo_dark.svg',
                width: effectiveWidth,
                height: effectiveHeight,
                fit: BoxFit.contain,
              ),
            ),
          ],
        ),
      );
    }

    return _buildComposedLogo(context, isDark, primaryTextColor);
  }

  Widget _buildComposedLogo(BuildContext context, bool isDark, Color primaryTextColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        PlanELogoIcon(
          size: iconSize,
          color: iconColor,
          useAsset: useAsset,
        ),
        if (showText) ...[
          const SizedBox(width: 8),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: 'PLAN',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w900,
                    fontSize: fontSize,
                    letterSpacing: 0.5,
                    color: primaryTextColor,
                  ),
                ),
                TextSpan(
                  text: '-E',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w900,
                    fontSize: fontSize,
                    letterSpacing: 0.5,
                    color: AppTheme.logoAccent,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _PlanELogoPainter extends CustomPainter {
  final Color color;

  const _PlanELogoPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 160.0;
    canvas.scale(scale, scale);

    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    // Smooth rounded frame with exact cubic bezier quarter-circles (k = 24 * 0.55228475 = 13.255)
    final framePath = Path()
      ..moveTo(114, 12)
      ..lineTo(36, 12)
      ..cubicTo(22.745, 12, 12, 22.745, 12, 36)
      ..lineTo(12, 124)
      ..cubicTo(12, 137.255, 22.745, 148, 36, 148)
      ..lineTo(124, 148)
      ..cubicTo(137.255, 148, 148, 137.255, 148, 124)
      ..lineTo(148, 42);

    canvas.drawPath(framePath, strokePaint);

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final planePath = Path()
      ..moveTo(142.0, 7.0)
      ..cubicTo(145.42, 7.17, 149.25, 7.92, 151.0, 9.0)
      ..cubicTo(151.83, 9.83, 152.0, 12.83, 152.0, 16.0)
      ..cubicTo(151.17, 19.33, 149.83, 23.5, 147.5, 26.75)
      ..cubicTo(144.0, 31.75, 137.5, 38.25, 133.0, 43.25)
      ..cubicTo(127.75, 49.25, 122.5, 54.75, 121.0, 56.0)
      ..cubicTo(122.5, 71.0, 124.5, 91.0, 127.0, 106.0)
      ..cubicTo(127.17, 111.17, 126.17, 115.83, 125.0, 117.0)
      ..cubicTo(122.67, 120.0, 120.33, 122.33, 119.0, 123.0)
      ..cubicTo(117.83, 122.83, 116.83, 122.17, 116.0, 121.0)
      ..cubicTo(113.17, 112.5, 109.83, 103.5, 106.0, 93.0)
      ..cubicTo(103.83, 87.33, 101.5, 83.17, 100.0, 82.0)
      ..cubicTo(97.67, 80.17, 96.67, 79.5, 96.0, 79.0)
      ..cubicTo(85.0, 88.5, 74.0, 98.5, 68.0, 103.0)
      ..cubicTo(68.67, 109.83, 69.67, 117.83, 70.0, 124.0)
      ..cubicTo(69.17, 126.67, 67.17, 128.0, 65.0, 128.0)
      ..cubicTo(62.17, 125.17, 58.83, 118.83, 55.0, 111.0)
      ..cubicTo(51.5, 111.67, 49.17, 112.67, 48.0, 113.0)
      ..cubicTo(46.83, 112.67, 46.17, 111.67, 46.0, 111.0)
      ..cubicTo(46.67, 108.33, 47.67, 106.33, 48.0, 105.0)
      ..cubicTo(40.0, 100.5, 32.5, 95.5, 29.0, 94.0)
      ..cubicTo(31.0, 91.83, 33.67, 90.17, 36.0, 89.0)
      ..cubicTo(43.17, 89.83, 50.5, 90.5, 55.0, 91.0)
      ..cubicTo(63.83, 81.17, 72.83, 71.17, 79.0, 63.0)
      ..cubicTo(76.5, 60.17, 73.83, 57.83, 71.0, 56.0)
      ..cubicTo(58.5, 51.5, 46.0, 47.0, 38.0, 44.0)
      ..cubicTo(35.83, 42.83, 35.17, 41.83, 35.0, 41.0)
      ..cubicTo(37.67, 37.33, 41.0, 34.33, 44.0, 33.0)
      ..cubicTo(62.67, 34.83, 82.33, 37.17, 102.0, 39.0)
      ..cubicTo(111.17, 29.83, 120.33, 20.67, 126.0, 15.0)
      ..cubicTo(131.83, 11.5, 137.67, 8.67, 141.0, 8.0)
      ..close();

    canvas.drawPath(planePath, fillPaint);
  }

  @override
  bool shouldRepaint(covariant _PlanELogoPainter oldDelegate) => oldDelegate.color != color;
}
