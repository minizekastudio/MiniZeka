import 'package:flutter/material.dart';

/// Uygulama acilirken tam ekran logo gosterir.
///
/// Android 12 ve sonrasinda sistemin kendi acilis ekrani (ortada yuvarlak
/// ikon) degistirilemiyor. Bu katman o ekran gectikten hemen sonra devreye
/// girer ve logoyu tam ekran gosterir, sonra yumusakca kaybolur.
class SplashOverlay extends StatefulWidget {
  final Widget child;
  const SplashOverlay({super.key, required this.child});

  @override
  State<SplashOverlay> createState() => _SplashOverlayState();
}

class _SplashOverlayState extends State<SplashOverlay> {
  /// Yalnizca uygulamanin ilk acilisinda gosterilir.
  static bool _alreadyShown = false;

  static const _hold = Duration(milliseconds: 1600);
  static const _fade = Duration(milliseconds: 500);

  late bool _visible;
  late bool _mountedInTree;

  @override
  void initState() {
    super.initState();
    _visible = !_alreadyShown;
    _mountedInTree = _visible;

    if (_visible) {
      _alreadyShown = true;
      Future.delayed(_hold, () {
        if (mounted) setState(() => _visible = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_mountedInTree)
          Positioned.fill(
            child: IgnorePointer(
              ignoring: !_visible,
              child: AnimatedOpacity(
                opacity: _visible ? 1.0 : 0.0,
                duration: _fade,
                curve: Curves.easeOut,
                onEnd: () {
                  if (!_visible && mounted) {
                    setState(() => _mountedInTree = false);
                  }
                },
                child: const _SplashArt(),
              ),
            ),
          ),
      ],
    );
  }
}

class _SplashArt extends StatelessWidget {
  const _SplashArt();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF11B5FE), // logonun gokyuzu
            Color(0xFF7FD0FF),
            Color(0xFF3FA64A),
            Color(0xFF0A7A15), // logonun alt yesili
          ],
          stops: [0.0, 0.38, 0.62, 1.0],
        ),
      ),
      child: Center(
        child: FractionallySizedBox(
          widthFactor: 0.92,
          child: Image.asset(
            'assets/splash/splash_full.png',
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
