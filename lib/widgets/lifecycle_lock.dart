import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';

class LifecycleLock extends StatefulWidget {
  const LifecycleLock({required this.child, super.key});

  final Widget child;

  @override
  State<LifecycleLock> createState() => _LifecycleLockState();
}

class _LifecycleLockState extends State<LifecycleLock>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      final auth = context.read<AuthProvider>();
      if (auth.isUnlocked) {
        auth.lock();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
