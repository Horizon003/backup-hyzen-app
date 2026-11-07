import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ScanFilterChoice {
  const ScanFilterChoice(this.filter, this.all);
  final String filter;
  final bool all;
}

class ScanFilterSheet extends StatefulWidget {
  const ScanFilterSheet({
    super.key,
    required this.path,
    required this.multiple,
  });
  final String path;
  final bool multiple;
  @override
  State<ScanFilterSheet> createState() => _ScanFilterSheetState();
}

class _ScanFilterSheetState extends State<ScanFilterSheet> {
  static const _camera = MethodChannel('com.hyzen.pharmd/camera_pages');
  bool _allowPop = false;
  Future<void> _close([ScanFilterChoice? choice]) async {
    setState(() => _allowPop = true);
    await WidgetsBinding.instance.endOfFrame;
    if (mounted) Navigator.pop(context, choice);
  }

  String _filter = 'original', _committed = 'original';
  bool _all = false, _loading = true, _processing = false;
  Uint8List? _bytes;
  String? _error;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final info = await _camera.invokeMapMethod<String, dynamic>('pageInfo', {
        'path': widget.path,
      });
      _committed = info?['filter'] as String? ?? 'original';
      _filter = _committed;
    } catch (_) {}
    if (mounted) _preview();
  }

  Future<void> _preview() async {
    if (_processing) return;
    _processing = true;
    while (mounted) {
      final requested = _filter;
      setState(() {
        _loading = true;
        _error = null;
      });
      try {
        final bytes = await _camera.invokeMethod<Uint8List>('preview', {
          'path': widget.path,
          'filter': requested,
        });
        if (!mounted) break;
        if (requested == _filter) {
          setState(() {
            _bytes = bytes;
            _loading = false;
          });
        }
      } catch (_) {
        if (mounted && requested == _filter) {
          setState(() {
            _error = 'Preview could not load. Select a filter to retry.';
            _loading = false;
          });
        }
      }
      if (requested == _filter) break;
    }
    _processing = false;
  }

  Future<void> _back() async {
    if (_filter == _committed && !_all) {
      if (mounted) await _close();
      return;
    }
    final action = await showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Apply filter changes?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, 'cancel'),
            child: const Text('Keep editing'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, 'discard'),
            child: const Text('Discard'),
          ),
          FilledButton(
            onPressed: _loading ? null : () => Navigator.pop(c, 'apply'),
            child: const Text('Apply'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (action == 'discard') await _close();
    if (action == 'apply') _close(ScanFilterChoice(_filter, _all));
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: _allowPop,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) _back();
    },
    child: SizedBox(
      height: MediaQuery.sizeOf(context).height * .72,
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: _close,
                tooltip: 'Cancel filters',
                icon: const Icon(Icons.close),
              ),
              const Expanded(
                child: Text(
                  'Filters',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                ),
              ),
              IconButton(
                tooltip: 'Confirm filter',
                onPressed: _loading || _error != null
                    ? null
                    : () => _close(ScanFilterChoice(_filter, _all)),
                icon: const Icon(Icons.check),
              ),
            ],
          ),
          if (_loading) const LinearProgressIndicator(),
          Expanded(
            child: _bytes == null
                ? Center(child: Text(_error ?? 'Preparing preview…'))
                : Image.memory(
                    _bytes!,
                    fit: BoxFit.contain,
                    gaplessPlayback: true,
                  ),
          ),
          if (_error != null) Text(_error!),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final item in [
                  ('original', 'Original'),
                  ('magic', 'Magic colour'),
                  ('gray', 'Grayscale'),
                  ('bw', 'Black & white'),
                ])
                  Padding(
                    padding: const EdgeInsets.all(4),
                    child: ChoiceChip(
                      label: Text(item.$2),
                      selected: _filter == item.$1,
                      onSelected: (_) {
                        setState(() => _filter = item.$1);
                        _preview();
                      },
                    ),
                  ),
              ],
            ),
          ),
          if (widget.multiple)
            SwitchListTile(
              title: const Text('Apply to all pages'),
              value: _all,
              onChanged: (v) => setState(() => _all = v),
            ),
        ],
      ),
    ),
  );
}
