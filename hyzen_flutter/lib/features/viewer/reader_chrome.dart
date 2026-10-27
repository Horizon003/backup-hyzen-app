import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

class ReaderTools {
  VoidCallback? search, zoomIn, zoomOut, pages;
  void run(String action, BuildContext context) {
    final callback = switch (action) { 'search' => search, 'pages' => pages, 'in' => zoomIn, _ => zoomOut };
    if (callback != null) { callback(); return; }
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('This tool is available after a native PDF opens. Save offline for full PDF tools.')));
  }
}

class ReaderAction {
  const ReaderAction(this.label, this.icon, this.run, {this.group = 'File options'});
  final String label, group;
  final IconData icon;
  final VoidCallback run;
}

Future<void> showReaderActions(BuildContext context, List<ReaderAction> actions) =>
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (c) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(c).height * .85),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
            children: [
              for (var i = 0; i < actions.length; i++) ...[
                if (i == 0 || actions[i].group != actions[i - 1].group)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
                    child: Text(actions[i].group, style: Theme.of(c).textTheme.titleSmall),
                  ),
                ListTile(
                  leading: Icon(actions[i].icon),
                  title: Text(actions[i].label),
                  onTap: () { Navigator.pop(c); actions[i].run(); },
                ),
              ],
            ],
          ),
        ),
      ),
    );

/// Observes taps without joining the gesture arena, leaving native PDF pinch,
/// scrolling and long-press text selection intact.
class ReaderScaffold extends StatefulWidget {
  const ReaderScaffold({super.key, required this.title, required this.child,
    required this.actions, this.onShare, this.banner});
  final String title;
  final Widget child;
  final List<ReaderAction> actions;
  final VoidCallback? onShare;
  final Widget? banner;
  @override
  State<ReaderScaffold> createState() => _ReaderScaffoldState();
}

class _ReaderScaffoldState extends State<ReaderScaffold> {
  bool _visible = true, _moved = false;
  final _pointers = <int>{};
  Offset? _down;
  Duration? _time;
  void _back() {
    if (context.canPop()) { context.pop(); } else { context.go('/pdf-studio'); }
  }
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: theme.brightness == Brightness.dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerHighest,
      body: SafeArea(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          AnimatedSize(
            duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 180),
            alignment: Alignment.topCenter,
            curve: Curves.easeOutCubic,
            child: _visible ? Material(
              color: theme.colorScheme.surface,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                SizedBox(height: 58, child: Row(children: [
                  IconButton(tooltip: 'Back', onPressed: _back, icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20)),
                  const SizedBox(width: 4),
                  Icon(Icons.picture_as_pdf_rounded, size: 20, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(child: Text(widget.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium)),
                  if (widget.onShare != null) IconButton(tooltip: 'Share', onPressed: widget.onShare, icon: const Icon(Icons.ios_share_rounded, size: 21)),
                  IconButton(tooltip: 'File options', onPressed: () => showReaderActions(context, widget.actions),
                    icon: const Icon(Icons.more_horiz_rounded)),
                  const SizedBox(width: 4),
                ])),
                if (widget.banner != null) widget.banner!,
              ]),
            ) : const SizedBox.shrink(),
          ),
          Expanded(child: Listener(
            key: const ValueKey('reader-page-surface'),
            behavior: HitTestBehavior.translucent,
            onPointerDown: (e) {
              _pointers.add(e.pointer);
              if (_pointers.length == 1) { _down = e.position; _time = e.timeStamp; _moved = false; }
              else { _moved = true; }
            },
            onPointerMove: (e) { if (_down != null && (e.position - _down!).distance > 9) _moved = true; },
            onPointerCancel: (e) { _pointers.remove(e.pointer); _moved = true; },
            onPointerUp: (e) {
              _pointers.remove(e.pointer);
              if (!_moved && _pointers.isEmpty && _time != null && e.timeStamp - _time! < const Duration(milliseconds: 220)) {
                setState(() => _visible = !_visible);
              }
            },
            child: RepaintBoundary(child: widget.child),
          )),
        ]),
      ),
    ));
  }
}
