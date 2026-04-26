import 'package:flutter/material.dart';

class ActivityListener extends StatelessWidget {
  const ActivityListener({
    required this.onActivity,
    required this.child,
    super.key,
  });

  final VoidCallback onActivity;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => onActivity(),
      onPointerMove: (_) => onActivity(),
      child: child,
    );
  }
}
