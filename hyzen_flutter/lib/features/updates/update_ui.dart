import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../content/data/content_providers.dart';
import '../../core/widgets/common.dart';
import 'update_manifest.dart';
import '../viewer/document_flow.dart';
import 'package:go_router/go_router.dart';

const updateChannel = MethodChannel('com.hyzen.pharmd/updates');
final appVersionProvider = FutureProvider<String>((ref) async {
  // CI derives this define from pubspec.yaml for browser previews. Android
  // continues to read the installed package metadata over the native channel.
  const buildVersion = String.fromEnvironment('HYZEN_APP_VERSION');
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
    return buildVersion.isEmpty ? 'Version unavailable' : buildVersion;
  }
  try {
    final info = await updateChannel.invokeMapMethod<String, dynamic>('info');
    return '${info?['name'] ?? 'Version unavailable'}';
  } catch (_) {
    return 'Version unavailable';
  }
});

Future<void> checkForUpdate(
  BuildContext context,
  Map<String, dynamic> raw, {
  bool silent = false,
}) async {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
    if (!silent && context.mounted) {
      showHSnack(context, 'Updates are available in the Android app.');
    }
    return;
  }
  try {
    final info = await updateChannel.invokeMapMethod<String, dynamic>('info');
    final code = (info?['code'] as num?)?.toInt() ?? 0;
    final manifest = UpdateManifest.parse(raw);
    if (!context.mounted) return;
    if (manifest == null || manifest.code <= code) {
      if (!silent) {
        showHSnack(
          context,
          manifest == null
              ? 'No update has been published yet.'
              : 'You have the latest version.',
        );
      }
      return;
    }
    if (silent &&
        (ProviderScope.containerOf(context).read(documentHandoffProvider) ||
            GoRouter.of(
              context,
            ).routeInformationProvider.value.uri.path.contains('viewer'))) {
      return;
    }
    await showDialog<void>(
      context: context,
      barrierDismissible: !manifest.requiredFor(code),
      builder: (_) => _UpdateDialog(
        manifest: manifest,
        requiredUpdate: manifest.requiredFor(code),
      ),
    );
  } catch (_) {
    if (!silent && context.mounted) {
      showHSnack(
        context,
        'Update check unavailable. Please retry.',
        error: true,
      );
    }
  }
}

class UpdateGate extends ConsumerStatefulWidget {
  const UpdateGate({super.key, required this.child});
  final Widget child;
  @override
  ConsumerState<UpdateGate> createState() => _UpdateGateState();
}

class _UpdateGateState extends ConsumerState<UpdateGate> {
  int? _checked;
  @override
  Widget build(BuildContext context) {
    final raw = ref.watch(siteSettingsProvider).raw;
    final update = UpdateManifest.parse(raw);
    final path = GoRouter.of(context).routeInformationProvider.value.uri.path;
    final documentFlow =
        ref.watch(documentHandoffProvider) ||
        path.startsWith('/pdf-studio') ||
        path == '/viewer' ||
        path == '/imported-viewer' ||
        path == '/create-pdf';
    if (!documentFlow && update != null && _checked != update.code) {
      _checked = update.code;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) checkForUpdate(context, raw, silent: true);
      });
    }
    return widget.child;
  }
}

class _UpdateDialog extends StatefulWidget {
  const _UpdateDialog({required this.manifest, required this.requiredUpdate});
  final UpdateManifest manifest;
  final bool requiredUpdate;
  @override
  State<_UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<_UpdateDialog> {
  bool _busy = false;
  double? _progress;
  String? _path, _error;
  @override
  void initState() {
    super.initState();
    updateChannel.setMethodCallHandler((call) async {
      if (call.method == 'progress' && mounted) {
        final args = Map<String, dynamic>.from(call.arguments as Map);
        final total = (args['total'] as num).toDouble();
        setState(
          () =>
              _progress = total > 0 ? (args['received'] as num) / total : null,
        );
      }
    });
  }

  @override
  void dispose() {
    updateChannel.setMethodCallHandler(null);
    if (_busy) updateChannel.invokeMethod('cancel');
    super.dispose();
  }

  Future<void> _update() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final m = widget.manifest;
      _path ??= await updateChannel.invokeMethod<String>('download', {
        'url': m.url,
        'sha256': m.sha256,
        'code': m.code,
      });
      final installed = await updateChannel.invokeMethod<bool>('install', {
        'path': _path,
        'code': m.code,
      });
      if (!mounted) return;
      setState(
        () => _error = installed == false
            ? 'Allow “Install unknown apps” for PHARM D WITH HYZEN, return here, then tap Install update.'
            : 'Android installer opened. Confirm Update to finish.',
      );
    } on PlatformException catch (e) {
      if (mounted) {
        setState(() => _error = e.message ?? 'Update failed. Please retry.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !widget.requiredUpdate && !_busy,
    child: AlertDialog(
      title: Text('PHARM D WITH HYZEN ${widget.manifest.name} is ready'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.manifest.notes),
          const SizedBox(height: 16),
          const Text(
            'Your saved notes and profile stay on this device. Android may ask you to approve installation.',
          ),
          if (_busy) ...[
            const SizedBox(height: 16),
            LinearProgressIndicator(value: _progress),
            Text(
              _progress == null
                  ? 'Downloading update…'
                  : '${(_progress! * 100).round()}%',
            ),
          ],
          if (_error != null) ...[const SizedBox(height: 12), Text(_error!)],
        ],
      ),
      actions: [
        if (!_busy && !widget.requiredUpdate)
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Later'),
          ),
        if (_busy)
          TextButton(
            onPressed: () => updateChannel.invokeMethod('cancel'),
            child: const Text('Cancel download'),
          ),
        FilledButton(
          onPressed: _busy ? null : _update,
          child: Text(_path == null ? 'Update now' : 'Install update'),
        ),
      ],
    ),
  );
}
