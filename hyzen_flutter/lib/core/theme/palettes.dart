import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/providers.dart';

/// Approved brand is Deep Teal (Q02). Alternative accents remain available as
/// personal preferences, but every install starts on Hyzen Teal.
const brandPalettes = <String, (String, Color)>{
  'teal': ('Hyzen Teal', Color(0xFF087F76)),
  'ocean': ('Clinical Blue', Color(0xFF2B6F9E)),
  'green': ('Pharmacy Green', Color(0xFF15724A)),
  'sage': ('Apothecary Sage', Color(0xFF5B6E4A)),
  'slate': ('Graphite Slate', Color(0xFF3B5664)),
  'amber': ('Calendula Gold', Color(0xFF9A6516)),
  'rose': ('Rose Wellness', Color(0xFFA34E6E)),
  'purple': ('Classic Purple', Color(0xFF6D3FD4)),
};

class PaletteController extends Notifier<String> {
  @override
  String build() {
    final prefs = ref.watch(sharedPrefsProvider);
    // One-time migration: earlier releases defaulted to purple.
    if (prefs.getBool('brand_palette_v15') != true) {
      final old = prefs.getString('brand_palette');
      if (old == null ||
          old == 'default' ||
          old == 'purple' ||
          old == 'mint' ||
          old == 'lavender') {
        prefs.setString('brand_palette', 'teal');
      }
      prefs.setBool('brand_palette_v15', true);
    }
    return prefs.getString('brand_palette') ?? 'teal';
  }

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
  return brandPalettes.containsKey(chosen) ? chosen : 'teal';
});
final paletteColorProvider = Provider<Color>(
  (ref) =>
      brandPalettes[ref.watch(effectivePaletteProvider)]?.$2 ??
      brandPalettes['teal']!.$2,
);
