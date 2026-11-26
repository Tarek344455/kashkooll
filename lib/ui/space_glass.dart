import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class KashkoolColors {
  static const Color cosmicBlack = Color(0xFF070B19);
  static const Color deepVoid = Color(0xFF0A0F1C);
  static const Color spaceSurface = Color(0xFF141D2F);
  static const Color neonCyan = Color(0xFF38BDF8);
  static const Color nebulaPurple = Color(0xFFA78BFA);
  static const Color emeraldValid = Color(0xFF34D399);
  static const Color solarGold = Color(0xFFEAB308);
  static const Color crimsonBlocked = Color(0xFFF87171);
  static const Color textPrimary = Color(0xFFF1F5F9);
  static const Color textSecondary = Color(0xFF94A3B8);
}

class CosmicParallaxCanvas extends StatefulWidget {
  final bool examModeActive;

  const CosmicParallaxCanvas({super.key, this.examModeActive = false});

  @override
  State<CosmicParallaxCanvas> createState() => _CosmicParallaxCanvasState();
}

class _CosmicParallaxCanvasState extends State<CosmicParallaxCanvas>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 24),
    );
    if (!widget.examModeActive) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant CosmicParallaxCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.examModeActive && _controller.isAnimating) {
      _controller.stop();
    } else if (!widget.examModeActive && !_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disableAnim = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            painter: _StarfieldPainter(
              progress: (widget.examModeActive || disableAnim)
                  ? 0.0
                  : _controller.value,
            ),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}

class _StarfieldPainter extends CustomPainter {
  final double progress;

  _StarfieldPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = KashkoolColors.cosmicBlack;
    canvas.drawRect(Offset.zero & size, bgPaint);

    final nebulaPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0, -0.6),
        radius: 0.9,
        colors: [
          KashkoolColors.neonCyan.withValues(alpha: 0.14),
          KashkoolColors.nebulaPurple.withValues(alpha: 0.05),
          Colors.transparent,
        ],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, nebulaPaint);

    final starPaint = Paint();
    for (int i = 0; i < 64; i++) {
      final depth = (i % 3) + 1;
      final fx = ((i * 73) % 100) / 100.0;
      final fy = ((i * 41) % 100) / 100.0;
      final x = (fx * size.width + progress * depth * 28) % size.width;
      final y = fy * size.height;
      final twinkle =
          0.35 + 0.55 * (0.5 + 0.5 * math.sin(progress * math.pi * 2 + i));
      starPaint.color = (depth == 3
              ? KashkoolColors.neonCyan
              : depth == 2
                  ? KashkoolColors.nebulaPurple
                  : KashkoolColors.textPrimary)
          .withValues(alpha: twinkle.clamp(0.15, 0.85));
      canvas.drawCircle(Offset(x, y), depth * 0.55, starPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _StarfieldPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class ZeroGravityCard extends StatefulWidget {
  final Widget child;
  final Color borderColor;
  final double phaseOffset;
  final bool freezeMotion;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  const ZeroGravityCard({
    super.key,
    required this.child,
    this.borderColor = KashkoolColors.neonCyan,
    this.phaseOffset = 0.0,
    this.freezeMotion = false,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  State<ZeroGravityCard> createState() => _ZeroGravityCardState();
}

class _ZeroGravityCardState extends State<ZeroGravityCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _floatController;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5600),
    );
    if (!widget.freezeMotion) {
      _floatController.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant ZeroGravityCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.freezeMotion && _floatController.isAnimating) {
      _floatController.stop();
    } else if (!widget.freezeMotion && !_floatController.isAnimating) {
      _floatController.repeat();
    }
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disableAnim = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return AnimatedBuilder(
      animation: _floatController,
      builder: (context, child) {
        final dy = (widget.freezeMotion || disableAnim)
            ? 0.0
            : math.sin((_floatController.value * math.pi * 2) +
                    widget.phaseOffset) *
                2.8;
        final scale = _pressed ? 0.985 : 1.0;
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.translationValues(0, dy, 0)
            ..scaleByDouble(scale, scale, 1.0, 1.0),
          child: child,
        );
      },
      child: GestureDetector(
        onTapDown: widget.onTap == null
            ? null
            : (_) => setState(() => _pressed = true),
        onTapCancel: widget.onTap == null
            ? null
            : () => setState(() => _pressed = false),
        onTapUp: widget.onTap == null
            ? null
            : (_) => setState(() => _pressed = false),
        onTap: widget.onTap == null
            ? null
            : () {
                HapticFeedback.selectionClick();
                widget.onTap?.call();
              },
        child: Container(
          padding: widget.padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xEB141D2F),
                Color(0xF50E1525),
              ],
            ),
            border: Border.all(
              color: widget.borderColor.withValues(alpha: 0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.55),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

class SpaceButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final Color color;
  final Future<void> Function()? onPressedAsync;
  final VoidCallback? onPressed;

  const SpaceButton({
    super.key,
    required this.label,
    this.icon,
    this.color = KashkoolColors.neonCyan,
    this.onPressedAsync,
    this.onPressed,
  });

  @override
  State<SpaceButton> createState() => _SpaceButtonState();
}

class _SpaceButtonState extends State<SpaceButton> {
  bool _submitting = false;

  Future<void> _handleTap() async {
    if (_submitting) return;
    HapticFeedback.lightImpact();
    if (widget.onPressedAsync != null) {
      setState(() => _submitting = true);
      try {
        await widget.onPressedAsync!();
      } finally {
        if (mounted) setState(() => _submitting = false);
      }
    } else {
      widget.onPressed?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final enabled =
        !_submitting && (widget.onPressed != null || widget.onPressedAsync != null);
    return FilledButton.icon(
      onPressed: enabled ? _handleTap : null,
      style: FilledButton.styleFrom(
        backgroundColor: widget.color,
        foregroundColor: KashkoolColors.cosmicBlack,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      icon: _submitting
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(widget.icon ?? Icons.arrow_forward, size: 18),
      label: Text(
        widget.label,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class OrbitalIgnitionSplash extends StatefulWidget {
  final VoidCallback onComplete;

  const OrbitalIgnitionSplash({super.key, required this.onComplete});

  @override
  State<OrbitalIgnitionSplash> createState() => _OrbitalIgnitionSplashState();
}

class _OrbitalIgnitionSplashState extends State<OrbitalIgnitionSplash>
    with SingleTickerProviderStateMixin {
  late final AnimationController _orbitController;
  bool _fading = false;

  @override
  void initState() {
    super.initState();
    _orbitController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    Future.delayed(const Duration(milliseconds: 620), () {
      if (!mounted) return;
      setState(() => _fading = true);
    });
    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      widget.onComplete();
    });
  }

  @override
  void dispose() {
    _orbitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _fading ? 0.0 : 1.0,
      duration: const Duration(milliseconds: 260),
      child: Container(
        color: KashkoolColors.cosmicBlack,
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 112,
              height: 112,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  RotationTransition(
                    turns: _orbitController,
                    child: Container(
                      width: 112,
                      height: 112,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: KashkoolColors.neonCyan.withValues(alpha: 0.45),
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      gradient: const LinearGradient(
                        colors: [KashkoolColors.neonCyan, Color(0xFF0284C7)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: KashkoolColors.neonCyan.withValues(alpha: 0.45),
                          blurRadius: 28,
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'ك',
                      style: TextStyle(
                        color: KashkoolColors.cosmicBlack,
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'كشكول',
              style: TextStyle(
                color: KashkoolColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
