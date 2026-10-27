import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;
import 'reader_chrome.dart';

/// Web preview: same Drive /preview iframe the website uses.
class PreviewFrame extends StatefulWidget {
  const PreviewFrame({super.key, required this.url, this.tools});
  final String url;
  final ReaderTools? tools;
  @override
  State<PreviewFrame> createState() => _PreviewFrameState();
}

class _PreviewFrameState extends State<PreviewFrame> {
  static int _seq = 0;
  late final String _type = 'hyzen-preview-${_seq++}';

  @override
  void initState() {
    super.initState();
    ui_web.platformViewRegistry.registerViewFactory(_type, (int _) {
      final f = web.HTMLIFrameElement()
        ..src = widget.url
        ..allow = 'autoplay'
        ..style.border = '0'
        ..style.width = '100%'
        ..style.height = '100%';
      return f;
    });
  }

  @override
  Widget build(BuildContext context) => HtmlElementView(viewType: _type);
}
