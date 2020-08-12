import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';

class QualityProvider with ChangeNotifier {
  int quality;

  QualityProvider({this.quality});

  changeQuality(int qual) async {
    final settings = await Hive.openBox('settings');
    settings.put('quality', qual);
    quality = qual;
    notifyListeners();
  }
}