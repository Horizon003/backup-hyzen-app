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
    with SingleTickerProviderStateMixin {
  late final AnimationController _idle;

  String get _asset => switch (widget.state) {
    HyzenMascotState.welcome => 'assets/mascot/mascot_idle_welcome.png',
    HyzenMascotState.peeking => 'assets/mascot/mascot_peeking.png',
    HyzenMascotState.studying => 'assets/mascot/mascot_studying.png',
    HyzenMascotState.downloading => 'assets/mascot/mascot_downloading.png',
    HyzenMascotState.success => 'assets/mascot/mascot_success_wave.png',
  };

  @override
  void initState() {
    super.initState();
    _idle = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context) || !widget.loop) {
      _idle.stop();
    } else if (!_idle.isAnimating) {
      _idle.forward(from: 0);
    }
  }

  @override
  void didUpdateWidget(covariant HyzenMascot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.loop != widget.loop || oldWidget.state != widget.state) {
      final reduced = MediaQuery.disableAnimationsOf(context);
      if (reduced || !widget.loop) {
        _idle.stop();
      } else if (!_idle.isAnimating) {
        _idle.forward(from: 0);
      }
    }
  }

  @override
  void dispose() {
    _idle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    final transition = reduced
        ? const Duration(milliseconds: 80)
        : const Duration(milliseconds: 360);
    final motion = reduced
        ? const AlwaysStoppedAnimation<double>(0)
        : TweenSequence<double>([
            TweenSequenceItem(tween: Tween(begin: -2.5, end: 2.5), weight: 55),
            TweenSequenceItem(tween: Tween(begin: 2.5, end: 0), weight: 45),
          ]).animate(
            CurvedAnimation(parent: _idle, curve: Curves.easeInOutCubic),
          );

    return Semantics(
      image: true,
      label: widget.semanticLabel,
      child: SizedBox(
        width: widget.size,
        height: widget.size * 1.5,
        child: AnimatedBuilder(
          animation: motion,
          builder: (context, child) => Transform.translate(
            offset: Offset(0, motion.value),
            child: child,
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
