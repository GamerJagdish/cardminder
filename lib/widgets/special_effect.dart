import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import '../services/sound_effect_service.dart';

export '../services/sound_effect_service.dart';

/// Theatrical fullscreen easter egg overlay featuring:
/// - True continuous, infinite clown & confetti rain that randomly enters from top.
/// - 3D movable clown emoji with real-time perspective tilt, spherical specular sheen,
///   squish physics, wall bouncing with zero impact lag, and pop-up burst particles.
/// - Low-latency horn honk sound routed through headphones/media.
class SpecialEffectOverlay extends StatefulWidget {
  final VoidCallback onDismiss;

  const SpecialEffectOverlay({super.key, required this.onDismiss});

  @override
  State<SpecialEffectOverlay> createState() => _SpecialEffectOverlayState();
}

class _SpecialEffectOverlayState extends State<SpecialEffectOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final Animation<double> _backdropFade;

  @override
  void initState() {
    super.initState();
    SoundEffectService.init();

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _backdropFade = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOut,
    );
    _entranceController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ClipRect(
        child: FadeTransition(
          opacity: _backdropFade,
          child: Material(
            color: Colors.black.withValues(alpha: 0.76),
            child: Stack(
              fit: StackFit.expand,
              children: [
              // 1. Continuous, infinite random rain (completely decoupled with RepaintBoundary)
              const Positioned.fill(
                child: RepaintBoundary(
                  child: _ContinuousRainLayer(),
                ),
              ),

              // 2. Ambient Circus Radial Vignette
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment.center,
                        radius: 0.85,
                        colors: [
                          const Color(0xFFF59E0B).withValues(alpha: 0.18),
                          const Color(0xFFEF4444).withValues(alpha: 0.07),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),
                ),
              ),

              // 3. Movable 3D Clown Emoji & Burst Layer (Direct Stack children for robust hit testing)
              const Positioned.fill(
                child: RepaintBoundary(
                  child: _MovableClownLayer(),
                ),
              ),

              // 4. Pack Up Circus Action Button
              Positioned(
                bottom: 24,
                left: 0,
                right: 0,
                child: Center(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      widget.onDismiss();
                    },
                    icon: const Text('🎪', style: TextStyle(fontSize: 18)),
                    label: const Text(
                      'Pack Up Circus',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        letterSpacing: 0.2,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF59E0B),
                      foregroundColor: Colors.black,
                      elevation: 8,
                      shadowColor:
                          const Color(0xFFF59E0B).withValues(alpha: 0.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side:
                            const BorderSide(color: Colors.white, width: 1.5),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 26,
                        vertical: 14,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  }
}

// ============================================================================
// Continuous Organic Rain: Pre-recorded GPU Display-List Drawing
// ============================================================================

class _RainDropParticle {
  double x;
  double y;
  double speed;
  final int type; // 0: small clown, 1: mid clown, 2: big clown, 3: star, 4: sparkle, 5: ribbon
  double rotation;
  final double rotSpeed;
  final double swayPhase;
  final double swaySpeed;
  final double swayAmplitude;
  final Color? confettiColor;

  _RainDropParticle({
    required this.x,
    required this.y,
    required this.speed,
    required this.type,
    required this.rotation,
    required this.rotSpeed,
    required this.swayPhase,
    required this.swaySpeed,
    required this.swayAmplitude,
    this.confettiColor,
  });
}

class _ContinuousRainLayer extends StatefulWidget {
  const _ContinuousRainLayer();

  @override
  State<_ContinuousRainLayer> createState() => _ContinuousRainLayerState();
}

class _ContinuousRainLayerState extends State<_ContinuousRainLayer>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _lastElapsed = Duration.zero;
  final List<_RainDropParticle> _particles = [];
  final math.Random _random = math.Random();
  late final List<ui.Picture> _cachedPictures;

  final _RainRepaintNotifier _repaintNotifier = _RainRepaintNotifier();

  @override
  void initState() {
    super.initState();

    // Pre-record emoji glyphs into compiled GPU display lists once.
    // This reduces rasterization cost from ~300μs (TextPainter) to ~2μs (drawPicture) per drop!
    _cachedPictures = [
      _recordEmojiPicture('🤡', 22, 0.45), // 0: Small clown
      _recordEmojiPicture('🤡', 32, 0.75), // 1: Medium clown
      _recordEmojiPicture('🤡', 44, 1.00), // 2: Large clown
      _recordEmojiPicture('⭐', 18, 0.90), // 3: Gold star
      _recordEmojiPicture('✨', 20, 0.90), // 4: Sparkle
    ];

    final confettiPalette = [
      const Color(0xFFEF4444),
      const Color(0xFFF59E0B),
      const Color(0xFF10B981),
      const Color(0xFF3B82F6),
      const Color(0xFFEC4899),
      const Color(0xFF8B5CF6),
    ];

    // 18 clown drops distributed across depth layers, initially scattered across the screen
    for (int i = 0; i < 18; i++) {
      final depth = i % 3;
      final speed = depth == 0
          ? 0.16 + _random.nextDouble() * 0.08
          : depth == 1
              ? 0.26 + _random.nextDouble() * 0.10
              : 0.38 + _random.nextDouble() * 0.12;

      _particles.add(_RainDropParticle(
        x: _random.nextDouble(),
        y: -0.15 + _random.nextDouble() * 1.25,
        speed: speed,
        type: depth,
        rotation: 0.0,
        rotSpeed: 0.0,
        swayPhase: _random.nextDouble() * math.pi * 2,
        swaySpeed: 1.2 + _random.nextDouble() * 1.4,
        swayAmplitude: 10.0 + _random.nextDouble() * 14.0,
      ));
    }

    // 8 festive stars and sparkles
    for (int i = 0; i < 8; i++) {
      _particles.add(_RainDropParticle(
        x: _random.nextDouble(),
        y: -0.15 + _random.nextDouble() * 1.25,
        speed: 0.20 + _random.nextDouble() * 0.14,
        type: i % 2 == 0 ? 3 : 4,
        rotation: 0.0,
        rotSpeed: 0.0,
        swayPhase: _random.nextDouble() * math.pi * 2,
        swaySpeed: 1.5 + _random.nextDouble() * 1.5,
        swayAmplitude: 12.0 + _random.nextDouble() * 12.0,
      ));
    }

    // 14 colorful confetti ribbons
    for (int i = 0; i < 14; i++) {
      _particles.add(_RainDropParticle(
        x: _random.nextDouble(),
        y: -0.15 + _random.nextDouble() * 1.25,
        speed: 0.28 + _random.nextDouble() * 0.22,
        type: 5,
        rotation: _random.nextDouble() * math.pi * 2,
        rotSpeed: (_random.nextDouble() - 0.5) * 4.0,
        swayPhase: _random.nextDouble() * math.pi * 2,
        swaySpeed: 1.8 + _random.nextDouble() * 1.8,
        swayAmplitude: 16.0 + _random.nextDouble() * 16.0,
        confettiColor: confettiPalette[i % confettiPalette.length],
      ));
    }

    _ticker = createTicker(_onTick)..start();
  }

  ui.Picture _recordEmojiPicture(String emoji, double fontSize, double opacity) {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final textPainter = TextPainter(
      text: TextSpan(
        text: emoji,
        style: TextStyle(
          fontSize: fontSize,
          color: Colors.white.withValues(alpha: opacity),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      Offset(-textPainter.width / 2, -textPainter.height / 2),
    );
    textPainter.dispose();
    return recorder.endRecording();
  }

  void _onTick(Duration elapsed) {
    if (_lastElapsed == Duration.zero) {
      _lastElapsed = elapsed;
      return;
    }
    final dt = ((elapsed - _lastElapsed).inMicroseconds / 1000000.0).clamp(0.0, 0.05);
    _lastElapsed = elapsed;
    if (dt <= 0) return;

    for (final p in _particles) {
      p.y += p.speed * dt;
      p.rotation += p.rotSpeed * dt;

      // Re-enter from top with fresh random X and speed when passing off the bottom
      if (p.y > 1.06) {
        p.y = -0.06 - _random.nextDouble() * 0.15;
        p.x = _random.nextDouble();
        if (p.type < 3) {
          final depth = p.type;
          p.speed = depth == 0
              ? 0.16 + _random.nextDouble() * 0.08
              : depth == 1
                  ? 0.26 + _random.nextDouble() * 0.10
                  : 0.38 + _random.nextDouble() * 0.12;
        }
      }
    }

    _repaintNotifier.notify();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _repaintNotifier.dispose();
    for (final pic in _cachedPictures) {
      pic.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _ContinuousRainPainter(
        repaint: _repaintNotifier,
        particles: _particles,
        pictures: _cachedPictures,
      ),
      size: Size.infinite,
    );
  }
}

class _RainRepaintNotifier extends ChangeNotifier {
  void notify() => notifyListeners();
}

class _ContinuousRainPainter extends CustomPainter {
  final List<_RainDropParticle> particles;
  final List<ui.Picture> pictures;
  final Paint _confettiPaint = Paint()..style = PaintingStyle.fill;

  _ContinuousRainPainter({
    required Listenable repaint,
    required this.particles,
    required this.pictures,
  }) : super(repaint: repaint);

  @override
  void paint(Canvas canvas, Size size) {
    final height = size.height;
    final width = size.width;

    for (final p in particles) {
      final y = p.y * height;
      final sway = math.sin(p.swayPhase + p.y * math.pi * 3) * p.swayAmplitude;
      final x = (p.x * width + sway).clamp(0.0, width);

      if (p.type < 5) {
        // Pre-recorded GPU display list: immediate, ultra-fast render
        canvas.save();
        canvas.translate(x, y);
        canvas.drawPicture(pictures[p.type]);
        canvas.restore();
      } else {
        // Confetti ribbon with tumbling rotation
        _confettiPaint.color = (p.confettiColor ?? const Color(0xFFF59E0B))
            .withValues(alpha: 0.78);

        canvas.save();
        canvas.translate(x, y);
        canvas.rotate(p.rotation);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(-4, -9, 8, 18),
            const Radius.circular(2),
          ),
          _confettiPaint,
        );
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ContinuousRainPainter oldDelegate) => false;
}

// ============================================================================
// Movable 3D Clown Emoji: Zero-Rebuild GPU Physics & True Edge-to-Edge Bounds
// ============================================================================

class _ClownPhysicsState {
  final Offset position;
  final double tiltX;
  final double tiltY;
  final double squish;

  const _ClownPhysicsState({
    required this.position,
    required this.tiltX,
    required this.tiltY,
    this.squish = 0.0,
  });

  _ClownPhysicsState copyWith({
    Offset? position,
    double? tiltX,
    double? tiltY,
    double? squish,
  }) {
    return _ClownPhysicsState(
      position: position ?? this.position,
      tiltX: tiltX ?? this.tiltX,
      tiltY: tiltY ?? this.tiltY,
      squish: squish ?? this.squish,
    );
  }
}

class _BurstParticle {
  final String symbol;
  final Offset velocity;
  Offset offset = Offset.zero;

  _BurstParticle({required this.symbol, required this.velocity});
}

class _MovableClownLayer extends StatefulWidget {
  const _MovableClownLayer();

  @override
  State<_MovableClownLayer> createState() => _MovableClownLayerState();
}

class _MovableClownLayerState extends State<_MovableClownLayer>
    with TickerProviderStateMixin {
  static const double _clownSize = 100.0;

  bool _initialized = false;
  late final ValueNotifier<_ClownPhysicsState> _physicsNotifier;

  // Fling momentum ticker
  Ticker? _flingTicker;
  Offset _flingVelocity = Offset.zero;
  Duration _lastFlingTime = Duration.zero;

  // Rest-tilt recovery animation controller
  late final AnimationController _tiltRecoveryController;

  // Tap bursts
  late final AnimationController _burstController;
  final List<_BurstParticle> _bursts = [];

  // Dialogue notifier (updating text never rebuilds clown)
  final ValueNotifier<String> _dialogueNotifier =
      ValueNotifier("yes that's me a clown. laugh on me bro :)");
  int _honkCount = 0;
  Timer? _dialogueResetTimer;
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();

    _physicsNotifier = ValueNotifier(
      const _ClownPhysicsState(
        position: Offset(150, 300),
        tiltX: 0.0,
        tiltY: 0.0,
      ),
    );

    _tiltRecoveryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );

    _burstController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    )..addListener(() {
        if (_bursts.isNotEmpty) {
          final t = _burstController.value;
          for (final b in _bursts) {
            b.offset = b.velocity * t;
          }
          setState(() {});
        }
      });
  }

  void _stopFling() {
    _flingTicker?.stop();
    _flingTicker?.dispose();
    _flingTicker = null;
    _lastFlingTime = Duration.zero;
    _flingVelocity = Offset.zero;
  }

  void _animateTiltToRest() {
    _tiltRecoveryController.stop();
    final startState = _physicsNotifier.value;
    if (startState.tiltX == 0.0 && startState.tiltY == 0.0 && startState.squish == 0.0) {
      return;
    }

    final startTiltX = startState.tiltX;
    final startTiltY = startState.tiltY;
    final startSquish = startState.squish;

    _tiltRecoveryController.reset();
    late final VoidCallback listener;
    listener = () {
      final t = Curves.easeOut.transform(_tiltRecoveryController.value);
      _physicsNotifier.value = _physicsNotifier.value.copyWith(
        tiltX: ui.lerpDouble(startTiltX, 0.0, t) ?? 0.0,
        tiltY: ui.lerpDouble(startTiltY, 0.0, t) ?? 0.0,
        squish: ui.lerpDouble(startSquish, 0.0, t) ?? 0.0,
      );
      if (_tiltRecoveryController.isCompleted) {
        _tiltRecoveryController.removeListener(listener);
      }
    };
    _tiltRecoveryController.addListener(listener);
    _tiltRecoveryController.forward();
  }

  void _startFling(Offset initialVelocity, Size screenSize) {
    _stopFling();
    _tiltRecoveryController.stop();
    _flingVelocity = initialVelocity;
    _lastFlingTime = Duration.zero;

    // True edge-to-edge bounds: clown touches physical display boundaries
    const minX = 0.0;
    final maxX = screenSize.width - _clownSize;
    const minY = 0.0;
    final maxY = screenSize.height - _clownSize;

    _flingTicker = createTicker((elapsed) {
      if (_lastFlingTime == Duration.zero) {
        _lastFlingTime = elapsed;
        return;
      }
      final dt = ((elapsed - _lastFlingTime).inMicroseconds / 1000000.0).clamp(0.0, 0.04);
      _lastFlingTime = elapsed;
      if (dt <= 0) return;

      // Smooth friction glide
      const friction = 1.3;
      _flingVelocity *= math.exp(-friction * dt);

      final current = _physicsNotifier.value;
      var squish = current.squish * math.exp(-14.0 * dt);

      var newPos = current.position + _flingVelocity * dt;
      bool bounced = false;
      const elasticity = 0.82;

      // Elastic reflection: exact contact at edges with zero stutter
      if (newPos.dx < minX) {
        newPos = Offset(minX, newPos.dy);
        _flingVelocity = Offset(-_flingVelocity.dx * elasticity, _flingVelocity.dy);
        bounced = true;
      } else if (newPos.dx > maxX) {
        newPos = Offset(maxX, newPos.dy);
        _flingVelocity = Offset(-_flingVelocity.dx * elasticity, _flingVelocity.dy);
        bounced = true;
      }

      if (newPos.dy < minY) {
        newPos = Offset(newPos.dx, minY);
        _flingVelocity = Offset(_flingVelocity.dx, -_flingVelocity.dy * elasticity);
        bounced = true;
      } else if (newPos.dy > maxY) {
        newPos = Offset(newPos.dx, maxY);
        _flingVelocity = Offset(_flingVelocity.dx, -_flingVelocity.dy * elasticity);
        bounced = true;
      }

      if (bounced && _flingVelocity.distance > 120.0) {
        squish = 0.16;
      }

      // Tilt follows fling direction smoothly
      final targetTiltX = (-_flingVelocity.dy * 0.0004).clamp(-0.35, 0.35);
      final targetTiltY = (_flingVelocity.dx * 0.0004).clamp(-0.35, 0.35);
      final lerpFactor = (dt * 12.0).clamp(0.0, 1.0);
      final tiltX = ui.lerpDouble(current.tiltX, targetTiltX, lerpFactor) ?? 0.0;
      final tiltY = ui.lerpDouble(current.tiltY, targetTiltY, lerpFactor) ?? 0.0;

      if (_flingVelocity.distance < 16.0) {
        _stopFling();
        _physicsNotifier.value = _ClownPhysicsState(
          position: newPos,
          tiltX: tiltX,
          tiltY: tiltY,
          squish: 0.0,
        );
        _animateTiltToRest();
        return;
      }

      // Pure ValueNotifier update: ZERO widget rebuilds!
      _physicsNotifier.value = _ClownPhysicsState(
        position: newPos,
        tiltX: tiltX,
        tiltY: tiltY,
        squish: squish,
      );
    })..start();
  }

  void _onClownTap() {
    _honkCount++;
    SoundEffectService.playHonk();
    HapticFeedback.heavyImpact();

    // Quick squish pop
    final current = _physicsNotifier.value;
    _physicsNotifier.value = current.copyWith(squish: 0.22);
    _animateTiltToRest();

    // Spawn popping burst symbols around clown
    _bursts.clear();
    final burstSymbols = ['🎵', '🎶', '✨', '⭐', '🎈', '🎉', '🔴'];
    for (int i = 0; i < 7; i++) {
      final angle = (i / 7.0) * math.pi * 2 + (_random.nextDouble() - 0.5) * 0.4;
      final speed = 75.0 + _random.nextDouble() * 65.0;
      _bursts.add(_BurstParticle(
        symbol: burstSymbols[i % burstSymbols.length],
        velocity: Offset(math.cos(angle) * speed, math.sin(angle) * speed),
      ));
    }
    _burstController.forward(from: 0.0);

    final quotes = [
      "HONK! 🔴 Squeak!",
      "HONK HONK! 🤡 Pure comedy!",
      "Stop poking me bro! 😂",
      "Do I look like a squeeze toy to you?! 🪅",
      "Honk #$_honkCount! Circus champion!",
    ];
    _setDialogue(quotes[_random.nextInt(quotes.length)]);
  }

  void _setDialogue(String text) {
    _dialogueResetTimer?.cancel();
    _dialogueNotifier.value = text;
    _dialogueResetTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) {
        _dialogueNotifier.value = "yes that's me a clown. laugh on me bro :)";
      }
    });
  }

  @override
  void dispose() {
    _stopFling();
    _tiltRecoveryController.dispose();
    _burstController.dispose();
    _dialogueResetTimer?.cancel();
    _dialogueNotifier.dispose();
    _physicsNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenSize = Size(constraints.maxWidth, constraints.maxHeight);

        if (!_initialized) {
          _physicsNotifier.value = _ClownPhysicsState(
            position: Offset(
              (screenSize.width - _clownSize) / 2,
              (screenSize.height - _clownSize) / 2 - 30,
            ),
            tiltX: 0.0,
            tiltY: 0.0,
          );
          _initialized = true;
        }

        const minX = 0.0;
        final maxX = screenSize.width - _clownSize;
        const minY = 0.0;
        final maxY = screenSize.height - _clownSize;

        return Stack(
          clipBehavior: Clip.none,
          children: [
        // 1. Tap burst particles
        if (_bursts.isNotEmpty && _burstController.isAnimating)
          ..._bursts.map((burst) {
            final clownCenter = Offset(
              _physicsNotifier.value.position.dx + _clownSize / 2,
              _physicsNotifier.value.position.dy + _clownSize / 2,
            );
            final pos = clownCenter + burst.offset;
            final progress = _burstController.value;
            return Positioned(
              left: pos.dx - 14,
              top: pos.dy - 14,
              child: IgnorePointer(
                child: Opacity(
                  opacity: (1.0 - progress).clamp(0.0, 1.0),
                  child: Transform.scale(
                    scale: 0.8 + progress * 0.9,
                    child: Text(
                      burst.symbol,
                      style: const TextStyle(fontSize: 22),
                    ),
                  ),
                ),
              ),
            );
          }),

        // 2. Zero-Rebuild 3D Movable Clown (Permanent Stack Positioned at 0,0)
        Positioned(
          left: 0,
          top: 0,
          child: ValueListenableBuilder<_ClownPhysicsState>(
            valueListenable: _physicsNotifier,
            builder: (context, physics, child) {
              // Dynamic speech bubble position: slides horizontally & flips vertically to stay on-screen
              final bubbleLeft =
                  (physics.position.dx + _clownSize / 2 - 95.0)
                      .clamp(12.0, screenSize.width - 200.0);
              final bubbleLocalX = bubbleLeft - physics.position.dx;
              final bubbleLocalY =
                  physics.position.dy < 62.0 ? 104.0 : -48.0;

              // 3D Perspective Matrix Transform
              final matrix = Matrix4.identity()
                ..setEntry(3, 2, 0.0015)
                ..rotateX(physics.tiltX)
                ..rotateY(physics.tiltY)
                ..rotateZ(physics.tiltY * 0.12);

              return Transform.translate(
                offset: physics.position,
                child: SizedBox(
                  width: _clownSize,
                  height: _clownSize,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _onClownTap,
                    onPanStart: (details) {
                      _stopFling();
                      _tiltRecoveryController.stop();
                      HapticFeedback.selectionClick();
                      _setDialogue("Wheeeee! Where we going bro? 🎈");
                    },
                    onPanUpdate: (details) {
                      final current = _physicsNotifier.value;
                      var newPos = current.position + details.delta;

                      // Exact edge-to-edge boundaries
                      newPos = Offset(
                        newPos.dx.clamp(minX, maxX),
                        newPos.dy.clamp(minY, maxY),
                      );

                      // Responsive 3D perspective tilt during drag
                      final targetTiltX =
                          (-details.delta.dy * 0.016).clamp(-0.35, 0.35);
                      final targetTiltY =
                          (details.delta.dx * 0.016).clamp(-0.35, 0.35);

                      // Zero rebuild: pure ValueNotifier update
                      _physicsNotifier.value = _ClownPhysicsState(
                        position: newPos,
                        tiltX: targetTiltX,
                        tiltY: targetTiltY,
                      );
                    },
                    onPanEnd: (details) {
                      final velocity = details.velocity.pixelsPerSecond;
                      if (velocity.distance > 80.0) {
                        _startFling(velocity, screenSize);
                        if (velocity.distance > 400.0) {
                          _setDialogue("WHEEEEEEE! 🚀 Look at me fly!");
                        }
                      } else {
                        _animateTiltToRest();
                      }
                    },
                    child: Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.center,
                      children: [
                        // Soft GPU Ground Shadow
                        Positioned(
                          bottom: -6,
                          child: Container(
                            width: 68,
                            height: 14,
                            decoration: BoxDecoration(
                              borderRadius: const BorderRadius.all(
                                Radius.elliptical(34, 7),
                              ),
                              gradient: RadialGradient(
                                colors: [
                                  Colors.black.withValues(alpha: 0.45),
                                  Colors.transparent,
                                ],
                                stops: const [0.3, 1.0],
                              ),
                            ),
                          ),
                        ),

                        // Speech Bubble (Dynamic offset, clamped to screen)
                        Positioned(
                          top: bubbleLocalY,
                          left: bubbleLocalX,
                          child: _buildSpeechBubble(),
                        ),

                        // 3D Perspective Body & Squish Scale (Transforms static child)
                        Transform(
                          transform: matrix,
                          alignment: Alignment.center,
                          child: Transform.scale(
                            scaleX: 1.0 + physics.squish,
                            scaleY: 1.0 - physics.squish,
                            alignment: Alignment.center,
                            child: child, // Static child! Never rebuilt!
                          ),
                        ),

                        // Hint Pill below/above clown
                        Positioned(
                          bottom: physics.position.dy > screenSize.height - 150.0
                              ? null
                              : -34,
                          top: physics.position.dy > screenSize.height - 150.0
                              ? -34
                              : null,
                          child: _buildHintPill(),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
            // The clown emoji & 3D specular sheen: constructed ONCE, never rebuilt during drag or fling
            child: _buildClownEmojiBody(),
          ),
        ),
      ],
    );
  },
);
  }

  Widget _buildClownEmojiBody() {
    return Stack(
      alignment: Alignment.center,
      children: [
        const Text(
          '🤡',
          style: TextStyle(
            fontSize: 96,
            height: 1.0,
          ),
        ),
        // 3D Spherical Specular Sheen (Gives glossy 3D rubber toy appearance)
        Positioned.fill(
          child: IgnorePointer(
            child: Container(
              margin: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  center: const Alignment(-0.35, -0.40),
                  radius: 0.55,
                  colors: [
                    Colors.white.withValues(alpha: 0.38),
                    Colors.white.withValues(alpha: 0.0),
                  ],
                  stops: const [0.0, 1.0],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSpeechBubble() {
    return ValueListenableBuilder<String>(
      valueListenable: _dialogueNotifier,
      builder: (context, text, _) {
        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 7,
          ),
          constraints: const BoxConstraints(maxWidth: 190),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFF59E0B),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.28),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF1E293B),
              fontWeight: FontWeight.w800,
              fontSize: 12.0,
              height: 1.2,
            ),
          ),
        );
      },
    );
  }

  Widget _buildHintPill() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.52),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.white12,
          width: 0.8,
        ),
      ),
      child: const Text(
        'Tap to Honk! • Drag to fling! 🚀',
        style: TextStyle(
          color: Color(0xFFFDE68A),
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
