import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class AnimatedTransferLine extends StatefulWidget {
  const AnimatedTransferLine({super.key});

  @override
  State<AnimatedTransferLine> createState() => _AnimatedTransferLineState();
}

class _AnimatedTransferLineState extends State<AnimatedTransferLine>
    with SingleTickerProviderStateMixin {
  static const _animationDuration = Duration(milliseconds: 900);

  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _animationDuration)
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 66,
      height: 12,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: TransferLinePainter(progress: _controller.value),
          );
        },
      ),
    );
  }
}

class TransferLinePainter extends CustomPainter {
  TransferLinePainter({required this.progress});

  static const _dashWidth = 7.0;
  static const _dashGap = 7.0;
  static const _strokeWidth = 2.0;
  static const _packetRadius = 2.5;
  static const _glowRadius = 5.0;
  static const _glowBlurRadius = 5.0;
  static const _glowOpacity = 0.18;

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    _drawAnimatedDashes(canvas, size);
    _drawTransferPacket(canvas, size);
  }

  void _drawAnimatedDashes(Canvas canvas, Size size) {
    const dashStride = _dashWidth + _dashGap;
    final animationOffset = progress * dashStride;
    final dashPaint = Paint()
      ..strokeWidth = _strokeWidth
      ..strokeCap = StrokeCap.round;

    var x = -dashStride + animationOffset;
    while (x < size.width) {
      final startX = x.clamp(0.0, size.width);
      final endX = (x + _dashWidth).clamp(0.0, size.width);

      if (endX > startX) {
        final position = ((startX + endX) / 2 / size.width).clamp(0.0, 1.0);
        dashPaint.color = _colorAt(position);
        canvas.drawLine(
          Offset(startX, size.height / 2),
          Offset(endX, size.height / 2),
          dashPaint,
        );
      }

      x += dashStride;
    }
  }

  void _drawTransferPacket(Canvas canvas, Size size) {
    final packetX = progress * size.width;
    final packetColor = _colorAt(progress);
    final center = Offset(packetX, size.height / 2);

    _drawPacketGlow(canvas, center, packetColor);
    canvas.drawCircle(center, _packetRadius, Paint()..color = packetColor);
  }

  void _drawPacketGlow(Canvas canvas, Offset center, Color color) {
    canvas.drawCircle(
      center,
      _glowRadius,
      Paint()
        ..color = color.withValues(alpha: _glowOpacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, _glowBlurRadius),
    );
  }

  Color _colorAt(double position) {
    return Color.lerp(AppColors.spotifyGreen, AppColors.youtubeRed, position)!;
  }

  @override
  bool shouldRepaint(covariant TransferLinePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
