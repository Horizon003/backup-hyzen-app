import 'package:flutter/material.dart';
import '../academics/data/drive_gateway.dart';
import '../../core/errors/app_error.dart';
import 'offline_pdf.dart';
import 'reader_chrome.dart';
import '../downloads/data/file_store.dart';
import '../academics/domain/drive.dart';
import 'preview_frame.dart';

/// PDFium reads byte ranges. Offline save is a separate explicit operation.
class NativePreview extends StatefulWidget {
  const NativePreview({super.key, required this.url, this.tools});
  final String url;
  final ReaderTools? tools;
  @override
  State<NativePreview> createState() => _NativePreviewState();
}

class _NativePreviewState extends State<NativePreview> {
  late Future<DocumentRequest> _request;
  Future<DownloadedFile>? _documentDownload;
  bool _onlinePreview = false;
  @override
  void initState() {
    super.initState();
    _request = DriveGateway.instance.resolve(widget.url);
  }

  void _retry() => setState(() {
    _onlinePreview = false;
    _documentDownload = null;
    _request = DriveGateway.instance.resolve(widget.url, refresh: true);
  });
  @override
  Widget build(BuildContext context) => _onlinePreview
      ? PreviewFrame(url: DriveLinks.previewUrl(widget.url), tools: widget.tools)
      : FutureBuilder<DocumentRequest>(
          future: _request,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              final error = snapshot.error;
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.cloud_off_rounded, size: 40),
                      const SizedBox(height: 14),
                      Text(
                        error is FriendlyException
                            ? error.message
                            : 'Could not open this file.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        children: [
                          FilledButton(
                            onPressed: _retry,
                            child: const Text('Retry'),
                          ),
                          if (DriveLinks.fileId(widget.url).isNotEmpty)
                            FilledButton.tonal(
                              onPressed: () =>
                                  setState(() => _onlinePreview = true),
                              child: const Text('Online preview'),
                            ),
                          OutlinedButton(
                            onPressed: () async {
                              try {
                                await DriveGateway.instance.connect();
                                _retry();
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(
                                    context,
                                  ).showSnackBar(SnackBar(content: Text('$e')));
                                }
                              }
                            },
                            child: const Text('Connect Google Drive'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }
            final data = snapshot.data;
            if (data == null) {
              return const Center(child: CircularProgressIndicator());
            }
            if (data.publicFallback) {
              return PreviewFrame(url: DriveLinks.previewUrl(widget.url), tools: widget.tools);
            }
            if (data.mimeType != null && data.mimeType != 'application/pdf') {
              return FutureBuilder<DownloadedFile>(
                future: _documentDownload ??= FileStore.create().download(
                  widget.url,
                  'preview_${DriveLinks.offlineKey(widget.url)}',
                  (_, __) {},
                ),
                builder: (context, file) => file.hasData
                    ? OfflinePdf(path: file.data!.path, tools: widget.tools)
                    : file.hasError
                    ? const Center(
                        child: Text(
                          'Could not open this document. Please retry.',
                        ),
                      )
                    : const Center(child: CircularProgressIndicator()),
              );
            }
            return OfflinePdf(
              tools: widget.tools,
              uri: data.uri,
              headers: data.headers,
              onOnlinePreview: DriveLinks.fileId(widget.url).isEmpty
                  ? null
                  : () => setState(() => _onlinePreview = true),
            );
          },
        );
}
