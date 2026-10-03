import 'package:flutter/material.dart';
import 'package:frontend/controllers/movil/auth_controller.dart';

/// Redirige una sola vez por invalidación, incluso desde rutas superpuestas.
class SessionNavigation extends StatefulWidget {
  const SessionNavigation({
    super.key,
    required this.loginBuilder,
    required this.builder,
  });

  final WidgetBuilder loginBuilder;
  final Widget Function(BuildContext, GlobalKey<NavigatorState>) builder;

  @override
  State<SessionNavigation> createState() => _SessionNavigationState();
}

class _SessionNavigationState extends State<SessionNavigation> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  AuthController? _auth;
  int _lastInvalidation = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = AuthScope.of(context);
    if (!identical(auth, _auth)) {
      _auth?.removeListener(_onSessionChanged);
      _auth = auth;
      _lastInvalidation = 0;
      auth.addListener(_onSessionChanged);
    }
    _onSessionChanged();
  }

  void _onSessionChanged() {
    final auth = _auth!;
    final version = auth.sessionInvalidationVersion;
    if (version == _lastInvalidation) return;
    _lastInvalidation = version;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          !identical(auth, _auth) ||
          auth.sessionInvalidationVersion != version ||
          auth.token != null) {
        return;
      }
      _navigatorKey.currentState?.pushAndRemoveUntil<void>(
        MaterialPageRoute<void>(builder: widget.loginBuilder),
        (_) => false,
      );
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  @override
  void dispose() {
    _auth?.removeListener(_onSessionChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _navigatorKey);
}
