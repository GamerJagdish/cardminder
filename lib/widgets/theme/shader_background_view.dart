import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../theme/theme_presets.dart';

/// Renders a hardware-accelerated animated GLSL fragment shader background.
///
/// Automatically handles FragmentProgram compilation caching, 60fps time ticking,
/// and graceful fallback rendering while loading.
class ShaderBackgroundView extends StatefulWidget {
  final AppThemePreset preset;
  final bool animate;
  final double opacity;
  final Widget? child;

  const ShaderBackgroundView({
    super.key,
    required this.preset,
    this.animate = true,
    this.opacity = 1.0,
    this.child,
  });

  /// Global static cache of loaded FragmentPrograms to avoid redundant asset loading.
  static final Map<String, ui.FragmentProgram> _programCache = {};

  @override
  State<ShaderBackgroundView> createState() => _ShaderBackgroundViewState();
}

class _ShaderBackgroundViewState extends State<ShaderBackgroundView>
    with SingleTickerProviderStateMixin {
  late AnimationController _timeController;
  ui.FragmentProgram? _currentProgram;

  @override
  void initState() {
    super.initState();
    _timeController = AnimationController(
      duration: const Duration(seconds: 120),
      vsync: this,
    );

    if (widget.preset.shaderType != ShaderType.none &&
        widget.preset.shaderAsset.isNotEmpty) {
      if (widget.animate) {
        _timeController.repeat();
      }
      _loadShader(widget.preset.shaderAsset);
    }
  }

  @override
  void didUpdateWidget(covariant ShaderBackgroundView oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.preset.shaderType == ShaderType.none ||
        widget.preset.shaderAsset.isEmpty) {
      if (_timeController.isAnimating) {
        _timeController.stop();
      }
      _currentProgram = null;
    } else {
      if (oldWidget.preset.shaderAsset != widget.preset.shaderAsset ||
          _currentProgram == null) {
        _loadShader(widget.preset.shaderAsset);
      }

      if (widget.animate) {
        if (!_timeController.isAnimating) {
          _timeController.repeat();
        }
      } else {
        if (_timeController.isAnimating) {
          _timeController.stop();
        }
      }
    }
  }

  @override
  void dispose() {
    _timeController.dispose();
    super.dispose();
  }

  Future<void> _loadShader(String assetPath) async {
    if (assetPath.isEmpty) return;

    if (ShaderBackgroundView._programCache.containsKey(assetPath)) {
      if (mounted) {
        setState(() {
          _currentProgram = ShaderBackgroundView._programCache[assetPath];
        });
      }
      return;
    }

    try {
      final program = await ui.FragmentProgram.fromAsset(assetPath);
      ShaderBackgroundView._programCache[assetPath] = program;
      if (mounted) {
        setState(() {
          _currentProgram = program;
        });
      }
    } catch (e) {
      debugPrint('Error loading fragment shader $assetPath: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.preset.shaderType == ShaderType.none ||
        widget.preset.shaderAsset.isEmpty) {
      return widget.child ?? const SizedBox.shrink();
    }

    Widget content;

    if (_currentProgram != null) {
      content = AnimatedBuilder(
        animation: _timeController,
        builder: (context, _) {
          return CustomPaint(
            painter: _ShaderPainter(
              program: _currentProgram!,
              time: _timeController.value * 120.0,
              preset: widget.preset,
            ),
            size: Size.infinite,
          );
        },
      );
    } else {
      // Graceful fallback during asset loading or on unsupported environments
      content = Container(
        decoration: BoxDecoration(
          color: widget.preset.bgColor,
          gradient: RadialGradient(
            center: const Alignment(0.4, -0.4),
            radius: 1.2,
            colors: [
              widget.preset.lineColor.withValues(alpha: 0.25),
              widget.preset.bgColor,
            ],
          ),
        ),
      );
    }

    if (widget.opacity < 1.0) {
      content = Opacity(opacity: widget.opacity, child: content);
    }

    if (widget.child != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          content,
          widget.child!,
        ],
      );
    }

    return content;
  }
}

class _ShaderPainter extends CustomPainter {
  final ui.FragmentProgram program;
  final double time;
  final AppThemePreset preset;

  _ShaderPainter({
    required this.program,
    required this.time,
    required this.preset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final shader = program.fragmentShader();

    // uniform vec2 uResolution; (index 0, 1)
    shader.setFloat(0, size.width);
    shader.setFloat(1, size.height);

    // uniform float uTime; (index 2)
    shader.setFloat(2, time);

    // uniform vec4 uLineColor; (index 3, 4, 5, 6)
    shader.setFloat(3, preset.lineColor.r);
    shader.setFloat(4, preset.lineColor.g);
    shader.setFloat(5, preset.lineColor.b);
    shader.setFloat(6, preset.lineColor.a);

    // uniform vec4 uBgColor; (index 7, 8, 9, 10)
    shader.setFloat(7, preset.bgColor.r);
    shader.setFloat(8, preset.bgColor.g);
    shader.setFloat(9, preset.bgColor.b);
    shader.setFloat(10, preset.bgColor.a);

    final paint = Paint()..shader = shader;
    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(covariant _ShaderPainter oldDelegate) {
    return oldDelegate.time != time ||
        oldDelegate.preset.id != preset.id ||
        oldDelegate.program != program;
  }
}
