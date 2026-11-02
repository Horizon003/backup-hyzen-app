import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// Top-level locations owned by the StatefulShellRoute (bottom-dock shell).
const shellRoots = [
  '/home',
  '/study',
  '/search',
  '/pdf-studio',
  '/downloads',
  '/profile',
  '/shop',
  '/settings',
];

/// Whether [path] is rendered inside the bottom-dock shell.
bool isShellLocation(String path) {
  final p = Uri.parse(path).path;
  if (p.startsWith('/pdf-studio/viewer/')) return false; // full-screen root
  return shellRoots.any((r) => p == r || p.startsWith('$r/'));
}

/// Opens [path] without ever creating a second shell.
///
/// Pushing a shell location while a root route (notifications, orders,
/// viewer, create-pdf…) is on top makes go_router build another
/// StatefulShellRoute that reuses the same navigator GlobalKeys. Release
/// builds then hit framework.dart `_dependents.isEmpty` and the
/// notifyClients "really is our descendant" assertions (red screen).
/// In that situation we `go` to the shell location instead.
void openRoute(GoRouter router, String path) {
  final current = router.routerDelegate.currentConfiguration;
  final topIsShell =
      current.matches.isNotEmpty && current.matches.last is ShellRouteMatch;
  if (isShellLocation(path) && !topIsShell) {
    router.go(path);
  } else {
    router.push(path);
  }
}

extension SafeNavigation on BuildContext {
  /// Crash-safe replacement for `context.push` with dynamic/shell paths.
  void open(String path) => openRoute(GoRouter.of(this), path);
}
