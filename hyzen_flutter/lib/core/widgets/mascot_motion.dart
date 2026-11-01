import 'package:flutter/material.dart';

/// Semantic mascot states used by the app instead of decorative one-off images.
enum HyzenMascotState { welcome, peeking, studying, downloading, success }

class HyzenMascot extends StatefulWidget {
  const HyzenMascot({
    super.key,
    required this.state,
    this.size = 220,
    this.semanticLabel = 'Hyzen panda mascot',
    this.loop = true,
  });

  final HyzenMascotState state;
  final double size;
  final String semanticLabel;
  final bool loop;

  @override
  State<HyzenMascot> createState() => _HyzenMascotState();
}

class _HyzenMascotState extends State<HyzenMascot>
    with TickerProviderStateMixin {
  late final AnimationController _idle;
  late final AnimationController _blink;

  String get _asset => switch (widget.state) {
    HyzenMascotState.welcome => 'assets/mascot/mascot_idle_welcome.png',
    HyzenMascotState.peeking => 'assets/mascot/mascot_peeking.png',
    HyzenMascotState.studying => 'assets/mascot/mascot_studying.png',
    HyzenMascotState.downloading => 'assets/mascot/mascot_downloading.png',
    HyzenMascotState.success => 'assets/mascot/mascot_success_wave.png',
  };

  Duration get _idleDuration => switch (widget.state) {
    HyzenMascotState.success => const Duration(milliseconds: 1500),
    HyzenMascotState.downloading => const Duration(milliseconds: 1900),
    _ => const Duration(milliseconds: 2800),
  };

  @override
  void initState() {
    super.initState();
    _idle = AnimationController(vsync: this, duration: _idleDuration);
    // Long cycle with a short dip: a restrained blink-like expression pulse.
    _blink = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    );
  }

  void _syncAnimations() {
    final reduced = MediaQuery.disableAnimationsOf(context);
    if (reduced || !widget.loop) {
      _idle.stop();
      _blink.stop();
      return;
    }
    if (!_idle.isAnimating) {
      _idle
        ..duration = _idleDuration
        ..forward(from: 0);
    }
    if (!_blink.isAnimating) {
      _blink.forward(from: 0);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncAnimations();
  }

  @override
  void didUpdateWidget(covariant HyzenMascot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.loop != widget.loop || oldWidget.state != widget.state) {
      _idle.duration = _idleDuration;
      _idle.value = 0;
      _blink.value = 0;
      _syncAnimations();
    }
  }

  @override
  void dispose() {
    _idle.dispose();
    _blink.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    final transition = reduced
        ? const Duration(milliseconds: 80)
        : const Duration(milliseconds: 360);
    final bob = reduced
        ? const AlwaysStoppedAnimation<double>(0)
        : Tween<double>(begin: -2.5, end: 2.5).animate(
            CurvedAnimation(parent: _idle, curve: Curves.easeInOutSine),
          );
    final reaction = reduced
        ? const AlwaysStoppedAnimation<double>(1)
        : TweenSequence<double>([
            TweenSequenceItem(tween: Tween(begin: 1, end: .992), weight: 7),
            TweenSequenceItem(tween: Tween(begin: .992, end: 1), weight: 3),
            TweenSequenceItem(tween: ConstantTween(1), weight: 90),
          ]).animate(_blink);

    return Semantics(
      image: true,
      label: widget.semanticLabel,
      child: SizedBox(
        width: widget.size,
        height: widget.size * 1.5,
        child: AnimatedBuilder(
          animation: Listenable.merge([_idle, _blink]),
          builder: (context, child) => Transform.translate(
            offset: Offset(0, bob.value),
            child: Transform.scale(
              alignment: Alignment.bottomCenter,
              scaleY: reaction.value,
              child: child,
            ),
          ),
          child: AnimatedSwitcher(
            duration: transition,
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            layoutBuilder: (current, previous) => Stack(
              alignment: Alignment.bottomCenter,
              children: <Widget>[...previous, if (current != null) current],
            ),
            child: Image.asset(
              _asset,
              key: ValueKey(_asset),
              width: widget.size,
              height: widget.size * 1.5,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.medium,
            ),
          ),
        ),
      ),
    );
  }
}
