import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/providers.dart';

const brandPalettes = <String, (String, Color)>{
  'purple': ('Hyzen Purple', Color(0xFF7C3AED)),
  'green': ('Pharmacy Green', Color(0xFF087747)),
  'ocean': ('Clinical Blue', Color(0xFF246FA8)),
  'lavender': ('Lavender Lab', Color(0xFF7953A5)),
  'mint': ('Mint Care', Color(0xFF167E74)),
  'sage': ('Apothecary Sage', Color(0xFF60734D)),
  'amber': ('Calendula Gold', Color(0xFFA16B16)),
  'rose': ('Rose Wellness', Color(0xFFAD5575)),
  'teal': ('Teal Rx', Color(0xFF177C90)),
};

class PaletteController extends Notifier<String> {
  @override
  String build() =>
      ref.watch(sharedPrefsProvider).getString('brand_palette') ?? 'default';
  void set(String id) {
    state = id;
    ref.read(sharedPrefsProvider).setString('brand_palette', id);
  }
}

final paletteProvider = NotifierProvider<PaletteController, String>(
  PaletteController.new,
);
final effectivePaletteProvider = Provider<String>((ref) {
  final chosen = ref.watch(paletteProvider);
  return chosen == 'default' ? 'purple' : chosen;
});
final paletteColorProvider = Provider<Color>(
  (ref) =>
      brandPalettes[ref.watch(effectivePaletteProvider)]?.$2 ??
      brandPalettes['purple']!.$2,
);
