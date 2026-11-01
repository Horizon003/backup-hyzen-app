import 'dart:io';
import 'dart:typed_data';

Future<Uint8List> documentBytes(String path) => File(path).readAsBytes();
