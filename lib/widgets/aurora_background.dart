import 'package:flutter/material.dart';

class AuroraBackground extends StatelessWidget {
  const AuroraBackground({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                Color(0xFF060914),
                Color(0xFF12173A),
                Color(0xFF1D0F3B),
              ],
            ),
          ),
        ),
        Positioned(
          top: -100,
          right: -50,
          child: _glow(const Color(0xFF6F52FF)),
        ),
        Positioned(
          bottom: -120,
          left: -80,
          child: _glow(const Color(0xFF26E7FF)),
        ),
        child,
      ],
    );
  }

  Widget _glow(Color color) {
    return Container(
      width: 260,
      height: 260,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: color.withValues(alpha: 0.35),
            blurRadius: 120,
            spreadRadius: 40,
          ),
        ],
      ),
    );
  }
}
